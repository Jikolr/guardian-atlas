"""Export validated metadata tables without keys, literals or native-address claims."""
from pathlib import Path
import argparse,csv,gzip,hashlib,json,io

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--source',required=True,type=Path)
    ap.add_argument('--version',required=True)
    ap.add_argument('--repo',type=Path,default=Path(__file__).resolve().parent)
    args=ap.parse_args()
    if not all(c.isdigit() or c=='.' for c in args.version):ap.error('Version must contain digits and periods')
    s=json.loads((args.source/'metadata-summary.json').read_text(encoding='utf8'))
    for key in ['all_section_bounds_valid','all_sections_contiguous','all_method_owners_valid','all_records_covered_once','all_literal_strings_strict_utf8']:
        if not s.get(key):raise ValueError('Metadata validation missing: '+key)
    out=args.repo/'dist/data/research'/('metadata-'+args.version);out.mkdir(parents=True,exist_ok=True)
    files=[]
    for family in ['types','methods','fields']:
        raw=(args.source/('managed-'+family+'.csv')).read_bytes()
        records=sum(1 for _ in csv.DictReader(io.StringIO(raw.decode('utf8'))))
        if records!=s[family]:raise ValueError(f'{family}: count mismatch')
        packed=gzip.compress(raw,mtime=0);assert gzip.decompress(packed)==raw
        target=out/('managed-'+family+'.csv.gz');target.write_bytes(packed)
        files.append(dict(name=target.name,records=records,bytes=len(packed),sha256=hashlib.sha256(packed).hexdigest(),encoding='gzip',contentType='text/csv'))
    summary={k:s[k] for k in ['metadata_size','metadata_sha256','types','methods','fields','literals','assemblies','all_section_bounds_valid','all_sections_contiguous','all_method_owners_valid','all_records_covered_once','all_literal_strings_strict_utf8']}
    summary.update(version=args.version,package='com.kakaogames.gdtskr',files=files,notice='Validated metadata tables from the supplied APK and phone capture. This is a metadata index, not original C# source. No native addresses are assigned here. The existing native-code browser remains historical 3.54.0 evidence. String literals and decryption constants are excluded from these public exports.')
    (out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
    evidence_path=args.repo/'dist/data/research/evidence.json'
    evidence=json.loads(evidence_path.read_text(encoding='utf8'))
    labels={'summary.json':'metadata validation and coverage','managed-types.csv.gz':'type index',
            'managed-methods.csv.gz':'method index','managed-fields.csv.gz':'field index',
            'method-addresses.json.gz':'validated native method addresses',
            'codegen-modules.json.gz':'native module index','native-summary.json':'native mapping validation'}
    prefix='metadata-'+args.version+'/'
    evidence=[r for r in evidence if not r['path'].startswith(prefix)]
    for filename,label in labels.items():
        p=out/filename
        if p.exists():evidence.append(dict(path=prefix+filename,name=args.version+' — '+label,
            category='Download inventories',url=p.relative_to(args.repo/'dist').as_posix(),bytes=p.stat().st_size,
            note='Current snapshot structural evidence. Historical native disassembly remains separately labeled.',version=args.version))
    evidence_path.write_text(json.dumps(evidence,ensure_ascii=False,separators=(',',':')),encoding='utf8')
    print(json.dumps(dict(version=args.version,files=files),indent=2))

if __name__=='__main__':main()
