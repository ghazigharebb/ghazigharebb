import re
p='plus_doc.html'; s=open(p).read()
def rep(a,b,c=1):
    global s
    assert s.count(a)==c,(a[:70],s.count(a)); s=s.replace(a,b)

# ---------- copy fixes ----------
rep("sub:'هەر کاتێک بتەوێت ڕایبگرە'","sub:'هەر مانگێک 5,000 د.ع'")
rep("sub:'وەک 4,167 د.ع لە مانگێکدا'","sub:'هەر مانگێک نزیکەی 4,167 د.ع'")
rep("sub:'نرخی 50٪ بۆ ساڵێک دەمێنێتەوە'","sub:'هەر مانگێک نزیکەی 4,167 د.ع، بۆ ساڵێک'")
rep("لە ئەپی FIB ـەوە، بێ کارت","بە ئەپی FIB، بێ پێویستی بە کارت")
rep("لە ئەپی FastPay ـەوە","بە ئەپی FastPay")
rep("پارەدانەکە لەناو ئەپی شێوازەکە تەواو دەبێت","پارەدانەکە لە ئەپی هەڵبژێردراو تەواو دەکرێت")
rep("hint:'ئەپی FIB بکەرەوە ← «سکان» ← ئەم بارکۆدە بخوێنەرەوە'","hint:'ئەپی FIB بکەرەوە، «سکان» هەڵبژێرە و ئەم بارکۆدە بخوێنەرەوە'")
rep("hint:'ئەپی Qi بکەرەوە ← «سکان» ← ئەم بارکۆدە بخوێنەرەوە'","hint:'ئەپی Qi بکەرەوە، «سکان» هەڵبژێرە و ئەم بارکۆدە بخوێنەرەوە'")
rep("hint:'ئەپی FastPay بکەرەوە ← «سکان» ← ئەم بارکۆدە بخوێنەرەوە'","hint:'ئەپی FastPay بکەرەوە، «سکان» هەڵبژێرە و ئەم بارکۆدە بخوێنەرەوە'")
rep("left>0?'بارکۆدەکە ماوەی':'بارکۆدەکە بەسەرچوو'","left>0?'ماوەی بارکۆد':'بارکۆدەکە بەسەرچووە'")
rep('id="sTimeL">بارکۆدەکە ماوەی<','id="sTimeL">ماوەی بارکۆد<')
rep("پلانەکەت چالاک کرا · چالاکە تا","VEX Plus چالاک کرا · کاریگەرە تا")
rep("(دیمۆ — هیچ پارەیەک نەبڕدرا)","(دیمۆ: هیچ پارەیەکی ڕاستەقینە وەرنەگیرا)")
rep(">تەواو</button></div>\n</div>",">دەستپێبکە</button></div>\n</div>")
rep("تکایە پەڕەکە دامەخە","تکایە ئەم پەڕەیە دامەخە")

