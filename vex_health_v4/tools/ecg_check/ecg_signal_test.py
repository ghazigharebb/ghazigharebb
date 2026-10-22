# Python mirror of lib/ecg/ecg_signal.dart (logic check on synthetic PPG, 72 bpm @ 50 Hz)
import math, random
class Sig:
    def __init__(s, rate=50, seconds=5, dcAlpha=0.03, ampDecay=0.994, minStd=0.8, ampFloor=40.0):
        s.rate=rate; s.seconds=seconds; s.dcA=dcAlpha; s.ad=ampDecay; s.minStd=minStd; s.floor=ampFloor
        s.disp=[0.0]*int(seconds*rate); s.raw=[]; s.rr=[]; s.n=0; s.last=-10**6
        s.dc=0; s.lp=0; s.amp=1e-6; s.v1=s.v2=0; s.init=False; s.beats=0
    def push(s,x):
        s.n+=1
        if not s.init: s.dc=x; s.init=True
        s.dc+=(x-s.dc)*s.dcA; y=x-s.dc; s.lp+=(y-s.lp)*0.4
        s.amp=max(s.amp*s.ad,abs(s.lp)); v=max(-1,min(1,s.lp/max(s.amp,s.floor)))
        s.disp.append(v); s.disp.pop(0)
        s.raw.append(x); s.raw=s.raw[-s.rate:]
        if s.n>3 and s.v2<s.v1 and s.v1>=v and s.v1>0.5 and (s.n-1-s.last)>s.refr()*s.rate:
            i=s.n-1
            if s.last>0:
                rr=(i-s.last)/s.rate
                if .3<rr<1.7: s.rr=(s.rr+[rr])[-8:]
            s.last=i; s.beats+=1
        s.v2=s.v1; s.v1=v
    def refr(s):
        if len(s.rr)>=3:
            return max(0.3,0.6*sorted(s.rr)[len(s.rr)//2])
        return 0.4
    def std(s,l):
        m=sum(l)/len(l); return math.sqrt(sum((x-m)**2 for x in l)/len(l))
    def contact(s): return len(s.raw)>=s.rate*.6 and s.std(s.raw)>s.minStd
    def bpm(s):
        if len(s.rr)<3: return None
        m=sorted(s.rr)[len(s.rr)//2]; return 60/m
def ppg(t,bpm):
    ph=(t*bpm/60)%1
    return 800*(math.exp(-((ph-.2)/.07)**2)+.35*math.exp(-((ph-.5)/.1)**2))
random.seed(1)
for bpm in (60,72,95,120):
    s=Sig(); flat_ok=True
    for k in range(150):  # 3 s no finger: constant
        s.push(5000+random.gauss(0,.2))
    flat_ok = (max(map(abs,s.disp))<=1) and not s.contact() and s.bpm() is None
    for k in range(50*20):
        t=k/50; s.push(30000+ppg(t,bpm)+random.gauss(0,15)+t*2)
    print(f"true {bpm}: est {s.bpm()}, contact {s.contact()}, flat-before-finger ok={flat_ok}")
