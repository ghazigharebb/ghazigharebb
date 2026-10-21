/* VEX Food — شیمی سەربەخۆ: ئەو بەشانە دابین دەکات کە لە ئەپی وێب لە پەنجەرەی دایک (shell) بوون.
   لەناو Flutter (flutter_inappwebview) بەکار دێت؛ لە براوزەری ئاسایش کار دەکات (بۆ تاقیکردنەوە). */
(function(){
  'use strict';
  var W=window;
  // 1) وێنەی خواردنەکان: ڕاستەوخۆ فایلی img/<id>.webp
  W.VFIMG={get:function(id){return id?'img/'+id+'.webp':null},wait:function(f){},state:function(){return 2}};
  // 2) پردی Flutter
  function call(name,arg){
    try{
      var f=W.flutter_inappwebview;
      if(f&&f.callHandler)return f.callHandler(name,arg);
    }catch(e){}
    return null;
  }
  W.VexBridge={call:call,inFlutter:function(){return !!(W.flutter_inappwebview&&W.flutter_inappwebview.callHandler)}};
  function ls(k){try{return JSON.parse(localStorage.getItem(k)||'null')}catch(e){return null}}
  function regUser(){return ls('vexuser')}
  function today(){var d=new Date();return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0')}
  // 3) APP — هەمان ناو و واتای ئەپی وێب
  var lastAdd=null;
  var APP={
    toast:function(m){try{toast(m)}catch(e){}},
    // زیادکردنی خواردنێک (لە سکان/ڕێکلام/هتد) بۆ ڕۆژی ئەمڕۆ
    foodAdd:function(it){
      var item={n:String(it.n||'').slice(0,80),kcal:+it.kcal||0,p:+it.p||0,c:+it.c||0,f:+it.f||0,fib:+it.fib||0,sug:+it.sug||0,v:it.v||'ok',at:it.at||'',src:it.src||'home',slot:it.slot||''};
      if(it.salt!=null)item.salt=+it.salt||0;
      if(it.e)item.e=it.e;
      var slot=it.slot||mealByHour();
      try{day(TODAY).m[slot].push(item);save();try{render()}catch(e){}lastAdd={slot:slot,n:item.n}}catch(e){console.warn(e)}
    },
    foodUndo:function(){
      if(!lastAdd)return;
      try{var a=day(TODAY).m[lastAdd.slot];for(var i=a.length-1;i>=0;i--)if(a[i].n===lastAdd.n){a.splice(i,1);break}save();try{render()}catch(e){}lastAdd=null}catch(e){}
    },
    syncHome:function(){try{call('vexFoodChanged',{summary:APP.foodToday(),items:APP.todayItems()})}catch(e){}},
    // خواردنەکانی ئەمڕۆ بە هەمان شێوەی syncHome ی وێب
    todayItems:function(){
      var s=null;try{s=S}catch(e){}s=s||{};var d=(s.days||{})[today()],items=[];
      if(d&&d.m)Object.keys(d.m).forEach(function(sl){(d.m[sl]||[]).forEach(function(x){items.push({n:x.n,kcal:Math.round(+x.kcal||0),p:+x.p||0,c:+x.c||0,f:+x.f||0,at:x.at||'',v:x.v==='bad'?'bad':x.v==='good'?'good':'ok',e:x.e||'🍽️',slot:sl})})});
      items.sort(function(a,b){return String(b.at).localeCompare(String(a.at))});
      return items;
    },
    foodToday:function(){
      var s=null;try{s=S}catch(e){}
      s=s||{};var d=(s.days||{})[today()],k=0;
      if(d&&d.m)Object.values(d.m).forEach(function(a){(a||[]).forEach(function(x){k+=+x.kcal||0})});
      var g=s.goals||{};var P=null;try{P=(s.people||[]).find(function(q){return q.id===s.active})}catch(e){}
      return {kcal:Math.round(k),goal:+g.kcal||0,p:+g.p||0,c:+g.c||0,f:+g.f||0,burned:(typeof H!=='undefined'&&H.burn)||0,conds:(P&&P.conds)||[],allg:(P&&P.allg)||[]};
    },
    water:{
      get:function(){var s=null;try{s=S}catch(e){}if(!s||!s.days)return null;var dd=s.days[today()];return {n:dd&&dd.water!=null?+dd.water:null,goal:s.goals&&+s.goals.water||null}},
      set:function(n){try{day(TODAY).water=n;save();try{render()}catch(e){}}catch(e){}}
    },
    // سکانی خواردن (کامێرا/گەلەری/نووسین) — لە Flutter بە ScanPage ی خۆی دەکرێتەوە
    scan:function(o){
      o=o||{};
      var send=function(file64){
        var r=call('vexScan',{camera:!!o.camera,slot:o.slot||'',text:o.text||'',image:file64||''});
        if(r===null)try{toast('سکانی وێنە تەنها لەناو ئەپدا کار دەکات')}catch(e){}
      };
      if(o.file&&o.file.constructor&&typeof FileReader!=='undefined'){
        var fr=new FileReader();fr.onload=function(){send(String(fr.result||''))};fr.onerror=function(){send('')};fr.readAsDataURL(o.file);
      }else send('');
    },
    vxb:null
  };
  W.APP=APP;
  // 4) API ی ڕاستەوخۆ بۆ Flutter (evaluateJavascript)
  W.VEXFOOD={
    add:function(it){APP.foodAdd(it)},
    undo:function(){APP.foodUndo()},
    today:function(){return APP.foodToday()},
    items:function(){return APP.todayItems()},
    state:function(){try{return JSON.stringify(S)}catch(e){return null}},
    // تیم: 'dark' یان 'light'
    theme:function(t){var h=document.documentElement;h.setAttribute('data-theme',t==='light'?'light':'dark');h.setAttribute('data-vxm',t==='light'?'light':'dark')},
    // پاش گۆڕینی پرۆفایل لە دەرەوە: دووبارە بخوێنەوە
    reload:function(){location.reload()}
  };
  // 5) پاشەکەوتکراو بە ئاگادارکردنەوەی Flutter (بۆ هاوکاتکردنی ماڵەوە)
  try{
    var _set=localStorage.setItem.bind(localStorage),t=0,t2=0;
    Storage.prototype.setItem=function(k,v){_set(k,v);if(k==='vexfood-v2'){
      clearTimeout(t);t=setTimeout(function(){try{APP.syncHome()}catch(e){}},400);
      clearTimeout(t2);t2=setTimeout(function(){try{call('vexFoodSave',String(v))}catch(e){}},700)}};
  }catch(e){}
})();
