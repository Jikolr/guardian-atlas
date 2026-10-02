// OAuth exchange for Decap. No secrets, tokens or request URLs are logged.
const headers={'Cache-Control':'no-store','Referrer-Policy':'no-referrer','X-Content-Type-Options':'nosniff'};
const cookieName='__Host-atlas-oauth';
const cookie=(value,age=600)=>`${cookieName}=${value}; Path=/; Secure; HttpOnly; SameSite=Lax; Max-Age=${age}`;
const fail=(message,status=400)=>new Response(message,{status,headers:{...headers,'Set-Cookie':cookie('',0)}});
function random(){return Array.from(crypto.getRandomValues(new Uint8Array(32)),v=>v.toString(16).padStart(2,'0')).join('');}
export default {async fetch(request,env){
 try{
  env={SITE_ORIGIN:'https://jikolr.github.io',ALLOWED_LOGIN:'Jikolr',REPOSITORY:'Jikolr/guardian-explorer',...env};
  const url=new URL(request.url);
  if(request.method!=='GET')return fail('Method not allowed',405);
  if(url.pathname==='/')return new Response('Guardian Atlas authentication service',{headers});
  if(!env.GITHUB_CLIENT_ID||!env.GITHUB_CLIENT_SECRET||!env.SITE_ORIGIN||!env.ALLOWED_LOGIN||!env.REPOSITORY)return fail('Authentication setup is incomplete.',503);
  const origin=new URL(env.SITE_ORIGIN).origin;
  if(!origin.startsWith('https://'))return fail('Invalid site configuration',503);
  const redirect=url.origin+'/callback';
  if(url.pathname==='/auth'){
   if(url.searchParams.get('provider')!=='github')return fail('Unsupported provider');
   const state=random();
   const to=new URL('https://github.com/login/oauth/authorize');
   to.search=new URLSearchParams({client_id:env.GITHUB_CLIENT_ID,redirect_uri:redirect,scope:'public_repo',state}).toString();
   return new Response(null,{status:302,headers:{...headers,Location:to.href,'Set-Cookie':cookie(state)}});
  }
  if(url.pathname!=='/callback')return fail('Not found',404);
  const state=url.searchParams.get('state');
  const saved=request.headers.get('Cookie')?.split(';').map(v=>v.trim()).find(v=>v.startsWith(cookieName+'='))?.slice(cookieName.length+1);
  if(!state||!saved||state!==saved||!/^[a-f0-9]{64}$/.test(state))return fail('Invalid or expired login. Please try again.');
  const code=url.searchParams.get('code');if(!code)return fail('Login cancelled or code missing.');
  const response=await fetch('https://github.com/login/oauth/access_token',{method:'POST',headers:{Accept:'application/json','Content-Type':'application/json'},body:JSON.stringify({client_id:env.GITHUB_CLIENT_ID,client_secret:env.GITHUB_CLIENT_SECRET,code,redirect_uri:redirect})});
  const data=await response.json();if(!response.ok||!data.access_token)return fail('GitHub rejected the login.',401);
  const token=data.access_token;
  const ghHeaders={Accept:'application/vnd.github+json',Authorization:`Bearer ${token}`,'User-Agent':'Guardian-Atlas-Editor'};
  const userResponse=await fetch('https://api.github.com/user',{headers:ghHeaders});
  const user=await userResponse.json();
  if(!userResponse.ok||user.login?.toLowerCase()!==env.ALLOWED_LOGIN.toLowerCase())return fail('This account is not an administrator.',403);
  const repoResponse=await fetch(`https://api.github.com/repos/${env.REPOSITORY}`,{headers:ghHeaders});
  const repo=await repoResponse.json();if(!repoResponse.ok||!repo.permissions?.push)return fail('Repository write access is required.',403);
  const nonce=random();
  const payload=JSON.stringify('authorization:github:success:'+JSON.stringify({token,provider:'github'})).replace(/</g,'\\u003c');
  const html=`<!doctype html><meta charset="utf-8"><title>Connexion à Guardian Atlas</title><p>Connexion réussie. Retourne dans l’éditeur.</p><script nonce="${nonce}">const origin=${JSON.stringify(origin)};const receive=e=>{if(e.origin!==origin||e.source!==window.opener)return;window.opener.postMessage(${payload},origin);window.removeEventListener('message',receive);window.close();};window.addEventListener('message',receive);if(window.opener)window.opener.postMessage('authorizing:github',origin);</script>`;
  return new Response(html,{headers:{...headers,'Content-Type':'text/html; charset=utf-8','Set-Cookie':cookie('',0),'Content-Security-Policy':`default-src 'none'; script-src 'nonce-${nonce}'; base-uri 'none'; frame-ancestors 'none'`}});
 }catch{return fail('Authentication service unavailable. Please try again.',502);}
}};
