
"""Upload the verified 3.55.0 snapshot using existing Git credentials (never written to disk).
Creates a draft first; publishes and switches the local catalog only after all assets verify.
"""
from pathlib import Path
import json,subprocess,os,urllib.request,urllib.error,urllib.parse,http.client,hashlib
B=Path(__file__).resolve().parent;OUT=B.parent/'guardian-release-archives/3.55.0'
REPO='Jikolr/guardian-atlas';TAG='game-files-3.55.0-snapshot'
def hash_file(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for part in iter(lambda:f.read(4*1024*1024),b''):h.update(part)
 return h.hexdigest()
def main():
 manifest=json.loads((OUT/'release-manifest.json').read_text())
 for a in manifest['archives']:
  p=OUT/a['name']
  if p.stat().st_size!=a['bytes'] or hash_file(p)!=a['sha256']:raise RuntimeError('Archive changed: '+a['name'])
 env=dict(os.environ,GIT_TERMINAL_PROMPT='0',GCM_INTERACTIVE='Never')
 c=subprocess.run(['git','-c','credential.interactive=never','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,env=env,timeout=20)
 cred=dict(line.split('=',1) for line in c.stdout.splitlines() if '=' in line)
 token=cred.get('password')
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
   release=api(base+'/releases','POST',{'tag_name':TAG,'target_commitish':'main','name':'Guardian Tales game files — 3.55.0','body':(OUT/'RELEASE.md').read_text(encoding='utf8'),'draft':True,'prerelease':False})
   print('Draft release created',release['html_url'],flush=True)
 manifest['releasePublished']=True;manifest['notes']='Verified game content snapshot 3.55.0; see coverage.json for exclusions and decode gaps.'
 (OUT/'release-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
 files=[OUT/a['name'] for a in manifest['archives']]+[OUT/n for n in ['release-manifest.json','coverage.json','SHA256SUMS.txt','RELEASE.md']]
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
 candidate=json.loads((OUT/'file-catalog.pending.json').read_text())
 current=json.loads((B/'dist/data/file-catalog.json').read_text())
 candidate['files']=[r for r in candidate['files'] if r['section']!='exports']+[r for r in current['files'] if r['section']=='exports']
 candidate['releasePublished']=True;candidate['notes']=manifest['notes']
 (B/'dist/data/file-catalog.json').write_text(json.dumps(candidate,separators=(',',':')),encoding='utf8')
 (OUT/'publication.json').write_text(json.dumps({'url':release['html_url'],'id':release['id'],'assets':len(files),'verified':True},indent=2),encoding='utf8')
 print('PUBLISHED',release['html_url'],flush=True)
if __name__=='__main__':
 try:main()
 except Exception as e:
  print('Publication stopped:',type(e).__name__,str(e) if isinstance(e,RuntimeError) else 'See the release state before retrying.',flush=True)
  raise SystemExit(1)

