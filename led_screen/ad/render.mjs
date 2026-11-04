// node render.mjs [--scale 5.3333] [--out file.mp4] [--stills t1,t2,...] [--fps 30]
import { createRequire } from 'module';
import { spawn } from 'child_process';
import fs from 'fs'; import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d; };
const scale = +arg('scale', 5.3333), fps = +arg('fps', 30), DUR = 20, out = arg('out', 'wastaghareb_ad_4K.mp4'), stills = arg('stills');
import http from 'http';
const root = path.resolve('..'), types = { '.html': 'text/html', '.png': 'image/png', '.ttf': 'font/ttf', '.js': 'text/javascript' };
const srv = http.createServer((q, r) => { const f = path.join(root, decodeURIComponent(q.url.split('?')[0])); if (!f.startsWith(root) || !fs.existsSync(f)) { r.writeHead(404); return r.end(); } r.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(r); });
await new Promise(r => srv.listen(0, '127.0.0.1', r)); const port = srv.address().port;
const b = await chromium.launch({ args: ['--disable-gpu-vsync'] });
const page = await b.newPage({ viewport: { width: 800, height: 300 } });
page.on('pageerror', e => { console.error('PAGE ERROR', e); process.exit(1); });
page.on('console', m => console.log('console:', m.text()));
await page.goto(`http://127.0.0.1:${port}/ad/index.html?capture&scale=${scale}`);
await page.evaluate(() => window.ready);
const grab = t => page.evaluate(async t => { await window.prepFrame(t); window.renderAt(t); return document.getElementById('c').toDataURL('image/png').split(',')[1]; }, t);
if (stills) {
  fs.mkdirSync('stills', { recursive: true });
  for (const t of stills.split(',').map(Number)) fs.writeFileSync(`stills/t${t.toFixed(2)}.png`, Buffer.from(await grab(t), 'base64'));
} else {
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-i', '-',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', '15', '-r', String(fps), '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
  const N = fps * DUR, t0 = Date.now();
  for (let i = 0; i < N; i++) { const buf = Buffer.from(await grab(i / fps), 'base64'); if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r)); if (i % 60 === 0) console.log(`frame ${i}/${N} ${((Date.now() - t0) / 1000).toFixed(0)}s`); }
  ff.stdin.end(); await new Promise(r => ff.on('close', r));
}
await b.close(); srv.close();
