import numpy as np, wave
SR=44100; DUR=10.0; N=int(SR*DUR)
rng=np.random.default_rng(7)
L=np.zeros(N);R=np.zeros(N)
def tt(d): return np.arange(int(d*SR))/SR
def add(sig,t0,pan=0.0,g=1.0):
    i=int(t0*SR); 
    if i<0:
        sig=sig[-i:]; i=0
    n=min(len(sig),N-i)
    if n<=0: return
    a=(pan+1)*np.pi/4
    L[i:i+n]+=sig[:n]*np.cos(a)*g; R[i:i+n]+=sig[:n]*np.sin(a)*g
def env(d,att=.002,dec=.1,pw=1.0):
    t=tt(d); e=np.minimum(1,t/max(att,1e-4))*np.exp(-t/dec)**pw; return e
def noise(d): return rng.standard_normal(int(d*SR))
def fft_f(x,lo,hi):
    X=np.fft.rfft(x); f=np.fft.rfftfreq(len(x),1/SR); m=np.ones_like(f)
    if lo: m*=1/(1+(lo/np.maximum(f,1))**4)
    if hi: m*=1/(1+(f/hi)**4)
    return np.fft.irfft(X*m,len(x))
def bp(x,lo,hi): return fft_f(x,lo,hi)
def sine(f,d,ph=0): return np.sin(2*np.pi*f*tt(d)+ph)
def chirp(f0,f1,d,exp=True):
    t=tt(d); k=t/d
    f=f0*(f1/f0)**k if exp else f0+(f1-f0)*k
    return np.sin(2*np.pi*np.cumsum(f)/SR)
def pluck(f,d=.25,dec=.08,h=(1,.5,.25)):
    t=tt(d); return sum(a*np.sin(2*np.pi*f*(i+1)*t) for i,a in enumerate(h))*env(d,.002,dec)
def whoosh(d,lo0,hi0,lo1,hi1,peak=.5,g=1.0):
    n=noise(d); out=np.zeros(len(n)); K=6
    for k in range(K):
        lo=lo0*(lo1/lo0)**(k/(K-1)); hi=hi0*(hi1/hi0)**(k/(K-1))
        e=np.exp(-((tt(d)/d-(k+.5)/K)**2)/(2*(.9/K)**2))
        out+=bp(n,lo,hi)*e
    t=tt(d)/d; shape=np.sin(np.pi*np.clip(t**peak,0,1))**1.2
    out*=shape; m=np.max(np.abs(out)); return out/m*g if m>0 else out
def kick(g=1.0):
    d=.32;t=tt(d);f=45+110*np.exp(-t/.035);ph=2*np.pi*np.cumsum(f)/SR
    return (np.sin(ph)*np.exp(-t/.11)+.25*np.sin(2*ph)*np.exp(-t/.03))*g+ (noise(d)*np.exp(-t/.004))*.12*g
def hat(g=.2,d=.05): return bp(noise(d),6500,16000)*env(d,.0005,.012)*g
def clap(g=.35):
    d=.18;n=bp(noise(d),900,4500);e=sum(np.exp(-np.clip(tt(d)-o,0,None)/.025)*(tt(d)>=o) for o in (0,.012,.026));return n*e*.5*g
def boom(d=1.3,g=1.0):
    t=tt(d);f=34+70*np.exp(-t/.12);ph=2*np.pi*np.cumsum(f)/SR
    return (np.sin(ph)*np.exp(-t/.5)+bp(noise(d),30,500)*np.exp(-t/.18)*.7)*g
def ding(f,d=.6,g=.4,dec=.25): 
    t=tt(d);return (np.sin(2*np.pi*f*t)+.4*np.sin(2*np.pi*f*2.01*t)+.2*np.sin(2*np.pi*f*3.02*t))*env(d,.001,dec)*g
def click(f=2400,d=.03,g=.4): return np.sin(2*np.pi*f*tt(d))*env(d,.0005,.006)*g

