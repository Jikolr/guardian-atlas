"""Inventory and extract original hero illustration inputs without running game code.

The capture remains read-only. The output is a local build cache, not a public
download folder. Source references are relative to the supplied capture.
Rendering and PNG publication are separate steps so provenance survives them.
"""
from pathlib import Path
import argparse
import collections
import gzip
import hashlib
import json
import re
import sys

from export_map_sprite_frames import extract, write


def read_json(path):
    data = path.read_bytes()
    return json.loads(gzip.decompress(data) if path.suffix == '.gz' else data)


def source_roots(snapshot):
    return [snapshot / 'phone/decoded/files/AssetBundles/Android',
            snapshot / 'apk/decoded/com.kakaogames.gdtskr/assets/AssetBundles/Android']


def labels(data):
    """Only exact captured asset references and reviewed character aliases link names."""
    heroes = read_json(data / 'heroes.json')
    aliases = read_json(data / 'character-aliases.json')
    reviewed_names = read_json(Path(__file__).with_name('hero_illustration_names.json'))
    items = read_json(data / 'static-items.json')
    by_portrait, by_item, by_name = (collections.defaultdict(list) for _ in range(3))
    by_id = {row['id']: row['fields'] for row in heroes}
    for row in heroes:
        by_name[row['fields'].get('Name')].append(row['fields'])
        asset = row['fields'].get('PortraitAssetName')
        if isinstance(asset, str) and asset:
            by_portrait[asset].append(row['fields'])
    for row in items:
        asset = row['fields'].get('IllustAssetName')
        if isinstance(asset, str) and asset:
            by_item[asset].append(row['fields'])

    def for_bundle(name):
        direct = by_portrait.get(name, [])
        costume = by_item.get(name, [])
        named = by_name.get(name, []) if not direct and not costume else []
        hero_ids = sorted({r['OriginId'] for r in direct + named} |
                          {by_id.get(i, {}).get('OriginId', i)
                           for r in costume for i in r.get('TargetCharacterIds', [])})
        name_evidence = []
        for ident in hero_ids:
            reviewed = reviewed_names.get(str(ident), aliases.get(str(ident), {}))
            if reviewed.get('name'):
                name_evidence.append({'originId': ident, **reviewed})
        names = sorted({row['name'] for row in name_evidence})
        links = ([{'table': 'heroes', 'id': r['Id'], 'field': 'PortraitAssetName', 'value': name}
                  for r in direct] +
                 [{'table': 'items', 'id': r['Id'], 'field': 'IllustAssetName', 'value': name,
                   'targetCharacterIds': r.get('TargetCharacterIds', [])} for r in costume] +
                 [{'table': 'heroes', 'id': r['Id'], 'field': 'Name', 'value': name,
                   'originId': r['OriginId'], 'portraitAssetName': r.get('PortraitAssetName')}
                  for r in named])
        variant = ('Super costume' if costume else 'Myth' if name.endswith('_myth')
                   else 'Ascended' if name.endswith(('_ascend', '_ascent')) else 'Standard')
        notes = []
        if named:
            notes.append('Matched by the exact hero Name field; this row reuses a different PortraitAssetName.')
        if not links:
            variant = 'Additional artwork'
            notes.append('This illustration bundle has no exact portrait or costume reference in the captured tables; its source identifier is preserved.')
        if not names:
            notes.append('No reviewed display name is available; the original asset identifier is shown.')
        hero_name = ' / '.join(names) or name
        return {'id': name, 'name': hero_name, 'heroName': hero_name,
                'heroId': hero_ids[0] if len(hero_ids) == 1 else None,
                'heroIds': hero_ids, 'variant': variant,
                'sourceBundle': 'illusts/' + name, 'references': links,
                'nameVerified': bool(names), 'nameEvidence': name_evidence, 'notes': notes}
    return for_bundle


