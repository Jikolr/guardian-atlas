/* Local render intermediates stay outside the deployed website. */
const fs=require('node:fs'),path=require('node:path');
module.exports=function buildCache(publicRoot,configuredRoot){
 const root=path.resolve(configuredRoot||path.join(__dirname,'.build-cache/map-entities'));
 function writePath(relative){
  const target=path.resolve(root,relative);
  if(!target.startsWith(root+path.sep))throw Error('Build cache path escapes its directory');
  fs.mkdirSync(path.dirname(target),{recursive:true});return target;
 }
 function readPath(relative){
  const target=writePath(relative),legacy=path.resolve(publicRoot,relative);
  if(!legacy.startsWith(path.resolve(publicRoot)+path.sep))throw Error('Legacy cache path escapes public directory');
  if(!fs.existsSync(target)&&fs.existsSync(legacy))fs.copyFileSync(legacy,target);
  return target;
 }
 return {root,readPath,writePath};
};
