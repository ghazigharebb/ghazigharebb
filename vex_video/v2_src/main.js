import * as THREE from 'three';
import {EffectComposer} from 'three/addons/postprocessing/EffectComposer.js';
import {RenderPass} from 'three/addons/postprocessing/RenderPass.js';
import {UnrealBloomPass} from 'three/addons/postprocessing/UnrealBloomPass.js';
import {ShaderPass} from 'three/addons/postprocessing/ShaderPass.js';
import {OutputPass} from 'three/addons/postprocessing/OutputPass.js';
import {RoomEnvironment} from 'three/addons/environments/RoomEnvironment.js';
import {RoundedBoxGeometry} from 'three/addons/geometries/RoundedBoxGeometry.js';

/* ============ timeline (shared with audio.py) ============ */
const W=1080,H=1920,B=.625;
const ST=[1.25,3.125,5.0,6.875,8.75];            // heart, arena, family, food, (burst)
const T_BURST=8.75,T_VORTEX=10.0,T_BAND=11.875,T_END=13.75,DUR=15;
const R=4.0,D=9.4;                                // ring radius, camera→object distance
const clamp=(x,a=0,b=1)=>Math.min(b,Math.max(a,x)),lerp=(a,b,t)=>a+(b-a)*t;
const P=(t,a,b)=>clamp((t-a)/(b-a)),S=x=>x*x*(3-2*x),eo3=x=>1-(1-x)**3,eio=x=>x<.5?4*x**3:1-(-2*x+2)**3/2;
const eoB=x=>{const c1=1.70158,c3=c1+1;return 1+c3*(x-1)**3+c1*(x-1)**2},eoE=x=>x>=1?1:1-2**(-10*x);
const rad=d=>d*Math.PI/180,hs=n=>{n=Math.sin(n*127.1+311.7)*43758.5453;return n-Math.floor(n)};
const V3=(x=0,y=0,z=0)=>new THREE.Vector3(x,y,z);
const C=n=>new THREE.Color(n);
const PAL={heart:0xff6f86,spo2:0x3fd0ff,stress:0xffbe4d,skin:0xff9466,sleep:0x9b7bff,act:0x3cf08a,cy:0x00ecff,mint:0x3cf08a,violet:0x7b4dff,gold:0xffc94d};

/* ============ renderer / scene ============ */
const renderer=new THREE.WebGLRenderer({antialias:false,preserveDrawingBuffer:true,powerPreference:'high-performance'});
renderer.setPixelRatio(1);renderer.setSize(W,H);renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=.92;renderer.outputColorSpace=THREE.SRGBColorSpace;
const scene=new THREE.Scene();scene.fog=new THREE.FogExp2(0x03141d,.026);
const camera=new THREE.PerspectiveCamera(40,W/H,.1,200);
const pm=new THREE.PMREMGenerator(renderer);scene.environment=pm.fromScene(new RoomEnvironment(),.04).texture;
const bg=new THREE.Mesh(new THREE.SphereGeometry(90,32,16),new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,fog:false,
 uniforms:{cA:{value:C(0x010910)},cB:{value:C(0x07344a)},tint:{value:C(0x00b8d0)},k:{value:0}},
 vertexShader:'varying vec3 vP;void main(){vP=normalize(position);gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',
 fragmentShader:'varying vec3 vP;uniform vec3 cA,cB,tint;uniform float k;void main(){float h=vP.y*.5+.5;vec3 c=mix(cA,cB,smoothstep(.15,.95,h));c+=tint*.07*k*exp(-abs(vP.y)*3.);gl_FragColor=vec4(c,1.);}'}));
scene.add(bg);
const key=new THREE.DirectionalLight(0xffffff,2.0);key.position.set(3,5,6);scene.add(key);
const rimC=new THREE.DirectionalLight(0x00e5ff,2.2);rimC.position.set(-5,2,-4);scene.add(rimC);
const rimM=new THREE.DirectionalLight(0x3cf08a,1.4);rimM.position.set(5,1,-5);scene.add(rimM);
scene.add(new THREE.HemisphereLight(0x6fa8c0,0x02131c,.5));

/* ============ helpers ============ */
const loadImg=u=>new Promise(r=>{const i=new Image();i.onload=()=>r(i);i.src=u});
function canvasTex(w,h,draw){const c=document.createElement('canvas');c.width=w;c.height=h;draw(c.getContext('2d'),w,h);const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=8;return t}
const hot=(c,k=2)=>new THREE.MeshBasicMaterial({color:C(c).multiplyScalar(k),toneMapped:false,fog:false});
const addMat=(c,o=.6)=>new THREE.MeshBasicMaterial({color:C(c),transparent:true,opacity:o,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false,side:THREE.DoubleSide});
function setScaleSafe(o,s){o.visible=s>.002;o.scale.setScalar(Math.max(s,.0001))}
const IMG={},CHAR=[];let LOGO;const TX={};const mkT=(img,rep)=>{const t=new THREE.Texture(img);t.needsUpdate=true;t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=8;if(rep){t.wrapS=t.wrapT=THREE.RepeatWrapping;t.repeat.set(rep[0],rep[1])}return t};
function medallion(img,accent,r=.4,dark=false){const g=new THREE.Group();const a=C(accent);
 const tex=canvasTex(512,512,(c,w,h)=>{const gr=c.createRadialGradient(256,170,30,256,256,330);gr.addColorStop(0,dark?'#0c5870':'#'+a.clone().lerp(C(0xffffff),.45).getHexString());gr.addColorStop(1,dark?'#021a24':'#'+a.clone().multiplyScalar(.28).getHexString());c.fillStyle=gr;c.fillRect(0,0,w,h);const s=w/img.width*1.1;c.drawImage(img,(w-img.width*s)/2,h-img.height*s+26,img.width*s,img.height*s)});
 const face=new THREE.Mesh(new THREE.CircleGeometry(r,64),new THREE.MeshStandardMaterial({map:tex,roughness:.5,metalness:0,envMapIntensity:.5,emissiveMap:tex,emissive:0xffffff,emissiveIntensity:.32}));face.position.z=.046;
 const body=new THREE.Mesh(new THREE.CylinderGeometry(r*1.04,r*1.04,.09,64).rotateX(Math.PI/2),new THREE.MeshStandardMaterial({color:0x061a24,metalness:.9,roughness:.25}));
 const rim=new THREE.Mesh(new THREE.TorusGeometry(r*1.04,.032,16,96),new THREE.MeshStandardMaterial({color:accent,metalness:.9,roughness:.18,emissive:accent,emissiveIntensity:.3}));rim.position.z=.046;
 g.add(body,face,rim);return g}
