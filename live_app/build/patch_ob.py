p='/tmp/scr/live/index.html'
s=open(p,encoding='utf8').read()
def rep(a,b,cnt=1):
    global s
    assert s.count(a)==cnt,(s.count(a),a[:80])
    s=s.replace(a,b)

G_SVG='<svg viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>'
GM_SVG='<svg viewBox="0 0 48 48" aria-hidden="true"><path fill="#4caf50" d="M45 16.2l-5 2.75-5 4.75V40h7c1.66 0 3-1.34 3-3V16.2z"/><path fill="#1e88e5" d="M3 16.2l3.61 1.97 6.39 5.53V40H6c-1.66 0-3-1.34-3-3V16.2z"/><polygon fill="#e53935" points="35,11.2 24,19.45 13,11.2 12,17 13,23.7 24,31.95 35,23.7 36,17"/><path fill="#c62828" d="M3 12.3v3.9l10 7.5V11.2L9.87 8.86C6.97 6.69 3 8.76 3 12.3z"/><path fill="#fbc02d" d="M45 12.3v3.9l-10 7.5V11.2l3.13-2.34C41.03 6.69 45 8.76 45 12.3z"/></svg>'

# 1) phone step: Gmail button
rep('''<span>ژمارەکەت بۆ هیچ کەسێک دەرناکەوێت و تەنها بۆ چوونە ژوورەوە و پاراستنی هەژمارەکەت بەکاردێت.</span></div>`,''',
 '''<span>ژمارەکەت بۆ هیچ کەسێک دەرناکەوێت و تەنها بۆ چوونە ژوورەوە و پاراستنی هەژمارەکەت بەکاردێت.</span></div>
   <div class="vo-or"><span>یان</span></div><button class="vo-gm" id="fGm" type="button"><i>'''+G_SVG+'''</i><span>بەردەوامبە لەگەڵ Gmail</span></button>`,''')
rep("i.oninput=up;up();i.onkeydown=e=>{if(e.key==='Enter')$('voGo').click()};focusSoon(i)},",
    "i.oninput=up;up();i.onkeydown=e=>{if(e.key==='Enter')$('voGo').click()};$('fGm').onclick=openGm;focusSoon(i)},")