# ---------- CSS ----------
css='''
/* ===== v3: stability + motion ===== */
.m-fib{--mg:rgba(10,148,136,.55)}.m-qi{--mg:rgba(255,203,5,.5)}.m-fp{--mg:rgba(212,42,87,.5)}
.pseg{margin-top:18px}
.pp{padding:20px 4px 12px;min-height:100px}
.pp i{top:-11px;overflow:hidden}
.pp i::after,.psub i::after{content:"";position:absolute;inset:0;background:linear-gradient(100deg,transparent 30%,rgba(255,255,255,.65) 50%,transparent 70%);transform:translateX(-120%);animation:shn 3.4s ease-in-out infinite}
.pp i,.psub i{position:absolute;overflow:hidden}.psub i{position:relative}
.pp{transition:transform .2s cubic-bezier(.2,.9,.3,1.3),background .2s,border-color .2s,box-shadow .2s}
.pp:active{transform:scale(.96)}.pp.on{transform:translateY(-2px)}
.btot{width:132px;flex:none}
.pbar .pay{position:relative;overflow:hidden;min-width:0;white-space:nowrap;animation:glw 2.8s ease-in-out infinite;transition:background .25s,color .25s}
.pbar .pay>*{position:relative;z-index:1}
.pbar .pay img{flex:none;width:30px;height:30px}
.pbar .pay::after{content:"";position:absolute;top:0;bottom:0;width:60%;left:0;background:linear-gradient(100deg,transparent,rgba(255,255,255,.28),transparent);transform:translateX(-130%) skewX(-18deg);animation:swp 3.6s ease-in-out infinite}
.pbar .pay:active{transform:scale(.97)}
.pm{transition:background .2s,box-shadow .2s}.pm:active{background:var(--surf2)}
.pm .rd{transition:background .2s,border-color .2s,transform .25s cubic-bezier(.2,.9,.3,1.4)}.pm.on .rd{transform:scale(1.08)}
.rs{opacity:0}
.pv:not([hidden]) .rs{animation:rise .55s cubic-bezier(.2,.8,.2,1) both;animation-delay:calc(var(--i,0)*70ms)}
.rv{opacity:0;transform:translateY(18px);transition:opacity .6s cubic-bezier(.2,.8,.2,1),transform .6s cubic-bezier(.2,.8,.2,1);transition-delay:var(--d,0ms)}
.rv.in{opacity:1;transform:none}
@keyframes rise{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}
@keyframes shn{0%,55%{transform:translateX(-120%)}100%{transform:translateX(120%)}}
@keyframes swp{0%,55%{transform:translateX(-130%) skewX(-18deg)}100%{transform:translateX(330%) skewX(-18deg)}}
@keyframes glw{0%,100%{box-shadow:0 8px 20px -10px var(--mg),0 0 0 0 transparent}50%{box-shadow:0 10px 26px -8px var(--mg),0 0 0 5px transparent}}
@keyframes flt{from{transform:translate(0,0) scale(1)}to{transform:translate(18px,-14px) scale(1.15)}}
@keyframes orb{0%,100%{transform:translateY(0) rotate(-3deg)}50%{transform:translateY(-6px) rotate(3deg)}}
@keyframes ring{0%{transform:scale(.8);opacity:.7}100%{transform:scale(1.9);opacity:0}}
@keyframes tw{0%,100%{opacity:.15;transform:scale(.6)}50%{opacity:1;transform:scale(1)}}
/* feature page */
.fh0{position:relative;overflow:hidden;border-radius:28px;padding:28px 18px 22px;text-align:center;background:var(--pl-bg);border:1.5px solid var(--pl-bd);box-shadow:var(--sh);isolation:isolate}
.blob{position:absolute;border-radius:50%;filter:blur(30px);opacity:.5;z-index:-1;animation:flt 9s ease-in-out infinite alternate;pointer-events:none}
.b1{width:190px;height:190px;background:#ffbe4d;top:-70px;right:-50px}
.b2{width:170px;height:170px;background:#2fe6f3;bottom:-80px;left:-50px;opacity:.32;animation-delay:-3s}
.b3{width:120px;height:120px;background:#b79bff;top:30%;left:35%;opacity:.25;animation-delay:-6s}
:root[data-theme="light"] .blob{opacity:.34}
.orb{position:relative;width:72px;height:72px;margin:0 auto;border-radius:24px;background:var(--pl-ib);display:flex;align-items:center;justify-content:center;box-shadow:0 14px 30px -10px rgba(255,160,40,.7);animation:orb 4.5s ease-in-out infinite}
.orb::before{content:"";position:absolute;inset:0;border-radius:24px;border:2px solid var(--pl-bd);animation:ring 2.8s ease-out infinite}
.sp1,.sp2,.sp3{position:absolute;fill:var(--amber);animation:tw 2.4s ease-in-out infinite}
.sp1{width:14px;top:24px;right:24%}.sp2{width:10px;top:52px;left:22%;animation-delay:-.8s}.sp3{width:12px;top:18px;left:30%;animation-delay:-1.5s}
.fh0 h2{margin:16px 0 4px;font:800 30px/1.2 "Sora","Noto Sans Arabic",sans-serif;color:var(--pl-t);direction:ltr}
.fh0 p{margin:0 auto;max-width:300px;font-size:14px;line-height:1.9;font-weight:600;color:var(--pl-s)}
.hps{display:flex;flex-wrap:wrap;gap:8px;justify-content:center;margin-top:16px}
.hp{display:inline-flex;align-items:center;gap:6px;padding:6px 12px;border-radius:99px;background:var(--surf);border:1px solid var(--pl-bd);font-size:12px;font-weight:700;color:var(--tx)}
.hp b{font-family:"Sora",sans-serif;color:var(--tm)}
.gh{display:flex;align-items:center;gap:10px;margin:26px 4px 12px;font-weight:800;font-size:16px}
.gh u{width:30px;height:30px;border-radius:10px;display:flex;align-items:center;justify-content:center;text-decoration:none;background:var(--c);color:#062832}
.gh small{margin-inline-start:auto;font-size:11.5px;font-weight:700;color:var(--mu)}
.gr{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.fc{position:relative;overflow:hidden;border-radius:22px;padding:14px 13px 15px;background:var(--surf);border:1px solid var(--line);display:flex;flex-direction:column;gap:9px;min-width:0}
.fc::before{content:"";position:absolute;inset:0;background:radial-gradient(130px 90px at 100% 0,var(--c),transparent 70%);opacity:.2;pointer-events:none}
.fc:last-child:nth-child(odd){grid-column:1/-1;flex-direction:row;align-items:center;gap:13px}
.ft{position:relative;width:46px;height:46px;border-radius:15px;flex:none;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,var(--c),color-mix(in srgb,var(--c) 62%,#fff));color:#062832;box-shadow:0 10px 18px -10px var(--c)}
.fc b{position:relative;display:block;font-size:13.5px;font-weight:800;line-height:1.55}
.fc span.d{position:relative;display:block;font-size:12px;line-height:1.7;color:var(--mu);margin-top:2px}
.fc .tx{min-width:0}
.cmp{border-radius:24px;border:1px solid var(--line);background:var(--surf);overflow:hidden}
.cr{display:grid;grid-template-columns:1fr 74px 74px;align-items:center;border-top:1px solid var(--line);min-height:50px}
.cr>div{padding:8px 10px;font-size:12.5px;line-height:1.55}
.cr>div:first-child{font-weight:700;padding-inline-start:14px}
.cr .c2{text-align:center;color:var(--mu);font-size:11.5px;font-weight:700}
.cr .c3{text-align:center;background:rgba(255,190,77,.1);height:100%;display:flex;align-items:center;justify-content:center;font-size:11.5px;font-weight:800;color:var(--tm)}
.cr.hd{border-top:0;min-height:48px;background:var(--surf2)}
.cr.hd .c2{font-size:11px}
.cr.hd .c3{background:var(--pl-ib);color:var(--pl-star);font-size:12px}
.ck{display:inline-flex;width:22px;height:22px;border-radius:50%;align-items:center;justify-content:center}
.ck.g{background:var(--pl-ib);color:var(--pl-star)}.ck.m{background:var(--surf2);color:var(--mu);border:1px solid var(--line)}
.cta{margin-top:22px;text-align:center;font-size:13px;line-height:1.9;color:var(--mu);padding:0 12px}
.cta b{color:var(--tx)}
.okb{display:flex;flex-wrap:wrap;gap:8px;justify-content:center;margin-top:18px}
.okb span{display:inline-flex;align-items:center;gap:6px;padding:7px 12px;border-radius:99px;background:var(--surf);border:1px solid var(--pl-bd);font-size:12.5px;font-weight:700}
@media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}.rs,.rv{opacity:1!important;transform:none!important}}
'''
rep('</style>',css+'</style>')