function tube(points,r,mat,closed=false,seg){const cur=new THREE.CatmullRomCurve3(points,closed);const geo=new THREE.TubeGeometry(cur,seg||points.length*2,r,8,closed);geo.userData.full=geo.index.count;return new THREE.Mesh(geo,mat)}
function draw01(mesh,f){const g=mesh.geometry;const n=Math.floor(g.userData.full*clamp(f)/48)*48;g.setDrawRange(0,n);mesh.visible=n>0}
function arc3(r,a0,a1,z,tubeR,mat,seg=64){const pts=[];for(let i=0;i<=seg;i++){const a=lerp(a0,a1,i/seg);pts.push(V3(Math.cos(a)*r,Math.sin(a)*r,z))}return tube(pts,tubeR,mat,false,seg)}
function glowTex(){return canvasTex(128,128,(c)=>{const g=c.createRadialGradient(64,64,0,64,64,64);g.addColorStop(0,'rgba(255,255,255,1)');g.addColorStop(.25,'rgba(255,255,255,.45)');g.addColorStop(1,'rgba(255,255,255,0)');c.fillStyle=g;c.fillRect(0,0,128,128)})}
function link(a,b,m,r){const L=a.distanceTo(b);m.position.copy(a).lerp(b,.5);m.scale.set(1,L,1);m.quaternion.setFromUnitVectors(V3(0,1,0),b.clone().sub(a).normalize());return m}
const beat=t=>{const p=(t%B)/B;return Math.exp(-((p*13)**2))+.55*Math.exp(-(((p-.2)*13)**2))};

/* ============ station groups ============ */
const backGlow=(g,c,size=7,op=.38)=>{const m=new THREE.Mesh(new THREE.PlaneGeometry(size,size),new THREE.MeshBasicMaterial({map:glowTex(),color:C(c),transparent:true,opacity:op,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,toneMapped:false}));m.position.set(0,0,-1.6);g.add(m);return m};
const stationPos=i=>V3(R*Math.sin(rad(90*i)),0,R*Math.cos(rad(90*i)));
const mkStation=i=>{const g=new THREE.Group();g.position.copy(stationPos(i));g.rotation.y=rad(90*i);scene.add(g);return g};
let G={},U={};

/* ---- 0 HEART ---- */
function buildHeart(){const g=mkStation(0);const sh=new THREE.Shape();const k=1/40;const X=x=>(x-25)*k,Y=y=>-(y-47)*k;
 sh.moveTo(X(25),Y(25));sh.bezierCurveTo(X(25),Y(25),X(20),Y(0),X(0),Y(0));sh.bezierCurveTo(X(-30),Y(0),X(-30),Y(35),X(-30),Y(35));sh.bezierCurveTo(X(-30),Y(55),X(-10),Y(77),X(25),Y(95));sh.bezierCurveTo(X(60),Y(77),X(80),Y(55),X(80),Y(35));sh.bezierCurveTo(X(80),Y(35),X(80),Y(0),X(50),Y(0));sh.bezierCurveTo(X(35),Y(0),X(25),Y(25),X(25),Y(25));
 const geo=new THREE.ExtrudeGeometry(sh,{depth:.5,bevelEnabled:true,bevelThickness:.22,bevelSize:.2,bevelSegments:12,curveSegments:56});geo.center();
 const heart=new THREE.Mesh(geo,new THREE.MeshPhysicalMaterial({color:0xc8102e,roughness:.18,metalness:.15,clearcoat:1,clearcoatRoughness:.05,emissive:0xd0102c,emissiveIntensity:.22,envMapIntensity:1.5}));
 const hw=new THREE.Group();hw.add(heart);g.add(hw);
 const tilt=new THREE.Group();tilt.rotation.set(-1.12,.25,0);g.add(tilt);const spin=new THREE.Group();tilt.add(spin);
 const cols=[PAL.heart,PAL.spo2,PAL.stress,PAL.skin,PAL.sleep,PAL.act];
 cols.forEach((c,k)=>{const a=arc3(1.32,k*Math.PI/3+.06,k*Math.PI/3+Math.PI/3-.1,0,.05,new THREE.MeshStandardMaterial({color:c,emissive:c,emissiveIntensity:.42,roughness:.3,metalness:.2}),32);spin.add(a)});
 const ecgPts=[];for(let i=0;i<=260;i++){const a=i/260*Math.PI*2;const p=((i/260)*3)%1;const e=[[0,0],[.1,0],[.15,-8],[.2,0],[.3,0],[.33,10],[.37,-78],[.41,40],[.45,0],[.6,0],[.68,-14],[.76,0],[1,0]];let y=0;for(let q=1;q<e.length;q++){if(p<=e[q][0]){y=lerp(e[q-1][1],e[q][1],(p-e[q-1][0])/(e[q][0]-e[q-1][0]));break}}ecgPts.push(V3(Math.cos(a)*1.62,Math.sin(a)*1.62,-y*.0022))}
 const tilt2=new THREE.Group();tilt2.rotation.set(-.62,-.4,.35);g.add(tilt2);const spin2=new THREE.Group();tilt2.add(spin2);
 const ecg=tube(ecgPts,.014,hot(PAL.cy,1.5),true,260);spin2.add(ecg);
 const pr=new THREE.Mesh(new THREE.RingGeometry(.97,1,128),addMat(PAL.heart,.5));g.add(pr);
 const lt=new THREE.PointLight(0xff3d6e,0,7);lt.position.set(0,.2,1.8);g.add(lt);
 g.userData.upd=(t)=>{const b=beat(t);heart.scale.setScalar(.7*(1+.12*b));hw.rotation.y=Math.sin(t*1.1)*.3;hw.rotation.x=Math.sin(t*.8)*.07;spin.rotation.z=t*.75;spin2.rotation.z=-t*.55;const ph=(t%B)/B;pr.scale.setScalar(1+1.5*ph);pr.material.opacity=.5*(1-ph)**2;lt.intensity=2+6*b;g.position.y=Math.sin(t*1.3)*.07};
 backGlow(g,0xff2a52,7.5,.42);G.heart=g;G.heartRing=[spin,spin2]}