B=0.6
# ---------- music bed ----------
for k in range(17):
    t=k*B
    if t<9.95: add(kick(.95),t,0)
bass_notes=[55,55,65.41,82.41, 55,55,73.42,65.41]
for k in range(33):
    t=k*.3
    if t<9.0:
        f=bass_notes[k%8]; d=.28; tm=tt(d); sc=1-np.exp(-((t%B))/.08)*0  # simple
        duck=1-np.exp(-(tm+( (t%B) ))/.09) if (t%B)<.01 else 1
        s_=(np.sin(2*np.pi*f*tm)+.35*np.sin(2*np.pi*f*2*tm)+.15*np.sin(2*np.pi*f*3*tm))*np.minimum(1,tm/.01)*np.exp(-tm/.25)
        s_*=np.minimum(1,tm/.07) if (t%B)<.01 else 1
        add(s_,t,0,.30)
for k in range(33):
    t=.3+k*.6
    if t<9.5: add(hat(.22),t,.25)
for k in range(66):
    t=k*.15
    if 1.2<=t<9.0 and k%2==1: add(hat(.07,.03),t,-.3)
for t in (1.2+.3,2.4+.3,3.6+.3,4.8+.3,6.0+.3,7.2+.3): add(clap(.4),t,0)
arp=[440,523.25,659.25,783.99,880,783.99,659.25,523.25]
for k in range(80):
    t=1.2+k*.15
    if t<9.0:
        g=.07+.06*min(1,(t-1.2)/3)
        add(pluck(arp[k%8]*(2 if (t>5.4 and k%16>7) else 1),.3,.09),t,(-1)**k*.5,g)
# riser through the whole piece (low level) + big one 8.4-9.0
add(whoosh(8.4,300,1500,2000,12000,peak=2.2,g=.10),0.0,0)
# ---------- scene sfx ----------
starts=[0,.6,1.2,1.8,2.4,3.0,3.6,4.2,4.8,5.4,6.0,6.6,7.2,7.8,8.4,9.0]
for i,s in enumerate(starts[1:],1):
    if i in (15,): continue
    add(whoosh(.22,500,3000,3000,14000,peak=1.5,g=.33),s-.2,(-1)**i*.3)
# S1 green screen zap
d=.5;z=chirp(120,2800,d)*env(d,.01,.3)*.35+bp(noise(d),3000,12000)*env(d,.001,.12)*.25+np.sin(2*np.pi*60*tt(d))*env(d,.01,.5)*.25
add(z,0.05,0); add(ding(1318,.5,.3,.2),.30,0); add(kick(1.0),0,0); add(boom(1.0,.45),0,0)
# S2 pencil scribble
for j in range(7):
    t0=.62+j*.075;d=.07;add(bp(noise(d),1800,7000)*np.sin(np.linspace(0,np.pi,int(d*SR)))*(.9+.3*rng.random()),t0,(-1)**j*.4,.22)
add(click(900,.05,.4),.62,0);add(click(1200,.05,.3),.96,0)
# S3 headline swipes
for j in range(8):
    t0=1.2+j*.075;add(click(2600+j*180,.025,.35),t0,(-1)**j*.5);add(bp(noise(.05),3000,9000)*env(.05,.001,.02)*.3,t0,(-1)**j*.5)
add(boom(.5,.4),1.2,0)
# S4 digital zoom chirp (bitcrushed) + glitch
d=.6;c=chirp(260,5200,d)*env(d,.02,.7)*.28;c=np.round(c*6)/6;c=np.repeat(c[::8],8)[:len(c)]
add(c,1.8,0);
for j in range(5):
    t0=1.82+j*.11;add(bp(noise(.04),2000,12000)*env(.04,.0005,.01)*.35,t0,(-1)**j*.7)
