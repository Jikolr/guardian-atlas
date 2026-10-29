"""Import an already decoded game snapshot, preserving public record/link identities.

This module contains no decryption keys and does not execute game code. Decoding and
original-file archiving happen outside the repository. See docs/MAINTAINING.md.
"""
from pathlib import Path
import argparse
import collections
import gc
import gzip
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import time

BASE = Path(__file__).resolve().parent
DATA = BASE / 'dist/data'


def read(path):
    path = Path(path)
    if not path.exists():
        path = Path(str(path) + '.gz')
    raw = path.read_bytes()
    return json.loads(gzip.decompress(raw) if path.suffix == '.gz' else raw)


def write(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode('utf8')
    if path.suffix == '.gz':
        raw = gzip.compress(raw, mtime=0)
    if not path.exists() or path.read_bytes() != raw:
        temporary = path.with_name(path.name + '.pending')
        temporary.write_bytes(raw)
        for attempt in range(5):
            try:
                temporary.replace(path)
                break
            except OSError:
                if attempt == 4:
                    raise
                time.sleep(.2)


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for data in iter(lambda: f.read(4 * 1024 * 1024), b''):
            h.update(data)
    return h.hexdigest()


def semantic_rows(records):
    return collections.Counter(json.dumps({k: v for k, v in r['fields'].items() if k != 'Position'},
                               sort_keys=True, ensure_ascii=False) for r in records)


def rows(obj, previous=()):
    if isinstance(obj, list):
        result = [{'id': v.get('Id', i) if isinstance(v, dict) else i,
                   'fields': v if isinstance(v, dict) else {'Value': v}}
                  for i, v in enumerate(obj)]
    else:
        result = []
        for section, value in sorted(obj.items()):
            for i, v in enumerate(value if isinstance(value, list) else [value]):
                result.append({'id': len(result), 'fields': {'Section': section, 'Position': i,
                               **(v if isinstance(v, dict) else {'Value': v})}})
    if len({str(r['id']) for r in result}) != len(result):
        for i, r in enumerate(result):
            r['id'] = i
    source_ids = [r['fields'].get('Id') for r in result]
    synthetic_list = isinstance(obj, list) and all(isinstance(value, dict) for value in obj) and (
        any(ident is None for ident in source_ids) or len(set(map(str, source_ids))) != len(source_ids))
    if (isinstance(obj, dict) or synthetic_list) and previous:
        # Public IDs are links. Preserve them when JSON sections or records move.
        def key(row, field):
            fields = row['fields']
            if field == '__position__':
                value = row['id']
            elif field == '__content__':
                if set(fields) <= {'Section', 'Position', 'Value'}:
                    # Primitive arrays are indexed scales; equal values do not
                    # give two positions the same gameplay identity.
                    return None
                value = {k: v for k, v in fields.items() if k not in {'Position', 'Section'}}
            else:
                if field not in fields:
                    return None
                value = fields[field]
            return (fields.get('Section'), json.dumps(value, sort_keys=True, ensure_ascii=False))
        assigned, used = {}, set()
        for field in ['Id', 'OriginId', 'Name', 'Level', 'Floor', 'Key', '__content__', 'Position', '__position__']:
            old_lookup, new_lookup = collections.defaultdict(list), collections.defaultdict(list)
            for row in previous:
                if (ident := key(row, field)) is not None:
                    old_lookup[ident].append(row)
            for i, row in enumerate(result):
                if (ident := key(row, field)) is not None:
                    new_lookup[ident].append(i)
            for ident, positions in new_lookup.items():
                candidates = old_lookup.get(ident, [])
                if len(positions) != 1 or len(candidates) != 1:
                    continue
                i, old_id = positions[0], candidates[0]['id']
                if i not in assigned and old_id not in used:
                    assigned[i] = old_id
                    used.add(old_id)
        next_id = max((r['id'] for r in previous), default=-1) + 1
        for i, row in enumerate(result):
            if i in assigned:
                row['id'] = assigned[i]
            else:
                row['id'] = next_id
                next_id += 1
        result.sort(key=lambda row: row['id'])
    return result


def load_helper(name):
    path = BASE / 'snapshot_formats.py'
    spec = importlib.util.spec_from_file_location('snapshot_formats', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return getattr(module, name)


class Importer:
    def __init__(self, args):
        self.args = args
        self.work = args.work.resolve()
        self.source = args.source.resolve()
        if self.work == self.source or self.work.is_relative_to(self.source):
            raise ValueError('The snapshot work directory must be outside the read-only phone source.')
        if BASE == self.source or BASE.is_relative_to(self.source):
            raise ValueError('The read-only phone source must not contain the website repository.')
        self.phone = self.work / 'phone'
        self.decoded = self.phone / 'decoded'
        self.apk = self.work / 'apk/decoded'
        self.state = self.work / 'website-import'
        self.state.mkdir(parents=True, exist_ok=True)
        self.version = args.version
        self.identity = {'schema': 1, 'version': self.version,
                         'source': os.path.normcase(str(self.source)),
                         'decodedRoot': os.path.normcase(str(self.decoded)),
                         'apkRoot': os.path.normcase(str(self.apk))}
        # A new capture may reuse the same version and source path. Bind resumes to
        # the captured inventory and current file attributes before trusting caches.
        fingerprint = hashlib.sha256()
        for p in sorted(self.source.rglob('*')):
            if p.is_file():
                stat = p.stat()
                fingerprint.update(json.dumps([p.relative_to(self.source).as_posix(), stat.st_size,
                                               stat.st_mtime_ns], separators=(',', ':')).encode())
        for p in [self.phone / 'reports/inventory.json', self.work / 'apk/decoded-inventory.json']:
            if p.is_file():
                fingerprint.update(digest(p).encode())
        self.identity['captureFingerprint'] = fingerprint.hexdigest()
        identity_path = self.state / 'snapshot-identity.json'
        if identity_path.exists():
            previous_identity = read(identity_path)
            legacy_identity = {k: v for k, v in self.identity.items() if k != 'captureFingerprint'}
            if previous_identity not in (self.identity, legacy_identity):
                raise ValueError('This work directory belongs to a different capture, source or version; use a new snapshot work directory.')
        write(identity_path, self.identity)
        self.baseline = self.state / 'baseline'
        self.baseline.mkdir(exist_ok=True)
        for rel in ['file-catalog.json', 'manifest.json', 'text.json.gz', 'research/scripts.json',
                    'research/events.json', 'visual/maps.json', 'visual/tilesets.json']:
            src = DATA / rel
            dest = self.baseline / rel
            if src.exists() and not dest.exists():
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src, dest)
        if not (self.baseline / 'name-evidence.json').exists():
            shutil.copyfile(BASE / 'name-evidence.json', self.baseline / 'name-evidence.json')
        for path in args.library:
            sys.path.insert(0, str(path.resolve()))

    def inventory(self):
        target = self.state / 'original-comparison.json'
        if target.exists():
            saved = read(target)
            if saved.get('snapshotIdentity') == self.identity:
                return saved
            legacy_identity = {k: v for k, v in self.identity.items() if k != 'captureFingerprint'}
            if saved.get('snapshotIdentity') not in (None, legacy_identity):
                raise ValueError('The saved original inventory belongs to a different snapshot.')
            # Older checkpoints had no source/version identity. Rehash their input
            # instead of silently accepting the unbound cache.
        old = {r['path']: r for r in read(self.baseline / 'file-catalog.json')['files']
               if r['section'] in {'encrypted', 'unencrypted', 'unknown'} and r.get('sha256')}
        changed, present = [], set()
        for i, source in enumerate(sorted(self.source.rglob('*'))):
            if not source.is_file():
                continue
            rel = source.relative_to(self.source).as_posix()
            present.add(rel)
            sha = digest(source)
            previous = old.get(rel)
            state = 'added' if previous is None else 'unchanged' if previous['sha256'] == sha else 'modified'
            changed.append({'path': rel, 'sha256': sha, 'bytes': source.stat().st_size, 'change': state})
        missing = sorted(set(old) - present)
        apk_additions = []
        apk_assets = self.apk / 'com.kakaogames.gdtskr/assets'
        for source in sorted(apk_assets.rglob('*')):
            if not source.is_file():
                continue
            equivalent = 'files/' + source.relative_to(apk_assets).as_posix()
            if equivalent in present:
                continue
            rel = 'apk/' + source.relative_to(self.apk).as_posix()
            row = {'path': rel, 'sha256': digest(source), 'bytes': source.stat().st_size, 'change': 'added',
                   'equivalentPhonePath': equivalent}
            changed.append(row)
            apk_additions.append(rel)
        result = {'files': changed, 'absentFromCapture': missing,
                  'counts': dict(collections.Counter(r['change'] for r in changed)),
                  'apkRoot': str(self.apk), 'apkAdditions': apk_additions,
                  'snapshotIdentity': self.identity}
        write(target, result)
        print('Original comparison', result['counts'], 'absent', len(missing), flush=True)
        return result

    def data(self):
        manifest = read(DATA / 'manifest.json')
        changed, stats, reordered = [], [], []
        static_source = self.state / 'decoded-static'
        static_source.mkdir(exist_ok=True)
        for source in sorted((self.decoded / 'files/static_data').iterdir()):
            if not source.is_file() or source.name.endswith('.etag') or '-bin' in source.name:
                continue
            try:
                obj = read(source)
            except (UnicodeDecodeError, json.JSONDecodeError):
                continue
            write(static_source / (source.name + '.json'), obj)
            name = 'static-' + source.name
            baseline = self.baseline / 'tables' / (name + '.json')
            if not baseline.exists() and (DATA / (name + '.json')).exists():
                baseline.parent.mkdir(exist_ok=True)
                shutil.copyfile(DATA / (name + '.json'), baseline)
            old = read(baseline) if baseline.exists() else []
            records = rows(obj, old)
            if old != records:
                if semantic_rows(old) == semantic_rows(records):
                    reordered.append(name)
                else:
                    changed.append(name)
                before = {str(r['id']): r['fields'] for r in old}
                after = {str(r['id']): r['fields'] for r in records}
                stats.append({'table': name, 'before': len(old), 'after': len(records),
                              'added': len(after.keys() - before.keys()),
                              'removed': len(before.keys() - after.keys()),
                              'modified': sum(before[k] != after[k] for k in before.keys() & after.keys())})
            write(DATA / (name + '.json'), records)
            manifest[name] = {'count': len(records), 'fields': sorted({k for r in records for k in r['fields']}),
                              'source': 'static_data/' + source.name, 'title': source.name,
                              'group': 'Decoded tables', 'version': self.version}
        table_sources = {}
        for name, filename in {'heroes': 'heroes-bin', 'actions': 'battleactions-bin', 'monsters': 'monsters-bin',
                               'npcs': 'npc-bin', 'text': 'strings-bin-enUS'}.items():
            # Downloaded static tables are current; a phone cache can be left over from an older run.
            source = self.phone / 'tables/files/static_data' / (filename + '.json')
            if not source.exists():
                source = self.phone / 'tables/cache' / (filename + '.json')
            obj = read(source)
            idx = read(source.with_name(filename + '.index.json'))
            ids = [r['record_id'] for r in idx]
            assert len(ids) == len(obj) and len(set(ids)) == len(ids), filename
            records = [{'id': ident, 'fields': value} for ident, value in zip(ids, obj)]
            baseline = self.baseline / 'tables' / (name + ('.json.gz' if name == 'text' else '.json'))
            if not baseline.exists():
                baseline.parent.mkdir(exist_ok=True)
                shutil.copyfile(DATA / baseline.name, baseline)
            old = read(baseline)
            before = {str(r['id']): r['fields'] for r in old}
            after = {str(r['id']): r['fields'] for r in records}
            if old != records:
                changed.append(name)
                stats.append({'table': name, 'before': len(old), 'after': len(records),
                              'added': len(after.keys() - before.keys()), 'removed': len(before.keys() - after.keys()),
                              'modified': sum(before[k] != after[k] for k in before.keys() & after.keys())})
            target = DATA / (name + ('.json.gz' if name == 'text' else '.json'))
            write(target, records)
            manifest[name] = {'count': len(records), 'fields': sorted({k for r in obj for k in r}),
                              'source': filename, 'version': self.version}
            if name == 'text':
                manifest[name].update(url='data/text.json.gz', encoding='gzip')
                newtext = records
            table_sources[name] = source.relative_to(self.work).as_posix()
        write(DATA / 'manifest.json', manifest)
        oldtext = {r['id']: r['fields']['Text'] for r in read(self.baseline / 'text.json.gz')}
        bybody = collections.defaultdict(list)
        for r in newtext:
            bybody[r['fields']['Text']].append(r['id'])
        evidence = read(self.baseline / 'name-evidence.json')
        for entry in evidence:
            body = oldtext[entry['biographyId']]
            ids = bybody.get(body, [])
            if not ids:
                raise ValueError('Biography changed; manual review needed: ' + entry['name'])
            entry['biographyId'] = ids[0]
        write(BASE / 'name-evidence.json', evidence)
        for name in ['exps2', 'weaponenhance', 'guardianlevel']:
            write(DATA / 'research' / (name + '.json'), read(static_source / (name + '.json')))
        write(self.state / 'data-result.json', {'changedTables': changed, 'tableChanges': stats,
                                              'reorderedTables': reordered,
                                              'tableSources': table_sources, 'tableCount': len(manifest)})
        print('Tables', len(manifest), 'changed', len(changed), flush=True)

    def scripts(self):
        index = read(DATA / 'research/scripts.json')
        names = {r['path'].replace('\\', '/').casefold(): r for r in index}
        chunks, added, changed, seen = {}, [], [], set()
        next_id = max(int(r['id']) for r in index) + 1
        inputs = [(p, p.relative_to(self.decoded / 'files/GameScript').as_posix())
                  for p in sorted((self.decoded / 'files/GameScript').rglob('*.lua'))]
        inputs += [(p, '_immediates/' + p.name) for p in sorted((self.decoded / 'files/media/immediates').rglob('*.lua'))]
        current_names = {name.casefold() for _, name in inputs}
        apk_scripts = self.apk / 'com.kakaogames.gdtskr/assets/GameScript'
        inputs += [(p, p.relative_to(apk_scripts).as_posix()) for p in sorted(apk_scripts.rglob('*.lua'))
                   if p.relative_to(apk_scripts).as_posix().casefold() not in current_names]
        for source, name in inputs:
            text = source.read_text(encoding='utf8')
            seen.add(name.casefold())
            row = names.get(name.casefold())
            if row is None:
                row = {'id': str(next_id), 'path': name, 'chunk': next_id // 100}
                next_id += 1
                index.append(row)
                names[name.casefold()] = row
                added.append(name)
            chunk = row['chunk']
            path = DATA / 'research/scripts' / (str(chunk) + '.json.gz')
            if chunk not in chunks:
                chunks[chunk] = read(path) if path.exists() else {}
            if chunks[chunk].get(row['id']) != text:
                changed.append(name)
            chunks[chunk][row['id']] = text
            row.update(category=name.split('/')[0] if '/' in name else 'root controllers',
                       lines=len(text.splitlines()), version=self.version, snapshotStatus='present',
                       functions=[{'name': m.group(1), 'line': i} for i, line in enumerate(text.splitlines(), 1)
                                  if (m := re.search(r'^\s*(?:local\s+)?function\s+([\w.:]+)', line))])
        absent = []
        for row in index:
            if row['path'].casefold() not in seen:
                row['snapshotStatus'] = 'absent from current capture; historical source retained'
                absent.append(row['path'])
        write(DATA / 'research/scripts.json', index)
        for chunk, content in chunks.items():
            write(DATA / 'research/scripts' / (str(chunk) + '.json.gz'), content)
        summary = read(DATA / 'research/catalog-summary.json')
        summary.update(lua_files=len(index), lua_lines=sum(r['lines'] for r in index),
                       lua_function_definitions=sum(len(r['functions']) for r in index),
                       lua_categories=dict(collections.Counter(r['category'] for r in index)),
                       dataVersion=self.version, nativeEvidenceVersion='3.54.0')
        write(DATA / 'research/catalog-summary.json', summary)
        write(self.state / 'scripts-result.json', {'total': len(index), 'current': len(inputs),
                                                 'added': added, 'changed': changed, 'absentFromCapture': absent})
        print('Scripts', len(index), 'changed', len(changed), 'added', len(added), flush=True)

    def events(self):
        index = read(DATA / 'research/events.json')
        byname = {r['name']: r for r in index}
        next_id = max(r['id'] for r in index) + 1
        changes, errors = [], []
        for source in sorted((self.source / 'files/events').glob('*.json')):
            raw = source.read_text(encoding='utf8')
            normalized = False
            try:
                obj = json.loads(raw)
            except json.JSONDecodeError:
                # A JSON-aware trailing comma normalizer is provided in snapshot_formats.
                try:
                    obj = json.loads(load_helper('strip_trailing_commas')(raw))
                    normalized = True
                except Exception as error:
                    errors.append({'path': source.name, 'error': str(error)})
                    continue
            row = byname.get(source.stem)
            if row is None:
                row = {'id': next_id, 'name': source.stem}
                next_id += 1
                index.append(row)
                byname[source.stem] = row
            target = DATA / 'research/events' / (str(row['id']) + '.json')
            if not target.exists() or read(target) != obj:
                changes.append(source.name)
            write(target, obj)
            row.update(normalized=normalized, count=str(len(obj)), version=self.version)
        write(DATA / 'research/events.json', index)
        write(self.state / 'events-result.json', {'total': len(index), 'changed': changes, 'errors': errors})
        print('Events', len(index), 'changed', len(changes), 'errors', len(errors), flush=True)

    def visuals(self):
        import UnityPy
        from PIL import Image
        visual = DATA / 'visual'
        assets = read(visual / 'assets.json')
        icons = read(visual / 'icons.json')
        bundles = {r['path']: r for r in read(DATA / 'research/bundles.json')}
        changes = [r for r in self.inventory()['files'] if r['change'] != 'unchanged']
        processed, errors, placeholders, images = [], [], [], 0
        checkpoint_dir = self.state / 'visual-checkpoints'
        checkpoint_dir.mkdir(exist_ok=True)
        for record in changes:
            name = record['path']
            source = self.apk / name.removeprefix('apk/') if name.startswith('apk/') else self.source / name
            if not (name.startswith('files/AssetBundles/') or name.startswith('apk/') and '/AssetBundles/' in name) or name.endswith('.etag'):
                continue
            with source.open('rb') as f:
                if not f.read(7).startswith(b'UnityFS'):
                    continue
            if digest(source) != record['sha256']:
                raise ValueError('Original bundle changed after snapshot inventory: ' + name)
            checkpoint = checkpoint_dir / (hashlib.sha256(name.encode()).hexdigest()[:20] + '.json')
            expected_checkpoint = {'version': self.version, 'sourceSha256': record['sha256'], 'bundlePath': name}
            checkpoint_valid = False
            if checkpoint.exists():
                part = read(checkpoint)
                checkpoint_valid = part.get('input') == expected_checkpoint
                if checkpoint_valid:
                    for entry in part['assets'] + part['icons']:
                        if entry.get('image'):
                            image_path = visual / entry['image']
                            if not image_path.exists() or digest(image_path) != entry.get('previewSha256'):
                                checkpoint_valid = False
                                break
            if not checkpoint_valid:
                newassets, newicons, local_errors = [], [], []
                env = UnityPy.load(str(source))
                counts = collections.Counter(o.type.name for o in env.objects)
                bundle = {'path': name, 'objects': sum(counts.values()), 'types': dict(counts), 'version': self.version}
                objects = {o.path_id: o for o in env.objects}
                textures = {}
                for obj in env.objects:
                    if obj.type.name in ('Texture2D', 'Sprite'):
                        aid = hashlib.sha256((name + ':' + str(obj.path_id)).encode()).hexdigest()[:20]
                        entry = {'id': aid, 'bundle': name, 'type': obj.type.name, 'pathId': str(obj.path_id),
                                 'name': '', 'status': 'unavailable', 'version': self.version}
                        try:
                            value = obj.read()
                            entry['name'] = value.m_Name
                            if obj.type.name == 'Texture2D' and (value.m_Width == 0 or value.m_Height == 0):
                                raise ValueError('Runtime texture placeholder: zero dimensions and no stored pixels')
                            if obj.type.name == 'Sprite' and value.m_RD.texture.m_PathID == 0:
                                raise ValueError('Sprite has no stored texture reference')
                            image = value.image
                            entry.update(width=image.width, height=image.height)
                            image.thumbnail((768, 768))
                            image.save(visual / 'images' / (aid + '.webp'), format='WEBP', quality=82, method=3)
                            entry.update(image='images/' + aid + '.webp', status='ready',
                                         previewWidth=image.width, previewHeight=image.height)
                        except Exception as error:
                            entry['error'] = str(error)[:180]
                            local_errors.append({'bundle': name, 'object': str(obj.path_id), 'error': str(error)})
                        newassets.append(entry)
                    if '/spritesheets/' not in name or obj.type.name != 'MonoBehaviour':
                        continue
                    tree = obj.read_typetree()
                    if not tree.get('mSprites') or not tree.get('material', {}).get('m_PathID'):
                        continue
                    try:
                        ptr = tree['material']
                        assert ptr['m_FileID'] == 0
                        mt = objects[ptr['m_PathID']].read_typetree()
                        ptr = dict(mt['m_SavedProperties']['m_TexEnvs'])['_MainTex']['m_Texture']
                        assert ptr['m_FileID'] == 0
                        tid = ptr['m_PathID']
                        if tid not in textures:
                            textures[tid] = objects[tid].read().image
                        image = textures[tid]
                        for sprite in tree['mSprites']:
                            x, y, w, h = [sprite[k] for k in ['x', 'y', 'width', 'height']]
                            if not (w > 0 and h > 0 and 0 <= x < x+w <= image.width and 0 <= y < y+h <= image.height):
                                local_errors.append({'bundle': name, 'sprite': sprite['name'], 'error': 'Invalid atlas rectangle'})
                                continue
                            aid = hashlib.sha256((name + str(obj.path_id) + sprite['name']).encode()).hexdigest()[:20]
                            crop = image.crop((x, y, x+w, y+h))
                            crop.thumbnail((768, 768))
                            crop.save(visual / 'images' / (aid + '.webp'), quality=90)
                            newicons.append({'id': aid, 'name': sprite['name'], 'bundle': name, 'type': 'Atlas sprite',
                                             'status': 'ready', 'image': 'images/' + aid + '.webp', 'width': w, 'height': h,
                                             'atlas': tree['m_Name'], 'rect': [x, y, w, h], 'version': self.version})
                    except Exception as error:
                        local_errors.append({'bundle': name, 'object': str(obj.path_id), 'error': str(error)})
                for entry in newassets + newicons:
                    if entry.get('image'):
                        entry['previewSha256'] = digest(visual / entry['image'])
                part = {'input': expected_checkpoint, 'assets': newassets, 'icons': newicons,
                        'bundle': bundle, 'errors': local_errors}
                write(checkpoint, part)
                del env
            assets = [r for r in assets if r['bundle'] != name] + part['assets']
            icons = [r for r in icons if r['bundle'] != name] + part['icons']
            bundles[name] = part['bundle']
            for error in part['errors']:
                if error['error'].startswith(('Runtime texture placeholder:', 'Sprite has no stored texture reference')):
                    placeholders.append(error)
                else:
                    errors.append(error)
            images += sum(r['status'] == 'ready' for r in part['assets']) + len(part['icons'])
            processed.append(name)
            print('Visual bundle', len(processed), name, len(part['assets']), len(part['icons']), flush=True)
            if len(processed) % 20 == 0:
                gc.collect()
        for record in changes:
            name = record['path']
            if not name.startswith('files/media/') or not name.lower().endswith(('.png', '.jpg', '.jpeg')):
                continue
            image = Image.open(self.source / name)
            width, height = image.size
            image.thumbnail((768, 768))
            aid = hashlib.sha256(name.encode()).hexdigest()[:20]
            image.save(visual / 'images' / (aid + '.webp'), quality=85)
            assets = [r for r in assets if r['id'] != aid] + [dict(id=aid, bundle=name, name=Path(name).name,
                       type='Image', status='ready', image='images/' + aid + '.webp', width=width, height=height,
                       previewWidth=image.width, previewHeight=image.height, version=self.version)]
            images += 1
        write(visual / 'assets.json', assets)
        write(visual / 'icons.json', icons)
        write(DATA / 'research/bundles.json', list(bundles.values()))
        write(self.state / 'visuals-result.json', {'bundles': processed, 'imagesWritten': images,
                                                'errors': errors, 'unavailablePlaceholders': placeholders})
        print('Visuals', len(processed), 'bundles,', images, 'images,', len(errors), 'errors', flush=True)

    def maps(self):
        parse_map = load_helper('parse_map')
        visual = DATA / 'visual'
        index = read(visual / 'maps.json')
        byname = {r['name']: r for r in index}
        research = read(DATA / 'research/maps.json')
        research_byname = {Path(r['path']).stem: r for r in research}
        next_id = max((r['id'] for r in research if r['id'] is not None), default=-1) + 1
        changed, added, errors = [], [], []
        sources = list(sorted((self.decoded / 'files/Tilemaps').glob('*.bytes')))
        names = {p.name.casefold() for p in sources}
        sources += [p for p in sorted((self.apk / 'com.kakaogames.gdtskr/assets/Tilemaps').glob('*.bytes'))
                    if p.name.casefold() not in names]
        for source in sources:
            if '.partial.' in source.name:
                continue
            target = visual / 'maps' / (source.stem + '.json.gz')
            sha = digest(source)
            if target.exists() and read(target).get('sha256') == sha:
                continue
            try:
                obj = parse_map(source)
                reference_names = list(dict.fromkeys([t['name'] for t in obj['tilesets']] +
                                     [n for t in obj['tilesets'] for n in t['tiles']] +
                                     [n for h in obj['handles'] for n in h['names']]))
                research_row = research_byname.get(source.stem)
                if research_row is None:
                    research_row = {'id': next_id, 'path': 'files/Tilemaps/' + source.name}
                    research.append(research_row)
                    research_byname[source.stem] = research_row
                    next_id += 1
                if research_row['id'] is None:
                    research_row['id'] = next_id
                    next_id += 1
                research_row.update(bytes=source.stat().st_size, version=obj['version'], references=len(reference_names),
                                    status='Decoded and completely parsed; runtime behavior not reconstructed', snapshotVersion=self.version)
                write(DATA / 'research/maps' / (str(research_row['id']) + '.json'), reference_names)
                for layer in obj['layers']:
                    layer.pop('partitions', None)
                    layer.pop('properties', None)
                    for tile in layer['tiles']:
                        tile.pop('raw', None)
                obj.pop('physics', None)
                obj.pop('handles', None)
                obj['snapshotVersion'] = self.version
                write(target, obj)
                row = dict(name=source.stem, status='ready', version=obj['version'],
                           tiles=sum(len(layer['tiles']) for layer in obj['layers']), layers=len(obj['layers']),
                           tilesets=[t['name'] for t in obj['tilesets']], snapshotVersion=self.version)
                if source.stem not in byname:
                    index.append(row)
                    added.append(source.stem)
                else:
                    byname[source.stem].update(row)
                byname[source.stem] = row if source.stem in added else byname[source.stem]
                changed.append(source.stem)
            except Exception as error:
                row = byname.get(source.stem)
                detail = {'name': source.stem, 'error': str(error)}
                errors.append(detail)
                if row is None:
                    row = dict(name=source.stem, status='unavailable', error=str(error), snapshotVersion=self.version)
                    index.append(row)
                    byname[source.stem] = row
                elif row['status'] != 'ready':
                    row.update(error=str(error), snapshotVersion=self.version)
        write(visual / 'maps.json', index)
        write(DATA / 'research/maps.json', research)
        write(self.state / 'maps-result.json', {'total': len(index), 'changed': changed, 'added': added,
                                              'ready': sum(r['status'] == 'ready' for r in index), 'errors': errors})
        print('Maps', len(index), 'changed', len(changed), 'added', len(added), 'unsupported', len(errors), flush=True)

    def links(self):
        load_helper('link_visual_records')(DATA)
        env = os.environ.copy()
        env['ATLAS_STATIC_SOURCE'] = str(self.state / 'decoded-static')
        subprocess.run([sys.executable, str(BASE / 'prepare_profiles.py')], cwd=BASE, env=env, check=True)
        subprocess.run([sys.executable, str(BASE / 'prepare_orbital.py')], cwd=BASE, env=env, check=True)
        reviewed = read(DATA / 'reviewed-names.json')
        reviewed['snapshot'] = self.version
        write(DATA / 'reviewed-names.json', reviewed)

    def tilesets(self):
        load_helper('refresh_tilesets')(DATA, self.source, self.inventory(), self.version)

    def finish(self):
        map_root = (DATA / 'research/maps').resolve()
        for source in map_root.glob('*.json'):
            assert source.resolve().parent == map_root
            raw = source.read_bytes()
            target = source.with_suffix('.json.gz')
            target.write_bytes(gzip.compress(raw, mtime=0))
            assert gzip.decompress(target.read_bytes()) == raw
            source.unlink()
        results = {name: read(self.state / (name + '-result.json'))
                   for name in ['data', 'scripts', 'events', 'maps', 'visuals']
                   if (self.state / (name + '-result.json')).exists()}
        results.update(version=self.version, previousVersion='3.55.0', package='com.kakaogames.gdtskr',
                       nativeEvidenceVersion='3.54.0',
                       limitations=['Capture differences do not prove a feature was introduced in this patch.',
                                    'Historical native disassembly and behavior research remain 3.54.0 evidence.',
                                    'Files absent from this capture retain historical website entries where applicable.',
                                    'Legacy map formats and malformed assets are listed explicitly.'])
        semantic = self.work / 'comparison/table-content-summary.json'
        if semantic.exists():
            results['semanticComparison'] = read(semantic)
        # Diagnostics in the local work directory may contain absolute input paths.
        from sanitize_public_exports import walk
        results = walk(results)
        write(DATA / ('update-' + self.version + '.json'), results)
        summary = read(DATA / 'research/catalog-summary.json')
        summary.update(dataVersion=self.version, nativeEvidenceVersion='3.54.0',
                       events=len(read(DATA / 'research/events.json')))
        write(DATA / 'research/catalog-summary.json', summary)
        write(self.state / 'result.json', results)
        print('Import summary', self.state / 'result.json', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--work', type=Path, required=True, help='Decoded snapshot workspace (contains phone/)')
    parser.add_argument('--source', type=Path, required=True, help='Read-only phone dump directory')
    parser.add_argument('--version', required=True)
    parser.add_argument('--library', type=Path, action='append', default=[], help='Optional local Python dependency directory')
    parser.add_argument('--phase', choices=['all', 'inventory', 'data', 'scripts', 'events', 'visuals', 'maps', 'tilesets', 'links', 'finish'], default='all')
    args = parser.parse_args()
    app = Importer(args)
    phases = ['inventory', 'data', 'scripts', 'events', 'visuals', 'maps', 'tilesets', 'links', 'finish'] if args.phase == 'all' else [args.phase]
    for phase in phases:
        getattr(app, phase)()


if __name__ == '__main__':
    main()
