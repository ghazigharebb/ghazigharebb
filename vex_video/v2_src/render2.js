const {chromium}=require('playwright');const fs=require('fs');
const [k,n]=process.argv.slice(2).map(Number);
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium',args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist']});
const p=await b.newPage({viewport:{width:1080,height:1920}});p.on('pageerror',e=>console.log('PAGEERR',e.message));
await p.goto('http://localhost:8124/index.html');await p.waitForFunction('window.READY===true||window.INITERR',null,{timeout:180000});
const F=450;let c=0;for(let f=k;f<F;f+=n){const d=await p.evaluate(f=>window.grab(f/30),f);fs.writeFileSync(`frames/f_${String(f).padStart(4,'0')}.jpg`,Buffer.from(d.split(',')[1],'base64'));if(++c%20==0)console.log('w'+k,'frame',f)}
await b.close();console.log('w'+k,'DONE')})();
