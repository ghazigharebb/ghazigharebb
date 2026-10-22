# Python mirror of lib/band/ble/vex_frame.dart + vex_parsers.dart (same logic) — checked against real SDK output
import datetime
def bcd(v): return (((v//10)%10)<<4)|(v%10)
def F(cmd,b={}):
    v=bytearray(16); v[0]=cmd
    for i,x in b.items(): v[i]=x&0xff
    v[15]=sum(v[:15])&0xff; return v.hex()
def hist(cmd,mode,frm=None,withTime=True):
    b={1:mode}
    if frm:
        b[4]=bcd(frm.year%100);b[5]=bcd(frm.month);b[6]=bcd(frm.day)
        if withTime: b[7]=bcd(frm.hour);b[8]=bcd(frm.minute);b[9]=bcd(frm.second)
    return F(cmd,b)
out={}
out['battery']=F(0x13);out['version']=F(0x27);out['mac']=F(0x22);out['gettime']=F(0x41)
out['steps0']=hist(0x51,0,None,False);out['steps2']=hist(0x51,2,None,False)
out['stepsDate']=hist(0x51,1,datetime.datetime(2026,10,22,1,6,5),False)
out['hr']=hist(0x55,0,datetime.datetime(2026,10,22,13,9,45))
out['sleep']=hist(0x53,0);out['hrv']=hist(0x56,2);out['spo2']=hist(0x66,0);out['temp']=hist(0x62,0);out['dyn']=hist(0x54,0)
m=lambda k,start,sec:F(0x28,{1:k,2:1 if start else 0,4:sec&0xff,5:(sec>>8)&0xff})
out['meas_hr']=m(2,True,50);out['meas_spo2_stop']=m(3,False,300);out['meas_hrv']=m(4,True,50)
out['rt']=F(9,{1:1,2:1});out['ppg']=F(7,{1:1});out['find']=F(0x19,{1:5});out['ex']=F(0x19,{1:1,2:5,4:30})
out['name']=F(0x3d,{i+1:c for i,c in enumerate(b'VEX Band')})
out['basic']=F(3,{5:0x81,6:0x80})
out['auto']=F(0x2a,{1:1,2:bcd(8),3:bcd(30),4:bcd(22),5:bcd(5),6:0x7f,7:10,8:0,9:1})
out['user']=F(2,{1:1,2:30,3:175,4:70,5:70})
exp={l.split()[0]:l.split()[1] for l in open('java_frames.txt') if len(l.split())==2}
bad=[k for k in out if exp.get(k)!=out[k]]
print('frames compared:',len(out),'mismatch:',bad)
for k in bad: print(k,exp.get(k),out[k])