add(ding(2093,.2,.25,.06),2.34,0)
# S5 glass pings
for f,t0,g in ((1318.5,2.43,.35),(1760,2.53,.3),(2637,2.63,.25),(3520,2.78,.18)): add(ding(f,.9,g,.45),t0,(-1)**int(f)*.4)
add(whoosh(.3,800,4000,4000,15000,peak=1.2,g=.3),2.45,0)
# S6 orbit doppler
d=.6;pan=np.sin(np.linspace(0,2*np.pi*1.2,int(d*SR)))
w=whoosh(d,300,2500,500,6000,peak=1.0,g=.32);a=(pan+1)*np.pi/4
i=int(3.0*SR);L[i:i+len(w)]+=w*np.cos(a);R[i:i+len(w)]+=w*np.sin(a)
for k in range(6):
    t0=3.06+k*.05;add(chirp(500+k*150,1800+k*200,.08)*env(.08,.002,.03)*.35,t0,(k-2.5)*.3)
add(ding(1568,.5,.2,.25),3.36,0)
# S7 phone
add(whoosh(.35,200,1800,1500,9000,peak=.8,g=.3),3.6,-.3)
for j in range(3): add(sine(160,.06)*env(.06,.002,.03)*.5,3.86+j*.07,0)       # haptic buzz
add(ding(1318.5,.45,.35,.18),3.88,.2);add(ding(1975.5,.7,.35,.3),3.99,.2)
for j in range(8): add(click(3000,.015,.18),3.7+j*.06,-.6+j*.1)
# S8 ui world
for j,(t0,pn) in enumerate(((4.28,-.6),(4.42,.6),(4.54,-.3),(4.64,.4))):
    add(whoosh(.18,400,2500,1500,10000,peak=1.2,g=.35),t0,pn)
for j,f in enumerate((1046,1318,1568,2093,2637,1760)): add(ding(f,.3,.2,.1),4.24+j*.1,(-1)**j*.5)
# S9 chart grow: rising marimba + counter ticks
sc=[523,587,659,784,880,1047,1175]
for i,f in enumerate(sc): add(pluck(f,.4,.12,(1,.4,.15))*.55,4.8+.6*(.05+i*.07+.1),(i-3)*.2,.9)
for j in range(24): add(click(1800+j*60,.012,.2),4.84+j*.02,0)
add(ding(1568,.8,.35,.4),5.30,0);add(ding(2093,.8,.3,.4),5.36,0)
# S10 checklist
for i in range(6):
    t0=5.4+.6*(.08+.115*i+.03);add(click(1200,.04,.5),t0,0);add(ding(1568+i*0,.35,.3,.1),t0+.015,(i-2.5)*.15)
add(boom(.5,.5),5.4+.6*.92,0);add(ding(1046,1.0,.3,.5),5.95,0);add(ding(1318,1.0,.25,.5),5.95,0);add(ding(1568,1.0,.25,.5),5.95,0)
# S11 paper
for i,dl in enumerate((0,.1,.2,.3,.4)):
    t0=6.0+.6*dl;add(whoosh(.2,1200,5000,2500,9000,peak=1.4,g=.4)*np.sin(np.linspace(0,np.pi,int(.2*SR))),t0,(-1)**i*.5)
add(boom(.4,.5),6.27,0);add(bp(noise(.08),600,6000)*env(.08,.001,.03)*.7,6.27,0)
# S12 couch wall
add(boom(.7,.35),6.6,0)
for f,g in ((220,.18),(261.6,.14),(329.6,.14),(392,.12),(523.3,.08)):
    d=.9;pad=sine(f,d)*np.sin(np.linspace(0,np.pi,int(d*SR)))**1.5*g;add(pad,6.6,0)
add(np.sin(2*np.pi*100*tt(.5))*env(.5,.02,.5)*.1+bp(noise(.5),2000,5000)*(rng.random(int(.5*SR))>.985)*.8,6.65,0)
add(ding(1568,.5,.25,.2),6.84,0)
# S13 cover story: slam + shutter
add(boom(.6,.55),7.2+.03,0)
for t0 in (7.2,7.28):
    add(bp(noise(.025),1500,9000)*env(.025,.0005,.006)*.8,t0,0);add(sine(140,.05)*env(.05,.001,.02)*.6,t0+.012,0)
