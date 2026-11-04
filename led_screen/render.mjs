// Render index.html -> 720x200, 10 s, 30 fps H.264 MP4 (frame-exact, deterministic)
import { createRequire } from 'module';
const { chromium } = createRequire(import.meta.url)('playwright');
import { spawn } from 'child_process';
import path from 'path';
const FPS = 30, DUR = 10, out = process.argv[2] || 'wastaghareb_led_720x200.mp4';
const stills = process.argv.includes('--stills');
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 720, height: 200 }, deviceScaleFactor: 1 });
page.on('pageerror', e => { console.error('PAGE ERROR', e); process.exit(1); });
await page.goto('file://' + path.resolve('index.html') + '?capture');
await page.evaluate(() => window.ready);
const grab = t => page.evaluate(t => { window.renderAt(t); return document.getElementById('c').toDataURL('image/png').split(',')[1]; }, t);
if (stills) {
  const fs = await import('fs'); fs.mkdirSync('stills', { recursive: true });
  for (const t of [0, 0.45, 0.95, 1.2, 1.9, 2.6, 3.7, 4.1, 5.3, 6.35, 7.4, 8.1, 9.6, 9.99])
    fs.writeFileSync(`stills/t${t.toFixed(2)}.png`, Buffer.from(await grab(t), 'base64'));
} else {
  const ff = spawn('ffmpeg', ['-y', '-f', 'image2pipe', '-framerate', String(FPS), '-i', '-',
    '-c:v', 'libx264', '-profile:v', 'main', '-level', '3.1', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', '14',
    '-r', String(FPS), '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
  for (let i = 0; i < FPS * DUR; i++) ff.stdin.write(Buffer.from(await grab(i / FPS), 'base64'));
  ff.stdin.end(); await new Promise(r => ff.on('close', r));
}
await browser.close();
