// Development-only source inventory. Acorn is not shipped to visitors.
const fs=require('fs'),path=require('path');
const acorn=require('./.i18n-tools/node_modules/acorn');
const root=path.join(__dirname,'dist'),results=[];
function collect(code,file){
 let tree;try{tree=acorn.parse(code,{ecmaVersion:'latest',sourceType:'script',locations:true})}catch(error){throw Error(file+': '+error.message)}
 function variants(node,state){
  if(node.type==='Literal'&&typeof node.value==='string')return[node.value];
  if(node.type==='ConditionalExpression'&&[node.consequent,node.alternate].every(n=>n.type==='Literal'&&typeof n.value==='string'&&n.value.length<80))return[node.consequent.value,node.alternate.value];
  const join=(left,right)=>left.length*right.length<=16?left.flatMap(a=>right.map(b=>a+b)):['{'+state.next+++'}'];
  if(node.type==='BinaryExpression'&&node.operator==='+')return join(variants(node.left,state),variants(node.right,state));
  if(node.type==='TemplateLiteral'){
   let rows=[node.quasis[0].value.cooked||''];
   node.expressions.forEach((expression,index)=>{rows=join(rows,variants(expression,state)).map(row=>row+(node.quasis[index+1].value.cooked||''))});return rows;
  }
  return ['{'+state.next+++'}'];
 }
 function walk(node,parent){
  if(!node||typeof node!=='object')return;
  if((node.type==='Literal'&&typeof node.value==='string')||node.type==='TemplateLiteral'||(node.type==='BinaryExpression'&&node.operator==='+'&&!(parent?.type==='BinaryExpression'&&parent.operator==='+'))){
   for(const value of variants(node,{next:0}))if(value.length<16000)results.push({value,file,line:node.loc.start.line,kind:node.type});
  }
  for(const [key,value] of Object.entries(node))if(key!=='loc'){if(Array.isArray(value))value.forEach(child=>walk(child,node));else if(value&&typeof value==='object')walk(value,node)}
 }
 walk(tree,null);
}
for(const name of fs.readdirSync(root)){
 const file=path.join(root,name);if(name.endsWith('.js')&&!name.startsWith('site-language'))collect(fs.readFileSync(file,'utf8'),name);
 if(name.endsWith('.html')&&!['name-review.html','logo-concepts.html'].includes(name)){const html=fs.readFileSync(file,'utf8');for(const match of html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi))if(match[1].trim())collect(match[1],name+' (inline)')}
}
collect(fs.readFileSync(path.join(root,'admin/editor.js'),'utf8'),'admin/editor.js');
process.stdout.write(JSON.stringify(results));
