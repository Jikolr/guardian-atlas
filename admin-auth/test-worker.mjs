import assert from 'node:assert/strict';
import worker from './worker.mjs';
const env={GITHUB_CLIENT_ID:'test',GITHUB_CLIENT_SECRET:'never-real',SITE_ORIGIN:'https://jikolr.github.io',ALLOWED_LOGIN:'Jikolr',REPOSITORY:'Jikolr/guardian-explorer'};
const run=(path,cookie)=>worker.fetch(new Request('https://auth.example'+path,{headers:cookie?{Cookie:cookie}:{}}),env);
assert.equal((await run('/auth?provider=other')).status,400);
const login=await run('/auth?provider=github');assert.equal(login.status,302);
const state=new URL(login.headers.get('location')).searchParams.get('state');
assert.equal(state.length,64);assert(login.headers.get('set-cookie').includes('HttpOnly'));
const cookie=login.headers.get('set-cookie').split(';')[0];
assert.equal((await run('/callback?code=x&state='+state)).status,400);
assert.equal((await run('/callback?code=x&state=wrong',cookie)).status,400);
let user='Jikolr',push=true;
const original=globalThis.fetch;
globalThis.fetch=async url=>Response.json(url.includes('access_token')?{access_token:'fake-token'}:url.endsWith('/user')?{login:user}:{permissions:{push}});
try{
 const ok=await run('/callback?code=x&state='+state,cookie);assert.equal(ok.status,200);
 const html=await ok.text();assert(html.includes('authorization:github:success'));assert(html.includes('e.source!==window.opener'));assert(!html.includes('postMessage("*"'));assert(ok.headers.get('content-security-policy').includes("frame-ancestors 'none'"));
 user='someone-else';assert.equal((await run('/callback?code=x&state='+state,cookie)).status,403);
 user='Jikolr';push=false;assert.equal((await run('/callback?code=x&state='+state,cookie)).status,403);
}finally{globalThis.fetch=original;}
console.log('PASS: OAuth state, owner restriction, write permissions and callback origin');
