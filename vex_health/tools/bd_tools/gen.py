# -*- coding: utf-8 -*-
import re,sys,json
sys.path.insert(0,'/tmp/scr/fl/bd')
import add1,add2
src='/tmp/scr/fl/out/proj/lib/core/vx_bd_data.dart'
d=open(src,encoding='utf8').read()
def entries(name):
    i=d.index('const Map<String, String> '+name); j=d.index('\n};',i)
    return dict(re.findall(r'^\s*"((?:[^"\\]|\\.)*)":\s*"((?:[^"\\]|\\.)*)",?\s*$',d[i:j],re.M))
def dec(t):
    import re as _r
    return _r.sub(r'\\(.)',lambda m:{'n':'\n','t':'\t'}.get(m.group(1),m.group(1)),t)
dic=entries('kBdDict'); lit=entries('kBdLit'); food=entries('kBdFood')
dic={dec(k):dec(v) for k,v in dic.items()}; lit={dec(k):dec(v) for k,v in lit.items()}; food={dec(k):dec(v) for k,v in food.items()}
i=d.index('const List<List<String>> kBdTpl'); j=d.index('\n];',i)
tpl=[(dec(a),dec(b)) for a,b in re.findall(r'\[\s*"((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\s*\]',d[i:j])]
ARC=re.compile(r'^[ء-يٱ-ۓە۰-۹‌]+(?: [ء-يٱ-ۓە۰-۹‌]+)*$')
def fix(v):
    v=v.replace('هاوکاتکرن','هەڤدەمکرن').replace('هاوکات','هەڤدەم')
    v=re.sub(r'(?<![ء-ي])زۆرترین(?![ء-ي])','گەلەکترین',v)
    v=re.sub(r'(?<![ء-ي])زۆرتر(?![ء-ي])','گەلەکتر',v)
    v=re.sub(r'(?<![ء-ي])زۆر(?![ء-ي])','گەلەک',v)
    v=re.sub(r'(?<![ء-ي])دووبارە(?![ء-ي])','جارەکا دی',v)
    return v
def esc(s): return s.replace('\\','\\\\').replace('"','\\"').replace('$','\\$').replace('\n','\\n')
def unesc(s): return s
# تێکەڵ کردن
for k,v in list(dic.items()): dic[k]=fix(v)
for k,v in list(lit.items()): lit[k]=fix(v)
tpl=[(k,fix(v)) for k,v in tpl]
added=0
for src_d in (add1.D, add2.D2):
    for k,v in src_d.items():
        v=fix(v)
        if k==v: continue
        if ARC.match(k): 
            if dic.get(k)!=v: dic[k]=v; added+=1
        else:
            if lit.get(k)!=v: lit[k]=v; added+=1
# قاڵب: تەنها ئەوانەی دەقی تایبەتیان هەیە
def distinct(k):
    t=re.sub(r'\{\d+\}','',k); t=re.sub(r'[\s\W\d_]','',t)
    return len(t)>=8
have={k for k,_ in tpl}
nt=0
for k,v in add1.T if hasattr(add1,'T') else []: pass
for k,v in add2.T:
    if not distinct(k) or k in have: continue
    tpl.insert(0,(k,v)); nt+=1
print('added',added,'tpl',nt,'total dict',len(dic),'lit',len(lit),'tpl',len(tpl))
def dump_map(name,m):
    return 'const Map<String, String> %s = {\n'%name+''.join('  "%s": "%s",\n'%(esc(k),esc(v)) for k,v in sorted(m.items()))+'};\n'
out='// VEX Health — داتای وەرگێڕانی کوردی بادینی (v2: چاککرا + تەواوکرا)\n// ignore_for_file: prefer_single_quotes, unnecessary_string_escapes\n\n'
out+='/// وشە و ڕستەی کورتی سۆرانی ← بادینی\n'+dump_map('kBdDict',dic)+'\n'
out+='/// دەقی تەواو (ئیمۆجی، ژمارە…) ← بادینی\n'+dump_map('kBdLit',lit)+'\n'
out+='/// قاڵبەکان ({0} {1} … = بەشی گۆڕاو)\nconst List<List<String>> kBdTpl = [\n'+''.join('  ["%s", "%s"],\n'%(esc(k),esc(v)) for k,v in tpl)+'];\n\n'
out+='/// ناوی خواردن\n'+dump_map('kBdFood',food)+'\n'
W=dict(add2.W)
out+='/// وشە بە وشە (بۆ ئەو دەقانەی لە فەرهەنگی ڕستەکاندا نین)\n'+dump_map('kBdWord',{k:v for k,v in W.items() if k!=v})
open('/tmp/scr/fl/bd/vx_bd_data.dart','w',encoding='utf8').write(out)
