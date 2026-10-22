p='/tmp/scr/live/index.html'
s=open(p,encoding='utf8').read()
def rep(a,b,cnt=1):
    global s
    assert s.count(a)==cnt,(s.count(a),a[:90])
    s=s.replace(a,b)

CSS='''
#vxGate{position:fixed;left:0;right:0;top:0;bottom:0;z-index:6;display:none;align-items:center;justify-content:center;padding:70px 22px 26px;background:color-mix(in srgb,var(--bg) 42%,transparent);backdrop-filter:blur(16px) saturate(.7);-webkit-backdrop-filter:blur(16px) saturate(.7)}
#vxGate.on{display:flex;animation:vgIn .4s cubic-bezier(.2,.9,.25,1)}
@keyframes vgIn{from{opacity:0}to{opacity:1}}
#vxGate.tabm{padding-top:40px;align-items:center}
.vg-back{position:absolute;top:calc(env(safe-area-inset-top,0px) + 12px);right:14px;width:42px;height:42px;border-radius:14px;border:1px solid rgba(140,235,245,.22);background:rgba(6,40,50,.75);backdrop-filter:blur(10px);color:#effeff;display:grid;place-items:center;cursor:pointer}
.vg-back svg{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}
#vxGate.tabm .vg-back{display:none}
.vg-c{position:relative;width:100%;max-width:350px;margin-top:44px;padding:0 20px 20px;text-align:center;border-radius:32px;background:linear-gradient(180deg,rgba(15,62,77,.9),rgba(7,33,43,.94));border:1px solid rgba(140,235,245,.2);box-shadow:0 34px 80px -22px rgba(0,0,0,.75),inset 0 1px 0 rgba(255,255,255,.07);color:#effeff;animation:vgUp .5s cubic-bezier(.2,.9,.25,1) both}
@keyframes vgUp{from{opacity:0;transform:translateY(22px) scale(.96)}to{opacity:1;transform:none}}
:root[data-theme="light"] .vg-c{background:linear-gradient(180deg,rgba(255,255,255,.96),rgba(236,247,250,.96));border-color:rgba(6,40,50,.1);color:#062832}
.vg-ic{position:relative;width:88px;height:88px;margin:-44px auto 12px;border-radius:30px;display:grid;place-items:center;color:#032a31;background:linear-gradient(135deg,#8ff3f9,#3cf08a);box-shadow:0 18px 40px -12px rgba(60,240,138,.6),inset 0 1px 0 rgba(255,255,255,.5)}
.vg-ic svg{width:46px;height:46px}
.vg-c.plus .vg-ic{background:linear-gradient(135deg,#ffe29a,#ffbf47 60%,#ff9d3d);box-shadow:0 18px 40px -12px rgba(255,170,50,.65),inset 0 1px 0 rgba(255,255,255,.5);color:#4a2c00}
.vg-lk{position:absolute;right:-6px;bottom:-6px;width:30px;height:30px;border-radius:11px;display:grid;place-items:center;background:#06222c;border:2px solid rgba(140,235,245,.3);color:#effeff}
:root[data-theme="light"] .vg-lk{background:#fff;color:#062832;border-color:rgba(6,40,50,.2)}
.vg-lk svg{width:15px;height:15px;fill:none;stroke:currentColor;stroke-width:2.4;stroke-linecap:round;stroke-linejoin:round}
.vg-c h3{margin:0 0 6px;font-size:20px;font-weight:800;line-height:1.55}
.vg-c>p{margin:0 0 14px;font-size:13px;line-height:1.95;color:var(--mu)}
.vg-ul{list-style:none;margin:0 0 16px;padding:0;display:flex;flex-direction:column;gap:8px;text-align:right}
.vg-ul li{display:flex;align-items:center;gap:10px;font-size:13px;font-weight:700;line-height:1.6}
.vg-ul li i{flex:none;width:22px;height:22px;border-radius:50%;display:grid;place-items:center;background:rgba(60,240,138,.16);color:#3cf08a}
.vg-c.plus .vg-ul li i{background:rgba(255,191,71,.18);color:#ffbf47}
.vg-ul li i svg{width:12px;height:12px;fill:none;stroke:currentColor;stroke-width:3.2;stroke-linecap:round;stroke-linejoin:round}
.vg-b{display:flex;align-items:center;justify-content:center;gap:9px;width:100%;height:54px;border:0;border-radius:18px;background:linear-gradient(135deg,#8ff3f9,#3cf08a);color:#032a31;font:800 15.5px "Noto Sans Arabic",Sora,sans-serif;cursor:pointer;box-shadow:0 14px 30px -12px rgba(60,240,138,.7);position:relative;overflow:hidden;transition:transform .15s}
.vg-c.plus .vg-b{background:linear-gradient(135deg,#ffe29a,#ffbf47 55%,#ff9d3d);color:#3b2500;box-shadow:0 14px 30px -12px rgba(255,170,50,.75)}
.vg-b:active{transform:scale(.97)}
.vg-b:after{content:"";position:absolute;top:0;bottom:0;width:40%;left:-60%;background:linear-gradient(100deg,transparent,rgba(255,255,255,.45),transparent);transform:skewX(-20deg);animation:vgSh 3.6s ease-in-out infinite}
@keyframes vgSh{0%,55%{left:-60%}100%{left:130%}}
.vg-s{display:block;width:100%;margin-top:10px;padding:10px;background:none;border:0;color:var(--mu);font:700 13px "Noto Sans Arabic",Sora,sans-serif;cursor:pointer}
.vg-tag{display:inline-flex;padding:2px 9px;border-radius:99px;background:rgba(3,42,49,.16);font-size:11px;font-weight:800}
@media (prefers-reduced-motion:reduce){.vg-b:after,#vxGate.on,.vg-c{animation:none}}
'''
anchor=".sback{position:absolute;z-index:3;"
assert s.count(anchor)==1
i=s.index(anchor); j=s.index('}',i)+1
s=s[:j]+CSS+s[j:]