# gmail sheet logic before sendCode
rep("function sendCode(){busy=true;",
'''function openGm(){if(busy||document.getElementById('gmSh'))return;vib(8);
 const sh=document.createElement('div');sh.id='gmSh';sh.className='gm-sh';
 sh.innerHTML=`<div class="gm-bd"></div><div class="gm-c" role="dialog" aria-modal="true"><span class="gm-grip"></span><div class="gm-ic">'''+GM_SVG+'''</div><h3>چوونە ژوورەوە بە Gmail</h3><p>هەژماری Gmail ـەکەت بنووسە و بێ ژمارەی مۆبایل دەست پێبکە.</p>
  <input class="vo-in gm-in" id="gmIn" type="email" dir="ltr" inputmode="email" autocomplete="email" placeholder="name@gmail.com" autocapitalize="off" spellcheck="false"><p class="vo-err gm-err" id="gmErr"></p>
  <button class="vo-go" id="gmGo" type="button">بەردەوامبە</button><button class="vo-link" id="gmX" type="button">پاشگەزبوونەوە</button>
  <small class="gm-n">دیمۆ: لە وەشانی ڕاستەقینەدا پەنجەرەی هەڵبژاردنی هەژماری Google دەکرێتەوە.</small></div>`;
 document.body.appendChild(sh);requestAnimationFrame(()=>sh.classList.add('on'));
 const close=()=>{sh.classList.remove('on');setTimeout(()=>sh.remove(),260)};
 const ok=v=>/^[a-z0-9._%+\\-]+@(gmail|googlemail)\\.com$/i.test(v.trim());
 const inp=sh.querySelector('#gmIn'),err=sh.querySelector('#gmErr'),go=sh.querySelector('#gmGo');
 const submit=()=>{const v=inp.value.trim();if(!ok(v)){err.textContent='ئیمەیڵێکی Gmail ی دروست بنووسە، بۆ نموونە name@gmail.com';inp.classList.add('bad');vib([30,40,30]);return}
  go.disabled=true;go.innerHTML='<span class="sp"></span>پشکنین…';
  setTimeout(()=>{D.email=v.toLowerCase();D.auth='gmail';D.phone='';verified=true;vib(12);close();setTimeout(()=>{if(cur==='phone')next()},180)},650)};
 inp.oninput=()=>{err.textContent='';inp.classList.remove('bad')};inp.onkeydown=e=>{if(e.key==='Enter')submit()};
 go.onclick=submit;sh.querySelector('#gmX').onclick=close;sh.querySelector('.gm-bd').onclick=close;setTimeout(()=>{try{inp.focus()}catch(e){}},320)}
function sendCode(){busy=true;''')
# save email in profile
rep("const u={name:D.name.trim().slice(0,30),phone:D.phone,","const u={name:D.name.trim().slice(0,30),phone:D.phone,email:D.email||'',auth:D.auth||'phone',")
# CSS
css='''
.vo-or{display:flex;align-items:center;gap:12px;margin:18px 2px 12px;color:#7fa6ae;font-size:12.5px;font-weight:700}
.vo-or:before,.vo-or:after{content:"";flex:1;height:1px;background:rgba(140,235,245,.14)}
.vo-gm{display:flex;align-items:center;justify-content:center;gap:12px;width:100%;height:54px;border-radius:18px;border:1px solid rgba(255,255,255,.7);background:linear-gradient(180deg,#fff,#eef4f6);color:#1f2a2e;font:800 15.5px "Noto Sans Arabic",Sora,sans-serif;cursor:pointer;box-shadow:0 10px 26px -14px rgba(0,0,0,.7),inset 0 -2px 0 rgba(0,0,0,.05);transition:transform .15s,box-shadow .2s}
.vo-gm:active{transform:scale(.975)}
.vo-gm i{display:grid;place-items:center;width:26px;height:26px;flex:none}.vo-gm svg{width:24px;height:24px}
:root[data-theme="light"] .vo-gm{border-color:rgba(6,40,50,.14);background:#fff}
.gm-sh{position:fixed;inset:0;z-index:9000;display:flex;align-items:flex-end;justify-content:center;pointer-events:none}
.gm-sh.on{pointer-events:auto}
.gm-bd{position:absolute;inset:0;background:rgba(2,12,16,.62);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);opacity:0;transition:opacity .25s}
.gm-sh.on .gm-bd{opacity:1}
.gm-c{position:relative;width:100%;max-width:480px;padding:10px 20px calc(20px + env(safe-area-inset-bottom,0px));border-radius:28px 28px 0 0;background:linear-gradient(180deg,#0b3340,#06222c);border:1px solid rgba(140,235,245,.16);border-bottom:0;color:#effeff;text-align:center;transform:translateY(105%);transition:transform .38s cubic-bezier(.2,.9,.25,1);box-shadow:0 -20px 60px rgba(0,0,0,.5)}
.gm-sh.on .gm-c{transform:none}
:root[data-theme="light"] .gm-c{background:linear-gradient(180deg,#fff,#eef7fa);color:#062832;border-color:rgba(6,40,50,.1)}
.gm-grip{display:block;width:42px;height:5px;border-radius:9px;background:rgba(140,235,245,.25);margin:2px auto 14px}
.gm-ic{width:66px;height:66px;margin:0 auto 10px;border-radius:22px;background:#fff;display:grid;place-items:center;box-shadow:0 14px 30px -12px rgba(229,57,53,.55)}.gm-ic svg{width:40px;height:40px}
.gm-c h3{margin:0 0 4px;font-size:19px;font-weight:800}.gm-c>p{margin:0 0 14px;font-size:13px;color:#8cb7bf;line-height:1.8}
.gm-in{text-align:left;width:100%;margin-bottom:4px}.gm-in.bad{border-color:#ff5f7e!important}
.gm-err{min-height:20px;margin:2px 0 8px;text-align:right}
.gm-c .vo-go{width:100%}.gm-c .vo-link{display:block;margin:8px auto 0}
.gm-n{display:block;margin-top:12px;font-size:11px;color:#6f969d;line-height:1.7}
'''
anchor=".vo-lock{align-items:center}.vo-lock .e.ix{width:34px;height:34px;border-radius:12px;flex:none}"
rep(anchor,anchor+css)
open(p,'w',encoding='utf8').write(s)
print('ok')
