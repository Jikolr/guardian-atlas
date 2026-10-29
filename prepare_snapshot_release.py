"""Build verified release ZIPs outside the repository without publishing.

Usage: python prepare_snapshot_release.py --version VERSION --snapshot-root PATH
       --phone-source PATH --output PATH

Reads the captured phone/reports/inventory.json and apk/decoded-inventory.json.
No game code or decryption tool is executed. The live catalog is not changed.
"""
from pathlib import Path, PurePosixPath
import argparse
import collections
import hashlib
import json
import struct
import zipfile

BASE = Path(__file__).resolve().parent
ALLOWED = {'AssetBundles', 'Assets', 'events', 'GameScript', 'Hotfix', 'media', 'static_data', 'Tilemaps', 'Title'}
MANIFESTS = {'files/.index-firstpass', 'files/Android.checksum', 'files/Android.index',
             'files/Android.index.etag', 'files/assetbundle-version',
             'files/assetbundle-version.etag', 'files/patch-index', 'files/patch-index.etag'}
CACHES = {'battleactions-bin', 'heroes-bin', 'monsters-bin', 'npc-bin', 'strings-bin-enUS'}
DECODE_FOLDERS = {'GameScript': 'decoded-scripts', 'static_data': 'decoded-static',
                  'Tilemaps': 'decoded-maps', 'events': 'decoded-events'}
