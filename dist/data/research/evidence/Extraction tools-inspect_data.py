from pathlib import Path
from collections import Counter, defaultdict
import json, re, hashlib

ROOT = Path(r'com.kakaogames.gdtskr')
OUT = Path(__file__).parent
paths = sorted(p for p in ROOT.rglob('*') if p.is_file())
groups = defaultdict(lambda: [0, 0])
for p in paths:
    parts = p.relative_to(ROOT).parts
    group = '/'.join(parts[:2]) if parts[0] == 'files' and len(parts)>2 else parts[0]
    groups[group][0] += 1
    groups[group][1] += p.stat().st_size
samples = ['cache/heroes-bin','cache/monsters-bin','cache/battleactions-bin','files/static_data/heroes-bin','files/static_data/heroes','files/static_data/battleactions','files/Android.index','files/patch-index','files/events/FortuneTeller.json','files/GameScript/DemonWorldDataStore.encrypted','files/GameScript/eventcontrollers/DemonWorldDataStore.encrypted','files/GameScript/sections/DemonWorldDataStore/DemonWorldDataStoreSection1.encrypted']
details=[]
for name in samples:
    p=ROOT/name
    if not p.exists(): continue
    b=p.read_bytes()
    details.append(dict(path=name,size=len(b),head=b[:48].hex(),strings=[s.decode('ascii') for s in re.findall(rb'[\x20-\x7e]{6,}', b)[:12]],sha256=hashlib.sha256(b).hexdigest()))
encrypted=[p for p in paths if p.suffix=='.encrypted']
prefixes=Counter(p.read_bytes()[:16].hex() for p in encrypted)
report=dict(file_count=len(paths),total_bytes=sum(p.stat().st_size for p in paths),groups=dict(groups),encrypted_count=len(encrypted),encrypted_size_mod16=dict(Counter(p.stat().st_size%16 for p in encrypted)),common_encrypted_first_blocks=prefixes.most_common(6),samples=details)
(OUT/'inventory.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