/* ---- 1 ARENA ---- */
function buildArena(){const g=mkStation(1);const gold=new THREE.MeshStandardMaterial({color:0xffc94d,metalness:1,roughness:.2,envMapIntensity:1.7});
 const tr=new THREE.Group();const prof=[[.001,0],[.62,0],[.62,.1],[.5,.18],[.5,.26],[.22,.34],[.17,.5],[.15,.95],[.22,1.05],[.28,1.12],[.5,1.2],[.62,1.5],[.72,1.95],[.74,2.2],[.7,2.22],[.64,2.2],[.6,1.95],[.52,1.55],[.4,1.4],[.2,1.3],[.001,1.28]].map(p=>new THREE.Vector2(p[0],p[1]));
 tr.add(new THREE.Mesh(new THREE.LatheGeometry(prof,72),gold));
 [[-.74,Math.PI/2],[.74,-Math.PI/2]].forEach(([x,rz])=>{const h=new THREE.Mesh(new THREE.TorusGeometry(.34,.06,16,40,Math.PI),gold);h.position.set(x,1.72,0);h.rotation.z=rz;tr.add(h)});
 tr.scale.setScalar(.68);tr.position.y=.5;g.add(tr);
 const pod=[{x:-.9,h:.72,c:0xc9d4dc,m:2,ch:CHAR[5]},{x:0,h:1.0,c:0xffc94d,m:1,ch:CHAR[9]},{x:.9,h:.52,c:0xd08a5a,m:3,ch:CHAR[3]}];
 const meds=[];pod.forEach(p=>{const y0=-1.5;const b=new THREE.Mesh(new RoundedBoxGeometry(.82,p.h,.7,4,.05),new THREE.MeshStandardMaterial({color:0x0b2230,metalness:.7,roughness:.3,envMapIntensity:.9}));b.position.set(p.x,y0+p.h/2,0);g.add(b);
  const top=new THREE.Mesh(new THREE.BoxGeometry(.82,.05,.7),new THREE.MeshStandardMaterial({color:p.c,metalness:1,roughness:.25,emissive:p.c,emissiveIntensity:.35}));top.position.set(p.x,y0+p.h+.02,0);g.add(top);
  const nt=canvasTex(128,128,(c)=>{c.font='800 96px Sora';c.textAlign='center';c.fillStyle='#'+C(p.c).getHexString();c.fillText(String(p.m),64,100)});const np=new THREE.Mesh(new THREE.PlaneGeometry(.4,.4),new THREE.MeshBasicMaterial({map:nt,transparent:true,toneMapped:false}));np.position.set(p.x,y0+p.h/2,.36);g.add(np);
  const m=medallion(p.ch,p.c,p.m===1?.38:.32);m.position.set(p.x,y0+p.h+.07+(p.m===1?.42:.38),.05);g.add(m);meds.push(m)});
 const N=150,cm=new THREE.InstancedMesh(new THREE.BoxGeometry(.07,.12,.006),new THREE.MeshBasicMaterial({toneMapped:false,fog:false}),N);const cc=[PAL.gold,PAL.cy,PAL.heart,PAL.mint,PAL.sleep,0xffffff];const col=new THREE.Color();for(let i=0;i<N;i++)cm.setColorAt(i,col.set(cc[i%6]).multiplyScalar(1.4));g.add(cm);
 const beams=new THREE.Group();for(let i=0;i<5;i++){const b=new THREE.Mesh(new THREE.PlaneGeometry(.35,4.2),addMat(PAL.gold,.07));b.position.set(0,1.6,-.4);b.rotation.z=(i-2)*.32;beams.add(b)}g.add(beams);
 const lt=new THREE.PointLight(0xffc94d,0,7);lt.position.set(0,1.2,2);g.add(lt);const dm=new THREE.Object3D();
 g.userData.upd=(t)=>{const lt0=t-ST[1];tr.rotation.y=Math.sin(t*.9)*.5+t*.15;meds.forEach((m,k)=>{m.position.y+=0;m.rotation.y=Math.sin(t*1.2+k)*.22});beams.children.forEach((b,i)=>{b.material.opacity=.05+.04*Math.sin(t*2+i)});
  cm.visible=lt0>.1&&lt0<2.6;if(cm.visible){const tau=lt0-.2;for(let i=0;i<N;i++){const a=hs(i)*6.28,sp=1.2+hs(i+7)*2.6,up=1.2+hs(i+3)*2.2;const x=Math.cos(a)*sp*tau*.55,y=1.6+up*tau-1.7*tau*tau,z=Math.sin(a)*sp*tau*.45;dm.position.set(x,y,z);dm.rotation.set(tau*(3+hs(i+1)*5),tau*(2+hs(i+2)*4),0);const s=tau>0?clamp(1.8-tau*.7,0,1):0;dm.scale.setScalar(s);dm.updateMatrix();cm.setMatrixAt(i,dm.matrix)}cm.instanceMatrix.needsUpdate=true}
  lt.intensity=6;g.position.y=Math.sin(t*1.1+1)*.06};backGlow(g,0xffb02e,8,.4);G.arena=g}

/* ---- 2 FAMILY ---- */
function buildFamily(){const g=mkStation(2);const ring=new THREE.Group();ring.rotation.x=-.42;g.add(ring);
 const cen=medallion(canvasTexImg(),PAL.cy,.42,true);ring.add(cen);const ids=[0,1,2,3,5,7],acc=[PAL.mint,PAL.heart,PAL.spo2,PAL.stress,PAL.sleep,PAL.act],stat=[PAL.mint,PAL.stress,PAL.mint,PAL.heart,PAL.mint,PAL.mint],fr=[.9,.55,.8,.4,.95,.7];
 const mem=[],arcs=[],links=[],dots=[],sdots=[];
 const lm=new THREE.MeshBasicMaterial({color:C(PAL.cy).multiplyScalar(1.3),transparent:true,opacity:.55,toneMapped:false});
 ids.forEach((id,k)=>{const m=medallion(CHAR[id],acc[k],.33);ring.add(m);mem.push(m);const a=arc3(.33*1.26,rad(90),rad(90)+Math.PI*2*fr[k],.05,.028,hot(acc[k],1.6),48);m.add(a);arcs.push(a);
  const sd=new THREE.Mesh(new THREE.SphereGeometry(.05,16,12),hot(stat[k],1.8));sd.position.set(.27,-.27,.07);m.add(sd);
  const l=new THREE.Mesh(new THREE.CylinderGeometry(.01,.01,1,8),lm);ring.add(l);links.push(l);const d=new THREE.Mesh(new THREE.SphereGeometry(.045,12,10),hot(PAL.cy,2.4));ring.add(d);dots.push(d)});
 const lt=new THREE.PointLight(0x5ce1ff,0,7);lt.position.set(0,.4,2);g.add(lt);
 g.userData.upd=(t)=>{const lt0=t-ST[2];const rr=1.0*eoB(P(lt0,-.25,.55));mem.forEach((m,k)=>{const a=t*.45+k*Math.PI/3;m.position.set(Math.cos(a)*rr,Math.sin(a)*rr*.92,0);m.rotation.x=.42;m.rotation.z=0;const s=eoB(P(lt0,-.3+k*.07,.5+k*.07));setScaleSafe(m,s);const f=eo3(P(lt0,.1+k*.07,.9+k*.07));arcs[k].geometry.setDrawRange(0,Math.floor(arcs[k].geometry.userData.full*f/48)*48);
  const c0=V3(0,0,0),p=m.position.clone();links[k].visible=s>.1;link(c0,p,links[k]);const q=((t*.8+k*.17)%1);dots[k].position.copy(c0).lerp(p,q);dots[k].visible=s>.3;dots[k].scale.setScalar(s)});
  cen.scale.setScalar(eoB(P(lt0,-.3,.4))*(1+.04*beat(t)));cen.rotation.x=.42;ring.rotation.y=Math.sin(t*.6)*.25;lt.intensity=5;g.position.y=Math.sin(t*1.2+2)*.06};backGlow(g,0x2fd0ff,7.5,.28);G.family=g}
function canvasTexImg(){const c=document.createElement('canvas');c.width=c.height=384;const x=c.getContext('2d');const s=260/LOGO.width;x.shadowColor='#00ecff';x.shadowBlur=16;x.drawImage(LOGO,(384-LOGO.width*s)/2,150-LOGO.height*s/2,LOGO.width*s,LOGO.height*s);return c}

