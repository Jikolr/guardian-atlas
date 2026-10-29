"""Validate transparent exports, prepare PNG downloads/packs, and build the gallery.

The native exports stay outside the Pages tree. Only small WebP previews and a
catalogue enter dist. PNG downloads are lossless; WebP is used for previews only.
"""
from pathlib import Path
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import re
import zipfile


def read(path):
    return json.loads(path.read_text(encoding='utf8'))


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, separators=(',', ':')), encoding='utf8')


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(4 * 1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def prepare_png(source, target, preview, crop, source_hash, previous):
    from PIL import Image
    if digest(source) != source_hash:
        raise ValueError('Rendered file changed: ' + source.name)
    changed = previous.get('sourceSha256') != source_hash or previous.get('crop') != crop or not target.exists()
    if changed:
        with Image.open(source) as original:
            rgba = original.convert('RGBA').crop(crop)
            extrema = rgba.getchannel('A').getextrema()
            if extrema[0] != 0 or extrema[1] == 0:
                raise ValueError('Missing transparency or empty artwork: ' + source.name)
            rgba.save(target, 'PNG', compress_level=9, optimize=True)
            dimensions = rgba.size
        with Image.open(target) as decoded, Image.open(source) as original:
            if decoded.convert('RGBA').tobytes() != original.convert('RGBA').crop(crop).tobytes():
                raise ValueError('Lossless PNG re-encoding changed pixels: ' + source.name)
        previous = {'sourceSha256': source_hash, 'sha256': digest(target), 'bytes': target.stat().st_size, 'width': dimensions[0], 'height': dimensions[1], 'alphaMin': extrema[0], 'alphaMax': extrema[1], 'crop': crop}
    preview_settings = '280x360-quality65-v1'
    if changed or previous.get('previewSettings') != preview_settings or not preview.exists():
        with Image.open(target) as original:
            thumb = original.convert('RGBA')
            thumb.thumbnail((280, 360), Image.Resampling.LANCZOS)
            thumb.save(preview, 'WEBP', quality=65, method=6, exact=True)
        previous['previewSettings'] = preview_settings
    if digest(target) != previous['sha256']:
        raise ValueError('Prepared PNG changed: ' + source.name)
    return previous


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--work', type=Path, required=True)
    p.add_argument('--dist', type=Path, default=Path(__file__).parent / 'dist')
    p.add_argument('--library', type=Path)
    p.add_argument('--download-base', default='/downloads/hero-illustrations/')
    p.add_argument('--skip-packs', action='store_true')
    args = p.parse_args()
    if args.library:
        import sys
        sys.path.insert(0, str(args.library))
    from PIL import Image
    work, dist = args.work.resolve(), args.dist.resolve()
    base, renders = read(work / 'catalog-base.json'), read(work / 'render-manifest.json')
    version = base['version']
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        raise ValueError('Invalid captured game version')
    if renders['errors']:
        raise ValueError('Resolve all rendering errors before building the public collection.')
    labels = {row['id']: row for row in base['illustrations']}
    rendered = list(renders['illustrations'].values())
    missing = set(labels) - {row['illustrationId'] for row in rendered}
    if missing:
        raise ValueError('Missing illustration renders: ' + ', '.join(sorted(missing)))
    release = work / 'release'
    release.mkdir(exist_ok=True)
    previews = dist / 'data/hero-illustrations/previews'
    previews.mkdir(parents=True, exist_ok=True)
    cache_path = work / 'publication-cache.json'
    cache = read(cache_path) if cache_path.exists() else {}
    assets, entries, validation, groups = {}, [], [], {key: [] for key in ('character', 'effects', 'effectsOnly')}
    encoder = ThreadPoolExecutor(max_workers=6)
    queue = []

    def finish_row(prepared):
        number, row, entry, pending = prepared
        for key, file, source, target, preview, future in pending:
            item = cache[source.name] = future.result()
            preview_url = 'data/hero-illustrations/previews/' + preview.name
            entry['files'][key] = {'url': args.download_base.rstrip('/') + '/' + target.name, 'preview': preview_url, 'filename': target.name, 'format': 'png', **{k: item[k] for k in ('width', 'height', 'bytes', 'sha256')}}
            assets[target.name] = {'name': target.name, 'path': target.name, 'bytes': item['bytes'], 'sha256': item['sha256']}
            groups[key].append(target)
            validation.append({'id': row['id'], 'mode': key, 'name': target.name, **item, 'framebuffer': file['diagnostics']})
        entry['preview'] = entry['files']['character']['preview']
        if entry['files'].get('effectsOnly'):
            entry['notes'].append('Effects use PNG alpha so they can be placed on a transparent background. Additive light can look different on light and dark backgrounds.')
        entries.append(entry)
        if number % 10 == 0:
            write(cache_path, cache)
            print(f'Prepared {number}/{len(rendered)} illustrations', flush=True)

    for number, row in enumerate(sorted(rendered, key=lambda row: row['id']), 1):
        label = labels[row['illustrationId']]
        entry = {key: value for key, value in label.items() if key not in ('rigs', 'provenance')}
        entry.update(id=row['id'], status='ready', files={}, skin=row['skin'], animation=row['animation'], time=row['time'])
        entry['notes'] = list(entry.get('notes', []))
        if row['skin'] != 'default':
            entry['variant'] += ' · ' + row['skin']
        entry['provenance'] = {**label['provenance'], 'prefab': row['prefab'], 'skin': row['skin'], 'animation': row['animation'], 'time': row['time'], 'rendererHash': row['rendererHash']}
        extents, source_size = [], None
        for file in row['files'].values():
            with Image.open(work / file['path']) as source_image:
                if source_size and source_image.size != source_size:
                    raise ValueError('Character and effect layer canvases do not align: ' + row['id'])
                source_size = source_image.size
                bounds = source_image.convert('RGBA').getchannel('A').getbbox()
                if bounds:
                    extents.append(bounds)
        if not extents:
            raise ValueError('Empty illustration: ' + row['id'])
        # Trim strictly zero-alpha outer margins, never individual components.
        # The union includes distant particles and is identical for all layers.
        crop = [max(0, min(b[0] for b in extents) - 32), max(0, min(b[1] for b in extents) - 32),
                min(source_size[0], max(b[2] for b in extents) + 32), min(source_size[1], max(b[3] for b in extents) + 32)]
        entry['provenance']['sourceCanvas'] = list(source_size)
        entry['provenance']['transparentMarginCrop'] = crop
        pending = []
        for key, file in row['files'].items():
            source = (work / file['path']).resolve()
            if not source.is_relative_to(work):
                raise ValueError('Rendered file is outside the work folder: ' + file['path'])
            target = release / source.name
            preview = previews / (source.stem + '.webp')
            pending.append((key, file, source, target, preview, encoder.submit(prepare_png, source, target, preview, crop, file['sha256'], cache.get(source.name, {}))))
        queue.append((number, row, entry, pending))
        # Keep a few independent illustrations in flight without holding the
        # entire full-resolution collection in memory.
        if len(queue) >= 3:
            finish_row(queue.pop(0))
    for prepared in queue:
        finish_row(prepared)
    encoder.shutdown()
    write(cache_path, cache)
    packs = []
    pack_labels = {'character': 'All character PNGs', 'effects': 'All illustrations with effects', 'effectsOnly': 'All separate effects'}
    if not args.skip_packs:
        for key, files in groups.items():
            chunks, current, size = [], [], 0
            for file in files:
                if current and size + file.stat().st_size > 1800 * 1024 * 1024:
                    chunks.append(current)
                    current, size = [], 0
                current.append(file)
                size += file.stat().st_size
            if current:
                chunks.append(current)
            for part, chunk in enumerate(chunks, 1):
                suffix = '-' + str(part) if len(chunks) > 1 else ''
                name = 'guardian-illustrations-' + version + '-' + key + suffix + '.zip'
                archive = release / name
                with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_STORED) as output:
                    for file in chunk:
                        output.write(file, file.name)
                with zipfile.ZipFile(archive) as check:
                    bad = check.testzip()
                    if bad or len(check.infolist()) != len(chunk):
                        raise ValueError('ZIP verification failed: ' + name)
                size = archive.stat().st_size
                assets[name] = {'name': name, 'path': name, 'bytes': size, 'sha256': digest(archive)}
                packs.append({'label': pack_labels[key] + (f' · part {part}' if suffix else ''), 'filename': name, 'url': args.download_base.rstrip('/') + '/' + name, 'bytes': size, 'sha256': assets[name]['sha256'], 'count': len(chunk)})
    summary = {**base.get('summary', {}), 'illustrations': len(entries), 'pngs': len(validation), 'pngBytes': sum(a['bytes'] for a in assets.values() if a['name'].endswith('.png')), 'previewsBytes': sum(path.stat().st_size for path in previews.glob('*.webp'))}
    catalog = {'version': base['version'], 'summary': summary, 'packs': packs, 'illustrations': entries}
    write(dist / 'data/hero-illustrations/index.json', catalog)
    write(work / 'gallery-validation.json', {'summary': summary, 'files': validation})
    write(release / 'illustration-catalog.json', catalog)
    (release / 'README.txt').write_text('Guardian Tales ' + version + ' — transparent hero illustrations\n\nOriginal captured Spine artwork, reconstructed without the separate background images.\nCharacter, combined and effects-only exports use the same pose and canvas bounds.\nPNG pixels are lossless. Effects designed for additive blending use an RGBA alpha approximation; PNG cannot store additive blending against an unknown background.\nSource bundle references, animation, time and SHA-256 hashes are in illustration-catalog.json.\n', encoding='utf8')
    for file in (release / 'illustration-catalog.json', release / 'README.txt'):
        assets[file.name] = {'name': file.name, 'path': file.name, 'bytes': file.stat().st_size, 'sha256': digest(file)}
    checksums = release / 'SHA256SUMS.txt'
    checksums.write_text(''.join(asset['sha256'] + '  ' + asset['name'] + '\n' for asset in sorted(assets.values(), key=lambda asset: asset['name'])), encoding='utf8')
    assets[checksums.name] = {'name': checksums.name, 'path': checksums.name, 'bytes': checksums.stat().st_size, 'sha256': digest(checksums)}
    manifest = {'version': version, 'releaseTag': 'hero-illustrations-' + version, 'repo': 'Jikolr/guardian-atlas', 'summary': summary, 'assets': list(assets.values())}
    if len(assets) > 1000:
        raise ValueError('More than 1000 release assets; split releases before publication.')
    write(release / 'release-manifest.json', manifest)
    print(json.dumps(summary), flush=True)


if __name__ == '__main__':
    main()
