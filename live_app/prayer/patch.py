import json,sys
P='/tmp/scr/live/pub_before_ml.html'
s=open(P).read()
T='<script type="application/json" id="pages">'
a=s.find(T)+len(T); b=s.find('</script>',a)
pages=json.loads(s[a:b])
css=open('/tmp/scr/pray/pray_css.css').read(); js=open('/tmp/scr/pray/pray_js.js').read()
card='''
  <section class="vxpr rise" id="vxPr" data-ph="night" role="button" tabindex="0" aria-label="کاتەکانی بانگ" style="animation-delay:.36s"><div class="vxpr-hero"><svg class="vxpr-sky" id="vxPrSky" viewBox="0 0 170 164" preserveAspectRatio="xMidYMid slice" aria-hidden="true"></svg><div class="vxpr-ht"><span class="vxpr-k"><i></i>بانگی داهاتوو</span><b class="vxpr-n" id="vxPrN">—</b><span class="vxpr-t" dir="ltr"><b id="vxPrT">--:--</b><small id="vxPrAp"></small></span><span class="vxpr-cd"><b dir="ltr" id="vxPrCd">0:00</b>ماوە</span></div></div><ul class="vxpr-l" id="vxPrL"></ul></section>'''
h=pages['home']
assert 'id="vxPr"' not in h
anc='</section>\n</div>\n<div class="sheet" id="sheet">'
assert h.count(anc)==1
h=h.replace(anc,'</section>'+card+'\n</div>\n<div class="sheet" id="sheet">')
assert h.count('</head>')==1
h=h.replace('</head>','<style id="vxPrCss">'+css+'</style>\n</head>')
i=h.rfind('</body>'); h=h[:i]+'<script id="vxPrJs">'+js+'</script>\n'+h[i:]
pages['home']=h
p=pages['profile']
o1="function openPray(){const P=AL.pray"
assert p.count(o1)==1
p=p.replace(o1,"let vxOwnPray=false;\nfunction openPray(){try{const A=window.parent&&window.parent.APP,F=A&&A._frames&&A._frames.home;if(F&&F.contentWindow&&F.contentWindow.vxPrayOpen){A.tab('home');setTimeout(()=>{try{F.contentWindow.vxPrayOpen()}catch(e){}},380);return}}catch(e){}vxOwnPray=true;openPrayOld()}\nfunction openPrayOld(){const P=AL.pray")
o2="const alSave=()=>{try{localStorage.setItem(ALK,JSON.stringify(AL))}catch(e){}};"
assert p.count(o2)==1
p=p.replace(o2,"const alSave=()=>{try{const o=JSON.parse(localStorage.getItem(ALK)||'null');if(o){if(o.pray&&!vxOwnPray)AL.pray=o.pray;if(o.fired)AL.fired=Object.assign({},o.fired,AL.fired)}}catch(e){}try{localStorage.setItem(ALK,JSON.stringify(AL))}catch(e){}};")
o3="function tick(){const now=new Date()"
assert p.count(o3)==1
p=p.replace(o3,"function vxHomeEng(){try{const A=window.parent&&window.parent.APP,F=A&&A._frames&&A._frames.home;return!!(F&&F.contentWindow&&F.contentWindow.vxPrayEngine)}catch(e){return false}}\nfunction tick(){if(!vxOwnPray){try{const o=JSON.parse(localStorage.getItem(ALK)||'null');if(o&&o.pray)AL.pray=Object.assign(AL.pray,o.pray)}catch(e){}}const now=new Date()")
o4="if(AL.pray.on){const t=pTimes(now),lead"
assert p.count(o4)==1
p=p.replace(o4,"if(AL.pray.on&&!vxHomeEng()){const t=pTimes(now),lead")
pages['profile']=p
d=json.dumps(pages,ensure_ascii=False).replace('</','<\\/').replace('<!--','\\u003c!--')
s=s[:a]+d+s[b:]
open(P,'w').write(s); print('ok')