/* ---- 3 FOOD ---- */
function buildFood(){const g=mkStation(3);const names=['pizza','burger','macarons','lemons','lahmacun','wings','tea'];
 const plane=(n,w,dark=1)=>{const im=IMG[n],t=new THREE.CanvasTexture(im);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=8;const m=new THREE.Mesh(new THREE.PlaneGeometry(w,w*im.height/im.width),new THREE.MeshStandardMaterial({map:t,roughness:.6,metalness:0,alphaTest:.06,emissiveMap:t,emissive:0xffffff,emissiveIntensity:.34*dark,envMapIntensity:.5,side:THREE.DoubleSide}));return m};
 const piz=new THREE.Group();[0,1,2].forEach(i=>{const p=plane('pizza',2.15,.45);p.position.z=-i*.035;piz.add(p)});piz.children[0].material.emissiveIntensity=.42;g.add(piz);piz.position.y=.2;
 const sh=new THREE.Mesh(new THREE.CircleGeometry(1.3,48),new THREE.MeshBasicMaterial({map:glowTex(),color:0x000000,transparent:true,opacity:.55,depthWrite:false}));sh.position.set(.1,.0,-.25);g.add(sh);
 const frm=new THREE.Group();const fm=hot(PAL.mint,2.2);[[-1,-1],[1,-1],[1,1],[-1,1]].forEach(([sx,sy])=>{const a=new THREE.Mesh(new THREE.BoxGeometry(.5,.045,.045),fm),b=new THREE.Mesh(new THREE.BoxGeometry(.045,.5,.045),fm);a.position.set(sx*1.1-sx*.25,sy*1.1,0);b.position.set(sx*1.1,sy*1.1-sy*.25,0);frm.add(a,b)});frm.position.y=.2;g.add(frm);
 const scan=new THREE.Mesh(new THREE.PlaneGeometry(2.5,.5),new THREE.MeshBasicMaterial({map:canvasTex(8,64,(c)=>{const gr=c.createLinearGradient(0,0,0,64);gr.addColorStop(0,'rgba(60,240,138,0)');gr.addColorStop(.85,'rgba(60,240,138,.55)');gr.addColorStop(.95,'rgba(180,255,210,1)');gr.addColorStop(1,'rgba(60,240,138,0)');c.fillStyle=gr;c.fillRect(0,0,8,64)}),transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false,color:C(0xffffff).multiplyScalar(1.5)}));scan.position.z=.05;g.add(scan);
 const mm=[PAL.sleep,PAL.stress,PAL.heart],ra=[1.42,1.5,1.58],cal=mm.map((c,k)=>{const a=arc3(ra[k],rad(120-k*5),rad(120-k*5)+Math.PI*2*[.34,.5,.22][k]*.92,.02,.045,hot(c,1.8),48);a.position.y=.2;g.add(a);return a});
 const orb=['burger','macarons','lemons','wings','tea','lahmacun'].map((n,k)=>{const p=plane(n,[.95,.9,.85,.85,.62,.9][k]);g.add(p);return p});
 const lt=new THREE.PointLight(0x3cf08a,0,7);lt.position.set(0,.6,2);g.add(lt);
 g.userData.upd=(t)=>{const l0=t-ST[3];piz.rotation.z=t*.35;piz.rotation.x=-.28+Math.sin(t*.9)*.05;piz.rotation.y=Math.sin(t*.7)*.2;setScaleSafe(piz,eoB(P(l0,-.35,.4)));sh.visible=piz.visible;
  const fs=eoB(P(l0,-.1,.5));setScaleSafe(frm,fs*(1+.012*Math.sin(t*10)));const sp=(l0*.9)%1;scan.position.y=.2+Math.sin(l0*3.4)*1.05;scan.visible=l0>.1&&l0<1.9;
  cal.forEach((a,k)=>{const f=eo3(P(l0,.25+k*.12,1.0+k*.12));a.geometry.setDrawRange(0,Math.floor(a.geometry.userData.full*f/48)*48);a.visible=f>0;a.rotation.z=Math.sin(t*.8+k)*.0});
  orb.forEach((p,k)=>{const a=t*.62+k*Math.PI/3;const s=eoB(P(l0,.0+k*.06,.6+k*.06));p.position.set(Math.cos(a)*1.35,.2+Math.sin(a*2)*.12+Math.sin(a)*.25,Math.sin(a)*.9);p.rotation.z=Math.sin(t+k)*.12;setScaleSafe(p,s*(.82+.18*(Math.sin(a)+1)/2))});
  lt.intensity=5;g.position.y=Math.sin(t*1.2+3)*.06};backGlow(g,0x2ee88a,7.5,.24);G.food=g}

/* ---- small icons (burst) ---- */
function buildIcons(){const g=new THREE.Group();scene.add(g);const icons=[];
 const phy=(c,e=.5)=>new THREE.MeshPhysicalMaterial({color:c,roughness:.14,metalness:.08,clearcoat:1,clearcoatRoughness:.05,emissive:c,emissiveIntensity:e,envMapIntensity:1.3});
 // drop
 const dp=[];for(let i=0;i<=48;i++){const th=i/48*Math.PI;dp.push(new THREE.Vector2(Math.max(.001,.5*Math.sin(th)*Math.pow(Math.sin(th/2),1.15)),.62*Math.cos(th)))}
 const drop=new THREE.Mesh(new THREE.LatheGeometry(dp,48),phy(PAL.spo2,.55));
 // moon
 const sh=new THREE.Shape();const d0=.26,R1=.6,R2=.5,xi=(d0*d0+R1*R1-R2*R2)/(2*d0),yi=Math.sqrt(R1*R1-xi*xi),a1=Math.atan2(yi,xi),a2=Math.atan2(yi,xi-d0);
 sh.moveTo(xi,yi);for(let i=0;i<=60;i++){const a=lerp(a1,Math.PI*2-a1,i/60);sh.lineTo(R1*Math.cos(a),R1*Math.sin(a))}for(let i=0;i<=60;i++){const a=lerp(Math.PI*2-a2,a2,i/60);sh.lineTo(d0+R2*Math.cos(a),R2*Math.sin(a))}
 const mg=new THREE.ExtrudeGeometry(sh,{depth:.16,bevelEnabled:true,bevelThickness:.07,bevelSize:.06,bevelSegments:8,curveSegments:48});mg.center();const moon=new THREE.Mesh(mg,phy(PAL.sleep,.5));moon.rotation.z=-.5;
 // bolt
 const bs=new THREE.Shape();[[.1,1],[-.5,0],[-.1,0],[-.3,-1],[.5,.15],[.1,.15],[.45,1]].forEach((p,i)=>i?bs.lineTo(p[0]*.6,p[1]*.6):bs.moveTo(p[0]*.6,p[1]*.6));bs.closePath();
 const bg2=new THREE.ExtrudeGeometry(bs,{depth:.14,bevelEnabled:true,bevelThickness:.05,bevelSize:.04,bevelSegments:6});bg2.center();const bolt=new THREE.Mesh(bg2,phy(PAL.act,.55));
 // AI orb
 const ai=new THREE.Group();ai.add(new THREE.Mesh(new THREE.IcosahedronGeometry(.42,4),phy(PAL.violet,.7)));const wf=new THREE.Mesh(new THREE.IcosahedronGeometry(.56,1),new THREE.MeshBasicMaterial({color:C(PAL.cy).multiplyScalar(1.6),wireframe:true,toneMapped:false}));ai.add(wf);
 const sp=[0,1,2].map(i=>{const s=new THREE.Mesh(new THREE.SphereGeometry(.05,12,10),hot(0xffffff,2));ai.add(s);return s});
 [drop,moon,bolt,ai].forEach((m,i)=>{const w=new THREE.Group();w.add(m);g.add(w);icons.push(w)});
 U.icons=icons;U.ai={wf,sp};U.iconsG=g}

