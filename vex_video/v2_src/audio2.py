import numpy as np, wave
SR=44100; DUR=15.0; N=int(SR*DUR); B=.625
rng=np.random.default_rng(11)
L=np.zeros(N);R=np.zeros(N)
def tt(d): return np.arange(int(d*SR))/SR
def add(sig,t0,pan=0.0,g=1.0):
    i=int(round(t0*SR))
    if i<0: sig=sig[-i:]; i=0
    n=min(len(sig),N-i)
    if n<=0: return
    a=(pan+1)*np.pi/4
    L[i:i+n]+=sig[:n]*np.cos(a)*g; R[i:i+n]+=sig[:n]*np.sin(a)*g
def env(d,att=.002,dec=.1): t=tt(d); return np.minimum(1,t/max(att,1e-4))*np.exp(-t/dec)
def noise(d): return rng.standard_normal(int(d*SR))
def fft_f(x,lo,hi):
    X=np.fft.rfft(x); f=np.fft.rfftfreq(len(x),1/SR); m=np.ones_like(f)
    if lo: m*=1/(1+(lo/np.maximum(f,1))**4)
    if hi: m*=1/(1+(f/hi)**4)
    return np.fft.irfft(X*m,len(x))
bp=fft_f
def sine(f,d): return np.sin(2*np.pi*f*tt(d))
def chirp(f0,f1,d):
    t=tt(d); k=t/d; f=f0*(f1/f0)**k; return np.sin(2*np.pi*np.cumsum(f)/SR)
def swell(d,pk=.7): t=tt(d)/d; return np.sin(np.pi*np.clip(t**pk,0,1))**1.6
def whoosh(d,lo0,hi0,lo1,hi1,g=1.0,pk=1.0):
    n=noise(d); out=np.zeros(len(n)); K=6; t=tt(d)/d
    for k in range(K):
        lo=lo0*(lo1/lo0)**(k/(K-1)); hi=hi0*(hi1/hi0)**(k/(K-1))
        out+=bp(n,lo,hi)*np.exp(-((t-(k+.5)/K)**2)/(2*(.9/K)**2))
    out*=swell(d,pk); m=np.max(np.abs(out)); return out/m*g if m>0 else out
def kick(g=1.0):
    d=.34;t=tt(d);f=44+105*np.exp(-t/.04);ph=2*np.pi*np.cumsum(f)/SR
    return (np.sin(ph)*np.exp(-t/.13)+.2*np.sin(2*ph)*np.exp(-t/.03))*g+noise(d)*np.exp(-t/.004)*.08*g
def boom(d=1.6,g=1.0):
    t=tt(d);f=32+78*np.exp(-t/.14);ph=2*np.pi*np.cumsum(f)/SR
    return (np.sin(ph)*np.exp(-t/.6)+bp(noise(d),28,420)*np.exp(-t/.22)*.8)*g
def bell(f,d=1.0,g=.3,dec=.35):
    t=tt(d);return (np.sin(2*np.pi*f*t)+.45*np.sin(2*np.pi*f*2.76*t)*np.exp(-t/(dec*.5))+.25*np.sin(2*np.pi*f*5.4*t)*np.exp(-t/(dec*.3)))*env(d,.001,dec)*g
def pluck(f,d=.5,dec=.16,g=.3):
    t=tt(d);return (np.sin(2*np.pi*f*t)+.4*np.sin(2*np.pi*f*2*t)+.2*np.sin(2*np.pi*f*3*t))*env(d,.002,dec)*g
def pad(freqs,d,g=.07):
    t=tt(d);s=np.zeros(len(t))
    for f in freqs:
        for det in (-.004,.004): s+=np.sin(2*np.pi*f*(1+det)*t)+.3*np.sin(2*np.pi*f*2*(1+det)*t)
    a=np.minimum(1,t/.5)*np.minimum(1,(d-t)/.8); return s*a*g/ (2*len(freqs))
def hat(g=.12,d=.05): return bp(noise(d),7000,16000)*env(d,.0005,.012)*g
def thump(f=62,d=.2,g=.9): t=tt(d);return np.sin(2*np.pi*(f+40*np.exp(-t/.02))*t)*env(d,.002,.06)*g

