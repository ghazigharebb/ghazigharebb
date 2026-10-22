def le(v,i,n): return sum((v[i+k] if i+k<len(v) else 0)<<(8*k) for k in range(n))
def u(v,i): return v[i] if i<len(v) else 0
h=lambda b:'%02x'%b
def dt(v,o): return '20%s.%s.%s %s:%s:%s'%tuple(h(u(v,o+k)) for k in range(6))
def parse(v):
    c=v[0]
    if c==0x13: return dict(battery=u(v,1),charge=u(v,2),mv=u(v,3)+(u(v,4)<<8))
    if c==0x27: return dict(version='.'.join('%X'%u(v,i) for i in range(1,5)))
    if c==0x09: return dict(steps=le(v,1,4),kcal=le(v,5,4)/100,km=le(v,9,4)/100,minutes=le(v,13,4)//60,act=le(v,17,4),hr=u(v,21),temp=round((u(v,22)+(u(v,23)<<8))*.1,1),spo2=u(v,24))
    if c==0x51:
        L=len(v);n=27
        if L!=2:
            n=26 if L%26==0 else 27 if L%27==0 else 26 if (L-2)%26==0 else 27 if (L-2)%27==0 else 27
        o=0;goal=u(v,21+o) if n==26 else u(v,21+o)+(u(v,22+o)<<8)
        return dict(date='20%s.%s.%s'%(h(v[2]),h(v[3]),h(v[4])),steps=le(v,5,4),minutes=le(v,9,4),km=le(v,13,4)/100,kcal=le(v,17,4)/100,goal=goal)
    if c in(0x55,0x66): return dict(date=dt(v,3),val=u(v,9))
    if c==0x62: return dict(date=dt(v,3),temp=round((u(v,9)+(u(v,10)<<8))*.1,1))
    if c==0x54: return dict(date=dt(v,3),bpm=list(v[9:24]))
    if c==0x53: k=u(v,9); return dict(start=dt(v,3),q=list(v[10:10+k]))
for l in open('pk.txt'):
    n,x=l.split()
    if n=='meas_hr' or n=='hrv': continue
    print(n,parse(bytes.fromhex(x)))