/* ---- the BAND ---- */
function strapGeo(rx,rz,Wd,th,N){const pos=[],uv=[],idx=[];const add=(off,y,i,v)=>{const a=i/N*Math.PI*2,e=[rx*Math.sin(a),rz*Math.cos(a)],n=[Math.sin(a)/rx,Math.cos(a)/rz],l=Math.hypot(n[0],n[1]);pos.push(e[0]+n[0]/l*off,y,e[1]+n[1]/l*off);uv.push(i/N*7,v)};
 const surf=(oa,ya,ob,yb,flip)=>{const b0=pos.length/3;for(let i=0;i<=N;i++){add(oa,ya,i,ya>0?1:0);add(ob,yb,i,yb>0?1:0)}for(let i=0;i<N;i++){const a=b0+i*2;flip?idx.push(a,a+2,a+1,a+1,a+2,a+3):idx.push(a,a+1,a+2,a+1,a+3,a+2)}};
 const h=Wd/2,o=th/2;surf(o,-h,o,h,false);surf(-o,-h,-o,h,true);surf(-o,h,o,h,true);surf(-o,-h,o,-h,false);
 const geo=new THREE.BufferGeometry();geo.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));geo.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));geo.setIndex(idx);geo.computeVertexNormals();return geo}
function fabricTex(){const t=canvasTex(256,256,(c,w,h)=>{c.fillStyle='#0b0c0e';c.fillRect(0,0,w,h);for(let y=0;y<h;y+=8)for(let x=0;x<w;x+=8){const k=((x/8)+(y/8))%2;c.fillStyle=k?'#2b2f34':'#08090a';c.beginPath();c.ellipse(x+4,y+4,4.6,3.2,.65,0,7);c.fill()}});t.wrapS=t.wrapT=THREE.RepeatWrapping;return t}
function plateTex(glow){return canvasTex(1024,512,(c,w,h)=>{if(glow){c.fillStyle='#000';c.fillRect(0,0,w,h)}else{const g=c.createLinearGradient(0,0,w,0);g.addColorStop(0,'#aab2b8');g.addColorStop(.3,'#e3e7ea');g.addColorStop(.55,'#9da5ab');g.addColorStop(.8,'#dfe3e6');g.addColorStop(1,'#a2aab0');c.fillStyle=g;c.fillRect(0,0,w,h);for(let i=0;i<420;i++){c.fillStyle=`rgba(${hs(i)>.5?255:60},${hs(i)>.5?255:60},${hs(i)>.5?255:60},${.03+hs(i+9)*.09})`;c.fillRect(0,hs(i+3)*h,w,1+hs(i+5)*1.5)}}
 const lw=w*.62,ls=lw/LOGO.width,lh=LOGO.height*ls,x=(w-lw)/2,y=(h-lh)/2;const tmp=document.createElement('canvas');tmp.width=w;tmp.height=h;const tc=tmp.getContext('2d');tc.drawImage(LOGO,x,y,lw,lh);tc.globalCompositeOperation='source-in';tc.fillStyle=glow?'#00ecff':'#2c3237';tc.fillRect(0,0,w,h);
 if(!glow){c.globalAlpha=.55;const t2=document.createElement('canvas');t2.width=w;t2.height=h;const t2c=t2.getContext('2d');t2c.drawImage(LOGO,x,y,lw,lh);t2c.globalCompositeOperation='source-in';t2c.fillStyle='#fff';t2c.fillRect(0,0,w,h);c.drawImage(t2,3,4);c.globalAlpha=1}
 c.drawImage(tmp,0,0)})}
function buildBand(){const g=new THREE.Group();scene.add(g);const asp=TX.band.width/TX.band.height,h=3.05,w=h*asp;
 const body=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({map:mkT(TX.band),transparent:true,alphaTest:.02,fog:false,color:C(0xffffff).multiplyScalar(1.3)}));g.add(body);
 const glow=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({map:mkT(TX.bglow),transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false,fog:false,color:C(0xffffff).multiplyScalar(0)}));glow.position.z=.006;g.add(glow);
 const halo=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({map:mkT(TX.halo),transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false,fog:false,opacity:0}));halo.position.z=-.03;halo.scale.setScalar(1.03);g.add(halo);
 const sweep=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.ShaderMaterial({transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,uniforms:{tMap:{value:mkT(TX.band)},uPos:{value:-2}},
  vertexShader:'varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',
  fragmentShader:'uniform sampler2D tMap;uniform float uPos;varying vec2 vUv;void main(){float a=texture2D(tMap,vUv).a;float d=abs((vUv.x+vUv.y*.45)-uPos);float gg=smoothstep(.05,0.,d);gl_FragColor=vec4(vec3(.5,.9,1.)*gg*gg*a*.8,1.);}'}));sweep.position.z=.01;g.add(sweep);
 const lt=new THREE.PointLight(0x00ecff,0,9);lt.position.set(0,0,2.2);g.add(lt);
 U.band={g,body,glow,halo,sweep,lt,w,h}}

/* ============ particles / trails / FX ============ */
function buildFX(){const gt=glowTex();
 const N=700,pos=new Float32Array(N*3),col=new Float32Array(N*3),cc=[C(0x00ecff),C(0x3cf08a),C(0xffffff),C(0x7b4dff)];for(let i=0;i<N;i++){const a=hs(i)*6.283,r=3+hs(i+1)*17,y=(hs(i+2)-.5)*12;pos.set([Math.sin(a)*r,y,Math.cos(a)*r],i*3);const c=cc[i%4].clone().multiplyScalar(.35+hs(i+5)*.7);col.set([c.r,c.g,c.b],i*3)}
 const gm=new THREE.BufferGeometry();gm.setAttribute('position',new THREE.BufferAttribute(pos,3));gm.setAttribute('color',new THREE.BufferAttribute(col,3));
 const dust=new THREE.Points(gm,new THREE.PointsMaterial({size:.09,map:gt,vertexColors:true,transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,sizeAttenuation:true,toneMapped:false}));scene.add(dust);U.dust=dust;
 // trails (vortex)
 const NT=8*18;U.tm=new THREE.InstancedMesh(new THREE.SphereGeometry(.11,8,6),new THREE.MeshBasicMaterial({toneMapped:false,fog:false}),NT);U.tm.frustumCulled=false;scene.add(U.tm);U.tmN=NT;
 // shock ring + sparks
 U.shock=new THREE.Mesh(new THREE.RingGeometry(.96,1,128),addMat(0x7ff6ff,.9));scene.add(U.shock);U.shock2=new THREE.Mesh(new THREE.RingGeometry(.96,1,128),addMat(0x3cf08a,.6));scene.add(U.shock2);
 const NS=160,sp=new Float32Array(NS*3);const sg=new THREE.BufferGeometry();sg.setAttribute('position',new THREE.BufferAttribute(sp,3));U.sparks=new THREE.Points(sg,new THREE.PointsMaterial({size:.14,map:gt,color:C(0x9ff8ff).multiplyScalar(1.8),transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,toneMapped:false}));U.sparks.frustumCulled=false;scene.add(U.sparks);
 // intro ECG line
 const pts=[];for(let i=0;i<=120;i++){const x=lerp(-6,6,i/120);let y=0;const q=x;if(Math.abs(q+2.6)<.3)y=.12*Math.sin((q+2.6)/.3*Math.PI);if(q>-.5&&q<-.2)y=-.18*(q+.5)/.3;if(q>=-.2&&q<0)y=-.18+(.18+1.0)*(q+.2)/.2;if(q>=0&&q<.25)y=1.0-(1.0+.55)*(q/.25);if(q>=.25&&q<.5)y=-.55*(1-(q-.25)/.25);if(q>=1.6&&q<2.2)y=.16*Math.sin((q-1.6)/.6*Math.PI);pts.push(V3(x,y,0))}
 U.core=new THREE.Mesh(new THREE.PlaneGeometry(1,1),new THREE.MeshBasicMaterial({map:glowTex(),color:C(0xbff8ff).multiplyScalar(1.4),transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,toneMapped:false,opacity:0}));scene.add(U.core);
 U.ecgI=tube(pts,.03,hot(PAL.cy,2.6),false,240);scene.add(U.ecgI);U.ecgI.position.copy(stationPos(0));U.ecgHead=new THREE.Mesh(new THREE.SphereGeometry(.09,16,12),hot(0xffffff,3));scene.add(U.ecgHead);U.ecgPts=pts}

