
/* ===== VEX prayer times — live card + settings page + Band engine ===== */
(function(){
const ALK='vexband-alerts';
const FALLBACK=[36.19,44.01]; /* used only until GPS is connected */
const PROFF={fajr:1.4,sunrise:-.5,dhuhr:.6,asr:.2,maghrib:1.55,isha:.3};

const FIVE=['fajr','dhuhr','asr','maghrib','isha'],SIX=['fajr','sunrise','dhuhr','asr','maghrib','isha'];

const LEADS=[0,5,10,15];
const PATV={short:[450],long:[1300],triple:[320,180,320,180,320]};
const p2=n=>String(n).padStart(2,'0');
let LG='ckb';try{const v=JSON.parse(localStorage.getItem('vexlang')||'null');if(['ckb','kmr','en','ar','fa','tr'].includes(v))LG=v}catch(e){}
const RTL=LG!=='en'&&LG!=='tr';
const TX={
 ckb:{loc:'شوێن',connect:'کۆنێکت',refresh:'نوێکردنەوە',locating:'دۆزینەوە…',notConn:'GPS کۆنێکت نەکراوە',hint:'کۆنێکت بکە بۆ کاتی وردی شوێنی خۆت',next:'بانگی داهاتوو',left:'ماوە',title:'کاتەکانی بانگ',master:'لەرینەوەی Band بۆ بانگ',mOn:'هەر بانگێک بە ڕێکخستنی خۆی',mOff:'کوژاوە · بۆ هەڵکردن دەستی لێبدە',city:'شار',prayers:'بانگەکان',here:'شوێنی ئێستا',before:'ئاگادارکردنەوە پێش بانگ',min:'خولەک',sec:'چرکە',vt:'جۆری لەرینەوە',alsoAt:'لە کاتی بانگیش بلەرێتەوە',test:'تاقیکردنەوەی لەرینەوە',method:'ڕێگای Muslim World League (فەجر 18° · عیشا 17°) · عەسری شافیعی',back:'گەڕانەوە',stop:'ڕاگرتن',off:'لەرینەوە کوژاوە',info:'تەنها زانیاری',at:'لە کاتی بانگ',tNext:'داهاتوو',tTom:'سبەی',tPast:'تێپەڕی',tToday:'ئەمڕۆ',plus:'زیاد',minus:'کەم',noGeo:'شوێن بەردەست نییە',geoNo:'ڕێپێدانی شوێن نەدرا',
  pats:{short:'کورت',long:'درێژ',triple:'سێ جار'},nm:{fajr:'بەیانی',sunrise:'خۆرهەڵات',dhuhr:'نیوەڕۆ',asr:'عەسر',maghrib:'ئێوارە',isha:'خەوتنان'},
  adh:n=>'بانگی '+n,now:n=>'کاتی بانگی '+n,w:(m,s)=>(m&&s?m+' خولەک و '+s+' چرکە':m?m+' خولەک':s+' چرکە')+' پێش بانگ'},
 kmr:{loc:'جه',connect:'گرێدان',refresh:'نووکرن',locating:'دیتن…',notConn:'GPS نەهاتییە گرێدان',hint:'گرێبدە بۆ دەمێن دروست یێن جهێ تە',next:'بانگا بێت',left:'مایە',title:'دەمێن بانگێ',master:'لەرزینا Band بۆ بانگێ',mOn:'هەر بانگەک ب ڕێکخستنا خۆ',mOff:'ڤەمراندییە · بۆ ڤەکرنێ ل سەر بدە',city:'باژێر',prayers:'بانگ',here:'جهێ نوکە',before:'ئاگەهداری بەری بانگێ',min:'دەقە',sec:'چرکە',vt:'جۆرێ لەرزینێ',alsoAt:'د دەمێ بانگێ ژی بلەرزیت',test:'تاقیکرنا لەرزینێ',method:'ڕێکا Muslim World League (فەجر 18° · عیشا 17°) · عەسرا شافیعی',back:'زڤڕین',stop:'ڕاگرتن',off:'لەرزین ڤەمراندییە',info:'تنێ زانیاری',at:'د دەمێ بانگێ دا',tNext:'یا بێت',tTom:'سوبەهی',tPast:'بۆری',tToday:'ئەڤرۆ',plus:'زێدە',minus:'کێم',noGeo:'جه بەردەست نینە',geoNo:'دەستووریا جهی نەهاتە دان',
  pats:{short:'کورت',long:'درێژ',triple:'سێ جاران'},nm:{fajr:'سپێدە',sunrise:'ڕۆژهەلات',dhuhr:'نیڤرۆ',asr:'عەسر',maghrib:'ئێڤار',isha:'عیشا'},
  adh:n=>'بانگا '+n,now:n=>'دەمێ بانگا '+n+' هات',w:(m,s)=>(m&&s?m+' دەقە و '+s+' چرکە':m?m+' دەقە':s+' چرکە')+' بەری بانگێ'},
 en:{loc:'Location',connect:'Connect',refresh:'Refresh',locating:'Locating…',notConn:'GPS not connected',hint:'Connect to get exact times for where you are',next:'Next prayer',left:'left',title:'Prayer times',master:'Band vibration for prayers',mOn:'Each prayer with its own settings',mOff:'Off · tap to turn on',city:'City',prayers:'Prayers',here:'Current location',before:'Alert before the adhan',min:'min',sec:'sec',vt:'Vibration type',alsoAt:'Also vibrate at the adhan',test:'Test vibration',method:'Muslim World League method (Fajr 18° · Isha 17°) · Shafi\'i Asr',back:'Back',stop:'Stop',off:'Vibration off',info:'Info only',at:'At the adhan',tNext:'Next',tTom:'Tomorrow',tPast:'Passed',tToday:'Today',plus:'Increase',minus:'Decrease',noGeo:'Location unavailable',geoNo:'Location permission denied',
  pats:{short:'Short',long:'Long',triple:'3 times'},nm:{fajr:'Fajr',sunrise:'Sunrise',dhuhr:'Dhuhr',asr:'Asr',maghrib:'Maghrib',isha:'Isha'},
  adh:n=>n+' adhan',now:n=>'Time for '+n,w:(m,s)=>(m&&s?m+' min '+s+' sec':m?m+' min':s+' sec')+' before the adhan'},
 ar:{loc:'الموقع',connect:'اتصال',refresh:'تحديث',locating:'جارٍ التحديد…',notConn:'GPS غير متصل',hint:'اتصل للحصول على أوقات دقيقة لموقعك',next:'الأذان القادم',left:'متبقٍ',title:'أوقات الصلاة',master:'اهتزاز Band للأذان',mOn:'لكل أذان إعداداته الخاصة',mOff:'متوقف · اضغط للتشغيل',city:'المدينة',prayers:'الصلوات',here:'الموقع الحالي',before:'تنبيه قبل الأذان',min:'دقيقة',sec:'ثانية',vt:'نوع الاهتزاز',alsoAt:'اهتز أيضاً عند الأذان',test:'اختبار الاهتزاز',method:'طريقة رابطة العالم الإسلامي (الفجر 18° · العشاء 17°) · العصر الشافعي',back:'رجوع',stop:'إيقاف',off:'الاهتزاز متوقف',info:'للمعلومات فقط',at:'عند الأذان',tNext:'التالي',tTom:'غداً',tPast:'مضى',tToday:'اليوم',plus:'زيادة',minus:'إنقاص',noGeo:'الموقع غير متاح',geoNo:'رُفض إذن الموقع',
  pats:{short:'قصير',long:'طويل',triple:'3 مرات'},nm:{fajr:'الفجر',sunrise:'الشروق',dhuhr:'الظهر',asr:'العصر',maghrib:'المغرب',isha:'العشاء'},
  adh:n=>'أذان '+n,now:n=>'حان وقت '+n,w:(m,s)=>{const a=(n,o,t,p)=>n===1?o:n===2?t:n<=10?n+' '+p:n+' '+o;const M=m?a(m,'دقيقة','دقيقتين','دقائق'):'',S=s?a(s,'ثانية','ثانيتين','ثوانٍ'):'';return 'قبل الأذان بـ'+(M&&S?M+' و'+S:M||S)}},
 fa:{loc:'موقعیت',connect:'اتصال',refresh:'به‌روزرسانی',locating:'در حال یافتن…',notConn:'GPS متصل نیست',hint:'برای اوقات دقیق موقعیت خود متصل شوید',next:'اذان بعدی',left:'مانده',title:'اوقات نماز',master:'لرزش Band برای اذان',mOn:'هر اذان با تنظیمات خودش',mOff:'خاموش · برای روشن کردن بزنید',city:'شهر',prayers:'نمازها',here:'موقعیت فعلی',before:'هشدار پیش از اذان',min:'دقیقه',sec:'ثانیه',vt:'نوع لرزش',alsoAt:'هنگام اذان هم بلرزد',test:'آزمایش لرزش',method:'روش اتحادیه جهان اسلام (فجر 18° · عشاء 17°) · عصر شافعی',back:'بازگشت',stop:'توقف',off:'لرزش خاموش است',info:'فقط اطلاعات',at:'هنگام اذان',tNext:'بعدی',tTom:'فردا',tPast:'گذشت',tToday:'امروز',plus:'افزایش',minus:'کاهش',noGeo:'موقعیت در دسترس نیست',geoNo:'اجازهٔ موقعیت داده نشد',
  pats:{short:'کوتاه',long:'بلند',triple:'3 بار'},nm:{fajr:'صبح',sunrise:'طلوع آفتاب',dhuhr:'ظهر',asr:'عصر',maghrib:'مغرب',isha:'عشاء'},
  adh:n=>'اذان '+n,now:n=>'وقت اذان '+n,w:(m,s)=>(m&&s?m+' دقیقه و '+s+' ثانیه':m?m+' دقیقه':s+' ثانیه')+' پیش از اذان'},
 tr:{loc:'Konum',connect:'Bağlan',refresh:'Yenile',locating:'Bulunuyor…',notConn:'GPS bağlı değil',hint:'Bulunduğun yerin tam vakitleri için bağlan',next:'Sıradaki vakit',left:'kaldı',title:'Namaz vakitleri',master:'Ezan için Band titreşimi',mOn:'Her vakit kendi ayarıyla',mOff:'Kapalı · açmak için dokun',city:'Şehir',prayers:'Vakitler',here:'Mevcut konum',before:'Ezandan önce uyarı',min:'dk',sec:'sn',vt:'Titreşim türü',alsoAt:'Ezan vaktinde de titreşsin',test:'Titreşimi test et',method:'Müslüman Dünya Birliği yöntemi (İmsak 18° · Yatsı 17°) · Şafii ikindi',back:'Geri',stop:'Durdur',off:'Titreşim kapalı',info:'Yalnızca bilgi',at:'Ezan vaktinde',tNext:'Sıradaki',tTom:'Yarın',tPast:'Geçti',tToday:'Bugün',plus:'Artır',minus:'Azalt',noGeo:'Konum kullanılamıyor',geoNo:'Konum izni verilmedi',
  pats:{short:'Kısa',long:'Uzun',triple:'3 kez'},nm:{fajr:'İmsak',sunrise:'Güneş',dhuhr:'Öğle',asr:'İkindi',maghrib:'Akşam',isha:'Yatsı'},
  adh:n=>n+' ezanı',now:n=>n+' vakti geldi',w:(m,s)=>'Ezandan '+(m&&s?m+' dk '+s+' sn':m?m+' dk':s+' sn')+' önce'}
}[LG];
const NM=TX.nm,PATS=[['short',TX.pats.short],['long',TX.pats.long],['triple',TX.pats.triple]];
const KDB=['یەکشەمب','دووشەمب','سێشەمب','چارشەمب','پێنجشەمب','ئەینی','شەمبی'],KMB=['کانوونا دووێ','شوبات','ئادار','نیسان','گولان','حزیران','تیرمەه','تەباخ','ئیلون','چریا ئێکێ','چریا دووێ','کانوونا ئێکێ'];

const qs=id=>document.getElementById(id);
function vexPray(date,lat,lng,tz,asrF){
 const R=Math.PI/180,sin=d=>Math.sin(d*R),cos=d=>Math.cos(d*R),tan=d=>Math.tan(d*R),asin=x=>Math.asin(x)/R,acos=x=>Math.acos(Math.max(-1,Math.min(1,x)))/R,acot=x=>Math.atan(1/x)/R,fix=(a,b)=>(a=a-b*Math.floor(a/b));
 const y=date.getFullYear(),m=date.getMonth()+1,d=date.getDate();
 let Y=y,M=m;if(M<=2){Y--;M+=12}const A=Math.floor(Y/100),B=2-A+Math.floor(A/4);
 const jd=Math.floor(365.25*(Y+4716))+Math.floor(30.6001*(M+1))+d+B-1524.5-lng/(15*24);
 function sp(j){const D=j-2451545,g=fix(357.529+.98560028*D,360),q=fix(280.459+.98564736*D,360),L=fix(q+1.915*sin(g)+.020*sin(2*g),360),e=23.439-.00000036*D,RA=Math.atan2(cos(e)*sin(L),cos(L))/R/15;return{dec:asin(sin(e)*sin(L)),eq:q/15-fix(RA,24)}}
 const S=sp(jd+.5),noon=fix(12-S.eq,24)-lng/15+tz;
 const ang=(a,r)=>{let tt=noon;for(let i=0;i<2;i++){const s=sp(jd+(tt-tz+lng/15)/24);const h=acos((-sin(a)-sin(s.dec)*sin(lat))/(cos(s.dec)*cos(lat)))/15;tt=noon+(r?-h:h)}return tt};
 const asr=(f)=>{const s=sp(jd+.5),a=-acot(f+tan(Math.abs(lat-s.dec))),h=acos((-sin(a)-sin(s.dec)*sin(lat))/(cos(s.dec)*cos(lat)))/15;return noon+h};
 const hz=.833;
 return{fajr:ang(18,1),sunrise:ang(hz,1),dhuhr:noon+1/60,asr:asr(asrF||1),maghrib:ang(hz,0),isha:ang(17,0)};
}
/* ---- shared state (same storage as the profile alerts) ---- */
let rawAL='',AL=null;
function defPray(){return{on:false,city:'erbil',lat:null,lng:null,lead:0,items:{fajr:1,dhuhr:1,asr:1,maghrib:1,isha:1},cfg:{}}}
function load(){let r=null;try{r=localStorage.getItem(ALK)||''}catch(e){r=''}
 if(AL&&r===rawAL)return AL;rawAL=r;let o=null;try{o=JSON.parse(r||'null')}catch(e){}
 AL=Object.assign({alarms:[],fired:{}},o||{});AL.pray=Object.assign(defPray(),AL.pray||{});AL.pray.items=Object.assign({fajr:1,dhuhr:1,asr:1,maghrib:1,isha:1},AL.pray.items||{});AL.pray.cfg=AL.pray.cfg||{};AL.fired=AL.fired||{};return AL}
function save(){try{const s=JSON.stringify(AL);localStorage.setItem(ALK,s);rawAL=s}catch(e){}}
function snap(m){m=+m||0;let b=0;for(const x of LEADS)if(Math.abs(x-m)<Math.abs(b-m))b=x;return b}
function cfg(k){const P=load().pray,c=P.cfg[k]||{};return{min:snap(c.min!=null?c.min:(P.lead||0)),sec:0,pat:c.pat||'short',at:c.at!=null?c.at:1}}
function setCfg(k,patch){const P=load().pray;P.cfg[k]=Object.assign(cfg(k),patch);save()}
function coordTx(a,b){return Math.abs(a).toFixed(2)+'°'+(a>=0?'N':'S')+' '+Math.abs(b).toFixed(2)+'°'+(b>=0?'E':'W')}
function place(){const P=load().pray;if(P.lat!=null&&P.lng!=null)return{n:TX.here,c:coordTx(P.lat,P.lng),gps:true,lat:P.lat,lng:P.lng};return{n:'',c:'',gps:false,lat:FALLBACK[0],lng:FALLBACK[1]}}
function clockTx(){const d=new Date(),x=h12(d.getHours()*60+d.getMinutes());return x.t+':'+p2(d.getSeconds())+' '+x.a}
let locating=false;
function locate(){if(locating)return;if(!navigator.geolocation){toastX(TX.noGeo);return}locating=true;paintPage();
 navigator.geolocation.getCurrentPosition(p=>{locating=false;const Q=load().pray;Q.city='gps';Q.lat=+p.coords.latitude.toFixed(4);Q.lng=+p.coords.longitude.toFixed(4);Q.fixAt=Date.now();save();lastSig='';lastF=-1;paintPage();paintCard()},
  e=>{locating=false;paintPage();toastX(e&&e.code===1?TX.geoNo:TX.noGeo)},{enableHighAccuracy:false,timeout:15000,maximumAge:6e5})}
const TC={};
function times(d){const pl=place(),key=d.getFullYear()+'-'+d.getMonth()+'-'+d.getDate()+'|'+pl.lat+','+pl.lng;if(TC[key])return TC[key];
 const tz=-d.getTimezoneOffset()/60,r=vexPray(d,pl.lat,pl.lng,tz,1),o={};for(const k in r){const mins=Math.round(r[k]*60+PROFF[k]);o[k]=((mins%1440)+1440)%1440}TC[key]=o;return o}
function h12(mn){const h=Math.floor(mn/60),m=mn%60;return{t:((h+11)%12+1)+':'+p2(m),a:h<12?'AM':'PM'}}
function tmHTML(mn){const x=h12(mn);return x.t+'<small>'+x.a+'</small>'}
function state(){const now=new Date(),nm=now.getHours()*60+now.getMinutes()+now.getSeconds()/60,t=times(now);
 let nx=null;for(const k of FIVE)if(t[k]>nm){nx={k:k,at:t[k],d:0};break}
 if(!nx){const tm=new Date(now.getTime()+864e5);nx={k:'fajr',at:times(tm).fajr,d:1}}
 let ph='night';if(nm<t.fajr)ph='night';else if(nm<t.sunrise)ph='dawn';else if(nm<t.dhuhr)ph='morning';else if(nm<t.asr)ph='noon';else if(nm<t.maghrib-40)ph='asr';else if(nm<t.maghrib)ph='sunset';else if(nm<t.isha)ph='dusk';
 const tgt=new Date(now);tgt.setHours(0,0,0,0);tgt.setTime(tgt.getTime()+(nx.d?864e5:0)+nx.at*60000);
 const left=Math.max(0,Math.floor((tgt-now)/1000));
 const f=Math.max(0,Math.min(1,(nm-t.sunrise)/(t.maghrib-t.sunrise)));
 return{now:now,nm:nm,t:t,nx:nx,ph:ph,left:left,f:f}}
function cdTxt(s){const h=Math.floor(s/3600),m=Math.floor(s%3600/60),c=s%60;return(h?h+':'+p2(m):m)+':'+p2(c)}
/* ---- sky art: sun travels from sunrise (right) to sunset (left) ---- */
const STARS=[[22,20,1.1],[60,12,.8],[96,26,1],[134,14,.9],[150,44,.7],[30,62,.8],[78,52,.7],[118,70,.6],[12,100,.7],[160,92,.6],[52,92,.6]];
function skySVG(ph,f,w,h){w=w||170;h=h||164;
 const night=ph==='night',dusk=ph==='dusk',dawn=ph==='dawn',sunUp=!(night||dusk||dawn);
 const so=night?1:dusk?.75:dawn?.45:0;
 let s=`<defs><radialGradient id="vxsg${w}" cx="50%" cy="50%" r="50%"><stop offset="0%" stop-color="${ph==='sunset'?'#FFB25A':'#FFF4C2'}" stop-opacity=".95"/><stop offset="35%" stop-color="${ph==='sunset'?'#FF8A3D':'#FFD36B'}" stop-opacity=".45"/><stop offset="100%" stop-color="#FFD36B" stop-opacity="0"/></radialGradient>`+
  `<radialGradient id="vxhg${w}" cx="50%" cy="100%" r="70%"><stop offset="0%" stop-color="${dawn?'#FFC59A':dusk?'#E57AA8':'#FFB060'}" stop-opacity=".75"/><stop offset="100%" stop-color="#FFB060" stop-opacity="0"/></radialGradient></defs>`;
 s+=`<g class="st" opacity="${so}">`+STARS.map(a=>`<circle cx="${a[0]*w/170}" cy="${a[1]*h/164}" r="${a[2]}" fill="#fff" opacity="${.45+(a[2]-.6)}"/>`).join('')+'</g>';
 if(night||dusk||dawn){const mo=dawn?.55:1,mx=34*w/170,my=36;
  s+=`<g transform="translate(${mx} ${my})" opacity="${mo}"><circle r="24" fill="var(--pa)" fill-opacity=".08"/><rect x="-14" y="-14" width="28" height="28" fill="none" stroke="var(--pa)" stroke-opacity=".32" stroke-width="1"/><rect x="-14" y="-14" width="28" height="28" fill="none" stroke="var(--pa)" stroke-opacity=".32" stroke-width="1" transform="rotate(45)"/><path d="M4 -9A10 10 0 1 0 4 9 8 8 0 1 1 4 -9z" fill="var(--pa)"/></g>`}
 if(dawn)s+=`<ellipse cx="${w*.8}" cy="${h}" rx="${w*.75}" ry="${h*.45}" fill="url(#vxhg${w})"/>`;
 if(dusk)s+=`<ellipse cx="${w*.15}" cy="${h}" rx="${w*.7}" ry="${h*.38}" fill="url(#vxhg${w})"/>`;
 if(sunUp){const x=w+8-(w+16)*f,y=h+4-(h*.8)*Math.sin(Math.PI*f),r=ph==='sunset'?20:ph==='noon'?14:16;
  if(ph==='sunset')s+=`<ellipse cx="${w*.1}" cy="${h}" rx="${w*.8}" ry="${h*.42}" fill="url(#vxhg${w})"/>`;
  const under=w<200&&x>w*.3&&y>h*.3,op=under?.5:1;
  s+=`<g opacity="${op}"><circle cx="${x}" cy="${y}" r="${r*3.2}" fill="url(#vxsg${w})"/><circle cx="${x}" cy="${y}" r="${under?r*.8:r}" fill="${ph==='sunset'?'#FFB04A':ph==='asr'?'#FFD36B':'#FFF1B8'}"/></g>`}
 /* skyline: hills + a small dome and minaret, very subtle */
 s+=`<path d="M0 ${h-14} Q${w*.25} ${h-26} ${w*.5} ${h-16} T${w} ${h-18} V${h} H0z" fill="#000" fill-opacity=".16"/>`+
  `<g fill="#000" fill-opacity=".22" transform="translate(${w*.14} ${h-16})"><path d="M-12 0a12 11 0 0 1 24 0z"/><rect x="-13" y="0" width="26" height="16"/><rect x="16" y="-22" width="4" height="38"/><path d="M15 -22l3-6 3 6z"/></g>`;
 return s}
/* ---- card ---- */
const BELL='<svg class="bl" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/></svg>';
let lastPh='',lastF=-1,lastSig='';
function paintCard(S){const c=qs('vxPr');if(!c)return;S=S||state();const P=load().pray;
 if(c.dataset.ph!==S.ph)c.dataset.ph=S.ph;
 if(S.ph!==lastPh||Math.abs(S.f-lastF)>.004){lastPh=S.ph;lastF=S.f;qs('vxPrSky').innerHTML=skySVG(S.ph,S.f)}
 const x=h12(S.nx.at),sig=S.nx.k+S.nx.at+S.nx.d+JSON.stringify(S.t)+P.on+JSON.stringify(P.items)+Math.floor(S.nm);
 if(sig!==lastSig){lastSig=sig;qs('vxPrN').textContent=NM[S.nx.k];qs('vxPrT').textContent=x.t;qs('vxPrAp').textContent=x.a;
  qs('vxPrL').innerHTML=FIVE.map(k=>{const ps=!S.nx.d?S.t[k]<=S.nm:true,nx=k===S.nx.k;const cls=nx?'nx':(ps&&!(S.nx.d&&k==='fajr')?'ps':'');return`<li class="${cls}"><span class="nm">${NM[k]}</span>${P.on&&P.items[k]?BELL:''}<span class="tm">${tmHTML(S.t[k])}</span></li>`}).join('')}
 qs('vxPrCd').textContent=cdTxt(S.left)}
/* ---- settings page ---- */
let open='',built=false,anim='',rpT=null;
function later(){clearTimeout(rpT);rpT=setTimeout(()=>{anim='';paintPage();paintCard()},300)}
function flip(b){const v=b.getAttribute('aria-checked')!=='true';b.setAttribute('aria-checked',String(v));return v}
const IC={h:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 18h18M7 18a5 5 0 0 1 10 0M12 6v4M5.6 10.6l1.4 1.4M18.4 10.6l-1.4 1.4"/></svg>',s:'<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/></svg>',m:'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/></svg>'};
const KIND={fajr:'h',sunrise:'h',dhuhr:'s',asr:'s',maghrib:'h',isha:'m'};
function whenTxt(c){if(!c.min&&!c.sec)return TX.at;return TX.w(c.min,c.sec)}
function patTxt(p){return(PATS.find(x=>x[0]===p)||PATS[0])[1]}
function dateTx(){const d=new Date();try{if(LG==='ckb')return KD[d.getDay()]+'، '+d.getDate()+'ی '+KM[d.getMonth()];if(LG==='kmr')return KDB[d.getDay()]+'، '+d.getDate()+'ێ '+KMB[d.getMonth()];const loc={en:'en-GB',ar:'ar-IQ-u-nu-latn',fa:'fa-IR-u-ca-gregory-nu-latn',tr:'tr-TR'}[LG];return new Intl.DateTimeFormat(loc,{weekday:'long',day:'numeric',month:'long'}).format(d)}catch(e){return''}}
function build(){if(built)return;built=true;const o=document.createElement('div');o.className='vxps';o.id='vxPs';o.setAttribute('role','dialog');o.setAttribute('aria-label',TX.title);o.setAttribute('translate','no');o.dir=RTL?'rtl':'ltr';document.body.appendChild(o);
 o.addEventListener('click',onClick)}
function paintPage(){const o=qs('vxPs');if(!o||!o.classList.contains('on'))return;const S=state(),P=load().pray,pl=place();o.dataset.ph=S.ph;const x=h12(S.nx.at);
 const rows=SIX.map(k=>{const c=cfg(k),on=P.on&&!!P.items[k],nx=k===S.nx.k,ps=!S.nx.d?S.t[k]<=S.nm:k!=='fajr',sun=k==='sunrise';
  const tag=nx?TX.tNext:(S.nx.d&&k==='fajr')?TX.tTom:ps?TX.tPast:TX.tToday;
  const sum=sun?TX.info:(on?`${whenTxt(c)} · ${patTxt(c.pat)}`:TX.off);
  return`<div class="vxps-it${nx?' nx':''}${ps&&!nx?' ps':''}${open===k&&!sun?' open':''}${anim===k&&!sun?' anim':''}" data-k="${k}"><div class="vxps-row"><button class="vxps-op" data-op="${k}" aria-expanded="${open===k}"><span class="vxps-ic">${IC[KIND[k]]}</span><span class="vxps-tx"><b>${NM[k]}<span class="vxps-tag">${tag}</span></b><small>${sum}</small></span><span class="vxps-tm">${tmHTML(S.t[k])}</span></button>${sun?'':`<button class="vxps-sw" role="switch" aria-checked="${on}" aria-label="${NM[k]}" data-tg="${k}"><i></i></button>`}</div>`+
  (sun?'':`<div class="vxps-ex"><div class="vxps-lb">${TX.before}</div><div class="vxps-pt vxps-ld">${LEADS.map(m=>`<button data-ld="${m}" data-k="${k}" class="${c.min===m?'on':''}">${m?`<b dir="ltr">${m}</b><small>${TX.min}</small>`:`<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/></svg><small>${TX.at}</small>`}</button>`).join('')}</div>
   <div class="vxps-lb" style="margin-top:14px">${TX.vt}</div><div class="vxps-pt">${PATS.map(p=>`<button data-pt="${p[0]}" data-k="${k}" class="${c.pat===p[0]?'on':''}">${p[1]}</button>`).join('')}</div>
   ${c.min?`<div class="vxps-row" style="padding:12px 0 0;min-height:0"><span class="vxps-tx"><b style="font-size:13.5px">${TX.alsoAt}</b></span><button class="vxps-sw" role="switch" aria-checked="${!!c.at}" aria-label="${TX.alsoAt}" data-at="${k}"><i></i></button></div>`:''}
   <button class="vxps-tst" data-test="${k}"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="8" y="3" width="8" height="18" rx="3"/><path d="M4 9v6M20 9v6"/></svg>${TX.test}</button></div>`)+'</div>'}).join('');
 const PIN='<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0c0 5.4-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.4"/></svg>';
 const locRow=`<div class="vxps-box vxps-loc${pl.gps?' ok':''}"><div class="vxps-row"><span class="vxps-ic">${PIN}</span><span class="vxps-tx"><b>${pl.gps?TX.here:TX.notConn}</b><small>${pl.gps?`<span dir="ltr">${pl.c}</span>`:TX.hint}</small><small class="vxps-clk">🕐 <span dir="ltr" id="vxPsClk">${clockTx()}</span></small></span><button class="vxps-gps" data-gps="1"${locating?' disabled':''}>${locating?TX.locating:pl.gps?TX.refresh:TX.connect}</button></div></div>`;
 o.innerHTML=`<div class="vxps-in"><div class="vxps-hd"><button class="vxps-bk" data-x="1" aria-label="${TX.back}"><svg viewBox="0 0 24 24"><path d="${RTL?'M9 6l6 6-6 6':'M15 6l-6 6 6 6'}"/></svg></button><div class="tt"><b>${TX.title}</b><small>${pl.gps?pl.n+' · ':''}${dateTx()}</small></div></div>
  <div class="vxps-hero"><svg class="vxpr-sky" viewBox="0 0 360 104" preserveAspectRatio="xMidYMid slice" aria-hidden="true">${skySVG(S.ph,S.f,360,104)}</svg><div class="tx"><span>${TX.next}</span><div><b>${NM[S.nx.k]}</b><em>${x.t}<small>${x.a}</small></em></div></div><div class="cd"><b id="vxPsCd">${cdTxt(S.left)}</b><small>${TX.left}</small></div></div>
  <div class="vxps-box"><div class="vxps-row"><span class="vxps-ic"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="8" y="3" width="8" height="18" rx="3"/><path d="M4 9v6M20 9v6M2 11v2M22 11v2"/></svg></span><span class="vxps-tx"><b>${TX.master}</b><small>${P.on?TX.mOn:TX.mOff}</small></span><button class="vxps-sw" role="switch" aria-checked="${P.on}" aria-label="${TX.master}" data-master="1"><i></i></button></div></div>
  <div class="vxps-sec">${TX.loc}</div>${locRow}
  <div class="vxps-sec">${TX.prayers}</div>${rows}
  <div class="vxps-nt">${TX.method}</div></div>`}
function openPage(k){build();const o=qs('vxPs');if(k)open=k;else if(!open)open=state().nx.k;o.classList.add('on');paintPage();o.scrollTop=0;
 try{history.pushState&&0}catch(e){}}
function closePage(){const o=qs('vxPs');if(o)o.classList.remove('on')}
window.vxPrayOpen=openPage;window.vxPrayClose=closePage;
function bump(k,st,d){const c=cfg(k);if(st==='min')c.min=Math.max(0,Math.min(60,c.min+d));else c.sec=Math.max(0,Math.min(55,c.sec+d));setCfg(k,{min:c.min,sec:c.sec});paintPage()}
function bindHold(root){let t=null,iv=null;const stop=()=>{clearTimeout(t);clearInterval(iv);t=iv=null};
 root.addEventListener('pointerdown',e=>{const b=e.target.closest('[data-st]');if(!b)return;e.preventDefault();const k=b.dataset.k,st=b.dataset.st,d=+b.dataset.d;bump(k,st,d);let n=0;t=setTimeout(()=>{iv=setInterval(()=>{n++;bump(k,st,d)},n>10?60:110)},400)});
 ['pointerup','pointercancel','pointerleave'].forEach(ev=>root.addEventListener(ev,stop))}
function onClick(e){const g=a=>e.target.closest('['+a+']');let b;
 if(g('data-x')){closePage();return}
 if((b=g('data-master'))){const P=load().pray;P.on=!P.on;save();flip(b);later();return}
 if((b=g('data-tg'))){const P=load().pray,k=b.dataset.tg;if(!P.on){P.on=true;P.items[k]=1}else P.items[k]=P.items[k]?0:1;save();flip(b);later();return}
 if((b=g('data-at'))){const k=b.dataset.at;setCfg(k,{at:cfg(k).at?0:1});flip(b);later();return}
 if((b=g('data-ld'))){setCfg(b.dataset.k,{min:+b.dataset.ld});b.parentNode.querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));later();return}
 if((b=g('data-pt'))){setCfg(b.dataset.k,{pat:b.dataset.pt});b.parentNode.querySelectorAll('button').forEach(x=>x.classList.toggle('on',x===b));buzz(b.dataset.pt);later();return}
 if((b=g('data-test'))){const k=b.dataset.test;ring(TX.adh(NM[k]),whenTxt(cfg(k)),cfg(k).pat,true);return}
 if((b=g('data-gps'))){locate();return}
 if((b=g('data-op'))){const k=b.dataset.op;if(open===k){const it=b.closest('.vxps-it');it.classList.add('closing');setTimeout(()=>{open='';paintPage()},220)}else{open=k;anim=k;paintPage();anim=''}return}}
function toastX(t){try{if(typeof toast==='function')return toast(t)}catch(e){}}
/* ---- Band vibration ---- */
function buzz(p){try{navigator.vibrate&&navigator.vibrate(PATV[p]||PATV.short)}catch(e){}}
let ringEl=null,ringT=null;
function ring(title,sub,pat,test){const D=(()=>{try{return window.parent&&window.parent.APP?window.parent.document:document}catch(e){return document}})();stopRing();
 ringEl=D.createElement('div');ringEl.setAttribute('role','alertdialog');ringEl.setAttribute('translate','no');
 ringEl.style.cssText='position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;background:rgba(4,10,24,.82);backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);font-family:"Noto Sans Arabic","Sora",sans-serif;direction:'+(RTL?'rtl':'ltr');
 ringEl.innerHTML=`<div style="width:min(86vw,340px);text-align:center;color:#fff;padding:28px 20px;border-radius:30px;background:linear-gradient(165deg,#13294A,#0B1830);border:1px solid rgba(242,196,109,.45);box-shadow:0 0 60px -12px #F2C46D"><svg width="64" height="64" viewBox="0 0 24 24" style="animation:vxsh .5s infinite" aria-hidden="true"><path d="M15 5.2A7.5 7.5 0 1 0 15 18.8 6 6 0 1 1 15 5.2z" fill="#F2C46D"/></svg><div style="font-size:21px;font-weight:800;margin:10px 0 4px">${title}</div><div style="font-size:13px;color:#C9D6EA;font-weight:700">${sub||''}</div><button id="vxPrStop" style="margin-top:22px;width:100%;border:0;border-radius:16px;padding:14px;font:800 15px 'Noto Sans Arabic';background:#F2C46D;color:#13294A;cursor:pointer">${TX.stop}</button></div><style>@keyframes vxsh{0%,100%{transform:rotate(-12deg)}50%{transform:rotate(12deg)}}</style>`;
 D.body.appendChild(ringEl);ringEl.querySelector('#vxPrStop').onclick=stopRing;
 buzz(pat);ringT=setInterval(()=>buzz(pat),2600);setTimeout(()=>{if(ringEl)stopRing()},test?6000:45000)}
function stopRing(){clearInterval(ringT);ringT=null;try{navigator.vibrate&&navigator.vibrate(0)}catch(e){}if(ringEl){ringEl.remove();ringEl=null}}
/* ---- engine: runs every second (home is always loaded) ---- */
window.vxPrayEngine=true;
function engine(S){const A=load(),P=A.pray;if(!P.on)return;const now=S.now,dk=now.getFullYear()+'-'+(now.getMonth()+1)+'-'+now.getDate(),ns=now.getHours()*3600+now.getMinutes()*60+now.getSeconds();let ch=false;
 for(const f in A.fired)if(!f.startsWith(dk)){delete A.fired[f];ch=true}
 for(const k of FIVE){if(!P.items[k])continue;const c=cfg(k),adh=S.t[k]*60,lead=c.min*60+c.sec;
  if(lead>0){const at=adh-lead,id=dk+'q'+k+'L';if(ns>=at&&ns<at+120&&!A.fired[id]){A.fired[id]=1;ch=true;ring(TX.adh(NM[k]),whenTxt(c),c.pat)}}
  if(lead===0||c.at){const id=dk+'q'+k;if(ns>=adh&&ns<adh+120&&!A.fired[id]){A.fired[id]=1;ch=true;ring(TX.now(NM[k]),(place().gps?place().n+' · ':'')+'<span dir="ltr">'+h12(S.t[k]).t+' '+h12(S.t[k]).a+'</span>',c.pat)}}}
 if(ch)save()}
function loop(){try{const S=state();paintCard(S);engine(S);const cd=qs('vxPsCd');if(cd){const o=qs('vxPs');if(o&&o.classList.contains('on')){if(o.dataset.ph!==S.ph||o.dataset.nx!==S.nx.k+S.nx.d){o.dataset.nx=S.nx.k+S.nx.d;paintPage()}else{cd.textContent=cdTxt(S.left);const ck=qs('vxPsClk');if(ck)ck.textContent=clockTx()}}}}catch(e){console.warn('vxpray',e)}}
function init(){const c=qs('vxPr');if(c){c.setAttribute('translate','no');c.setAttribute('aria-label',TX.title);const k=c.querySelector('.vxpr-k');if(k)k.innerHTML='<i></i>'+TX.next;const cd=c.querySelector('.vxpr-cd');if(cd)cd.innerHTML='<b dir="ltr" id="vxPrCd">0:00</b>'+TX.left;c.addEventListener('click',()=>openPage());c.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();openPage()}})}
 loop();setInterval(loop,1000);
 document.addEventListener('keydown',e=>{if(e.key==='Escape')closePage()});
 window.addEventListener('storage',e=>{if(e.key===ALK){lastSig='';paintPage()}})}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