def inspect_bundle(path, unity):
    env = unity.load(path.read_bytes())
    types = collections.Counter(o.type.name for o in env.objects)
    texts, textures, prefabs, renderers, materials = [], [], [], [], []
    for obj in env.objects:
        kind = obj.type.name
        if kind == 'Texture2D':
            item = obj.read()
            textures.append({'name': item.m_Name, 'pathId': str(obj.path_id),
                             'width': item.m_Width, 'height': item.m_Height,
                             'format': int(item.m_TextureFormat),
                             'filterMode': int(item.m_TextureSettings.m_FilterMode)})
        elif kind in ('TextAsset', 'AssetBundle', 'MonoBehaviour', 'Material'):
            item = obj.read_typetree()
            if kind == 'TextAsset':
                text = item['m_Script']
                raw = text.encode('utf8', 'surrogateescape') if isinstance(text, str) else bytes(text)
                texts.append({'name': item['m_Name'], 'pathId': str(obj.path_id),
                              'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
            elif kind == 'AssetBundle':
                prefabs.extend({'asset': name, 'pathId': str(entry['asset']['m_PathID'])}
                               for name, entry in item.get('m_Container', []) if name.endswith('.prefab'))
            elif kind == 'MonoBehaviour' and item.get('skeletonDataAsset', {}).get('m_PathID'):
                renderers.append({key: item.get(key) for key in
                                  ('initialSkinName', '_animationName', 'pmaVertexColors',
                                   'useClipping', 'initialFlipX', 'initialFlipY', 'timeScale')})
            elif kind == 'Material':
                floats = dict(item.get('m_SavedProperties', {}).get('m_Floats', []))
                materials.append({'name': item.get('m_Name'),
                                  'keywords': item.get('m_ValidKeywords', []) + item.get('m_InvalidKeywords', []),
                                  'shaderKeywords': item.get('m_ShaderKeywords', ''),
                                  'alphaFloats': {k: v for k, v in floats.items() if 'alpha' in k.lower()}})
    return {'objectTypes': dict(types), 'textures': textures, 'textAssets': texts,
            'prefabs': prefabs, 'renderers': renderers, 'materials': materials}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--snapshot', type=Path, required=True)
    p.add_argument('--version', default='3.57.0', help='Game version recorded in the illustration catalogue')
    p.add_argument('--data', type=Path, default=Path(__file__).parent / 'dist/data')
    p.add_argument('--output', type=Path)
    p.add_argument('--library', type=Path)
    p.add_argument('--inventory-only', action='store_true')
    p.add_argument('--only', nargs='*', help='Optional exact bundle names for focused regeneration')
    args = p.parse_args()
    if not re.fullmatch(r'\d+\.\d+\.\d+', args.version):
        p.error('Version must have the form 3.57.0')
    if args.library:
        sys.path.insert(0, str(args.library))
    import UnityPy
    snapshot = args.snapshot.resolve()
    out = (args.output or snapshot / 'illustrations/all-heroes').resolve()
    roots = source_roots(snapshot)
    if any(out.is_relative_to(root.resolve()) for root in roots):
        p.error('Output must not be inside a read-only source capture')
    out.mkdir(parents=True, exist_ok=True)
    get_label = labels(args.data)
    sources = {}
    for root in roots:
        folder = root / 'illusts'
        if folder.exists():
            for path in sorted(folder.rglob('*')):
                if path.is_file() and path.suffix != '.etag':
                    sources.setdefault(path.relative_to(root).as_posix(), []).append((root, path))
    entries, jobs, inventory, failures = [], [], [], []
    for i, (bundle, candidates) in enumerate(sorted(sources.items()), 1):
        root, path = candidates[0]
        name = path.name
        if args.only and name not in args.only:
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        label = get_label(name)
        label['provenance'] = {'sourceBundle': bundle, 'sourceSha256': digest,
                               'capture': path.relative_to(snapshot).as_posix()}
        inspection_file = out / 'inventory-cache' / (digest[:24] + '.json')
        try:
            details = read_json(inspection_file) if inspection_file.exists() else None
            if details is None or any('filterMode' not in t for t in details['textures']):
                details = inspect_bundle(path, UnityPy)
                write(inspection_file, details)
            inv = {'id': name, 'bundle': bundle, 'sourceSha256': digest,
                   'bytes': path.stat().st_size, 'capturedCopies': [
                       {'capture': cp.relative_to(snapshot).as_posix(),
                        'sourceSha256': hashlib.sha256(cp.read_bytes()).hexdigest()}
                       for _, cp in candidates], **details}
            inventory.append(inv)
            if args.inventory_only:
                label['status'] = 'inventoried'
                entries.append(label)
                continue
            cache = extract(bundle, root, out / 'rigs', UnityPy, source_roots=roots)
            payload = read_json(cache)
            label['provenance']['dependencySha256'] = payload.get('dependencySha256', {})
            label['provenance']['contentSha256'] = payload.get('contentSha256')
            label['status'] = 'extracted'
            label['rigs'] = []
            for ri, rig in enumerate(payload['skeletons']):
                # All prefab-linked rigs remain visible. A renderer can enumerate
                # non-default skins without inventing a character association.
                rid = name if len(payload['skeletons']) == 1 else name + '--' + str(ri + 1)
                job = {'id': rid, 'illustrationId': name, 'bundle': bundle,
                       'cacheFile': cache.relative_to(out).as_posix(), 'rigIndex': ri,
                       'prefab': rig['prefab'], 'skin': rig['defaultSkin'],
                       'animation': rig['defaultAnimation'], 'skeleton': rig['name'],
                       'sourceSha256': digest}
                jobs.append(job)
                label['rigs'].append({k: job[k] for k in ('id', 'rigIndex', 'prefab', 'skin', 'animation', 'skeleton')})
            if payload.get('skipped'):
                label['notes'].append('Some source components could not be resolved; see the extraction report.')
                failures.append({'id': name, 'partial': True, 'components': payload['skipped']})
            entries.append(label)
        except Exception as error:
            label['status'] = 'unresolved'
            label['notes'].append(str(error))
            entries.append(label)
            failures.append({'id': name, 'reason': str(error)})
        if i % 10 == 0:
            print(f'{i}/{len(sources)} bundles; {len(jobs)} rigs; {len(failures)} unresolved', flush=True)
            # Checkpoints let the renderer start before the full extraction ends.
            write(out / 'jobs.json', {'schemaVersion': 1, 'jobs': jobs})
            write(out / 'catalog-base.json', {'version': args.version, 'illustrations': entries})
    hero_rows = [row['fields'] for row in read_json(args.data / 'heroes.json')]
    captured_names = {row['id'] for row in entries}
    playable = [row for row in hero_rows if row.get('Playable')]
    missing_playable = sorted({row['PortraitAssetName'] for row in playable
                               if row.get('PortraitAssetName') not in captured_names})
    summary = {'bundles': len(entries), 'sourceBytes': sum(r['bytes'] for r in inventory),
               'rigs': len(jobs), 'linkedBundles': sum(bool(r['references']) for r in entries),
               'namedBundles': sum(r['nameVerified'] for r in entries),
               'playableHeroOrigins': len({row['OriginId'] for row in playable}),
               'missingPlayablePortraitReferences': missing_playable,
               'unresolved': len(failures), 'variants': dict(collections.Counter(r['variant'] for r in entries)),
               'textures': sum(len(r['textures']) for r in inventory),
               'texturePixels': sum(t['width'] * t['height'] for r in inventory for t in r['textures'])}
    write(out / 'inventory.json', {'schemaVersion': 1, 'summary': summary, 'bundles': inventory})
    write(out / 'jobs.json', {'schemaVersion': 1, 'jobs': jobs})
    write(out / 'catalog-base.json', {'version': args.version, 'summary': summary, 'illustrations': entries})
    write(out / 'extraction-report.json', {'summary': summary, 'failures': failures})
    print(json.dumps(summary), flush=True)


if __name__ == '__main__':
    main()