/* ============ camera rig ============ */
function camRig(t){const s1=S(P(t,ST[1]-.375,ST[1]+.375)),s2=S(P(t,ST[2]-.375,ST[2]+.375)),s3=S(P(t,ST[3]-.375,ST[3]+.375)),sB=S(P(t,T_BURST-.375,T_BURST+.65));
 const bu=S(P(t,T_BURST-.375,T_VORTEX)),vo=S(P(t,T_VORTEX,T_BAND-.15));
 const phi=rad(90*(s1+s2+s3)+40*bu+50*vo+7*Math.sin((t-T_BAND)*.8)*S(P(t,T_BAND+.4,T_BAND+1.2)));
 const w0=1-s1,w1=s1*(1-s2),w2=s1*s2*(1-s3),w3=s1*s2*s3*(1-sB),wO=s1*s2*s3*sB;
 const look=V3();[0,1,2,3].forEach((i,k)=>look.addScaledVector(stationPos(i),[w0,w1,w2,w3][k]));
 let Rc=R+D,h=.8,ly=-.85;
 const fr=((t-ST[0])%1.875)/1.875;Rc-=.55*Math.sin(Math.PI*fr)*(t>=ST[0]&&t<T_BURST?1:0);Rc+=1.3*(Math.sin(Math.PI*s1)+Math.sin(Math.PI*s2)+Math.sin(Math.PI*s3));
 let roll=.018*Math.sin(t*.7)+.05*(Math.sin(Math.PI*s1)-Math.sin(Math.PI*s2)+Math.sin(Math.PI*s3));
 if(t<ST[0]){const u=eio(P(t,0,ST[0]));Rc=lerp(R+D+6.5,R+D,u);h=lerp(2.4,.8,u);ly=-.85*u;look.copy(stationPos(0))}
 else if(t>=T_BURST-.375){const b=S(P(t,T_BURST-.375,T_BURST+.9));Rc=lerp(R+D,13.8,b);h=lerp(.8,3.2,b);ly=lerp(-.85,.1,b);
  if(t>=T_VORTEX){Rc=lerp(13.8,8.6,vo);h=lerp(3.2,.9,vo);}
  if(t>=T_BAND-.15){const q=S(P(t,T_BAND-.15,T_END));Rc=lerp(9.2,7.6,q);h=lerp(.9,.2,q);const e=S(P(t,T_END-.2,T_END+.9));Rc=lerp(Rc,8.6,e);ly=lerp(-.05,-1.0,e)}
  roll=.012*Math.sin(t*.9)}
 camera.position.set(Rc*Math.sin(phi),h,Rc*Math.cos(phi));look.y+=ly;camera.lookAt(look);camera.rotateZ(roll);return{phi}}

