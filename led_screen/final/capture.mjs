// node capture.mjs --stills 1,7,15   -> stills/t*.png      |  node capture.mjs --video  -> master 1440x400@60 + LED 720x200@60
import { createRequire } from 'module';
import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const arg = k => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : null; };
const FPS = 60, DUR = 46;
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 760, height: 240 }, deviceScaleFactor: 2 });
p.on('pageerror', e => { console.error('PAGE', e); process.exit(1); });
await p.goto('file://' + path.resolve('anim.html') + '?capture');
await p.evaluate(() => window.ready);
const F = await p.$('#F');
const shot = async t => { await p.evaluate(t => window.renderAt(t), t); return F.screenshot({ type: 'png' }); };
if (arg('stills')) {
  fs.mkdirSync('stills', { recursive: true });
  for (const t of arg('stills').split(',').map(Number)) fs.writeFileSync(`stills/t${t.toFixed(2).padStart(5, '0')}.png`, await shot(t));
} else {
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-i', '-',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', '14', '-r', String(FPS), '-movflags', '+faststart', 'master_1440x400_60fps.mp4'], { stdio: ['pipe', 'inherit', 'inherit'] });
  const N = FPS * DUR, t0 = Date.now();
  for (let i = 0; i < N; i++) {
    const buf = await shot(i / FPS);
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if (i % 300 === 0) console.log(`frame ${i}/${N} ${((Date.now() - t0) / 1000).toFixed(0)}s`);
  }
  ff.stdin.end(); await new Promise(r => ff.on('close', r));
}
await b.close();