JS=r'''
// ---------- VEX gates: Plus / Band ----------
const PLUS_UNTIL=()=>{try{const p=JSON.parse(localStorage.getItem('vexsub-plus')||'null');return p&&p.plan==='plus'&&p.until>Date.now()}catch(e){return false}};
const isPlus=PLUS_UNTIL;
function hasBand(){try{const d=JSON.parse(localStorage.getItem('vexdevice')||'null');return !!(d&&d.state==='on')}catch(e){return false}}
function openPlus(){go('plus');setTimeout(()=>{try{const f=scrs.plus.querySelector('iframe');f.contentWindow.plusReset&&f.contentWindow.plusReset()}catch(e){}},0)}
const VG_IC={band:'<svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><path d="M17 4h14l1.6 7H15.4zM17 44h14l1.6-7H15.4z" fill="currentColor" fill-opacity=".28"/><rect x="11" y="11" width="26" height="26" rx="9"/><path d="M16.5 25h4l2.2-5.5 3.4 9.5 2.4-4h3"/></svg>',
 plus:'<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2c.6 4.9 2.4 8.6 10 10-7.6 1.4-9.4 5.1-10 10-.6-4.9-2.4-8.6-10-10 7.6-1.4 9.4-5.1 10-10z"/></svg>',
 lock:'<svg viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="9" rx="3"/><path d="M8 11V8a4 4 0 018 0v3"/></svg>',
 ck:'<svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>'};
const BAND_D='ئەم بەشە داتای VEX Band ـەکەت پیشان دەدات. Band ـەکەت پەیوەست بکە تا هەموو شتێک زیندوو ببێت.';
const BAND_P=['لێدانی دڵ، ئۆکسجین و سترێس 24/7','شیکاری خەو و تەمەنی جەستە (VitalAge)','ECG و ئاگاداری نائاسایی'];
const GK={
 ai:{k:'plus',t:'ڕاوێژکاری AI ی تایبەت بە تۆ',d:'لە هەر کاتێکدا پرسیار بکە و ڕێنمایی تایبەت بەپێی داتاکانت وەربگرە، بە کوردی.',p:['پرسیاری بێسنوور بە VEX AI','شیکاری هەموو داتاکانی Band','ڕاهێنەری خۆراک و ڕاهێنان']},
 family:{k:'plus',t:'پرۆفایلی خێزان',d:'تەندروستی هەموو ئەندامانی خێزان لە یەک شوێن ببینە.',p:['هەر ئەندامێک پرۆفایلی خۆی','ئاگاداری نائاسایی بۆ ئازیزانت','ڕاپۆرتی هاوبەشی خێزان']},
 workout:{k:'plus',t:'پلانی ڕاهێنانی AI',d:'پلانێکی هەفتانە بەپێی دڵ، خەو و ئامانجەکەت.',p:['پلانی هەفتانە بە AI','گونجاندن بەپێی ئامادەبوونی جەستەت','ڕاپۆرتی پێشکەوتن'],alt:['ڕاهێنانی خێرا (بێ بەرامبەر)',()=>go('live')]},
 health:{k:'band',t:'نیشانە زیندووەکانت',d:BAND_D,p:BAND_P},
 heart:{k:'band',t:'لێدانی دڵ بە شێوەی زیندوو',d:BAND_D,p:BAND_P},
 spo2:{k:'band',t:'ئۆکسجینی خوێن',d:BAND_D,p:BAND_P},
 stress:{k:'band',t:'سترێس و HRV',d:BAND_D,p:BAND_P},
 temp:{k:'band',t:'پلەی گەرمی پێست',d:BAND_D,p:BAND_P},
 sleep:{k:'band',t:'شیکاری خەوی شەوانەت',d:BAND_D,p:BAND_P}};
const gateOn=k=>{const g=GK[k];return !!g&&(g.k==='plus'?!isPlus():!hasBand())};
let gateEl=null,gateKey='';
function gateBuild(k){const g=GK[k],plus=g.k==='plus';
  gateEl.innerHTML=`<button class="vg-back" id="vgBack" type="button" aria-label="دواوە"><svg viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg></button>
  <div class="vg-c ${g.k}"><div class="vg-ic">${plus?VG_IC.plus:VG_IC.band}<span class="vg-lk">${VG_IC.lock}</span></div>
   <h3>${g.t}</h3><p>${g.d}</p><ul class="vg-ul">${g.p.map(x=>`<li><i>${VG_IC.ck}</i><span>${x}</span></li>`).join('')}</ul>
   <button class="vg-b" id="vgGo" type="button">${plus?`${VG_IC.plus.replace('<svg','<svg width="18" height="18"')}<span>VEX Plus چالاک بکە</span><span class="vg-tag">٥٠٪ داشکان</span>`:'<span>VEX Band V8 بکڕە</span>'}</button>
   ${plus?(g.alt?`<button class="vg-s" id="vgAlt" type="button">${g.alt[0]}</button>`:''):'<button class="vg-s" id="vgAlt" type="button">Band ـم هەیە، پەیوەستی بکە</button>'}</div>`;
  gateEl.querySelector('#vgBack').onclick=()=>back();
  gateEl.querySelector('#vgGo').onclick=()=>{plus?openPlus():go('device')};
  const a=gateEl.querySelector('#vgAlt');if(a)a.onclick=()=>{if(plus&&g.alt)g.alt[1]();else go('device')}}
const VXK_CSS='.vxl{position:relative!important;overflow:hidden!important}.vxl>*:not(.vxk){filter:blur(6px) saturate(.55);opacity:.5;pointer-events:none;user-select:none;transition:filter .3s}.vxk{position:absolute;inset:0;z-index:30;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:7px;padding:14px;text-align:center;background:linear-gradient(180deg,rgba(4,26,34,.25),rgba(4,26,34,.55));font-family:inherit}.vxk .lk{width:46px;height:46px;border-radius:16px;display:grid;place-items:center;color:#032a31;background:linear-gradient(135deg,#8ff3f9,#3cf08a);box-shadow:0 10px 26px -8px rgba(60,240,138,.7)}.vxk.plus .lk{background:linear-gradient(135deg,#ffe29a,#ffbf47 60%,#ff9d3d);color:#4a2c00;box-shadow:0 10px 26px -8px rgba(255,170,50,.7)}.vxk .lk svg{width:24px;height:24px;fill:none;stroke:currentColor;stroke-width:2.3;stroke-linecap:round;stroke-linejoin:round}.vxk b{font-size:15px;font-weight:800;color:#effeff;line-height:1.5}.vxk small{font-size:11.5px;line-height:1.7;color:#cfe9ee;max-width:250px}.vxk button{margin-top:4px;height:40px;padding:0 20px;border:0;border-radius:14px;font:800 13px inherit;font-family:inherit;color:#032a31;background:linear-gradient(135deg,#8ff3f9,#3cf08a);cursor:pointer}.vxk.plus button{background:linear-gradient(135deg,#ffe29a,#ffbf47 60%,#ff9d3d);color:#3b2500}html[data-theme="light"] .vxk{background:linear-gradient(180deg,rgba(238,249,251,.35),rgba(238,249,251,.7))}html[data-theme="light"] .vxk b{color:#062832}html[data-theme="light"] .vxk small{color:#35606a}';
function vxLock(d,el,kind,title,sub,btn){if(!el)return;const need=kind==='plus'?!isPlus():!hasBand();let v=null;for(const c of el.children)if(c.classList&&c.classList.contains('vxk'))v=c;
  if(!d.getElementById('vxLockCss')){const st=d.createElement('style');st.id='vxLockCss';st.textContent=VXK_CSS;d.head.appendChild(st)}
  el.classList.toggle('vxl',need);
  if(need&&!v){v=d.createElement('div');v.className='vxk '+kind;v.innerHTML=`<span class="lk">${kind==='plus'?VG_IC.plus.replace('<svg','<svg style="fill:currentColor;stroke:none"'):VG_IC.lock}</span><b>${title}</b><small>${sub}</small><button type="button">${btn}</button>`;
   v.querySelector('button').onclick=e=>{e.preventDefault();e.stopPropagation();kind==='plus'?openPlus():go('device')};el.appendChild(v)}
  else if(!need&&v)v.remove()}
function homeSync(){try{const f=frames.home;if(!f)return;const d=f.contentDocument;if(!d||!d.body||!d.querySelector('.stat'))return;
  const band=hasBand();
  vxLock(d,d.querySelector('section.card.holo'),'band','تەندروستیی ئەمڕۆ','Band ـەکەت پەیوەست بکە تا نمرە و نیشانە زیندووەکانت ببینیت','پەیوەستکردنی Band');
  const fam=d.querySelector('.favs');vxLock(d,fam&&fam.closest('section'),'plus','بازنەی خێزان','تەندروستی ئەندامانی خێزانت لە یەک شوێن، بە VEX Plus','VEX Plus چالاک بکە');
  const st=d.querySelector('.stat');if(st&&st.dataset.nb!==(band?'0':'1')){st.dataset.nb=band?'0':'1';
   if(!band){st.dataset.orig=st.dataset.orig||st.innerHTML;st.innerHTML='<span class="lv" style="color:#ff9f7a"><i style="background:#ff9f7a;box-shadow:none"></i>Band پەیوەست نییە</span><span style="margin-inline-start:auto;font-weight:800;color:#8ff3f9;cursor:pointer" id="vxStatGo">پەیوەستکردن ‹</span>';
    const g=d.getElementById('vxStatGo');if(g)g.onclick=e=>{e.stopPropagation();go('device')}}
   else if(st.dataset.orig){st.innerHTML=st.dataset.orig}}}catch(e){}}
function gateSync(){if(!gateEl)return;const vis=stack.length?stack[stack.length-1]:cur,on=gateOn(vis);
  if(on){const tabm=!stack.length;if(gateKey!==vis){gateKey=vis;gateBuild(vis)}gateEl.classList.toggle('tabm',tabm);
   let nb=0;if(tabm){try{const n=frames[vis].contentDocument.querySelector('body>nav');nb=n?n.offsetHeight:0}catch(e){}}gateEl.style.bottom=nb+'px';gateEl.classList.add('on')}
  else{gateEl.classList.remove('on');gateKey=''}
  homeSync()}
(function(){gateEl=document.createElement('div');gateEl.id='vxGate';document.body.appendChild(gateEl);setInterval(gateSync,500);window.addEventListener('storage',gateSync)})();
// free plan: 3 scans a day, unlimited with Plus
const SCAN_FREE=3;
function scanQuota(){const d=new Date().toISOString().slice(0,10);let q=null;try{q=JSON.parse(localStorage.getItem('vexscans')||'null')}catch(e){}if(!q||q.d!==d)q={d,n:0};return q}
const subApi={isPlus,hasBand,openPlus,left(){return isPlus()?Infinity:Math.max(0,SCAN_FREE-scanQuota().n)},
 useScan(){if(isPlus())return true;const q=scanQuota();if(q.n>=SCAN_FREE){toast('سکانی خۆڕایی ئەمڕۆت تەواو بوو · بۆ بێسنوور VEX Plus چالاک بکە');openPlus();return false}
  q.n++;try{localStorage.setItem('vexscans',JSON.stringify(q))}catch(e){}const r=SCAN_FREE-q.n;toast(r>0?`سکانی خۆڕایی ماوە: ${r}`:'ئەمە دوایین سکانی خۆڕایی ئەمڕۆت بوو');return true}};
'''
anchor2="// ---------- boot ----------"
assert s.count(anchor2)==1
s=s.replace(anchor2,JS+anchor2)
# expose in APP
rep("window.APP={water,_frames:frames,","window.APP={get sub(){return subApi},water,_frames:frames,")
open(p,'w',encoding='utf8').write(s)
print('ok')
