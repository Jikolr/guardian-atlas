"""Conservative direct tower-class -> action -> buff reference index."""
import json
from import_snapshot import write
from pathlib import Path
ROOT = Path(__file__).resolve().parent/'dist/data'
def get(name):
    return json.loads((ROOT/(name+'.json')).read_text(encoding='utf-8'))
db = get('orbital-lift')
styles = get('static-battlestyles')
actions = {r['fields']['Name']: r for r in get('static-battleactions')}
buffs = get('static-buffs')
by_name = {r['fields']['Name']: r for r in buffs}
by_id = {r['id']: r for r in buffs}
result = {}
for enemy in db['enemies'].values():
    spec = enemy['spec']
    found = {}
    for style in styles:
        if style['fields'].get('Class') != spec['Class']:
            continue
        names = list(style['fields'].get('BattleActions') or [])
        # Reviewed nested Tower action: manager 1103 -> Extra 437 -> mark 3306021.
        # Do not infer activation of the optional weapon/special-option variants.
        if spec['Name'] == 'it_mirror_exorcist_girl_myth_rift' and 'ManualBranchComboManager:ExorcistGirl' in names:
            names.extend(actions['ManualBranchComboManager:ExorcistGirl']['fields'].get('ExtraAction') or [])
        for name in names:
            action = actions.get(name)
            if not action:
                continue
            for key, value in action['fields'].items():
                if 'buff' not in key.lower() or not isinstance(value, (str, int)):
                    continue
                buff = by_name.get(value) if isinstance(value, str) else by_id.get(value)
                if not buff:
                    continue
                fields = buff['fields']
                if str(fields.get('AilmentType', '')).lower() in ('poison','down','aerial'):
                    continue
                negative = {k:v for k,v in fields.items() if isinstance(v,(int,float)) and v < 0 and any(t in k.lower() for t in ('scale','resistance','amount','speed'))}
                if not negative:
                    continue
                entry = found.setdefault(buff['id'], {'id':buff['id'], 'record':fields, 'parameters':negative, 'references':[]})
                entry['references'].append({'styleId':style['id'], 'actionId':action['id'], 'action':name, 'field':key, 'level':action['fields'].get('BuffLevel',action['fields'].get('DebuffLv'))})
    if found:
        result[str(spec['Id'])] = list(found.values())
write(ROOT/'orbital-debuffs.json',{'enemies':result,'coverage':'Direct BattleActions buff references with negative stat parameters only. Script, projectile, graph and option-only effects may be missing. Assignment does not prove execution or target in combat.'})