/* ============ update ============ */
const vortexEnt=[];
function update(t){const{phi}=camRig(t);bg.position.copy(camera.position);bg.material.uniforms.k.value=1;
 // intro ecg line
 const iu=P(t,0,1.0),line=U.ecgI;draw01(line,iu);const hi=Math.min(120,Math.floor(iu*120));const hp=U.ecgPts[hi].clone().add(stationPos(0));U.ecgHead.position.copy(hp);U.ecgHead.visible=t<1.5&&iu>0;line.visible=t<2.1;line.material.opacity=1;
 const lf=1-S(P(t,1.2,1.9));line.scale.setScalar(1);line.visible=t<1.95&&iu>0;
 // heart reveal
 const hr=eoB(P(t,.85,1.55));G.heart.userData.upd(t);G.heart.scale.setScalar(Math.max(.0001,hr));G.heart.visible=hr>.002;
 G.arena.userData.upd(t);G.family.userData.upd(t);G.food.userData.upd(t);
 const rev=[eoB(P(t,ST[1]-.75,ST[1]-.05)),eoB(P(t,ST[2]-.75,ST[2]-.05)),eoB(P(t,ST[3]-.75,ST[3]-.05))];
 [G.arena,G.family,G.food].forEach((g,i)=>{g.userData.rev=rev[i]});
 // face-the-camera blend in burst
 const fb=S(P(t,T_BURST-.4,T_BURST+.7));
 const heroes=[G.heart,G.arena,G.family,G.food];const ringK=lerp(1,.5,fb);const endT=[ST[1],ST[2],ST[3],ST[4]];
 const baseS=[hr,rev[0],rev[1],rev[2]];
 const vo=S(P(t,T_VORTEX,T_BAND-.2));const vq=eio(vo);
 heroes.forEach((g,i)=>{const a0=rad(90*i);let ry=a0+((phi-a0+Math.PI)%(2*Math.PI)+2*Math.PI)%(2*Math.PI)*0;const d=((phi-a0)%(2*Math.PI)+3*Math.PI)%(2*Math.PI)-Math.PI;ry=a0+d*fb*(1-vo);g.rotation.y=ry;
  let s=baseS[i]*lerp(1,.55,fb)*Math.max(1-S(P(t,endT[i]+.05,endT[i]+.65)),S(P(t,T_BURST-.3,T_BURST+.5)));
  if(vo>0){const p0=stationPos(i).multiplyScalar(ringK);const r0=p0.length(),th0=Math.atan2(p0.x,p0.z)+0;const r=r0*Math.pow(1-vq,.85),th=th0+vq*5.2;g.position.set(r*Math.sin(th),Math.sin(vq*Math.PI)*.9+(1-vq)*0,r*Math.cos(th));s*=lerp(1,.08,vq**2.2);g.rotation.y+=vq*9}
  else g.position.set(stationPos(i).x*ringK,g.position.y,stationPos(i).z*ringK);
  g.scale.setScalar(Math.max(.0001,s));g.visible=s>.003&&t<T_BAND+.05;if(i===0)g.visible=g.visible&&hr>.002});
 // icons
 const ic=U.icons,ib=S(P(t,T_BURST+.05,T_BURST+.9));const orbR=2.3;
 ic.forEach((w,k)=>{const sc=eoB(P(t,T_BURST+.15+k*.12,T_BURST+.8+k*.12));const a=t*1.15+k*Math.PI/2;let x=Math.cos(a)*orbR,z=Math.sin(a)*3.0,y=Math.sin(a*1.0+k)*.35+.2;
  let s=sc;if(vo>0){const r0=Math.hypot(orbR*Math.cos(a),0);const th0=Math.atan2(x,z);const r=Math.hypot(x,z)*Math.pow(1-vq,.85),th=Math.atan2(x,z)+vq*5.2;x=r*Math.sin(th);z=r*Math.cos(th);y=y*(1-vq);s*=lerp(1,.08,vq**2.2)}
  w.position.set(x,y,z);w.rotation.y=t*1.6+k;w.rotation.x=Math.sin(t+k)*.2;setScaleSafe(w,s*(k===3?.8:.58)*(t<T_BAND?1:0))});
 U.ai.wf.rotation.y=t*1.4;U.ai.sp.forEach((s,i)=>{const a=t*3+i*2.1;s.position.set(Math.cos(a)*.7,Math.sin(a*1.3)*.4,Math.sin(a)*.7)});
 // vortex trails
 const tm=U.tm,dm=new THREE.Object3D();const ents=[...heroes,...ic];const tcol=[PAL.heart,PAL.gold,PAL.spo2,PAL.mint,PAL.spo2,PAL.sleep,PAL.act,PAL.violet];tm.visible=t>T_VORTEX+.05&&t<T_BAND+.25;
 if(tm.visible){const cc=new THREE.Color();let n=0;for(let e=0;e<8;e++){for(let j=0;j<18;j++){const lag=j*.028;const tv=S(P(t-lag,T_VORTEX,T_BAND-.2));const q=eio(tv);let p0,y0;if(e<4){p0=stationPos(e).multiplyScalar(ringK);y0=0}else{const a=(T_VORTEX-0.0)*1.15+(e-4)*Math.PI/2;p0=V3(Math.cos(a)*orbR,0,Math.sin(a)*3.0);y0=.2}
   const r=Math.hypot(p0.x,p0.z)*Math.pow(1-q,.85),th=Math.atan2(p0.x,p0.z)+q*5.2;const vis=t-lag>T_VORTEX&&q<.995?1:0;dm.position.set(r*Math.sin(th),Math.sin(q*Math.PI)*.9*(e<4?1:0)+y0*(1-q),r*Math.cos(th));dm.scale.setScalar(vis*(1-j/18)*(1-q*.6)*1.1);dm.updateMatrix();tm.setMatrixAt(n,dm.matrix);tm.setColorAt(n,cc.set(tcol[e]).multiplyScalar(1.8));n++}}tm.instanceMatrix.needsUpdate=true;tm.instanceColor.needsUpdate=true}
 const cq=S(P(t,T_VORTEX+.2,T_BAND));U.core.visible=t>T_VORTEX&&t<T_BAND+.4;U.core.quaternion.copy(camera.quaternion);U.core.scale.setScalar(.5+1.5*cq*(1+.06*Math.sin(t*30)));U.core.material.opacity=(.12+.5*cq*cq)*(1-S(P(t,T_BAND,T_BAND+.4)));
 // band (photo hero)
 const b=U.band,bs=eoB(P(t,T_BAND-.1,T_BAND+.75));b.g.visible=bs>.002;b.g.scale.setScalar(Math.max(.0001,bs));
 const pw=S(P(t,T_BAND,T_BAND+.9));b.g.rotation.set(Math.sin(t*.7)*.03,lerp(-1.0,0,eo3(P(t,T_BAND-.05,T_BAND+1.1)))+Math.sin(t*.9)*.16*S(P(t,T_BAND+.6,T_BAND+1.4)),Math.sin(t*.6)*.015);b.g.position.y=Math.sin(t*1.1)*.05;
 b.glow.material.color.setScalar(1.05*pw*(.88+.12*Math.sin(t*5)));b.halo.material.opacity=.3*pw*(.85+.15*Math.sin(t*3));b.lt.intensity=3*pw;
 b.sweep.material.uniforms.uPos.value=P(t,T_BAND+.55,T_BAND+1.5)*2.2-.6;
 // shock + sparks
 const sk=P(t,T_BAND-.05,T_BAND+.9);U.shock.visible=sk>0&&sk<1;U.shock.scale.setScalar(.2+5.5*eo3(sk));U.shock.material.opacity=.55*(1-sk)**2;U.shock.quaternion.copy(camera.quaternion);
 const sk2=P(t,T_BAND+.12,T_BAND+1.1);U.shock2.visible=sk2>0&&sk2<1;U.shock2.scale.setScalar(.2+8*eo3(sk2));U.shock2.material.opacity=.7*(1-sk2)**2;U.shock2.quaternion.copy(camera.quaternion);
 const sp=U.sparks,spp=sp.geometry.attributes.position.array,st=t-T_BAND;sp.visible=st>0&&st<1.3;if(sp.visible)for(let i=0;i<160;i++){const a=hs(i)*6.283,e=hs(i+3)*2-1,v=2.4+hs(i+7)*4.5;const q=1-Math.exp(-st*2.2);const r=Math.sqrt(1-e*e);spp[i*3]=Math.cos(a)*r*v*q;spp[i*3+1]=e*v*q-st*st*.8;spp[i*3+2]=Math.sin(a)*r*v*q}sp.geometry.attributes.position.needsUpdate=true;sp.material.opacity=1-P(st,.5,1.3);
 U.dust.rotation.y=t*.02;U.dust.material.opacity=.9}

