import json
s=open('/tmp/scr/live/index.html',encoding='utf8').read()
tag='<script type="application/json" id="pages">'
a=s.index(tag); st=a+len(tag); en=s.index('</script>',st)
P=json.loads(s[st:en])
pr=P['profile']
anchor='<div class="grp rise" id="apGrp"'
assert pr.count(anchor)==1
card='''<button class="plc rise" id="plusCard" type="button" aria-label="VEX Plus" style="animation-delay:.08s"><span class="pli"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2c.6 4.900 2.400 8.600 10 10-7.600 1.400-9.400 5.100-10 10-.6-4.900-2.400-8.600-10-10 7.600-1.400 9.400-5.100 10-10z"/></svg></span><span class="plt"><b class="num">VEX Plus</b><small id="plSub">٥٠٪ داشکان · ٣ شێوازی پارەدان</small></span><span class="plg" id="plGo">بەشداربوون<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 6l-6 6 6 6"/></svg></span></button>
 '''
pr=pr.replace(anchor,card+anchor,1)
css='''<style id="vxPlusCss">
.plc{display:flex;align-items:center;gap:14px;width:100%;margin-top:14px;padding:14px 16px;border-radius:24px;text-align:right;cursor:pointer;color:var(--pl-t);background:var(--pl-bg);border:1.5px solid var(--pl-bd);font-family:inherit}
.plc .pli{width:52px;height:52px;border-radius:16px;background:var(--pl-ib);display:flex;align-items:center;justify-content:center;flex:none}
.plc .pli svg{width:26px;height:26px;fill:var(--pl-star)}
.plc .plt{flex:1;min-width:0;display:flex;flex-direction:column;gap:2px}
.plc .plt b{font-size:18px;font-weight:800;text-align:right}
.plc .plt small{font-size:12.5px;font-weight:600;color:var(--pl-s)}
.plc .plg{display:flex;align-items:center;gap:2px;font-weight:800;font-size:12.5px;color:var(--pl-t)}
.plc .plg svg{width:16px;height:16px;fill:none;stroke:currentColor;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}
:root{--pl-bg:linear-gradient(100deg,rgba(255,190,77,.2),rgba(255,190,77,.06));--pl-bd:rgba(255,190,77,.5);--pl-t:#ffe29a;--pl-s:#e8cf92;--pl-ib:linear-gradient(135deg,#ffe29a,#ffbf47 60%,#ff9d3d);--pl-star:#4a2c00}
:root[data-theme="light"]{--pl-bg:linear-gradient(100deg,#ffe7a3,#ffc857);--pl-bd:#d9a23c;--pl-t:#3b2500;--pl-s:#5e3a00;--pl-ib:#3b2500;--pl-star:#ffd36b}
</style>
'''
assert pr.count('</head>')==1
pr=pr.replace('</head>',css+'</head>',1)
js='''<script>
(function(){
function rd(){try{return JSON.parse(localStorage.getItem('vexsub-plus')||'null')}catch(e){return null}}
function paint(){var p=rd(),sub=document.getElementById('plSub'),go=document.getElementById('plGo');if(!sub||!go)return;var on=p&&p.plan==='plus'&&p.until>Date.now();
  sub.textContent=on?'چالاکە · تا '+(p.text||new Date(p.until).toLocaleDateString('en-GB')):'٥٠٪ داشکان · ٣ شێوازی پارەدان';
  go.firstChild.textContent=on?'درێژکردنەوە':'بەشداربوون'}
var b=document.getElementById('plusCard');
if(b)b.addEventListener('click',function(){try{APP.go('plus');setTimeout(function(){try{var f=APP._scrs.plus.querySelector('iframe');f.contentWindow.plusReset&&f.contentWindow.plusReset()}catch(e){}},0)}catch(e){}});
var r0=window.refresh;window.refresh=function(){try{r0&&r0.apply(this,arguments)}catch(e){}paint()};
paint();
})();
</script>
'''
assert pr.count('</body>')==1
pr=pr.replace('</body>',js+'</body>',1)
P['profile']=pr
P['plus']=open('/tmp/scr/live/build/plus_doc.html',encoding='utf8').read()
raw=json.dumps(P,ensure_ascii=False,separators=(', ',': '))
raw=raw.replace('</','<\\/').replace('<!--','\\u003c!--')
assert json.loads(raw)==P
open('/tmp/scr/live/index.new.html','w',encoding='utf8').write(s[:st]+raw+s[en:])
print('ok')
