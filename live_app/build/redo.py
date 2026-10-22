import re
p='plus_doc.html'; s=open(p).read()
a=s.index('<div class="pv" id="pv-pick">'); b=s.index('<div class="pv" id="pv-feat" hidden>')
old=s[a:b]
m=re.findall(r'<button class="pm m-(?:fib|qi|fp)".*?</button>',old,re.S); assert len(m)==3
pick='''<div class="pv" id="pv-pick">
  <div class="ph"><button class="ib" id="pBack" aria-label="گەڕانەوە"><svg class="i" width="21" height="21" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg></button><b class="ttl"><svg width="18" height="18" viewBox="0 0 24 24" style="fill:var(--amber)" aria-hidden="true"><path d="M12 2c.6 4.900 2.400 8.600 10 10-7.600 1.400-9.400 5.100-10 10-.6-4.900-2.400-8.600-10-10 7.600-1.400 9.400-5.100 10-10z"/></svg><span class="num">VEX Plus</span></b><span style="width:38px"></span></div>
  <div class="sec"><b>ماوەی ئابوونە</b></div>
  <div class="pseg" id="pPlans" role="radiogroup" aria-label="ماوە"></div>
  <div class="psub"><i>٥٠٪ داشکان</i><span id="pSub"></span></div>
  <div class="sec"><b>شێوازی پارەدان</b></div>
  <div class="mlist" role="radiogroup" aria-label="شێوازی پارەدان">
  '''+"\n  ".join(m)+'''
  </div>
  <button class="fr" id="pFeat"><span class="ics" id="pIcs"></span><b>ئەوەی بە Plus وەریدەگریت</b><svg class="i" width="18" height="18" viewBox="0 0 24 24" style="color:var(--mu)"><path d="M15 6l-6 6 6 6"/></svg></button>
  <div class="lk"><svg class="i" width="13" height="13" viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 018 0v3"/></svg>پارەدانەکە لەناو ئەپی شێوازەکە تەواو دەبێت</div>
</div>
'''
s=s[:a]+pick+s[b:]
a=s.index('<div class="pbar" id="pbar">'); b=s.index('<script>(function(){',a)
bar='''<div class="pbar" id="pbar"><div class="brow">
  <div class="btot"><span class="mu" style="font-size:11.5px;font-weight:600">کۆی گشتی</span><span style="direction:ltr;display:inline-flex;align-items:baseline;gap:4px"><b id="bAmt" class="num" style="font-size:21px;font-weight:800"></b><span class="mu" style="font-size:11px;font-weight:700">IQD</span></span></div>
  <button class="pay" id="pPay"><img id="pPayLg" alt=""><span id="pPayT"></span></button>
</div></div>
'''
s=s[:a]+bar+s[b:]
css=open('css_add.txt').read()
s=s.replace('</style>',css+'</style>',1)
a=s.index('function renderPlans(){'); b=s.index('function renderMeth(){')
rp='''function renderPlans(){var h='';P.forEach(function(p){h+='<button class="pp'+(p.k===st.plan?' on':'')+'" role="radio" aria-checked="'+(p.k===st.plan)+'" data-pl="'+p.k+'">'+(p.b?'<i>'+p.b+'</i>':'')+'<span>'+p.n+'</span><span class="n">'+fmt(p.price)+'</span><s>'+fmt(p.old)+'</s></button>'});
  $('pPlans').innerHTML=h;var p=cur();$('pSub').textContent=p.sub;$('bAmt').textContent=fmt(p.price);
  $('pPlans').querySelectorAll('.pp').forEach(function(b){b.addEventListener('click',function(){st.plan=b.dataset.pl;renderPlans()})})}
'''
s=s[:a]+rp+s[b:]
open(p,'w').write(s)
