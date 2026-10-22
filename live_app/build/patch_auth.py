p='/tmp/scr/live/index.html'
s=open(p,encoding='utf8').read()
def rep(a,b,cnt=1):
    global s
    assert s.count(a)==cnt,(s.count(a),a[:90])
    s=s.replace(a,b)
GM=open('/tmp/scr/live/build/patch_ob.py').read().split("GM_SVG='")[1].split("'\n")[0]

# DEF
rep("const DEF=()=>({mode:'new',name:'',phone:'',","const DEF=()=>({mode:'new',name:'',phone:'',auth:'',email:'',")
# seq
old="function seq(){const a=D.mode==='login'?['lang','welcome','phone','otp','name']:['lang','welcome','name','phone','otp'];"
rep(old,"function seq(){const au=D.auth==='gmail'?['gmail']:['phone','otp'];const a=D.mode==='login'?['lang','welcome','method'].concat(au,['name']):['lang','welcome','name','method'].concat(au);")
# vault: key by phone or email
rep("function stash(){const u=get();if(!u||!u.phone)return;const v=lsGet(VAULT,{});v[u.phone]={snap:snap(),name:u.name||'',at:Date.now()};lsSet(VAULT,v)}",
    "function stash(){const u=get();const id=u&&(u.phone||u.email);if(!id)return;const v=lsGet(VAULT,{});v[id]={snap:snap(),name:u.name||'',email:u.email||'',phone:u.phone||'',at:Date.now()};lsSet(VAULT,v)}\ntry{setInterval(()=>{try{stash()}catch(e){}},45000);addEventListener('pagehide',()=>{try{stash()}catch(e){}});document.addEventListener('visibilitychange',()=>{if(document.hidden){try{stash()}catch(e){}}})}catch(e){}")
# phone step: remove gmail button, add switch link
i=s.index('<div class="vo-or"><span>یان</span></div><button class="vo-gm" id="fGm"')
j=s.index('</button>',i)+len('</button>')
s=s[:i]+'<button class="vo-link" id="fSw" type="button">هەژماری Gmail بەکاربهێنە</button>'+s[j:]
rep("$('fGm').onclick=openGm;focusSoon(i)},","$('fSw').onclick=()=>{D.auth='gmail';go('gmail')};focusSoon(i)},")
# openGm: submit -> gmLogin
a=s.index("go.disabled=true;go.innerHTML='<span class=\"sp\"></span>پشکنین…';\n  setTimeout(()=>{D.email=v.toLowerCase()")
b=s.index("\n",s.index("},650)};",a))
s=s[:a]+"go.disabled=true;go.innerHTML='<span class=\"sp\"></span>پشکنین…';\n  setTimeout(()=>{close();setTimeout(()=>gmLogin(v),120)},450)};"+s[b:]
# gmail helpers before openGm
rep("function openGm(){","""const GML='vxgmails';
function rememberGm(e,n){const L=lsGet(GML,[]).filter(x=>x.e!==e);L.unshift({e,n:n||'',at:Date.now()});lsSet(GML,L.slice(0,8))}
function gmList(){const seen={},out=[];const add=(e,n,has,at)=>{e=(e||'').toLowerCase();if(!e||seen[e])return;seen[e]=1;out.push({e,n:n||'',has,at:at||0})};
 const V=lsGet(VAULT,{});Object.keys(V).forEach(k=>{const a=V[k];if(a&&a.email)add(a.email,a.name,!!(a.snap&&a.snap[KEY]),a.at)});
 const u=get();if(u&&u.email)add(u.email,u.name,true,Date.now());
 lsGet(GML,[]).forEach(x=>add(x.e,x.n,!!account(x.e),x.at));return out.sort((a,b)=>b.at-a.at)}
function gmLogin(e){e=String(e).toLowerCase();if(busy)return;rememberGm(e,D.name);D.email=e;D.auth='gmail';D.phone='';
 busy=true;const b=$('voGo');b.disabled=true;b.innerHTML='<span class="sp"></span>پشکنین…';
 setTimeout(()=>{verified=true;vib(12);const hold=t=>{busy=true;b.disabled=true;b.innerHTML='<span class="sp"></span>'+t};
  const acc=account(e);
  if(acc){hold('داتاکانت دەگەڕێنرێنەوە…');restoreAccount(acc).then(()=>{busy=false;const ru=get();if(ru&&ru.name){rememberGm(e,ru.name);welcomeBack(ru)}else next()});return}
  const u=get();if(u&&u.email===e&&u.name&&u.h){hold('هەژمارەکەت دەکرێتەوە…');settle().then(()=>{busy=false;welcomeBack(u)});return}
  busy=false;paintGo();next()},500)}
function openGm(){""")
# new steps: insert before ' phone:{ic:'
rep(" phone:{ic:'📱',",""" method:{ic:'🔒',t:()=>'چۆن دەتەوێت بچیتە ژوورەوە؟',p:()=>'یەکێک لەم دوو شێوازە هەڵبژێرە. هەر کاتێک بگەڕێیتەوە، داتاکانت و Band ـەکەت وەک خۆیان دەمێننەوە.',
  html:()=>`<div class="vo-opts am">${opt('phone','📱','ژمارەی مۆبایل','کۆدێکی 6 ژمارەیی بە SMS دێت',D.auth==='phone')}${opt('gmail','<span class="e ix am-gm">"""+GM+"""</span>','Gmail','بە هەژماری Google ـەکەت',D.auth==='gmail')}</div><div class="vo-lock">${ei('🔒')}<span>هەر هەژمارێک داتای خۆی هەیە: خواردن، تەندروستی، Band و Plus. دوای چوونە دەرەوەش لە کاتی گەڕانەوە هەمووی دەگەڕێتەوە.</span></div>`,
  bind:m=>m.querySelectorAll('[data-v]').forEach(b=>b.onclick=()=>{D.auth=b.dataset.v;mark(m,b);vib(8);paintGo()}),ok:()=>!!D.auth},
 gmail:{ic:'✉️',t:()=>'هەژماری Gmail ـەکەت',p:()=>'هەژمارێک هەڵبژێرە یان Gmail ێکی نوێ زیاد بکە.',cta:'زیادکردنی Gmail',
  html:()=>{const L=gmList();return `<div class="gm-l">${L.map(a=>`<button class="gm-a" data-e="${esc(a.e)}" type="button"><span class="gm-av">${esc((a.n||a.e).trim().charAt(0).toUpperCase())}</span><div><b>${esc(a.n||a.e.split('@')[0])}</b><small dir="ltr">${esc(a.e)}</small></div>${a.has?'<span class="gm-tag">داتای هەیە</span>':''}<span class="gm-ar">‹</span></button>`).join('')}<button class="gm-a add" id="gmAdd" type="button"><span class="gm-av plus">+</span><div><b>Gmail ێکی تر زیاد بکە</b><small>هەژماری Google ـی تر</small></div></button></div><button class="vo-link" id="gmPh" type="button">ژمارەی مۆبایل بەکاربهێنە</button>`},
  bind:m=>{m.querySelectorAll('[data-e]').forEach(b=>b.onclick=()=>gmLogin(b.dataset.e));$('gmAdd').onclick=openGm;$('gmPh').onclick=()=>{D.auth='phone';go('phone')}},
  ok:()=>true,go:()=>openGm()},
 phone:{ic:'📱',""")