EXECUTABLE_SUFFIXES = {'.apk', '.dex', '.so', '.dll', '.exe', '.pdb'}


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path, value, pretty=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.pending-write')
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=2 if pretty else None,
                               separators=None if pretty else (',', ':')), encoding='utf-8')
    temp.replace(path)


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as src:
        for block in iter(lambda: src.read(4 * 1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def safe_path(root, relative):
    parts = PurePosixPath(relative.replace('\\', '/'))
    if parts.is_absolute() or '..' in parts.parts or ':' in str(parts):
        raise ValueError('Unsafe relative path: ' + relative)
    resolved = (root / Path(*parts.parts)).resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise ValueError('Path escaped root: ' + relative)
    return resolved


def public_phone(path):
    parts = PurePosixPath(path).parts
    return (path in MANIFESTS or
            len(parts) > 2 and parts[0] == 'files' and parts[1] in ALLOWED or
            len(parts) == 2 and parts[0] == 'cache' and parts[1] in CACHES)


def public_apk(path):
    parts = PurePosixPath(path).parts
    lower = path.lower()
    if len(parts) < 4 or parts[1] != 'assets':
        return False
    game_content = parts[2] in ALLOWED or parts[2:4] == ('bin', 'Data')
    return (game_content and Path(path).suffix.lower() not in EXECUTABLE_SUFFIXES and
            '/il2cpp' not in lower and '/managed/' not in lower and
            'global-metadata' not in lower and not lower.endswith('-resources.dat') and
            parts[-1] not in {'RuntimeInitializeOnLoads.json', 'ScriptingAssemblies.json', 'boot.config', 'unity_app_guid'})


def exported_files(repo):
    web, rows = repo / 'dist', []
    blocked = {'Extraction tools-' + n for n in ('decode_scripts.py', 'decode_static.py', 'decode_maps.py')}
    for folder in ('data', 'downloads'):
        for path in sorted((web / folder).rglob('*')):
            if not path.is_file() or path.name == 'file-catalog.json' or path.name in blocked:
                continue
            rel = path.relative_to(web).as_posix()
            rows.append(dict(section='exports', path=rel, bytes=path.stat().st_size,
                             url=rel, kind='Website export / preview'))
    return rows


def collect(args):
    snapshot = args.snapshot_root
    records = read(snapshot / 'phone/reports/inventory.json')['files']
    sources, excluded, gaps = [], [], []
    expected = {r['source'] for r in records}
    actual = {p.relative_to(args.phone_source).as_posix() for p in args.phone_source.rglob('*') if p.is_file()}
    if expected != actual:
        raise RuntimeError(f'Phone capture changed: {len(expected - actual)} missing, {len(actual - expected)} unexpected files')

    def add(section, bucket, rel, path, sha, kind, origin):
        if not path.is_file() or not sha:
            raise RuntimeError('Missing captured file or hash: ' + rel)
        sources.append(dict(section=section, bucket=bucket, path=rel, source=path,
                            sha256=sha, kind=kind, origin=origin))

    for row in records:
        rel = row['source']
        if not public_phone(rel):
            # Account-specific filenames and IDs belong only in the private audit.
            parts = PurePosixPath(rel).parts
            category = '/'.join(parts[:2]) if len(parts) > 2 else parts[0]
            excluded.append(dict(origin='phone', category=category, reason='Outside public game-content allowlist'))
            continue
        parts, family = PurePosixPath(rel).parts, row.get('family', '')
        encrypted = family in {'lua', 'static', 'manifest', 'media_manifest', 'map', 'hotfix'}
        original = safe_path(args.phone_source, rel)
        if family == 'map':
            with original.open('rb') as stream:
                encrypted = stream.read(4) != b'KONG'
        bucket = 'manifests' if rel in MANIFESTS else parts[1] if parts[0] == 'files' else 'cache'
        section = 'encrypted' if encrypted else 'unknown' if family in {'opaque_binary', 'text_or_binary_utf8'} else 'unencrypted'
        add(section, bucket, rel, original,
            row['source_sha256'], 'Original game content', 'phone')
        if row['status'] in {'failed', 'partial'}:
            gaps.append(dict(origin='phone', path=rel, status=row['status'],
                             note='Original included; no complete validated decoded output included.'))
            continue
        # Structured derivatives of k1ng containers complement the decrypted bytes.
        table = snapshot / 'phone/tables' / (rel + '.json')
        if table.is_file():
            folder = 'decoded' if parts[0] == 'cache' else 'decoded-static'
            tail = '/'.join(parts[2:]) if parts[0] == 'files' else parts[-1]
            add('decrypted', folder, folder + '/' + tail + '.json', table, digest(table),
                'Decoded table JSON', 'phone')
        if not row.get('output') or row['status'] != 'decoded' and family != 'map':
            continue
        decoded = safe_path(snapshot / 'phone', row['output'])
        folder = (DECODE_FOLDERS.get(parts[1], 'decoded-' + parts[1])
                  if parts[0] == 'files' and len(parts) > 2 else
                  'decoded-manifests' if rel in MANIFESTS else 'decoded')
        tail = '/'.join(parts[2:]) if parts[0] == 'files' and len(parts) > 2 else parts[-1]
        if family == 'lua':
            tail = str(PurePosixPath(tail).with_suffix('.lua'))
        elif family == 'static' and not table.is_file():
            with decoded.open('rb') as stream:
                head = stream.read(64).lstrip()
            if head.startswith((b'{', b'[')):
                tail += '.json'
        add('decrypted', folder, folder + '/' + tail, decoded,
            row['output_sha256'], 'Decrypted game content', 'phone')

    apk_manifest = snapshot / 'apk/decoded-inventory.json'
    if apk_manifest.is_file():
        document = read(apk_manifest)
        apk_records = document['files'] if isinstance(document, dict) else document
        for row in apk_records:
            rel = row['path']
            if not public_apk(rel):
                excluded.append(dict(origin='apk', path=rel, reason='Runtime, executable, metadata, or non-asset file'))
                continue
            original = safe_path(snapshot / 'apk/extracted', rel)
            section = 'encrypted' if row['status'] in {'decoded', 'partial', 'failed'} else 'unencrypted'
            add(section, 'apk-assets', 'apk/' + rel, original, row['source_sha256'],
                'Original APK game asset', 'apk')
            if row['status'] in {'failed', 'partial'}:
                gaps.append(dict(origin='apk', path=rel, status=row['status'],
                                 note='Original included; no complete validated decoded output included.'))
            elif row['status'] == 'decoded':
                add('decrypted', 'apk-assets', 'apk/' + rel,
                    safe_path(snapshot / 'apk', row['output']), row.get('output_sha256', row.get('sha256')),
                    'Decrypted APK game asset', 'apk')
    elif not args.skip_apk:
        raise RuntimeError('APK inventory missing; --skip-apk explicitly builds a phone-only snapshot')
    seen = set()
    for row in sources:
        key = row['section'], row['path']
        if key in seen:
            raise RuntimeError('Duplicate archive member: ' + str(key))
        seen.add(key)
    return sources, excluded, gaps


def verify(output):
    catalog, rows = read(output / 'file-catalog.pending.json'), collections.defaultdict(list)
    for row in catalog['files']:
        if row.get('archive'):
            rows[row['archive']].append(row)
    for archive in catalog['archives']:
        path = output / archive['name']
        if path.stat().st_size != archive['bytes'] or digest(path) != archive['sha256']:
            raise RuntimeError('Archive hash mismatch: ' + archive['name'])
        with zipfile.ZipFile(path) as z, path.open('rb') as raw:
            if z.testzip() is not None:
                raise RuntimeError('ZIP CRC failure: ' + archive['name'])
            if {i.filename for i in z.infolist()} != {r['member'] for r in rows[path.name]}:
                raise RuntimeError('ZIP catalog mismatch: ' + archive['name'])
            for row in rows[path.name]:
                info = z.getinfo(row['member'])
                if info.compress_type != zipfile.ZIP_STORED or info.file_size != row['bytes']:
                    raise RuntimeError('Unsupported ZIP entry: ' + row['member'])
                raw.seek(row['offset'])
                remaining, h = row['bytes'], hashlib.sha256()
                while remaining:
                    block = raw.read(min(4 * 1024 * 1024, remaining))
                    if not block:
                        raise RuntimeError('Truncated ZIP entry: ' + row['member'])
                    h.update(block)
                    remaining -= len(block)
                if h.hexdigest() != row['sha256']:
                    raise RuntimeError('Browser extraction offset/hash mismatch: ' + row['member'])
        print('Verified', archive['name'], len(rows[path.name]), 'files', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True)
    parser.add_argument('--snapshot-root', type=Path, required=True)
    parser.add_argument('--phone-source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--repo', type=Path, default=BASE)
    parser.add_argument('--github-repo', default='Jikolr/guardian-atlas')
    parser.add_argument('--limit-mib', type=int, default=250)
    parser.add_argument('--skip-apk', action='store_true')
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--refresh-exports', action='store_true')
    parser.add_argument('--refresh-live-exports', action='store_true',
                        help='Refresh direct website exports in the live catalog, preserving its release and archive entries')
    args = parser.parse_args()
    if args.output.resolve().is_relative_to(args.repo.resolve()):
        raise ValueError('Release archives must remain outside the website repository')
    if args.limit_mib <= 0:
        raise ValueError('Archive size limit must be positive')
    if args.verify_only:
        verify(args.output)
        return
    if args.refresh_exports or args.refresh_live_exports:
        exports = exported_files(args.repo)
        targets = []
        if args.refresh_exports:
            targets.append(args.output / 'file-catalog.pending.json')
        if args.refresh_live_exports:
            targets.append(args.repo / 'dist/data/file-catalog.json')
        for target in targets:
            catalog = read(target)
            catalog['files'] = [r for r in catalog['files'] if r['section'] != 'exports'] + exports
            write(target, catalog)
            print('Refreshed', target.name, len(exports), 'website exports; preserved release', catalog.get('currentVersion'))
        return
    args.output.mkdir(parents=True, exist_ok=True)
    sources, excluded, gaps = collect(args)
    groups = collections.defaultdict(list)
    for row in sources:
        groups[(row['section'], row['bucket'])].append(row)
    entries, archives = [], []
    for (section, bucket), group in sorted(groups.items()):
        chunks, chunk, length = [], [], 0
        for row in sorted(group, key=lambda r: r['path']):
            size = row['source'].stat().st_size
            if chunk and length + size > args.limit_mib * 1024 * 1024:
                chunks.append(chunk)
                chunk, length = [], 0
            chunk.append(row)
            length += size
        if chunk:
            chunks.append(chunk)
        for number, chunk in enumerate(chunks, 1):
            name = f'{section}-{bucket}-{number:02d}.zip'
            target, pending = args.output / name, args.output / (name + '.pending')
            members = []
            with zipfile.ZipFile(pending, 'w', compression=zipfile.ZIP_STORED, allowZip64=True) as z:
                for row in chunk:
                    member = section + '/' + row['path']
                    safe_path(args.output, member)
                    info = zipfile.ZipInfo(member, (1980, 1, 1, 0, 0, 0))
                    info.compress_type, info.external_attr = zipfile.ZIP_STORED, 0o644 << 16
                    h, size = hashlib.sha256(), 0
                    with row['source'].open('rb') as source, z.open(info, 'w') as destination:
                        for block in iter(lambda: source.read(4 * 1024 * 1024), b''):
                            h.update(block)
                            destination.write(block)
                            size += len(block)
                    if h.hexdigest() != row['sha256']:
                        raise RuntimeError('Captured source changed: ' + row['path'])
                    members.append(dict(section=section, path=row['path'], bytes=size, kind=row['kind'],
                                        archive=name, member=member, sha256=row['sha256'], version=args.version,
                                        headerOffset=z.getinfo(member).header_offset))
            with pending.open('rb') as raw:
                for row in members:
                    raw.seek(row.pop('headerOffset'))
                    header = raw.read(30)
                    if header[:4] != b'PK\x03\x04':
                        raise RuntimeError('Invalid ZIP header')
                    n, extra = struct.unpack_from('<HH', header, 26)
                    row['offset'] = raw.tell() + n + extra
            pending.replace(target)
            entries.extend(members)
            archives.append(dict(name=name, section=section, folder=bucket, bytes=target.stat().st_size,
                                 files=len(members), sha256=digest(target)))
            print('Built', name, len(members), 'files', flush=True)
    tag = 'game-files-' + args.version + '-snapshot'
    catalog = dict(version=1, currentVersion=args.version, releasePublished=False, releaseTag=tag,
                   releaseURL=f'https://github.com/{args.github_repo}/releases/tag/{tag}',
                   releaseBase=f'https://github.com/{args.github_repo}/releases/download/{tag}/',
                   archives=archives, files=entries + exported_files(args.repo),
                   notes=f'Prepared game content snapshot {args.version}. Not published. '
                   'Private state, executable binaries, metadata and decryption tools are excluded. '
                   'See coverage.json for exclusions and decode gaps.')
    write(args.output / 'file-catalog.pending.json', catalog)
    verify(args.output)
    categories = collections.Counter((r['origin'], r['section']) for r in sources)
    coverage = dict(snapshot=args.version, originalFiles=sum(r['section'] != 'decrypted' for r in sources),
                    decodedFiles=sum(r['section'] == 'decrypted' for r in sources),
                    categories={origin + '/' + section: count for (origin, section), count in sorted(categories.items())},
                    excluded=excluded, decodeGaps=gaps, archives=len(archives),
                    totalArchiveBytes=sum(a['bytes'] for a in archives),
                    changesFromPreviousRelease=['APK game assets are provided under a separate apk/ prefix.',
                    'New hotfix and decoded content manifests are included.',
                    'Player-specific minimap state is excluded from public archives and retained locally.',
                    'Already-readable events are provided as originals without redundant decoded copies.'],
                    scope='Allowlisted phone game content and APK assets, with complete validated decoded outputs. '
                    'Executables, metadata, account state, shader caches and extraction tools are excluded. '
                    'Partial decodings are retained in the local investigation only.',
                    validation='Every source matched its captured SHA-256. Every archive passed CRC and SHA-256 checks. '
                    'Every stored member was read by its browser extraction offset and matched its expected SHA-256.')
    write(args.output / 'coverage.json', coverage, pretty=True)
    write(args.output / 'release-manifest.json', {k: v for k, v in catalog.items() if k != 'files'}, pretty=True)
    (args.output / 'SHA256SUMS.txt').write_text(''.join(a['sha256'] + '  ' + a['name'] + '\n' for a in archives), encoding='utf-8')
    (args.output / 'RELEASE.md').write_text(
        f'# Guardian Tales game files — {args.version}\n\n'
        f"{coverage['originalFiles']:,} original files and {coverage['decodedFiles']:,} decoded outputs "
        f'in {len(archives)} independently extractable ZIP archives.\n\n'
        + coverage['scope'] + '\n\n' + coverage['validation'] + '\n\n'
        'Extract ZIP parts into the same empty folder. Keep each game version in a separate folder. '
        'See coverage.json for exclusions and decode gaps, and SHA256SUMS.txt for archive hashes.\n\n'
        'This snapshot is prepared locally and has not been published.\n', encoding='utf-8')
    print('READY', json.dumps({k: coverage[k] for k in ('originalFiles', 'decodedFiles', 'archives', 'totalArchiveBytes')}), flush=True)


if __name__ == '__main__':
    main()
