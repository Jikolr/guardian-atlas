"""Extract original Spine inputs for map sprites; never execute recovered game code.

Example: python export_map_sprite_frames.py --snapshot SNAPSHOT --jobs jobs.json
  --cache SNAPSHOT/map-graphics/rigs --library UNITYPY_LIBRARY
The companion render_map_sprite_frames.cjs renders the resulting jobs.json.
"""
from pathlib import Path
import argparse, base64, hashlib, io, json, re, sys


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, separators=(',', ':')), encoding='utf8')


def extract(bundle, source_root, cache, unity, source_roots=None):
    source = (source_root / bundle).resolve()
    if not source.is_relative_to(source_root.resolve()):
        raise ValueError('Bundle must remain inside the source asset directory')
    raw = source.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    roots = list(dict.fromkeys(Path(p).resolve() for p in (source_roots or [source_root])))

    def source_candidates(name):
        # Dependency names come from AssetBundle.m_Dependencies, but still must
        # stay within the supplied captures. A filename alone never selects an
        # external object: its serialized-file CAB and pathID must also match.
        if not name or Path(name).is_absolute() or name.startswith(('/', '\\')):
            raise ValueError('Invalid declared dependency name')
        for root in roots:
            path = (root / name).resolve()
            if not path.is_relative_to(root):
                raise ValueError('Declared dependency must remain inside its source asset directory')
            if path.is_file():
                yield path

    output_v2 = cache / (digest[:24] + '-v2.json')
    output_v3 = cache / (digest[:24] + '-v3.json')
    if output_v3.exists():
        cached = json.loads(output_v3.read_text(encoding='utf8'))
        deps = cached.get('dependencySha256')
        if isinstance(deps, dict) and not cached.get('skipped') and all(
            any(hashlib.sha256(p.read_bytes()).hexdigest() == expected for p in source_candidates(name))
            for name, expected in deps.items()
        ):
            return output_v3
    if output_v2.exists():
        cached = json.loads(output_v2.read_text(encoding='utf8'))
        if not cached.get('skipped'):
            return output_v2

    env = unity.load(raw)
    root_objects = list(env.objects)
    files, file_sources, loaded_paths, pending, queued = {}, {}, {source}, [], set()
    tree_cache, dependencies = {}, {}

    def file_name(file):
        return str(file.name).replace('\\', '/').rsplit('/', 1)[-1].lower()

    def register(environment, name, sha):
        declared = set()
        for obj in environment.objects:
            cab = file_name(obj.assets_file)
            files.setdefault(cab, obj.assets_file)
            file_sources.setdefault(cab, (name, sha))
            if obj.type.name == 'AssetBundle':
                declared.update(obj.read_typetree().get('m_Dependencies', []))
        for dependency in sorted(declared):
            for path in source_candidates(dependency):
                if path not in loaded_paths and path not in queued:
                    pending.append((dependency, path))
                    queued.add(path)

    register(env, bundle, digest)

    def external_file(cab):
        while cab not in files and pending:
            name, path = pending.pop(0)
            if path in loaded_paths:
                continue
            loaded_paths.add(path)
            data = path.read_bytes()
            register(unity.load(data), name, hashlib.sha256(data).hexdigest())
        if cab not in files:
            raise ValueError(f'External serialized file is unavailable in declared dependencies: {cab}')

    def key_for(pointer, owner):
        file_id = pointer.get('m_FileID', 0)
        cab = owner
        if file_id:
            externals = files[owner].externals
            if file_id < 1 or file_id > len(externals):
                raise ValueError('External asset fileID is outside its owning serialized file')
            cab = str(externals[file_id - 1].path).replace('\\', '/').rsplit('/', 1)[-1].lower()
            external_file(cab)
        ident = pointer['m_PathID']
        if ident not in files[cab].objects:
            raise ValueError(f'Asset pathID {ident} is absent from serialized file {cab}')
        name, sha = file_sources[cab]
        if name != bundle:
            previous = dependencies.setdefault(name, sha)
            if previous != sha:
                raise ValueError(f'Multiple captured versions are required for declared dependency {name}')
        return cab, ident

    def read_tree(key):
        if key not in tree_cache:
            tree_cache[key] = files[key[0]].objects[key[1]].read_typetree()
        return tree_cache[key]

    def tree(pointer, owner):
        key = key_for(pointer, owner)
        return key, read_tree(key)

    trees = {}
    objects = {}
    for obj in root_objects:
        key = file_name(obj.assets_file), obj.path_id
        objects[key] = obj
        if obj.type.name in ('MonoBehaviour', 'Material', 'Transform', 'GameObject', 'TextAsset', 'AssetBundle'):
            try:
                trees[key] = read_tree(key)
            except Exception:
                pass

    def text(pointer, owner):
        _, t = tree(pointer, owner)
        data = t['m_Script']
        return t['m_Name'], data.encode('utf8', 'surrogateescape') if isinstance(data, str) else bytes(data)

    texture_cache = {}
    def texture(pointer, owner):
        key = key_for(pointer, owner)
        if key not in texture_cache:
            item = files[key[0]].objects[key[1]].read()
            stream = io.BytesIO(); item.image.save(stream, format='PNG')
            texture_cache[key] = {'name': item.m_Name, 'png': base64.b64encode(stream.getvalue()).decode('ascii')}
        return texture_cache[key]

    transforms = {(k[0], t['m_GameObject']['m_PathID']): (k,t) for k,t in trees.items() if objects[k].type.name == 'Transform'}
    prefabs = {}
    for key,t in trees.items():
        if objects[key].type.name == 'AssetBundle':
            for asset_path,entry in t.get('m_Container', []):
                if asset_path.endswith('.prefab') and entry['asset'].get('m_FileID', 0) == 0:
                    prefabs[(key[0], entry['asset']['m_PathID'])] = Path(asset_path).stem

    def parent_transform(key, t):
        parent = t.get('m_Father', {})
        if not parent.get('m_PathID'):
            return None
        parent_key = key_for(parent, key[0])
        value = trees.get(parent_key)
        return (parent_key, value) if value is not None else None

    def hierarchy(go):
        result = []
        current = transforms.get(go)
        visited = set()
        while current and current[0] not in visited:
            key, t = current
            visited.add(key)
            ident = key[0], t['m_GameObject']['m_PathID']
            result.append((ident, trees.get(ident, {}).get('m_Name', '')))
            current = parent_transform(key, t)
        return result

    def transform_scale(go):
        value = [1., 1.]
        current = transforms.get(go)
        visited = set()
        while current and current[0] not in visited:
            key, t = current
            visited.add(key)
            scale = t.get('m_LocalScale', {})
            value[0] *= scale.get('x', 1); value[1] *= scale.get('y', 1)
            current = parent_transform(key, t)
        return value

    atlases, skeletons, rigs = {}, [], {}

    def extract_rig(key, t):
        if key in rigs:
            return rigs[key]
        name, binary = text(t['skeletonJSON'], key[0])
        atlas_ids = []
        for ptr in t['atlasAssets']:
            atlas_key, atlas = tree(ptr, key[0])
            atlas_name, atlas_raw = text(atlas['atlasFile'], atlas_key[0])
            atlas_id = f'{atlas_name}|{atlas_key[0]}|{atlas_key[1]}'
            if atlas_id not in atlases:
                contents = atlas_raw.decode('utf8')
                lines = contents.splitlines()
                page_names = [line.strip() for i,line in enumerate(lines[:-1]) if line.strip() and lines[i+1].strip().startswith(('size:', 'format:')) and not ':' in line]
                textures = []
                for matptr in atlas.get('materials', []):
                    material_key, material = tree(matptr, atlas_key[0])
                    slots = dict(material['m_SavedProperties']['m_TexEnvs'])
                    textures.append(texture(slots['_MainTex']['m_Texture'], material_key[0]))
                if len(page_names) != len(textures):
                    raise ValueError(f'Atlas page/material count differs: {atlas_name}')
                atlases[atlas_id] = {'text': contents, 'pages': {p:im['png'] for p,im in zip(page_names,textures)}}
            atlas_ids.append(atlas_id)
        if len(atlas_ids) != 1:
            raise ValueError(f'Multiple atlases need explicit support: {name}')
        rigs[key] = {'name': name, 'binary': base64.b64encode(binary).decode('ascii'),
                     'scale': t.get('scale'), 'atlas': atlas_ids[0]}
        return rigs[key]

    skipped = []
    for component_key, component in trees.items():
        pointer = component.get('skeletonDataAsset', {})
        if not pointer.get('m_PathID'):
            continue
        chain = []
        try:
            go = component_key[0], component.get('m_GameObject', {}).get('m_PathID')
            chain = hierarchy(go)
            prefab = next((prefabs[i] for i,n in chain if i in prefabs), None)
            if not prefab:
                continue
            data_key, data = tree(pointer, component_key[0])
            rig = extract_rig(data_key, data)
            direction = next((m.group(1).lower() for i,n in chain if (m:=re.fullmatch(r'spine_(front|side|back)',n,re.I))), None)
            if not direction:
                direction = next((m.group(1).lower() for i,n in chain if (m:=re.search(r'(?:^|_)(front|side|back)$',n,re.I))), None)
            skeletons.append({**rig,
                              'prefab': prefab, 'direction':direction, 'hierarchy':[n for i,n in chain],
                              'defaultSkin': component.get('initialSkinName', 'default'),
                              'defaultAnimation': component.get('_animationName', ''),
                              'transformScale': transform_scale(go)})
        except (KeyError, ValueError) as e:
            # An unrelated alternate prefab can remain unavailable without
            # discarding exact, independently resolved sibling graphs.
            skipped.append({'name': '/'.join(n for i,n in chain), 'reason':str(e)})
    if not skeletons:
        raise ValueError(skipped[0]['reason'] if skipped else 'No self-contained Spine skeleton data in bundle')
    version = 3 if dependencies else 2
    output = output_v3 if version == 3 else output_v2
    content_digest = hashlib.sha256(json.dumps({'sourceSha256':digest, 'dependencySha256':dependencies}, sort_keys=True, separators=(',', ':')).encode('utf8')).hexdigest()
    write(output, {'schemaVersion': version, 'sourceBundle': bundle, 'sourceSha256': digest,
                   'dependencySha256':dependencies, 'contentSha256':content_digest,
                   'atlases': atlases, 'skeletons': skeletons, 'skipped':skipped})
    return output


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--snapshot', type=Path, required=True)
    p.add_argument('--jobs', type=Path, required=True)
    p.add_argument('--cache', type=Path, required=True)
    p.add_argument('--library', type=Path)
    args = p.parse_args()
    if args.library: sys.path.insert(0, str(args.library))
    import UnityPy
    args.cache.mkdir(parents=True, exist_ok=True)
    source_roots = [args.snapshot / 'phone/decoded/files/AssetBundles/Android',
                    args.snapshot / 'apk/decoded/com.kakaogames.gdtskr/assets/AssetBundles/Android']
    jobs = json.loads(args.jobs.read_text(encoding='utf8'))
    resolved, errors, bundles = [], [], {}
    for job in jobs:
        try:
            if not re.fullmatch('[a-zA-Z0-9_-]+', job['id']): raise ValueError('Unsafe graphic ID')
            bundle = job['bundle'].strip('/')
            if bundle not in bundles:
                source_root = next((root for root in source_roots if (root / bundle).is_file()), source_roots[0])
                bundles[bundle] = extract(bundle, source_root, args.cache, UnityPy, source_roots)
            resolved.append({**job, 'payload': str(bundles[bundle].resolve())})
        except Exception as e:
            errors.append({'id':job['id'], 'bundle':job.get('bundle'), 'error':'Source bundle not present in supplied capture' if isinstance(e,FileNotFoundError) else str(e)})
    output = args.cache / (args.jobs.stem + '-extracted.json')
    write(output, {'jobs':resolved, 'errors':errors})
    print(json.dumps({'output':str(output), 'jobs':len(resolved), 'bundles':len(bundles), 'errors':len(errors)}))

if __name__ == '__main__': main()