# CSS
css='''
.vo-opt.am{padding:16px}.vo-opt.am b{font-size:16.5px}.vo-opt.am small{font-size:12.5px}
.am-gm{background:#fff!important}.am-gm svg{width:30px!important;height:30px!important}
.gm-l{display:flex;flex-direction:column;gap:10px}
.gm-a{display:flex;align-items:center;gap:12px;width:100%;padding:12px 14px;border-radius:20px;border:1.5px solid rgba(140,235,245,.14);background:linear-gradient(135deg,rgba(255,255,255,.055),rgba(255,255,255,.02));color:#effeff;text-align:start;cursor:pointer;font-family:inherit;transition:transform .15s,border-color .2s}
.gm-a:active{transform:scale(.975)}.gm-a:hover{border-color:rgba(60,240,138,.5)}
.gm-a>div{flex:1;min-width:0}.gm-a b{display:block;font-size:15px;font-weight:800;line-height:1.5;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.gm-a small{display:block;font-size:12px;color:#8cb7bf;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.gm-av{flex:none;width:44px;height:44px;border-radius:50%;display:grid;place-items:center;font:800 18px Sora,sans-serif;color:#032a31;background:linear-gradient(135deg,#8ff3f9,#3cf08a)}
.gm-av.plus{background:rgba(255,255,255,.07);color:#8ff3f9;border:1.5px dashed rgba(140,235,245,.4);font-size:24px;font-weight:600}
.gm-tag{flex:none;padding:2px 9px;border-radius:99px;background:rgba(60,240,138,.16);color:#3cf08a;font-size:11px;font-weight:800}
.gm-ar{flex:none;color:#7fa6ae;font-size:22px}
.gm-a.add{border-style:dashed}
:root[data-theme="light"] .gm-a{color:#062832;background:#fff;border-color:rgba(6,40,50,.1)}
'''
anchor=".vo-lock{align-items:center}.vo-lock .e.ix{width:34px;height:34px;border-radius:12px;flex:none}"
rep(anchor,anchor+css)
open(p,'w',encoding='utf8').write(s)
print('ok')
