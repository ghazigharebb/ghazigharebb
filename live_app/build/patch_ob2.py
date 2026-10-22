p='/tmp/scr/live/index.html'
s=open(p,encoding='utf8').read()
def rep(a,b,cnt=1):
    global s
    assert s.count(a)==cnt,(s.count(a),a[:80])
    s=s.replace(a,b)
RUN='<span class="e ix" style="--a:#ffbe4d"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="15.4" cy="4.6" r="1.9"/><path d="M13.9 8.2L11.6 13M13.7 9.2l3 1.7 2.5-1.4M13.4 9.4l-3 .7-2.4 2.5M11.6 13l3.5 2.2-.9 5M11.6 13l-2.4 4.2-3.6.3"/></svg></span>'
rep("['light','🚶','سووک','پیاسە و کاری ڕۆژانەی ئاسایی'],['active','🏃','چالاک',","['light','🚶','کەم چالاک','پیاسە و کاری ڕۆژانەی ئاسایی'],['active','"+RUN+"','چالاک',")
rep("${ei(e)}<div><b>${t}</b>${s?`<small>${s}</small>`:''}</div><span class=\"ck\">✓</span></button>`;","${e.charAt(0)==='<'?e:ei(e)}<div><b>${t}</b>${s?`<small>${s}</small>`:''}</div><span class=\"ck\">✓</span></button>`;")
rep('"کەم جووڵە"','"کەم جووڵە"',s.count('"کەم جووڵە"')) if False else None
# translation dict entry
if '"کەم چالاک"' not in s:
    rep('"ـیت":"",','"ـیت":"","کەم چالاک":"Lightly active",')
# ring fix: no clipping filter; glow ring
rep('.vo-pr svg{width:100%;height:100%;transform:rotate(-90deg)}','.vo-pr svg{width:100%;height:100%;transform:rotate(-90deg);overflow:visible}')
rep('stroke-dasharray:0 302;filter:drop-shadow(0 0 8px rgba(60,240,138,.7))}','stroke-dasharray:0 302}\n.vo-pr .g{fill:none;stroke:#3cf08a;stroke-width:13;stroke-linecap:round;stroke-dasharray:0 302;opacity:.16}')
rep('<circle class="t" cx="55" cy="55" r="48"/><circle class="p" id="bPr" cx="55" cy="55" r="48"/>','<circle class="t" cx="55" cy="55" r="48"/><circle class="g" id="bPg" cx="55" cy="55" r="48"/><circle class="p" id="bPr" cx="55" cy="55" r="48"/>')
rep("pr.style.strokeDasharray=`${(e*301.6).toFixed(1)} 302`;","{const da=`${(e*301.6).toFixed(1)} 302`;pr.style.strokeDasharray=da;const pg=$('bPg');if(pg)pg.style.strokeDasharray=da}")
open(p,'w',encoding='utf8').write(s)
print('ok')
