const {chromium}=require('playwright');const {spawn}=require('child_process');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium',args:['--no-sandbox']});
const p=await b.newPage({viewport:{width:1080,height:1920}});p.on('pageerror',e=>console.log('PAGEERR',e.message));
await p.goto('http://localhost:8123/index.html');await p.waitForFunction('window.READY===true',null,{timeout:60000});
const ff=spawn('ffmpeg',['-y','-f','image2pipe','-framerate','30','-c:v','mjpeg','-i','-','-i','audio.wav','-c:v','libx264','-preset','slow','-crf','13','-pix_fmt','yuv420p','-c:a','aac','-b:a','256k','-movflags','+faststart','-shortest','vex_band_10s.mp4'],{stdio:['pipe','inherit','inherit']});
const F=300;for(let f=0;f<F;f++){const d=await p.evaluate(f=>{render(f/30);return document.getElementById('c').toDataURL('image/jpeg',.97)},f);
 const buf=Buffer.from(d.split(',')[1],'base64');if(!ff.stdin.write(buf))await new Promise(r=>ff.stdin.once('drain',r));if(f%30==0)console.log('frame',f)}
ff.stdin.end();await new Promise(r=>ff.on('close',r));await b.close();console.log('DONE')})();
