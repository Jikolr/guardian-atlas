/* Freeze the recovered collectible meshes into an original-artwork map sprite. */
const fs=require('node:fs'),path=require('node:path');
const options={};for(let i=2;i<process.argv.length;i+=2)options[process.argv[i].replace(/^--/,'')]=process.argv[i+1];
const {chromium}=require(options.playwright||process.env.PLAYWRIGHT_MODULE||'playwright');
const root=path.resolve(options.out||path.join(__dirname,'dist/data/visual/map-entities'));
const cache=require('./map_build_cache.cjs')(root,options.cache);
(async()=>{
 const scene=JSON.parse(fs.readFileSync(cache.readPath('props/star-piece-scene.json')));
 for(const mat of Object.values(scene.materials))for(const [key,file] of [['png',mat.texture],['capPng',mat.matcap]])mat[key]='data:image/png;base64,'+fs.readFileSync(cache.readPath(file)).toString('base64');
 const browser=await chromium.launch({headless:true,...(options.chrome?{executablePath:options.chrome}:{channel:'msedge'}),args:['--enable-unsafe-swiftshader','--use-angle=swiftshader']});
 try{
  const page=await browser.newPage();
  const result=await page.evaluate(async scene=>{
   const projected=scene.parts.flatMap(p=>p.vertices.map(v=>[v[0],v[2]*.8+v[1]*.6]));
   const minX=Math.min(...projected.map(v=>v[0]))-.04,maxX=Math.max(...projected.map(v=>v[0]))+.04,minY=Math.min(...projected.map(v=>v[1]))-.04,maxY=Math.max(...projected.map(v=>v[1]))+.04;
   const worldWidth=maxX-minX,worldHeight=maxY-minY;
   const c=document.createElement('canvas');c.width=Math.ceil(worldWidth*200);c.height=Math.ceil(worldHeight*200);
   const gl=c.getContext('webgl',{alpha:true,antialias:true,preserveDrawingBuffer:true});
   const shader=(type,src)=>{const s=gl.createShader(type);gl.shaderSource(s,src);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s;};
   const p=gl.createProgram();gl.attachShader(p,shader(gl.VERTEX_SHADER,'attribute vec3 position;attribute vec3 normal;attribute vec2 uv;varying vec2 vUV;varying vec2 vCap;uniform vec4 bounds;void main(){float y=position.z*.8+position.y*.6;gl_Position=vec4((position.x-bounds.x)/bounds.z*2.-1.,(y-bounds.y)/bounds.w*2.-1.,(position.z*.6-position.y*.8)/5.,1.);vUV=uv;vec3 n=normalize(vec3(normal.x,normal.y*.6+normal.z*.8,normal.z*.6-normal.y*.8));vCap=n.xy*.5+.5;}'));
   // Recovered MatCap/Detail GLES program: main texture * tint * matcap * 3.
   gl.attachShader(p,shader(gl.FRAGMENT_SHADER,'precision mediump float;varying vec2 vUV;varying vec2 vCap;uniform sampler2D tex;uniform sampler2D cap;uniform vec4 tint;void main(){vec4 c=texture2D(tex,vUV)*tint*texture2D(cap,vCap)*3.;if(c.a<.01)discard;gl_FragColor=c;}'));gl.linkProgram(p);gl.useProgram(p);
   gl.uniform4f(gl.getUniformLocation(p,'bounds'),minX,minY,worldWidth,worldHeight);gl.uniform1i(gl.getUniformLocation(p,'tex'),0);gl.uniform1i(gl.getUniformLocation(p,'cap'),1);
   gl.enable(gl.DEPTH_TEST);gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.viewport(0,0,c.width,c.height);
   const pos=gl.getAttribLocation(p,'position'),uv=gl.getAttribLocation(p,'uv'),normal=gl.getAttribLocation(p,'normal');
   for(const part of scene.parts){
    const mat=scene.materials[part.material];for(const [unit,png] of [[0,mat.png],[1,mat.capPng]]){const img=new Image();img.src=png;await img.decode();const texture=gl.createTexture();gl.activeTexture(gl.TEXTURE0+unit);gl.bindTexture(gl.TEXTURE_2D,texture);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,img);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);}
    const verts=[];for(const tri of part.triangles)for(const i of tri)verts.push(...part.vertices[i],part.uv[i][0]*mat.scale[0]+mat.offset[0],part.uv[i][1]*mat.scale[1]+mat.offset[1],...part.normals[i]);
    const buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(verts),gl.STATIC_DRAW);gl.enableVertexAttribArray(pos);gl.enableVertexAttribArray(uv);gl.enableVertexAttribArray(normal);gl.vertexAttribPointer(pos,3,gl.FLOAT,false,32,0);gl.vertexAttribPointer(uv,2,gl.FLOAT,false,32,12);gl.vertexAttribPointer(normal,3,gl.FLOAT,false,32,20);gl.uniform4fv(gl.getUniformLocation(p,'tint'),mat.color);gl.drawArrays(gl.TRIANGLES,0,verts.length/8);
   }
   return {png:c.toDataURL(),width:c.width,height:c.height,worldWidth,worldHeight,anchor:[-minX/worldWidth,maxY/worldHeight]};
  },scene);
  fs.writeFileSync(path.join(root,'images/star_piece_field.png'),Buffer.from(result.png.split(',')[1],'base64'));delete result.png;
  const manifest=JSON.parse(fs.readFileSync(cache.readPath('collectible-frames.json')));manifest.graphics.star_piece_field={image:'images/star_piece_field.png',...result,sourceBundle:'effects/stage/base',prefab:'star_piece',renderKind:'native mesh prefab',shader:'MatCap/Detail',notes:['Static native mesh pose; particle sparkle and rotation are not simulated.']};
  fs.writeFileSync(cache.writePath('collectible-frames.json'),JSON.stringify(manifest));console.log(result);
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
