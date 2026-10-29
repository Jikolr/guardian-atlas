/* Minimal, dependency-free renderer for the exported Unity mesh data. */
window.createMapArt=async function(tiles){
 const root='data/visual/',index=await fetch(root+'tilesets.json').then(r=>{if(!r.ok)throw Error('Tileset catalog unavailable');return r.json()});
 const scene={meshes:{},materials:{},rotationDegreesPerCode:90,skipped:[]};
 for(const name of new Set(tiles.map(t=>t.tileset))){const entry=index[name];if(!entry?.path){scene.skipped.push(name);continue}
  try{const source=await fetch(root+entry.path).then(r=>{if(!r.ok)throw Error('Mesh data unavailable');return new Response(r.body.pipeThrough(new DecompressionStream('gzip'))).json()}),prefix=root+entry.path.slice(0,entry.path.lastIndexOf('/')+1);
   for(const [id,mat] of Object.entries(source.materials))scene.materials[name+':'+id]={...mat,texture:prefix+mat.texture};
   for(const [id,parts] of Object.entries(source.meshes))scene.meshes[name+'/'+id]=parts.map(p=>({...p,material:name+':'+p.material}));
  }catch(e){scene.skipped.push(name)}
 }
 const matched=tiles.filter(t=>scene.meshes[t.tileset+'/'+t.name]?.length).length;
 if(!matched)throw Error('No resolved static tile meshes for this map');
 const canvas=document.createElement('canvas'),gl=canvas.getContext('webgl',{alpha:true,antialias:true,preserveDrawingBuffer:true});if(!gl)throw Error('WebGL is unavailable');
 const shader=(type,source)=>{const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s};
 const program=gl.createProgram();gl.attachShader(program,shader(gl.VERTEX_SHADER,`
 attribute vec3 position;attribute vec2 uv;varying vec2 vUV;
 uniform vec4 view;uniform vec2 size;uniform vec2 tilt;uniform float depthRange;
 void main(){vec2 pixel=vec2(view.x+position.x*view.z,view.y-(position.z*tilt.x+position.y*tilt.y)*view.z);
 gl_Position=vec4(pixel.x/size.x*2.0-1.0,1.0-pixel.y/size.y*2.0,(position.z*tilt.y-position.y*tilt.x)/depthRange,1.0);vUV=uv;}`));
 gl.attachShader(program,shader(gl.FRAGMENT_SHADER,`precision mediump float;varying vec2 vUV;uniform sampler2D tex;uniform vec4 tint;void main(){vec4 c=texture2D(tex,vUV)*tint;if(c.a<0.15)discard;gl_FragColor=c;}`));
 gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(program));gl.useProgram(program);
 const loc={};for(const k of ['view','size','tilt','tint','tex','depthRange'])loc[k]=gl.getUniformLocation(program,k);
 const position=gl.getAttribLocation(program,'position'),uv=gl.getAttribLocation(program,'uv');
 // Billboards share the tile depth buffer. Their origin is the original foot
 // position, so a wall can cover a character without flattening it onto the map.
 const spriteProgram=gl.createProgram();
 gl.attachShader(spriteProgram,shader(gl.VERTEX_SHADER,`
 attribute vec3 position;attribute vec2 uv;attribute vec2 offset;varying vec2 vUV;
 uniform vec4 view;uniform vec2 size;uniform vec2 tilt;uniform float depthRange;
 void main(){vec2 pixel=vec2(view.x+position.x*view.z,view.y-(position.z*tilt.x+position.y*tilt.y)*view.z)+vec2(offset.x,-offset.y)*view.z;
 float standingDepth=position.z*tilt.y-position.y*tilt.x;
 if(tilt.y>0.001)standingDepth-=offset.y*tilt.x/tilt.y;
 gl_Position=vec4(pixel.x/size.x*2.0-1.0,1.0-pixel.y/size.y*2.0,standingDepth/depthRange-0.000001,1.0);vUV=uv;}`));
 gl.attachShader(spriteProgram,shader(gl.FRAGMENT_SHADER,`precision mediump float;varying vec2 vUV;uniform sampler2D tex;void main(){vec4 c=texture2D(tex,vUV);if(c.a<0.03)discard;gl_FragColor=c;}`));
 gl.linkProgram(spriteProgram);if(!gl.getProgramParameter(spriteProgram,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(spriteProgram));
 const spriteLoc={};for(const k of ['view','size','tilt','tex','depthRange'])spriteLoc[k]=gl.getUniformLocation(spriteProgram,k);
 const spritePosition=gl.getAttribLocation(spriteProgram,'position'),spriteUV=gl.getAttribLocation(spriteProgram,'uv'),spriteOffset=gl.getAttribLocation(spriteProgram,'offset');
 const spriteTextures=new Map(),spriteBuffer=gl.createBuffer();
 function spriteTexture(image){
  if(spriteTextures.has(image))return spriteTextures.get(image);
  const tex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,tex);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);
  gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);
  gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.NEAREST);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
  spriteTextures.set(image,tex);return tex;
 }
 const textures={};for(const mat of Object.values(scene.materials)){
  if(textures[mat.texture])continue;const img=new Image();img.src=mat.texture;await img.decode();const tex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,tex);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,img);
  gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.NEAREST);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.NEAREST);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);textures[mat.texture]=tex;
 }
 const depthRange=tiles.reduce((n,t)=>Math.max(n,Math.abs(t.position[1])+Math.abs(t.position[2])+100),100);
 const groups=new Map();let triangles=0;
 for(const tile of tiles){const angle=tile.rotation*scene.rotationDegreesPerCode*Math.PI/180,c=Math.cos(angle),s=Math.sin(angle);
  for(const part of scene.meshes[tile.tileset+'/'+tile.name]||[]){const key=tile.layer+':'+part.material;let group=groups.get(key);if(!group){group={layer:tile.layer,material:scene.materials[part.material],values:[]};groups.set(key,group)}const mat=group.material;
   for(const tri of part.triangles){triangles++;for(const idx of tri){const [x,y,z]=part.vertices[idx],uv=part.uv[idx];group.values.push(tile.position[0]+c*x+s*z,tile.position[1]+y,tile.position[2]-s*x+c*z,uv[0]*mat.scale[0]+mat.offset[0],uv[1]*mat.scale[1]+mat.offset[1])}}
  }
 }
 for(const group of groups.values()){group.count=group.values.length/5;group.buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,group.buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(group.values),gl.STATIC_DRAW);delete group.values}
 gl.enable(gl.DEPTH_TEST);gl.depthFunc(gl.LEQUAL);gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);
 return {triangles,scene,matched,render({width,height,scale,ox,oy,visible,tilted,entities=[]}){
  const dpr=window.devicePixelRatio||1,w=Math.round(width*dpr),h=Math.round(height*dpr);if(canvas.width!==w||canvas.height!==h){canvas.width=w;canvas.height=h}gl.viewport(0,0,w,h);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.useProgram(program);gl.uniform4f(loc.view,ox,oy,scale,0);gl.uniform2f(loc.size,width,height);gl.uniform2f(loc.tilt,tilted?.8:1,tilted?.6:0);gl.uniform1i(loc.tex,0);gl.uniform1f(loc.depthRange,depthRange);
  for(const group of groups.values()){if(!visible.has(group.layer))continue;gl.bindBuffer(gl.ARRAY_BUFFER,group.buffer);gl.enableVertexAttribArray(position);gl.enableVertexAttribArray(uv);gl.vertexAttribPointer(position,3,gl.FLOAT,false,20,0);gl.vertexAttribPointer(uv,2,gl.FLOAT,false,20,12);gl.bindTexture(gl.TEXTURE_2D,textures[group.material.texture]);gl.uniform4f(loc.tint,1,1,1,1);gl.drawArrays(gl.TRIANGLES,0,group.count)}
  if(entities.length){
   const tx=tilted?.8:1,ty=tilted?.6:0;
   gl.useProgram(spriteProgram);gl.uniform4f(spriteLoc.view,ox,oy,scale,0);gl.uniform2f(spriteLoc.size,width,height);
   gl.uniform2f(spriteLoc.tilt,tx,ty);gl.uniform1i(spriteLoc.tex,0);gl.uniform1f(spriteLoc.depthRange,depthRange);
   gl.bindBuffer(gl.ARRAY_BUFFER,spriteBuffer);
   for(let i=0;i<gl.getParameter(gl.MAX_VERTEX_ATTRIBS);i++)gl.disableVertexAttribArray(i);
   for(const attr of [spritePosition,spriteUV,spriteOffset])gl.enableVertexAttribArray(attr);
   gl.vertexAttribPointer(spritePosition,3,gl.FLOAT,false,28,0);gl.vertexAttribPointer(spriteUV,2,gl.FLOAT,false,28,12);gl.vertexAttribPointer(spriteOffset,2,gl.FLOAT,false,28,20);
   const sorted=[...entities].sort((a,b)=>(b.position[2]*ty-b.position[1]*tx)-(a.position[2]*ty-a.position[1]*tx));
   for(const item of sorted){
    if(!visible.has(item.layer)||!item.image)continue;
    const [originalAnchorX,ay]=item.anchor,ax=item.flipX?1-originalAnchorX:originalAnchorX,left=-ax*item.worldWidth,right=(1-ax)*item.worldWidth,top=ay*item.worldHeight,bottom=-(1-ay)*item.worldHeight;
    const screenX=ox+item.position[0]*scale,screenY=oy-(item.position[2]*tx+item.position[1]*ty)*scale;
    if(screenX+right*scale<0||screenX+left*scale>width||screenY-top*scale>height||screenY-bottom*scale<0)continue;
    const u0=item.flipX?1:0,u1=item.flipX?0:1;
    const vertices=[[left,top,u0,1],[right,top,u1,1],[left,bottom,u0,0],[left,bottom,u0,0],[right,top,u1,1],[right,bottom,u1,0]];
    gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(vertices.flatMap(([x,y,u,v])=>[...item.position,u,v,x,y])),gl.DYNAMIC_DRAW);
    gl.bindTexture(gl.TEXTURE_2D,spriteTexture(item.image));gl.drawArrays(gl.TRIANGLES,0,6);
   }
   for(const attr of [spritePosition,spriteUV,spriteOffset])gl.disableVertexAttribArray(attr);
  }
  return canvas;
 }};
};