add(whoosh(.35,1500,9000,3000,14000,peak=.6,g=.35),7.2,0)
add(chirp(2000,200,.25)*env(.25,.001,.1)*.25,7.3,0)
# S14 frame break
for j in range(6):
    t0=8.0+.6*.05+j*.012;add(bp(noise(.03),3000,14000)*env(.03,.0005,.008)*.7,t0,(-1)**j*.6)
add(boom(1.0,.8),8.05,0);add(bp(noise(.5),300,9000)*env(.5,.002,.12)*.6,8.05,0)
for j in range(22):
    f=rng.uniform(2500,9000);add(ding(f,.35,.08,.07),8.06+rng.uniform(0,.3),rng.uniform(-.8,.8))
# S15 zoom-through riser
d=.6;ch=chirp(180,5000,d)*np.linspace(0,1,int(d*SR))**1.5*.38
add(ch,8.4,0);add(whoosh(.6,200,2000,3000,16000,peak=3,g=.55)*np.linspace(.1,1,int(.6*SR)),8.4,0)
add(noise(.6)*0+bp(noise(.6),60,300)*np.linspace(0,1,int(.6*SR))**2*.5,8.4,0)
# silence gap before impact (duck last 25ms)
g0=int(8.975*SR);g1=int(9.0*SR);L[g0:g1]*=np.linspace(1,0,g1-g0);R[g0:g1]*=np.linspace(1,0,g1-g0)
# S16 impact + reveal
add(boom(1.6,1.0),9.0,0);add(kick(1.0),9.0,0);add(bp(noise(.8),200,8000)*env(.8,.001,.22)*.55,9.0,0)
add(whoosh(.5,300,2000,2000,12000,peak=.7,g=.28)[::-1].copy(),9.0,0)
for k,f in enumerate((880,1046.5,1318.5,1568,1760,2093,2637,3136)): add(ding(f,.9,.16,.35),9.22+k*.045,(k-3.5)*.18)
add(click(1000,.0,0),9.5,0)
beep=sine(1000,.09)*np.minimum(1,tt(.09)/.003)*np.minimum(1,(.09-tt(.09))/.01)*.35
add(beep,9.46,0)
for t0 in (9.66,9.79):   # lub-dub
    add(sine(70,.14)*env(.14,.003,.06)*.9,t0,0);add(bp(noise(.05),50,300)*env(.05,.001,.02)*.4,t0,0)
for f,g in ((110,.2),(164.8,.14),(220,.14),(329.6,.1),(493.9,.06)):
    d=1.0;pad=sine(f,d)*np.minimum(1,tt(d)/.2)*g*np.minimum(1,(1.0-tt(d))/.25);add(pad,9.0,0)
# ---------- master ----------
# reverb tail
ir=noise(.9)*np.exp(-tt(.9)/.22);ir=fft_f(ir,200,7000);ir/=np.max(np.abs(ir))
def rev(x,amt=.14):
    n=len(x)+len(ir);X=np.fft.rfft(x,n)*np.fft.rfft(ir,n);y=np.fft.irfft(X,n)[:len(x)];return x+y*amt*.06
L2=rev(L);R2=rev(R,.14)
out=np.stack([L2,R2],1)
out=np.tanh(out*1.1)/np.tanh(1.1)
pk=np.max(np.abs(out));out=out/pk*.89
fi=int(.01*SR);out[:fi]*=np.linspace(0,1,fi)[:,None]
fo=int(.08*SR);out[-fo:]*=np.linspace(1,0,fo)[:,None]
pcm=(out*32767).astype('<i2')
with wave.open('audio.wav','wb') as w:
    w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
print('ok',pk,len(pcm)/SR)
