# Python mirror of analyzePpg() in lib/band/ble/vex_wear.dart — checks the pulse detector on synthetic data.
import math, random
MIN_AC=8.0; MIN_ACF=0.45
def analyze(x, rate):
    n=len(x)
    if n < rate*3.5: return None
    w=max(3,int(round(rate*1.0)))
    # moving average detrend (centered, causal-friendly)
    pre=[0.0]
    for v in x: pre.append(pre[-1]+v)
    y=[]
    for i in range(n):
        a=max(0,i-w//2); b=min(n,i+w//2+1)
        y.append(x[i]-(pre[b]-pre[a])/(b-a))
    # 3-pt smooth
    z=[(y[max(0,i-1)]+y[i]+y[min(n-1,i+1)])/3 for i in range(n)]
    m=sum(z)/n; z=[v-m for v in z]
    ac=math.sqrt(sum(v*v for v in z)/n)
    lo=int(round(rate*0.33)); hi=min(int(round(rate*1.5)),n//2)
    e0=sum(v*v for v in z)
    if e0<=1e-9: return dict(pulse=False,ac=0.0,acf=0.0,bpm=0.0)
    rs=[]
    for l in range(lo,hi+1):
        s=sum(z[i]*z[i+l] for i in range(n-l))
        rs.append(s/e0*(n/(n-l)))   # bias-corrected
    best=max(rs)
    # یەکەم لوتکە کە ≥ 80% ی باشترینە = ماوەی لێدانی ڕاستەقینە (نەک هەرەمی دووەم)
    bl=lo
    for k in range(1,len(rs)-1):
        if rs[k]>=0.8*best and rs[k]>=rs[k-1] and rs[k]>=rs[k+1]: bl=lo+k; break
    bpm=60*rate/bl
    return dict(pulse=(ac>=MIN_AC and best>=MIN_ACF and 40<=bpm<=180), ac=ac, acf=best, bpm=bpm)
def ppg(n,rate,bpm,amp,noise,dc=30000,drift=0,seed=0,motion=0):
    r=random.Random(seed); out=[]
    for i in range(n):
        t=i/rate; ph=(t*bpm/60)%1
        p=amp*(math.exp(-((ph-.2)/.08)**2)+.35*math.exp(-((ph-.5)/.12)**2))
        out.append(dc+p+r.gauss(0,noise)+drift*math.sin(2*math.pi*0.07*t)+motion*r.gauss(0,1)*math.sin(2*math.pi*2.2*t))
    return out
if __name__=='__main__':
    rate=50; N=int(rate*6)
    print('--- on wrist (expect pulse=True)')
    bad=0
    for bpm in (50,60,72,95,120,150):
        for amp in (150,600,3000):
            for s in range(3):
                r=analyze(ppg(N,rate,bpm,amp,amp*0.08+5,drift=amp*0.8,seed=s),rate)
                ok=r['pulse'] and abs(r['bpm']-bpm)<6
                bad+= not ok
                if not ok: print('  MISS',bpm,amp,s,{k:round(v,2) if isinstance(v,float) else v for k,v in r.items()})
    print('  misses:',bad,'of',6*3*3)
    print('--- off wrist (expect pulse=False)')
    bad=0;tot=0
    for noise in (0,1,3,6,12):
        for drift in (0,20,200):
            for s in range(6):
                x=ppg(N,rate,72,0,noise,dc=5000,drift=drift,seed=s)
                r=analyze(x,rate); tot+=1
                if r and r['pulse']: bad+=1; print('  FALSE',noise,drift,s,{k:round(v,2) for k,v in r.items()})
    print('  false positives:',bad,'of',tot)
    print('--- worn with motion (info)')
    for mo in (50,200,800):
        r=analyze(ppg(N,rate,72,600,40,drift=300,seed=1,motion=mo),rate); print('  motion',mo,r and {k:round(v,2) for k,v in r.items()})
