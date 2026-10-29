
"""Verify a prepared snapshot; upload only when --publish is explicitly supplied.
Creates a draft first, then publishes and switches the catalog after all assets verify.
Usage: python publish_snapshot_release.py --archives PATH --version 3.57.0 [--publish]
"""
from pathlib import Path
import argparse,json,subprocess,os,re,urllib.request,urllib.error,urllib.parse,http.client,hashlib
from prepare_snapshot_release import exported_files, write
B=Path(__file__).resolve().parent
def hash_file(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for part in iter(lambda:f.read(4*1024*1024),b''):h.update(part)
 return h.hexdigest()
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--archives',type=Path,help='Prepared directory containing release-manifest.json and ZIPs')
 parser.add_argument('--work',type=Path,help='Snapshot directory; uses its packs/ child when --archives is omitted')
 parser.add_argument('--version',required=True)
 parser.add_argument('--repo',default='Jikolr/guardian-atlas')
 parser.add_argument('--desktop-account',help='Use this existing GitHub Desktop account if Git Credential Manager has no credential')
 parser.add_argument('--publish',action='store_true',help='Upload, verify, publish and activate the prepared snapshot')
 args=parser.parse_args()
 if not args.archives and not args.work:parser.error('Specify --archives or --work')
 OUT=args.archives or args.work/'packs';REPO=args.repo;TAG='game-files-'+args.version+'-snapshot'
 if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+',REPO):raise RuntimeError('Invalid GitHub owner/repository')
 manifest=json.loads((OUT/'release-manifest.json').read_text(encoding='utf8'))
 candidate=json.loads((OUT/'file-catalog.pending.json').read_text(encoding='utf8'))
 expected_base='https://github.com/'+REPO+'/releases/download/'+TAG+'/'
 for document in [manifest,candidate]:
  if document.get('currentVersion')!=args.version or document.get('releaseTag')!=TAG or document.get('releaseBase')!=expected_base:
   raise RuntimeError('Requested release does not match the prepared catalog')
 if manifest['archives']!=candidate['archives']:raise RuntimeError('Prepared catalog and release manifest disagree')
 for a in manifest['archives']:
  p=OUT/a['name']
  if p.resolve().parent!=OUT.resolve():raise RuntimeError('Unsafe archive name')
  if p.stat().st_size!=a['bytes'] or hash_file(p)!=a['sha256']:raise RuntimeError('Archive changed: '+a['name'])
 print('Verified prepared snapshot',args.version,len(manifest['archives']),'archives',flush=True)
 if not args.publish:
  print('No remote changes made. Supply --publish to upload and publish this snapshot.',flush=True)
  return
 env=dict(os.environ,GIT_TERMINAL_PROMPT='0',GCM_INTERACTIVE='Never')
 c=subprocess.run(['git','-c','credential.interactive=never','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,env=env,timeout=20)
 cred=dict(line.split('=',1) for line in c.stdout.splitlines() if '=' in line)
 token=cred.get('password')
 if not token and args.desktop_account:
  # Use GitHub Desktop's installed credential provider for this one explicit account.
  # Its service key is defined by Desktop's getKeyForEndpoint; no credential enumeration.
  desktop=Path(os.environ.get('LOCALAPPDATA',''))/'GitHubDesktop'
  providers=list(desktop.glob('app-*/resources/app/keytar.node'))
  providers.sort(key=lambda p:tuple(int(x) for x in re.findall(r'\d+',p.parents[2].name)),reverse=True)
  if providers:
   js="const k=require(process.argv[1]);k.getPassword('GitHub - https://api.github.com',process.argv[2]).then(p=>{if(p)process.stdout.write(p);else process.exitCode=1}).catch(()=>process.exitCode=1)"
   result=subprocess.run(['node','-e',js,str(providers[0]),args.desktop_account],capture_output=True,text=True,timeout=20)
   if result.returncode==0 and re.fullmatch(r'[A-Za-z0-9_]+',result.stdout):token=result.stdout
 if not token:raise RuntimeError('GitHub credentials unavailable')
 headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','User-Agent':'Guardian-Atlas-Release','X-GitHub-Api-Version':'2022-11-28'}
 def api(path,method='GET',body=None):
  data=json.dumps(body).encode() if body is not None else None
  req=urllib.request.Request('https://api.github.com'+path,data=data,method=method,headers={**headers,'Content-Type':'application/json'})
  with urllib.request.urlopen(req,timeout=60) as r:
   return None if r.status==204 else json.load(r)
 base='/repos/'+REPO
 try:release=api(base+'/releases/tags/'+TAG)
 except urllib.error.HTTPError as e:
  if e.code!=404:raise
  # Draft releases may not resolve through the tag endpoint until published.
  matches=[];page=1
  while True:
   releases=api(base+'/releases?per_page=100&page='+str(page))
   matches.extend(r for r in releases if r['tag_name']==TAG)
   if len(releases)<100:break
   page+=1
  if len(matches)>1:raise RuntimeError('Multiple releases use the snapshot tag; resolve before uploading.')
  if matches:
   release=matches[0]
   print('Resuming release',release['id'],flush=True)
  else:
   body=(OUT/'RELEASE.md').read_text(encoding='utf8').replace('This snapshot is prepared locally and has not been published.','This snapshot contains the verified archives listed below.')
   release=api(base+'/releases','POST',{'tag_name':TAG,'target_commitish':'main','name':'Guardian Tales game files — '+args.version,'body':body,'draft':True,'prerelease':False})
   print('Draft release created',release['html_url'],flush=True)
 # Stage published labels separately; a failed upload must not mark local artifacts published.
 published_manifest={**manifest,'releasePublished':True,'notes':'Verified game content snapshot '+args.version+'; see coverage.json for exclusions and decode gaps.'}
 staging=OUT/'publication-staging';staging.mkdir(exist_ok=True)
 (staging/'release-manifest.json').write_text(json.dumps(published_manifest,indent=2),encoding='utf8')
 (staging/'RELEASE.md').write_text((OUT/'RELEASE.md').read_text(encoding='utf8').replace('This snapshot is prepared locally and has not been published.','This snapshot contains the verified archives listed above.'),encoding='utf8')
 files=[OUT/a['name'] for a in manifest['archives']]+[staging/'release-manifest.json',OUT/'coverage.json',OUT/'SHA256SUMS.txt',staging/'RELEASE.md']
 def assets():
  result=[];page=1
  while True:
   chunk=api(base+'/releases/'+str(release['id'])+'/assets?per_page=100&page='+str(page));result+=chunk
   if len(chunk)<100:return {a['name']:a for a in result}
   page+=1
 existing=assets()
 def valid(a,p):
  if a['size']!=p.stat().st_size or a.get('state')!='uploaded':return False
  digest=a.get('digest')
  if digest:return digest=='sha256:'+hash_file(p)
  # Older GitHub responses may omit digest: verify the authenticated binary stream.
  req=urllib.request.Request(a['url'],headers={**headers,'Accept':'application/octet-stream'})
  h=hashlib.sha256()
  with urllib.request.urlopen(req,timeout=120) as r:
   for chunk in iter(lambda:r.read(4*1024*1024),b''):h.update(chunk)
  return h.hexdigest()==hash_file(p)
 for i,p in enumerate(files,1):
  old=existing.get(p.name)
  if old and release['draft'] and old.get('state')=='starter' and not old.get('digest'):
   api(base+'/releases/assets/'+str(old['id']),'DELETE')
   print('Removed incomplete failed upload',p.name,flush=True)
   old=None
  if old:
   if not valid(old,p):raise RuntimeError('Existing release asset differs; not overwritten: '+p.name)
   print('Already verified',p.name,flush=True);continue
  if not release['draft']:raise RuntimeError('Existing published release is incomplete; refusing to alter it.')
  url=urllib.parse.urlsplit(release['upload_url'].split('{')[0]+'?name='+urllib.parse.quote(p.name))
  conn=http.client.HTTPSConnection(url.netloc,timeout=180)
  conn.putrequest('POST',url.path+'?'+url.query)
  for k,v in {**headers,'Content-Type':'application/zip' if p.suffix=='.zip' else 'application/octet-stream','Content-Length':str(p.stat().st_size)}.items():conn.putheader(k,v)
  conn.endheaders()
  print('Uploading',i,'/',len(files),p.name,flush=True)
  with p.open('rb') as f:
   for chunk in iter(lambda:f.read(4*1024*1024),b''):conn.send(chunk)
  response=conn.getresponse();raw=response.read();status=response.status;conn.close()
  if status!=201:raise RuntimeError('Upload failed, HTTP '+str(status)+' for '+p.name)
  a=json.loads(raw)
  if not valid(a,p):raise RuntimeError('Uploaded asset validation failed: '+p.name)
  print('Uploaded and verified',p.name,flush=True)
 verified=assets()
 if not all(p.name in verified and valid(verified[p.name],p) for p in files):raise RuntimeError('Release verification incomplete')
 if release['draft']:release=api(base+'/releases/'+str(release['id']),'PATCH',{'draft':False})
 candidate['files']=[r for r in candidate['files'] if r['section']!='exports']+exported_files(B)
 candidate['releasePublished']=True;candidate['notes']=published_manifest['notes']
 write(B/'dist/data/file-catalog.json',candidate)
 (OUT/'release-manifest.json').write_text(json.dumps(published_manifest,indent=2),encoding='utf8')
 (OUT/'RELEASE.md').write_text((staging/'RELEASE.md').read_text(encoding='utf8'),encoding='utf8')
 (OUT/'publication.json').write_text(json.dumps({'url':release['html_url'],'id':release['id'],'assets':len(files),'verified':True},indent=2),encoding='utf8')
 print('PUBLISHED',release['html_url'],flush=True)
if __name__=='__main__':
 try:main()
 except Exception as e:
  print('Publication stopped:',type(e).__name__,str(e) if isinstance(e,RuntimeError) else 'See the release state before retrying.',flush=True)
  raise SystemExit(1)