# ---------- timeline ----------
ST=[1.25,3.125,5.0,6.875,8.75]; T_V=10.0; T_B=11.875; T_E=13.75
# ---------- music bed ----------
chords=[(1.25,3.125,[110,164.8,220,261.6,329.6],55),(3.125,5.0,[87.3,130.8,174.6,220,261.6],43.65),(5.0,6.875,[130.8,196,261.6,329.6,392],65.4),(6.875,8.75,[98,146.8,196,246.9,293.7],49),(8.75,10.0,[110,164.8,220,261.6,329.6],55),(10.0,11.875,[87.3,130.8,174.6,220,261.6],43.65)]
for a,b,fr,root in chords: add(pad(fr,b-a+.9,.09),a-.2,0)
add(pad([65.4,130.8,196,261.6,329.6,392,493.9],6.0,.11),T_B-.1,0)    # resolving C add9/maj7 for the finale
add(pad([55,110],1.3,.08),0,0)                                       # intro drone
k=0
while 1.25+k*B<T_V+.01:
    t=1.25+k*B;add(kick(.62),t,0);add(hat(.1),t+B/2,.3)
    root=[55,43.65,65.4,49,55,43.65][min(5,int(np.searchsorted([x[1] for x in chords],t)))] if t<T_V else 43.65
    add(pluck(root*2,.4,.2,.22),t+B/2,0);k+=1
# 16th shimmer arp from burst on
arp=[440,523.25,659.25,783.99,880,1046.5,880,783.99]
for j in range(int((T_B-8.75)/ (B/4))):
    t=8.75+j*B/4;g=.05+.07*(j/ int((T_B-8.75)/(B/4)));add(pluck(arp[j%8],.25,.07,g),t,(-1)**j*.5)
# ---------- intro ----------
add(whoosh(1.0,300,1500,1500,9000,.12,.5),0,0)
for j in range(10): add(bell(1568+j*60,.2,.05,.06),.15+j*.075,(j%2-.5))
add(chirp(400,2400,.18)*env(.18,.002,.1)*.25,.84,0)                  # ecg spike
add(thump(60,.22,.9),1.0,0);add(thump(74,.2,.7),1.19,0)              # first lub-dub
add(boom(1.2,.55),1.25,0);add(whoosh(.7,200,1200,2000,10000,.25,.7),.8,0)
# ---------- heart station: heart-beat per beat ----------
for kk in range(int((ST[1]-ST[0])/B)+1):
    t=ST[0]+kk*B
    if t<ST[1]: add(thump(58,.22,.55),t+.0,0);add(thump(70,.18,.4),t+.125,0)
add(bell(659.25,1.2,.22,.5),ST[0]+.2,-.1);add(bell(987.8,1.2,.14,.5),ST[0]+.26,.1)
# ---------- transitions + stations ----------
for b in ST[1:4]: add(whoosh(.8,250,2500,1200,9000,.34,.9),b-.5,(-1)**int(b)*.5)
# arena
a=ST[1]
add(bell(784,1.4,.22,.55),a+.2,0);add(bell(1174.7,1.4,.16,.55),a+.26,.2)
add(whoosh(.5,2000,9000,4000,15000,.3,.8),a+.1,0);add(boom(.8,.4),a+.2,0)
for j in range(18): add(bell(rng.uniform(2200,6500),.35,.07,.12),a+.25+rng.uniform(0,1.3),rng.uniform(-.9,.9))
add(bp(noise(1.6),500,3500)*swell(1.6,.5)*.25,a+.1,0)                 # crowd swell
# family
f0=ST[2];pent=[392,440,523.25,587.3,659.25,784]
for j in range(6): add(pluck(pent[j],.6,.2,.3),f0-.3+j*.07+.05,(j-2.5)*.2)
add(bell(523.25,1.4,.2,.6),f0+.2,0);add(bell(783.99,1.4,.15,.6),f0+.27,.2)
for j in range(6): add(bell(1318+j*50,.25,.05,.07),f0+.3+j*.2,(j-2.5)*.3)    # link pulses
# food
fd=ST[3]
add(bell(1046.5,1.2,.2,.5),fd+.2,0);add(bell(1568,1.2,.14,.5),fd+.26,.2)
sc=np.zeros(int(1.8*SR));tsc=tt(1.8);fsc=900+500*np.sin(tsc*3.4*2*np.pi/1.0*.5+0)  # scanner
phase=2*np.pi*np.cumsum(fsc)/SR;add((np.sin(phase)*.5+np.sin(phase*2)*.2)*np.sin(np.pi*np.clip(tsc/1.8,0,1))**1.0*.09,fd+.1,0)
for j in range(3): add(bell(880+j*220,.6,.14,.25),fd+.35+j*.12,(j-1)*.3)
add(whoosh(.5,300,2000,1500,8000,.25,.8),fd-.2,.4)
# ---------- burst ----------
add(whoosh(.9,250,2500,1500,12000,.36,.9),T_V-1.5-.0,0)
add(boom(.8,.5),T_V-1.25,0)
for j,f in enumerate((988,1175,1319,1568)): add(bell(f,.8,.2,.3),8.75+.25+j*.16,(j-1.5)*.3)
add(whoosh(1.25,300,2500,2000,14000,.3,1.6),8.75,0)
# ---------- vortex ----------
d=T_B-T_V
pan=np.sin(np.linspace(0,2*np.pi*3.4,int(d*SR)))
vw=whoosh(d,200,2000,1500,16000,.55,2.2);a_=(pan+1)*np.pi/4;i=int(T_V*SR);L[i:i+len(vw)]+=vw*np.cos(a_);R[i:i+len(vw)]+=vw*np.sin(a_)
add(chirp(150,3200,d)*np.linspace(0,1,int(d*SR))**1.7*.22,T_V,0)
add(bp(noise(d),40,260)*np.linspace(0,1,int(d*SR))**2*.45,T_V,0)
for j in range(22):
    t=T_V+d*(1-(1-j/22)**1.6);add(bell(1318+j*70,.18,.045,.05),t,(j%2-.5)*1.1)