# ---------- feat view renderer ----------
a=s.index("var CK='<svg"); b=s.index("var st={plan:'half'")
IC={'cam':'<path d="M4 8h3l1.5-2h7L17 8h3v11H4z"/><circle cx="12" cy="13.5" r="3.5"/>',
'chat':'<path d="M20 12a8 8 0 0 1-11.6 7.1L4 20l1-4A8 8 0 1 1 20 12z"/><path d="M9 11h6M9 14h4"/>',
'spark':'<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/><path d="M19 16l.7 1.8 1.8.7-1.8.7L19 21l-.7-1.8-1.8-.7 1.8-.7z"/>',
'fork':'<path d="M7 3v8a2 2 0 0 0 2 2v8M7 3v5M11 3v5M17 3c-2 2-3 5-3 8h3v10"/>',
'plan':'<rect x="4" y="5" width="16" height="15" rx="3"/><path d="M8 3v4M16 3v4M4 10h16M8 14h3"/>',
'pill':'<rect x="3.5" y="9" width="17" height="6" rx="3" transform="rotate(-35 12 12)"/><path d="M10.5 8.2l3 7.6"/>',
'dna':'<path d="M8 3c0 5 8 5 8 10s-8 5-8 8M16 3c0 5-8 5-8 10s8 5 8 8M9 7h6M9 17h6"/>',
'ecg':'<path d="M3 12h4l2-5 4 10 2-5h6"/>',
'book':'<path d="M5 4h10a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3z"/><path d="M8 8h6M8 12h6"/>',
'brain':'<path d="M9.5 4.5a3 3 0 0 0-3 3 3 3 0 0 0-2 5.2 3 3 0 0 0 2 4.8 3 3 0 0 0 5.5 1V6.3a3 3 0 0 0-2.5-1.8z"/><path d="M14.5 4.5a3 3 0 0 1 3 3 3 3 0 0 1 2 5.2 3 3 0 0 1-2 4.8 3 3 0 0 1-5.5 1"/>',
'chart':'<path d="M4 20V4M4 20h16"/><path d="M8 15l3-4 3 2 5-7"/>',
'mail':'<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M3 8l9 6 9-6"/>',
'run':'<circle cx="14" cy="4.5" r="2"/><path d="M8 21l3-6-2.5-2.5L10 8l4 1 2 3M11 15l3 2 1 4M10 8L7 11"/>',
'baby':'<circle cx="12" cy="9" r="5"/><path d="M9.5 9.5h.01M14.5 9.5h.01M10 12c1 .9 3 .9 4 0M7 19c1-2 3-3 5-3s4 1 5 3"/>',
'users':'<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.6-3.6 3.2-5.5 6.5-5.5s5.9 1.9 6.5 5.5M16 4.8a3.4 3.4 0 0 1 0 6.4M18 14.8c1.9.7 3.2 2.3 3.5 5.2"/>',
'lock':'<rect x="5" y="11" width="14" height="9" rx="3"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>'}
import json
js_ic=json.dumps(IC,ensure_ascii=False)
newjs='''var CK='<svg class="i" width="13" height="13" viewBox="0 0 24 24" style="stroke-width:3.2"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>';
var IC=%s;
function ico(k,sz){return '<svg class="i" width="'+sz+'" height="'+sz+'" viewBox="0 0 24 24" style="stroke-width:1.9">'+IC[k]+'</svg>'}
var G=[['VEX AI','#b79bff','spark',[['cam','#2fe6f3','سکانی خواردنی بێسنوور','وێنەی خواردنەکە بگرە و کالۆری و ماکرۆکانی دەزانیت'],['chat','#b79bff','پرسیاری بێسنوور لە VEX AI','هەر کاتێک و هەر چەندێک پرسیار بکە'],['spark','#ffd36b','ڕاهێنەری خۆراک بە AI','ڕێنمایی تایبەت بەپێی کێش و ئامانجەکەت'],['fork','#ff9466','«برسیمە! چی بخۆم؟»','لە چرکەیەکدا ژەمێکی گونجاوت بۆ پێشنیار دەکات']]],
['خۆراک','#3cf08a','fork',[['plan','#3cf08a','پلانی ژەم بە AI','پلانی ڕۆژانە، لەگەڵ ڕێسێپتی کوردی'],['pill','#ff8fc8','ڤیتامین و کانزاکان','بزانە چیت کەمە و چی بخۆیت']]],
['تەندروستی','#2fe6f3','ecg',[['dna','#2fe6f3','VitalAge','تەمەنی ڕاستەقینەی جەستەت'],['ecg','#ff5f7e','ECG و ڕاپۆرتی AI','خوێندنەوەی ڕیتمی دڵ لەگەڵ ڕاپۆرت'],['book','#9b7bff','ڕۆژەکەت','نەخشەی تەواوی ڕۆژت، کاتژمێر بە کاتژمێر'],['brain','#ffbe4d','شیکاری AI بۆ تەندروستی','هەموو داتاکانی Band پێکەوە شیدەکاتەوە'],['chart','#3cf08a','مێژووی هەفتە و مانگ','گۆڕانکارییەکانت بە درێژایی کات ببینە'],['mail','#8ff3f9','ڕاپۆرتی هەفتانە بە AI','چی باش بوو و چی بگۆڕیت']]],
['وەرزش','#ff9466','run',[['run','#ff9466','پلانی ڕاهێنان بە AI','هەفتانە، بەپێی دڵ و خەو و ئامانجەکەت']]],
['خێزان','#ff8fc8','users',[['baby','#ff8fc8','پرۆفایلی منداڵ','شیر و گەشە و خواردنی منداڵ'],['users','#ff8fc8','دایک و باوک','پرۆفایلی جیاواز بۆ هەر کەسێک']]]];
var CMP=[['ئامارەکانی Band','y','y'],['تۆمارکردنی خواردن بە دەست','y','y'],['سکانی خواردن بە وێنە','سنووردار','بێسنوور'],['پرسیار لە VEX AI','n','y'],['پلانی ژەم و ڕاهێنان','n','y'],['ECG و VitalAge','n','y'],['ڕاپۆرتی هەفتانە','n','y'],['پرۆفایلی منداڵ و خێزان','n','y']];
function cell(v,plus){if(v==='y')return '<span class="ck '+(plus?'g':'m')+'">'+CK+'</span>';if(v==='n')return '<span class="ck m">'+ico('lock',12)+'</span>';return v}
function renderFeat(){var n=0;G.forEach(function(g){n+=g[3].length});
  var h='<div class="fh0 rv"><i class="blob b1"></i><i class="blob b2"></i><i class="blob b3"></i>'+
  '<svg class="sp1" viewBox="0 0 24 24"><path d="M12 1c.6 6 3 9.400 11 11-8 1.600-10.400 5-11 11-.6-6-3-9.400-11-11 8-1.600 10.400-5 11-11z"/></svg><svg class="sp2" viewBox="0 0 24 24"><path d="M12 1c.6 6 3 9.400 11 11-8 1.600-10.400 5-11 11-.6-6-3-9.400-11-11 8-1.600 10.400-5 11-11z"/></svg><svg class="sp3" viewBox="0 0 24 24"><path d="M12 1c.6 6 3 9.400 11 11-8 1.600-10.400 5-11 11-.6-6-3-9.400-11-11 8-1.600 10.400-5 11-11z"/></svg>'+
  '<div class="orb"><svg width="34" height="34" viewBox="0 0 24 24" style="fill:var(--pl-star)"><path d="M12 2c.6 4.900 2.400 8.600 10 10-7.600 1.400-9.400 5.100-10 10-.6-4.900-2.400-8.600-10-10 7.600-1.400 9.400-5.100 10-10z"/></svg></div>'+
  '<h2>VEX Plus</h2><p>تەندروستییەکەت لە یەک شوێن، لەگەڵ AI ـیەک کە تەنها بۆ تۆ کار دەکات</p>'+
  '<div class="hps"><span class="hp"><b>'+n+'</b> تایبەتمەندی</span><span class="hp">AI ی بێسنوور</span><span class="hp">٥٠٪ داشکان</span></div></div>';
  var d=0;G.forEach(function(g){h+='<div class="gh rv" style="--c:'+g[1]+'"><u>'+ico(g[2],17)+'</u>'+g[0]+'<small>'+g[3].length+' تایبەتمەندی</small></div><div class="gr">';
    g[3].forEach(function(f,i){h+='<div class="fc rv" style="--c:'+f[1]+';--d:'+(i%%2*90)+'ms"><span class="ft">'+ico(f[0],23)+'</span><div class="tx"><b>'+f[2]+'</b><span class="d">'+f[3]+'</span></div></div>'});h+='</div>'});
  h+='<div class="gh rv" style="--c:#ffbe4d"><u>'+ico('chart',17)+'</u>بێ بەرامبەر یان Plus؟</div><div class="cmp rv"><div class="cr hd"><div></div><div class="c2">بێ بەرامبەر</div><div class="c3">Plus</div></div>';
  CMP.forEach(function(r){h+='<div class="cr"><div>'+r[0]+'</div><div class="c2">'+cell(r[1],0)+'</div><div class="c3">'+cell(r[2],1)+'</div></div>'});
  h+='</div><div class="cta rv"><b>هەموو ئەمانە بە یەک ئابوونە.</b><br>هەر کاتێک بتەوێت دەتوانیت دەست پێبکەیت.</div>';
  $('fBody').innerHTML=h;var ic='';for(var i=0;i<4;i++)ic+='<span>'+CK+'</span>';$('pIcs').innerHTML=ic}
var io=null;function reveal(){var els=document.querySelectorAll('#fBody .rv');
  if(!('IntersectionObserver' in window)){els.forEach(function(e){e.classList.add('in')});return}
  if(io)io.disconnect();els.forEach(function(e){e.classList.remove('in')});
  io=new IntersectionObserver(function(es){es.forEach(function(x){if(x.isIntersecting){x.target.classList.add('in');io.unobserve(x.target)}})},{threshold:.08});
  setTimeout(function(){els.forEach(function(e){io.observe(e)})},30);setTimeout(function(){els.forEach(function(e){e.classList.add('in')})},2600)}
function animNum(el,to){var from=parseInt((el.textContent||'0').replace(/,/g,''))||to,t0=null;if(from===to){el.textContent=fmt(to);return}
  function f(t){if(!t0)t0=t;var k=Math.min(1,(t-t0)/380),e=1-Math.pow(1-k,3);el.textContent=fmt(Math.round(from+(to-from)*e));if(k<1)requestAnimationFrame(f)}requestAnimationFrame(f)}
''' % js_ic
s=s[:a]+newjs+s[b:]
# renderPlans amount animate
rep("$('bAmt').textContent=fmt(p.price);","animNum($('bAmt'),p.price);")
# show(): reveal on feat
rep("window.scrollTo(0,0);if(id!=='scan')stopT()","window.scrollTo(0,0);if(id!=='scan')stopT();if(id==='feat')reveal()")
# rs classes init
rep("renderPlans();renderMeth();show('pick');\n})();","['pv-pick','pv-ok'].forEach(function(id){var n=0;$(id).querySelectorAll(':scope > *').forEach(function(e){e.classList.add('rs');e.style.setProperty('--i',n++)})});\nrenderPlans();renderMeth();show('pick');\n})();")
# ok benefits
rep('<div style="margin-top:26px"><button class="btn" id="okDone">','<div class="okb"><span>سکانی خواردنی بێسنوور</span><span>VEX AI</span><span>پلانی AI</span><span>ECG و VitalAge</span></div>\n  <div style="margin-top:26px"><button class="btn" id="okDone">')
open(p,'w').write(s)