/* ============ overlay ============ */
const FIN=document.createElement('canvas');FIN.width=W;FIN.height=H;const fx=FIN.getContext('2d');
const LABEL=[{t:'لێدانی دڵ',f:'NotoAr',sub:'72 BPM',sf:'Sora',col:'#FF6F86'},{t:'VEX Arena',f:'Sora',sub:'پێشبڕکێی تەندروستی و خەڵات',sf:'NotoAr',col:'#FFBE4D'},{t:'خێزان و هاوڕێ',f:'NotoAr',sub:'چالێنجی هەفتانەی خێزان',sf:'NotoAr',col:'#5CE1FF'},{t:'سکانی خواردن',f:'NotoAr',sub:'کالۆری ئەمڕۆ',sf:'NotoAr',col:'#3CF08A'}];
const CHIPS=[{t:'ئۆکسجین',col:'#3FD0FF',f:'NotoAr'},{t:'خەو',col:'#9B7BFF',f:'NotoAr'},{t:'چالاکی',col:'#3CF08A',f:'NotoAr'},{t:'VEX AI',col:'#7B8CFF',f:'Sora'}];
function txt(s,x,y,size,col,o={}){const{w=700,f='NotoAr',ls=0,al='center'}=o;fx.font=`${w} ${size}px ${f}`;fx.textAlign=al;fx.textBaseline='alphabetic';fx.letterSpacing=ls+'px';fx.fillStyle=col;fx.fillText(s,x,y);fx.letterSpacing='0px'}
function glass(x,y,w,h,r,col,a=1){fx.save();fx.globalAlpha=a;fx.beginPath();fx.roundRect(x,y,w,h,r);fx.fillStyle='rgba(4,26,38,.62)';fx.fill();fx.lineWidth=2.5;fx.strokeStyle=col;fx.shadowColor=col;fx.shadowBlur=18;fx.stroke();fx.restore()}
function overlay(t){
 // logo mark top
 const la=0;if(la>0&&LOGO){fx.save();fx.globalAlpha=.85*la;const lw=130,lh=lw*LOGO.height/LOGO.width;fx.shadowColor='#00ecff';fx.shadowBlur=24;fx.drawImage(LOGO,W/2-lw/2,120,lw,lh);fx.restore()}
 // station labels
 LABEL.forEach((L,i)=>{const a0=ST[i]+.12,a1=ST[i+1]-.34;const ia=eo3(P(t,a0,a0+.5)),oa=1-S(P(t,a1,a1+.28));const a=ia*oa;if(a<=0)return;const dy=(1-ia)*50;fx.save();fx.globalAlpha=a;
  const gr=fx.createLinearGradient(W/2-90,0,W/2+90,0);gr.addColorStop(0,'rgba(0,0,0,0)');gr.addColorStop(.5,L.col);gr.addColorStop(1,'rgba(0,0,0,0)');fx.fillStyle=gr;fx.fillRect(W/2-120,1396+dy,240,5);
  fx.shadowColor=L.col;fx.shadowBlur=30;txt(L.t,W/2,1520+dy,L.f==='Sora'?112:122,'#ffffff',{w:L.f==='Sora'?800:700,f:L.f,ls:L.f==='Sora'?2:0});fx.shadowBlur=0;
  txt(L.sub,W/2,1612+dy,L.sf==='Sora'?54:50,L.col,{w:L.sf==='Sora'?700:600,f:L.sf,ls:L.sf==='Sora'?6:0});fx.restore()});
 // burst chips
 CHIPS.forEach((c,k)=>{const t0=T_BURST+.25+k*.16;const s=eoB(P(t,t0,t0+.45))*(1-S(P(t,T_VORTEX+.05,T_VORTEX+.4)));if(s<=0.01)return;const cx=W/2+(k%2?200:-200),cy=1500+Math.floor(k/2)*130;fx.save();fx.translate(cx,cy);fx.scale(s,s);glass(-170,-48,340,96,48,c.col);fx.fillStyle=c.col;fx.shadowColor=c.col;fx.shadowBlur=16;fx.beginPath();fx.arc(-118,0,11,0,7);fx.fill();fx.shadowBlur=0;txt(c.t,36,18,c.f==='Sora'?44:52,'#fff',{w:c.f==='Sora'?800:700,f:c.f,ls:c.f==='Sora'?3:0});fx.restore()});
 // end card
 const e0=T_END-.15,ea=eo3(P(t,e0,e0+.7)),eb=eo3(P(t,e0+.35,e0+1.05));if(ea>0){fx.save();fx.globalAlpha=ea;const g=fx.createLinearGradient(W/2-300,0,W/2+300,0);g.addColorStop(0,'#8FF3F9');g.addColorStop(1,'#3CF08A');fx.fillStyle=g;fx.shadowColor='#00ecff';fx.shadowBlur=40;fx.font='800 212px Sora';fx.textAlign='center';fx.letterSpacing='26px';fx.translate(13,0);fx.fillText('VEX',W/2,1478+(1-ea)*30);fx.restore()}
 if(eb>0){fx.save();fx.globalAlpha=eb;fx.shadowColor='rgba(0,0,0,.6)';fx.shadowBlur=24;txt('تەندروستیت لەسەر دەستتە',W/2,1650+(1-eb)*26,74,'#ffffff',{w:700});fx.restore()}
 // flash + fades
 const fl=1-P(t,T_BAND,T_BAND+.2);if(t>=T_BAND&&fl>0){fx.save();fx.globalCompositeOperation='lighter';fx.fillStyle=`rgba(90,230,255,${.4*fl*fl*fl})`;fx.fillRect(0,0,W,H);fx.restore()}
 const fi=1-S(P(t,0,.45)),fo=S(P(t,DUR-.12,DUR));const k=Math.max(fi,fo);if(k>0){fx.fillStyle=`rgba(0,0,0,${k})`;fx.fillRect(0,0,W,H)}}

/* ============ post ============ */
const comp=new EffectComposer(renderer,new THREE.WebGLRenderTarget(W,H,{type:THREE.HalfFloatType,samples:4}));comp.setPixelRatio(1);comp.setSize(W,H);
comp.addPass(new RenderPass(scene,camera));const bloom=new UnrealBloomPass(new THREE.Vector2(W/2,H/2),.5,.6,.9);comp.addPass(bloom);comp.addPass(new OutputPass());
const fin=new ShaderPass({uniforms:{tDiffuse:{value:null},time:{value:0},ca:{value:.0014},vig:{value:.4}},vertexShader:'varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',fragmentShader:'uniform sampler2D tDiffuse;uniform float time,ca,vig;varying vec2 vUv;float h(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}void main(){vec2 c=vUv-.5;float d=dot(c,c);vec2 o=c*ca*(1.+d*5.);vec3 col=vec3(texture2D(tDiffuse,vUv+o).r,texture2D(tDiffuse,vUv).g,texture2D(tDiffuse,vUv-o).b);col*=1.-vig*smoothstep(.1,.8,d*2.2);col+=(h(vUv*vec2(1080.,1920.)+time)-.5)*.022;gl_FragColor=vec4(col,1.);}'});comp.addPass(fin);

window.grab=(t)=>{update(t);fin.uniforms.time.value=(t*13)%7;comp.render();fx.clearRect(0,0,W,H);fx.drawImage(renderer.domElement,0,0);overlay(t);return FIN.toDataURL('image/jpeg',.96)};

async function init(){
 await Promise.all([...['00','01','02','03','05','07','08','09','10','11'].map(async n=>CHAR[+n]=await loadImg(`assets/chars/${n}.webp`)),...['pizza','burger','macarons','lemons','lahmacun','wings','tea'].map(async n=>IMG[n]=await loadImg(`assets/foods/${n}.webp`)),loadImg('assets/logo.png').then(i=>LOGO=i),loadImg('assets/band.png').then(i=>TX.band=i),loadImg('assets/band_glow.png').then(i=>TX.bglow=i),loadImg('assets/band_halo.png').then(i=>TX.halo=i)]);
 await document.fonts.load('700 60px NotoAr','ڕێۆەڵ');await document.fonts.load('600 60px NotoAr','ڕێۆەڵ');await document.fonts.load('800 60px Sora','VEX');await document.fonts.load('700 60px Sora','72');
 buildHeart();buildArena();buildFamily();buildFood();buildIcons();buildBand();buildFX();
 document.body.appendChild(FIN);FIN.style.cssText='width:540px;height:960px';renderer.domElement.style.display='none';
 window.READY=true}
init().catch(e=>{console.error('INIT',e.stack||e);window.INITERR=String(e)});
window.dbg={renderer,scene,camera,comp,update,fin,bloom,U,G};