# duck then impact
g0=int((T_B-.045)*SR);g1=int(T_B*SR);L[g0:g1]*=np.linspace(1,.05,g1-g0);R[g0:g1]*=np.linspace(1,.05,g1-g0)
# ---------- band reveal ----------
add(boom(2.4,1.0),T_B,0);add(kick(1.0),T_B,0)
add(bp(noise(1.2),200,9000)*env(1.2,.001,.3)*.5,T_B,0)
add(whoosh(.9,300,3000,3000,16000,.3,.6)[::-1].copy(),T_B-.85,0)
add(chirp(180,1800,.5)*env(.5,.01,.35)*.3,T_B+.05,0)                 # power-up
for j,f in enumerate((784,987.8,1174.7,1568,1975.5,2349)): add(bell(f,1.4,.14,.5),T_B+.15+j*.06,(j-2.5)*.2)
add(sine(60,1.8)*np.minimum(1,tt(1.8)/.5)*np.exp(-tt(1.8)/1.2)*.1+sine(120,1.8)*.04*np.exp(-tt(1.8)/1.0),T_B+.1,0)  # hum
add(whoosh(.95,2500,8000,5000,16000,.28,1.0),T_B+.55,.2)               # glint sweep
for t in (T_B+.35,T_B+.95,T_B+1.55): add(thump(60,.2,.5),t,0)
# ---------- end ----------
add(bell(1046.5,2.0,.16,.9),T_E+.05,-.1);add(bell(1568,2.0,.12,.9),T_E+.1,.1)
add(whoosh(.5,2000,9000,3000,14000,.18,.8),T_E-.1,0)
add(bell(2093,1.4,.12,.9),T_E+.45,0);add(bell(1318.5,1.8,.1,1.0),T_E+.5,.2)
# ---------- master ----------
ir=noise(1.1)*np.exp(-tt(1.1)/.28);ir=fft_f(ir,180,7500);ir/=np.max(np.abs(ir))
def rev(x,amt):
    n=len(x)+len(ir);X=np.fft.rfft(x,n)*np.fft.rfft(ir,n);return x+np.fft.irfft(X,n)[:len(x)]*amt*.06
L2=rev(L,.2);R2=rev(R,.2)
out=np.stack([L2,R2],1);out=np.tanh(out*1.15)/np.tanh(1.15);out=out/np.max(np.abs(out))*.88
fi=int(.015*SR);out[:fi]*=np.linspace(0,1,fi)[:,None];fo=int(.14*SR);out[-fo:]*=np.linspace(1,0,fo)[:,None]
pcm=(out*32767).astype('<i2')
with wave.open('audio2.wav','wb') as w: w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
x=out
for i in range(30):
    seg=x[int(i*.5*SR):int((i+1)*.5*SR)];print(f'{i*.5:4.1f}s rms {np.sqrt((seg**2).mean()):.3f} pk {abs(seg).max():.2f}')
