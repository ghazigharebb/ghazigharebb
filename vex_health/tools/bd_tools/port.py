# -*- coding: utf-8 -*-
# پۆرتی Python ی vx_bd.dart بۆ تێست
import re
d=open('/tmp/scr/fl/bd/vx_bd_data.dart',encoding='utf8').read()
def dec(t): return re.sub(r'\\(.)',lambda m:{'n':'\n'}.get(m.group(1),m.group(1)),t)
def M(name):
    i=d.index('const Map<String, String> '+name); j=d.index('\n};',i)
    return {dec(k):dec(v) for k,v in re.findall(r'^\s*"((?:[^"\\]|\\.)*)":\s*"((?:[^"\\]|\\.)*)",?\s*$',d[i:j],re.M)}
Dict,Lit,Food,Word=M('kBdDict'),M('kBdLit'),M('kBdFood'),M('kBdWord')
i=d.index('const List<List<String>> kBdTpl'); j=d.index('\n];',i)
Tpl=[(dec(a),dec(b)) for a,b in re.findall(r'\[\s*"((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\s*\]',d[i:j])]
AR='ء-يٱ-ۓە۰-۹‌'
has=re.compile('[؀-ۿ‌]'); run=re.compile('[%s]+(?: [%s]+)*'%(AR,AR))
dayo=re.compile('(\\d)ی(?![%s])'%AR); daym=re.compile('(\\d)ی(?= [%s])'%AR)
tp=[]
for k,v in Tpl:
    b='^';last=0
    for m in re.finditer(r'\{(\d+)\}',k):
        b+=re.escape(k[last:m.start()])+'(.*?)';last=m.end()
    b+=re.escape(k[last:])+'$'; tp.append((re.compile(b,re.S),v))
SFX=[['ەکانی','ێن'],['ەکان',''],['ەکەی','ێ'],['ەکە',''],['یەکان',''],['یان','ان'],['یەک','ەک'],['ێک','ەک'],['ی','ێ']]
miss=set()
def word(w):
    if w in Word: return Word[w]
    for a,b in SFX:
        if len(w)>len(a)+1 and w.endswith(a):
            st=w[:-len(a)]; s=Word.get(st) or Food.get(st) or Dict.get(st)
            if s: return s+b
    x=w
    if x.endswith('کردنەوە'): x=x[:-7]+'کرنەڤە'
    elif x.endswith('کردنی'): x=x[:-5]+'کرنا'
    elif x.endswith('کردن'): x=x[:-4]+'کرن'
    elif x.endswith('ەوە') and len(x)>5: x=x[:-3]+'ەڤە'
    if len(x)>5 and x.startswith('دە') and (x.endswith('ات') or x.endswith('ێت') or x.endswith('یت')): x='د'+x[2:]
    if x==w: miss.add(w)
    return x
def seg(m):
    if m in Dict: return Dict[m]
    w=m.split(' ');n=len(w)
    if n==1: return Food.get(m) or word(m)
    out=[];i=0
    while i<n:
        hit=False
        for j in range(n,i,-1):
            dd=Dict.get(' '.join(w[i:j]))
            if dd is not None: out.append(dd);i=j;hit=True;break
        if not hit: out.append(word(w[i]));i+=1
    return ' '.join(x for x in out if x)
def conv(s):
    if s in Food: return Food[s]
    if s in Lit: return Lit[s]
    r=s
    for rx,v in tp:
        m=rx.match(r)
        if m:
            r=re.sub(r'\{(\d+)\}',lambda x:m.group(int(x.group(1))+1) or '',v);break
    r=daym.sub(lambda m:m.group(1)+'ێ',r); r=dayo.sub(lambda m:m.group(1),r)
    return run.sub(lambda m:seg(m.group(0)),r)
def tr(s): return conv(s) if s and has.search(s) else s
