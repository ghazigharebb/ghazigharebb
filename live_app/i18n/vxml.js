/* VXEN: multi-language layer (en, kmr, ar, fa, tr). DOM-level translation from Kurdish Sorani, active only when vexlang is one of these. */
(function(){
var SUP={en:{d:'ltr',h:'en'},tr:{d:'ltr',h:'tr'},ar:{d:'rtl',h:'ar'},fa:{d:'rtl',h:'fa'},kmr:{d:'rtl',h:'ku'}};
var LANG=null;try{LANG=JSON.parse(localStorage.getItem('vexlang'))}catch(e){}
var on=!!(LANG&&SUP[LANG]);
var LTR=on&&SUP[LANG].d==='ltr',HL=on?SUP[LANG].h:'ckb',DIR=on?SUP[LANG].d:'rtl';
var D={};
if(on){try{D=JSON.parse(document.getElementById('vxd-'+LANG).textContent)}catch(e){D={}}}
var OVL=/*OVL*/;
var SRCL=/*SRCL*/;
var OV=[],SRC=on?SRCL[LANG]:[];
if(on){OVL[LANG].forEach(function(r){try{OV.push([new RegExp(r[0],r[2]),r[1]])}catch(e){}})}
OVL=null;SRCL=null;
var HAS=/[؀-ۿ‌]/;
var RX=/[ء-يٱ-ۓە۰-۹‌]+(?: [ء-يٱ-ۓە۰-۹‌]+)*/g;
var MK=/([^]*)/,MKG=/[]/g;
/* runs that are already in the target language are left alone */
var SKIPRUN=LANG==='ar'?/[كيةىأإؤآً-ْ]|^(ما|لا|مع|عن|هل|قد|لم|لن|في|ثم|أو|او|إن|ان)$/:LANG==='fa'?/ه(?= |$)|[ً-ْ]/:null;
var miss={};var TR=null;try{if(localStorage.getItem('vxtrace'))TR=[]}catch(e){}
var DONE=new Set();
var PAIRS=[[/[٠-٩]/g,function(c){return String(c.charCodeAt(0)-0x660)}],[/[۰-۹]/g,function(c){return String(c.charCodeAt(0)-0x6f0)}]];
var KEEP=/^(Band|VEX|Kurdish|Sorani|Badini|English|Iraq|Iraqi|Erbil|Duhok|Kurdistan|Arena|Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec|SpO|HRV|ECG|AI|BMI|I\b|I'|WHO|CDC|GPS|Mom|Dad|Demo|USDA|Bluetooth|iPhone|Android|Pro|Plus|Arabic|Persian|Turkish|Ramadan|Eid|Nowruz|Islam|Muslim|God|Fajr|Dhuhr|Asr|Maghrib|Isha|Mifflin|Claude|MAC|PPI|IQD|ORS|Play|Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık|Pazartesi|Salı|Çarşamba|Perşembe|Cuma|Cumartesi|Pazar|Kürtçe|Arapça|Farsça|Türkçe|İngilizce|Irak|Erbil|Süleymaniye|Bağdat|Kerkük|Allah|Ramazan|Bayram|Nevruz|Kur'an|Peygamber)/;
var UPC=LANG==='tr'?/^[A-ZÇĞİÖŞÜ][a-zçğıöşü]/:/^[A-Z][a-z]/;
function lc1(o){if(!LTR||!o||!UPC.test(o)||KEEP.test(o))return o;return o.charAt(0).toLocaleLowerCase(HL)+o.slice(1)}
function seg(m){
  var e=D[m];if(e!==undefined)return e;
  var w=m.split(' '),n=w.length,i=0,out=[],j,k,hit;
  if(n===1){miss[m]=(miss[m]||0)+1;return m}
  while(i<n){
    hit=false;
    for(j=n;j>i;j--){k=w.slice(i,j).join(' ');if(D[k]!==undefined){if(D[k]!=='')out.push(out.length?lc1(D[k]):D[k]);i=j;hit=true;break}}
    if(!hit){miss[w[i]]=(miss[w[i]]||0)+1;out.push(w[i]);i++}
  }
  return out.join(' ');
}
function segAll(p){
  if(!HAS.test(p))return p;
  return p.replace(RX,function(m,off,whole){
    if(SKIPRUN&&SKIPRUN.test(m))return m;
    var o=seg(m);
    if(LTR&&off>0&&/([,;(،؛]|[\d٠-٩۰-۹])\s*$/.test(whole.slice(Math.max(0,off-3),off)))o=lc1(o);
    return o;
  });
}
var CAP0=/^[ء-يٱ-ۓە]/;
var STOP=LANG==='tr'?/^(dk|sa|sn|kcal|kal|kg|km|g|ml|bpm|ms|cm|ve|veya|ile|için|kadar|önce|sonra|gibi|göre|ise|da|de|ki|mi|mı|mu|mü|kez|kere|adım|gün|hafta|ay|yıl|saat|dakika|saniye|puan|üye|kişi)(?![a-zçğıöşü])/:/^(min|mins|minute|minutes|hour|hours|h|m|sec|secs|second|seconds|day|days|week|weeks|month|months|year|years|step|steps|kcal|cal|calorie|calories|kg|km|g|ml|l|bpm|ms|cm|lb|ft|in|cup|cups|glass|glasses|item|items|meal|meals|point|points|coin|coins|member|members|left|over|of|and|or|to|at|for|with|by|from|is|are|a|an|the|vs|per|than|then|but|as|on|off|not|no|only|about|because|so|if|when|which|that|it|you|your|zone|times|time|ago|more|less|once|twice|every|each|am|pm|new|pending|sent|shared|joined|g\b|min\b)(?![a-z])/;
var LOW=LANG==='tr'?/^[a-zçğıöşü]/:/^[a-z]/;
var PLU=/(^|[^\d.,])((?:[2-9]|\d{2,})(?:-\d+)?) (piece|Piece|spoon|Spoon|packet|Packet|slice|Slice|cup|Cup|glass|Glass|plate|Plate|snack|Snack|meal|item|bowl|can|scoop|tablespoon|teaspoon)\b(?!s)/g;
var SING=/(^|[^\d.,])1 (hours|days|minutes|weeks|months|years|seconds|cups|items|members|glasses|steps|portions|meals|points|coins)\b/g;
function conv(s){
  if(!on||!s||!HAS.test(s))return s;
  if(DONE.has(s))return s;
  var i,r=s,t0=s.trim();
  if(t0!==s||t0.indexOf(' ')>0||t0.length>1){var ex=D[t0];if(ex!==undefined&&/[()\[\]«»:،,.]/.test(t0)){r=s.replace(t0,'\ue000'+ex+'\ue001')}}
  for(i=0;i<OV.length;i++){r=r.replace(OV[i][0],OV[i][1])}
  if(r.indexOf('')>=0){
    r=r.split(MK).map(function(p,k){return k%2?p:segAll(p)}).join('').replace(MKG,'');
  }else r=segAll(r);
  if(LTR){
    for(i=0;i<PAIRS.length;i++)r=r.replace(PAIRS[i][0],PAIRS[i][1]);
    r=r.replace(/،/g,',').replace(/؟/g,'?').replace(/؛/g,';').replace(/٪/g,'%').replace(/٫/g,'.').replace(/٬/g,',');
    if(LANG==='tr')r=r.replace(/(^|[\s(])([\d.,]+)\s?%/g,'$1%$2');
  }
  if(LANG==='en')r=r.replace(SING,function(m,a,u){return a+'1 '+u.slice(0,-1)});
  if(LANG==='en')r=r.replace(PLU,function(m,a,n,u){return a+n+' '+(u==='glass'?'glasses':u==='Glass'?'Glasses':u+'s')});
  if(LTR&&CAP0.test(s)&&r!==s&&LOW.test(r)&&!STOP.test(r))r=r.charAt(0).toLocaleUpperCase(HL)+r.slice(1);
  if(r.indexOf('  ')>=0)r=r.replace(/ {2,}/g,' ');
  if(DONE.size>30000)DONE.clear();
  DONE.add(r);
  if(TR)TR.push([s,r]);
  return r;
}
var ATTRS=['placeholder','title','aria-label','alt','label','data-tip','data-t','data-title','data-label'];
var CHV=/[‹›]/,CHV2=/[‹›]/g;
var SKIP={SCRIPT:1,TEXTAREA:1,NOSCRIPT:1,STYLE:1};
function noTr(p){return p.closest&&p.closest('[translate="no"],.notranslate')}
function fixText(n){
  var p=n.parentNode;if(!p)return;
  if(SKIP[p.nodeName])return;
  var v=n.nodeValue;if(!v||n.__vxv===v)return;
  if(noTr(p)){n.__vxv=v;return}
  var c=v;
  if(HAS.test(v))c=conv(v);
  if(LTR&&CHV.test(c))c=c.replace(CHV2,function(x){return x==='‹'?'›':'‹'});
  if(c!==v){n.nodeValue=c}
  n.__vxv=c;
}
function fixEl(e){
  if(e.nodeType!==1)return;
  var i,a,v,c;
  if(noTr(e))return;
  for(i=0;i<ATTRS.length;i++){a=ATTRS[i];v=e.getAttribute&&e.getAttribute(a);if(v&&HAS.test(v)){c=conv(v);if(c!==v)e.setAttribute(a,c)}}
  if(e.nodeName==='INPUT'){var t=(e.getAttribute('type')||'').toLowerCase();if(t==='button'||t==='submit'){v=e.value;if(v&&HAS.test(v))e.value=conv(v)}}
}
function walk(root,doc){
  if(!root)return;
  if(root.nodeType===3){fixText(root);return}
  if(root.nodeType!==1&&root.nodeType!==9&&root.nodeType!==11)return;
  var w=doc.createTreeWalker(root,5,null,false),n;
  if(root.nodeType===1)fixEl(root);
  while((n=w.nextNode())){
    if(n.nodeType===3)fixText(n);else fixEl(n);
  }
}
function patchCanvas(win){
  try{
    var P=win.CanvasRenderingContext2D&&win.CanvasRenderingContext2D.prototype;if(!P||P.__vxen)return;
    ['fillText','strokeText','measureText'].forEach(function(k){
      var o=P[k];if(!o)return;
      P[k]=function(t){var a=arguments;if(typeof t==='string'&&HAS.test(t)){a=Array.prototype.slice.call(arguments);a[0]=conv(t)}return o.apply(this,a)};
    });
    P.__vxen=1;
  }catch(e){}
}
function attach(win){
  if(!on)return;
  var doc;try{doc=win.document}catch(e){return}
  if(win.__vxen)return;win.__vxen=1;
  patchCanvas(win);
  var html=doc.documentElement;
  function setLang(){try{if(html.getAttribute('lang')!==HL)html.setAttribute('lang',HL);if(html.getAttribute('dir')!==DIR)html.setAttribute('dir',DIR)}catch(e){}}
  setLang();
  var mo=new win.MutationObserver(function(ms){
    var i,j,m;
    for(i=0;i<ms.length;i++){
      m=ms[i];
      if(m.type==='characterData'){fixText(m.target)}
      else if(m.type==='childList'){for(j=0;j<m.addedNodes.length;j++)walk(m.addedNodes[j],doc)}
      else if(m.type==='attributes'){
        if(m.target===html){setLang()}else fixEl(m.target);
      }
    }
  });
  function start(){
    walk(html,doc);
    mo.observe(html,{subtree:true,childList:true,characterData:true,attributes:true,attributeFilter:ATTRS.concat(['dir','lang','value'])});
  }
  start();
  doc.addEventListener('DOMContentLoaded',function(){walk(html,doc)});
  win.addEventListener('load',function(){walk(html,doc)});
  try{win.__vxconv=conv}catch(e){}
}
var CSS=LTR?('html[lang="'+HL+'"],html[lang="'+HL+'"] body{direction:ltr}'+
 'html[lang="'+HL+'"] body,html[lang="'+HL+'"] button,html[lang="'+HL+'"] input,html[lang="'+HL+'"] select,html[lang="'+HL+'"] textarea{font-family:"Sora","Inter",system-ui,-apple-system,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif!important;letter-spacing:0}'+
 'html[lang="'+HL+'"] .lbl,html[lang="'+HL+'"] small{letter-spacing:.01em}'):'';
var FONT='https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&display=swap';
var LINK=LTR?'<link rel="stylesheet" href="'+FONT+'">':'';
function skinHtml(h){
  if(!on)return h;
  h=h.replace(/<html([^>]*)>/,function(m,a){a=a.replace(/\s(lang|dir)="[^"]*"/g,'');return '<html lang="'+HL+'" dir="'+DIR+'"'+a+'>'});
  var inj='<script>(function(){var w=window;for(var i=0;i<6;i++){try{if(w.VXEN){w.VXEN.attach(window);break}}catch(e){break}if(w.parent===w)break;w=w.parent}})()<\/script>'+(CSS?'<style id="vxen">'+CSS+'<\/style>':'')+LINK;
  for(var q=0;q<SRC.length;q++){if(h.indexOf(SRC[q][0])>=0)h=h.split(SRC[q][0]).join(SRC[q][1])}
  var i=h.indexOf('<head>');
  if(i>=0)h=h.slice(0,i+6)+inj+h.slice(i+6);
  return h;
}
function scan(win){
  var out=[],doc=win.document,w=doc.createTreeWalker(doc.documentElement,4,null,false),n;
  while((n=w.nextNode())){
    var p=n.parentNode;if(!p||p.nodeName==='SCRIPT'||p.nodeName==='STYLE'||p.nodeName==='TEXTAREA')continue;
    if(/[ەێۆڕڵڤ]/.test(n.nodeValue)&&!noTr(p)){
      var cs=win.getComputedStyle(p);
      out.push({t:n.nodeValue.trim().slice(0,80),vis:cs.display!=='none'&&cs.visibility!=='hidden'})
    }
  }
  return out;
}
window.VXEN={on:on,lang:on?LANG:'ckb',trace:function(){return TR},attach:attach,skinHtml:skinHtml,conv:conv,miss:miss,scan:scan,dict:D};
if(on){
  try{document.documentElement.setAttribute('lang',HL);document.documentElement.setAttribute('dir',DIR)}catch(e){}
  if(CSS){var s=document.createElement('style');s.id='vxen';s.textContent=CSS;(document.head||document.documentElement).appendChild(s);}
  if(LINK){var l=document.createElement('link');l.rel='stylesheet';l.href=FONT;(document.head||document.documentElement).appendChild(l);}
  attach(window);
}
})();
