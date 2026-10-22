p='plus_doc.html'; s=open(p).read()
def rep(a,b):
    global s
    assert s.count(a)==1,(a[:60],s.count(a)); s=s.replace(a,b)
# family -> general
a=s.index("['خێزان','#ff8fc8','users',"); b=s.index("var CMP=")
s=s[:a]+"['خێزان','#ff8fc8','users',[['users','#ff8fc8','پرۆفایلی خێزان','تەندروستی هەموو ئەندامانی خێزان لە یەک شوێن، هەر یەکە بە پرۆفایلی خۆی']]]];\n"+s[b:]
rep("['پرۆفایلی منداڵ و خێزان','n','y']","['پرۆفایلی خێزان','n','y']")
# new renderFeat
a=s.index("function renderFeat(){"); b=s.index("var io=null;")
new=r'''var ORB=[[0,62,26,0],[1,108,40,1],[2,152,52,0]];
var OR=[];
function renderFeat(){var n=0;G.forEach(function(g){n+=g[3].length});OR=[];
  var rings=[[0,0,0],[1,1,0],[2,2,0]];
  var ringItems=[G[0][3],G[2][3],[].concat(G[1][3],G[3][3],G[4][3])];
  var ob='';
  ringItems.forEach(function(it,ri){var cfg=ORB[ri],c=it.length;
    ob+='<div class="ring r'+ri+'"><i class="rl"></i>';
    it.forEach(function(f,i){var a=(360/c)*i-90+(ri*22),x=50+50*Math.cos(a*Math.PI/180),y=50+50*Math.sin(a*Math.PI/180);OR.push(f);
      ob+='<span class="ob" style="left:'+x.toFixed(2)+'%;top:'+y.toFixed(2)+'%"><span class="oi" data-i="'+(OR.length-1)+'" style="--c:'+f[1]+'">'+ico(f[0],20)+'</span></span>'});
    ob+='</div>'});
  var h='<div class="fh0 rv"><i class="blob b1"></i><i class="blob b2"></i><i class="blob b3"></i>'+
  '<div class="orbit"><i class="halo"></i>'+ob+'<div class="orb"><svg width="32" height="32" viewBox="0 0 24 24" style="fill:var(--pl-star)"><path d="M12 2c.6 4.900 2.400 8.600 10 10-7.600 1.400-9.400 5.100-10 10-.6-4.900-2.400-8.600-10-10 7.600-1.400 9.400-5.100 10-10z"/></svg></div></div>'+
  '<div class="ocap" id="oCap"><span class="ocn" id="oCn"></span><div class="oct"><b id="oCt"></b><span id="oCd"></span></div></div>'+
  '<h2>VEX Plus</h2><p>هەموو تەندروستییەکەت لە یەک شوێن، لەگەڵ ڕاوێژکارێکی AI کە تەنها بۆ تۆ کار دەکات</p>'+
  '<div class="hps"><span class="hp"><b>'+ar(n)+'</b> تایبەتمەندی</span><span class="hp">AI بێسنوور</span><span class="hp">٥٠٪ داشکان</span></div></div>';
  G.forEach(function(g){h+='<div class="gh rv" style="--c:'+g[1]+'"><u>'+ico(g[2],17)+'</u>'+g[0]+'<small>'+ar(g[3].length)+' تایبەتمەندی</small></div><div class="gr">';
    g[3].forEach(function(f,i){h+='<div class="fc rv" style="--c:'+f[1]+';--d:'+(i%2*90)+'ms"><span class="ft" style="--fd:'+(i*0.5)+'s">'+ico(f[0],24)+'</span><div class="tx"><b>'+f[2]+'</b><span class="d">'+f[3]+'</span></div></div>'});h+='</div>'});
  h+='<div class="gh rv" style="--c:#ffbe4d"><u>'+ico('chart',17)+'</u>بێ بەرامبەر یان Plus؟</div><div class="cmp rv"><div class="cr hd"><div></div><div class="c2">بێ بەرامبەر</div><div class="c3">Plus</div></div>';
  CMP.forEach(function(r){h+='<div class="cr"><div>'+r[0]+'</div><div class="c2">'+cell(r[1],0)+'</div><div class="c3">'+cell(r[2],1)+'</div></div>'});
  h+='</div><div class="cta rv"><b>هەموو ئەمانە بە یەک ئابوونە.</b><br>هەر کاتێک بتەوێت دەتوانیت دەست پێبکەیت.</div>';
  $('fBody').innerHTML=h;var ic='';for(var i=0;i<4;i++)ic+='<span>'+CK+'</span>';$('pIcs').innerHTML=ic}
var ot=null,oi=0;
function hot(i){var all=document.querySelectorAll('#fBody .oi');all.forEach(function(e){e.classList.toggle('hot',+e.dataset.i===i)});var f=OR[i];if(!f)return;var c=$('oCap');c.classList.remove('sw');void c.offsetWidth;c.classList.add('sw');c.style.setProperty('--c',f[1]);$('oCn').innerHTML=ico(f[0],22);$('oCt').textContent=f[2];$('oCd').textContent=f[3]}
function startOrbit(){stopOrbit();oi=0;hot(0);ot=setInterval(function(){oi=(oi+1)%OR.length;hot(oi)},2200)}
function stopOrbit(){if(ot){clearInterval(ot);ot=null}}
'''
s=s[:a]+new+s[b:]
rep("if(id!=='scan')stopT();if(id==='feat')reveal()","if(id!=='scan')stopT();if(id==='feat'){reveal();startOrbit()}else stopOrbit()")
# CSS: remove old orb related sizing & add orbit
css=r'''
/* ===== v4 orbit + neon icons ===== */
.fh0{padding:18px 14px 22px}
.orbit{position:relative;width:min(100%,336px);aspect-ratio:1;margin:0 auto}
.halo{position:absolute;inset:14%;border-radius:50%;background:radial-gradient(circle,rgba(255,190,77,.38),rgba(255,190,77,0) 68%);animation:pls 3.6s ease-in-out infinite}
@keyframes pls{0%,100%{transform:scale(.9);opacity:.8}50%{transform:scale(1.12);opacity:1}}
@keyframes spin{to{transform:rotate(360deg)}}
.orbit .orb{position:absolute;left:50%;top:50%;margin:-34px 0 0 -34px;width:68px;height:68px;border-radius:23px;z-index:3}
.ring{position:absolute;left:50%;top:50%;border-radius:50%;animation:spin var(--t) linear infinite}
.ring .rl{position:absolute;inset:0;border-radius:50%;border:1.2px dashed var(--pl-bd);opacity:.55}
.r0{width:36%;height:36%;margin:-18% 0 0 -18%;--t:26s}
.r1{width:66%;height:66%;margin:-33% 0 0 -33%;--t:42s;animation-direction:reverse}
.r2{width:98%;height:98%;margin:-49% 0 0 -49%;--t:64s}
.r1 .oi{animation-direction:normal!important}
.ob{position:absolute;width:0;height:0}
.oi{position:absolute;left:-19px;top:-19px;width:38px;height:38px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:var(--c);background:radial-gradient(circle at 30% 25%,rgba(255,255,255,.2),rgba(255,255,255,.02) 60%),var(--surf);border:1.5px solid var(--c);box-shadow:0 0 14px -2px var(--c),inset 0 0 10px -4px var(--c);animation:spin var(--t,26s) linear infinite reverse;transition:transform .45s cubic-bezier(.2,.9,.3,1.4),box-shadow .45s,background .45s}
.r0 .oi{--t:26s}.r1 .oi{--t:42s}.r2 .oi{--t:64s}
.oi svg{filter:drop-shadow(0 0 4px var(--c))}
.oi.hot{transform:scale(1.4);background:var(--c);color:#062832;box-shadow:0 0 26px 2px var(--c);z-index:5}
.oi.hot svg{filter:none}
.ocap{position:relative;display:flex;align-items:center;gap:12px;margin:14px auto 0;max-width:340px;min-height:70px;padding:10px 14px;border-radius:20px;background:var(--surf);border:1px solid var(--c,var(--pl-bd));text-align:right;box-shadow:0 12px 26px -18px var(--c,#000)}
.ocap.sw{animation:swp2 .5s cubic-bezier(.2,.8,.2,1)}
@keyframes swp2{from{opacity:.2;transform:translateY(8px)}to{opacity:1;transform:none}}
.ocn{width:42px;height:42px;border-radius:14px;flex:none;display:flex;align-items:center;justify-content:center;color:#062832;background:var(--c,var(--pl-bd));box-shadow:0 8px 16px -8px var(--c)}
.oct{min-width:0;flex:1}.oct b{display:block;font-size:14px;font-weight:800;line-height:1.5}.oct span{display:block;font-size:12px;color:var(--mu);line-height:1.6}
.fh0 h2{margin-top:18px}
/* neon tiles */
.ft{color:var(--c);background:radial-gradient(circle at 30% 20%,rgba(255,255,255,.22),rgba(255,255,255,0) 60%),linear-gradient(145deg,color-mix(in srgb,var(--c) 28%,transparent),color-mix(in srgb,var(--c) 6%,transparent));border:1.5px solid color-mix(in srgb,var(--c) 60%,transparent);box-shadow:0 0 18px -6px var(--c),inset 0 0 12px -6px var(--c);animation:fl 4.2s ease-in-out infinite;animation-delay:var(--fd,0s)}
.ft svg{filter:drop-shadow(0 0 5px var(--c))}
@keyframes fl{0%,100%{transform:translateY(0) rotate(0)}50%{transform:translateY(-4px) rotate(-3deg)}}
.fc::after{content:"";position:absolute;top:0;bottom:0;width:40%;left:0;background:linear-gradient(100deg,transparent,rgba(255,255,255,.07),transparent);transform:translateX(-140%) skewX(-18deg);animation:swp 7s ease-in-out infinite;animation-delay:var(--fd2,0s);pointer-events:none}
:root[data-theme="light"] .ft{color:#062832;background:linear-gradient(135deg,var(--c),color-mix(in srgb,var(--c) 62%,#fff));border-color:transparent}
:root[data-theme="light"] .ft svg,:root[data-theme="light"] .oi svg{filter:none}
:root[data-theme="light"] .oi{color:color-mix(in srgb,var(--c) 55%,#000);background:#fff}
:root[data-theme="light"] .oi.hot{background:var(--c);color:#062832}
:root[data-theme="light"] .ocn{color:#062832}
.gh u{animation:fl 4.6s ease-in-out infinite}
@media (prefers-reduced-motion:reduce){.ring,.oi{animation:none!important}}
'''
s=s.replace('</style>',css+'</style>',1)
# card sweep stagger
s=s.replace('<div class="fc rv" style="--c:\'+f[1]+\';--d:\'+(i%2*90)+\'ms">','<div class="fc rv" style="--c:\'+f[1]+\';--d:\'+(i%2*90)+\'ms;--fd2:\'+(i*1.3)+\'s">')
open(p,'w').write(s)
