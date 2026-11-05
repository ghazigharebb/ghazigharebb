// node loop.mjs  -> final/LOOP_wastaghareb_1440x400_60fps.mp4 + final/LOOP_wastaghareb_LED_720x200_60fps.mp4 (seamless, no audio)
import { createRequire } from 'module';
import { spawnSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const here = path.dirname(new URL(import.meta.url).pathname), root = path.resolve(here, '../..');
const ORDER = ['brand', 'pb_anker165', 'pb_maggo_stand', 'pb_qi2_blue', 'pb_anker20k', 'pb_instacord', 'adapter', 'cable_coil', 'magsafe', 'hours'];
const clip = {};
for (const l of fs.readFileSync(path.join(here, 'videos.txt'), 'utf8').split('\n')) { const [n, f] = l.split(' '); if (f && f.endsWith('.mp4')) clip[n] = f; }
const tmp = path.resolve(process.env.TMPDIR_FRAMES || '/tmp', 'loopframes');
const FPS = 60;
for (const [i, n] of ORDER.entries()) {
  const d = path.join(tmp, String(i)); if (fs.existsSync(path.join(d, 'f_0300.jpg'))) continue;
  fs.mkdirSync(d, { recursive: true });
  const vf = `crop=iw:iw/2.6,scale=1040:400:flags=lanczos,minterpolate=fps=${FPS}:mi_mode=mci:mc_mode=aobmc:vsbmc=1,trim=duration=5`;
  const r = spawnSync('ffmpeg', ['-loglevel', 'error', '-y', '-i', path.join(root, clip[n]), '-vf', vf, '-q:v', '2', '-frames:v', '300', path.join(d, 'f_%04d.jpg')]);
  if (r.status) { console.error(n, r.stderr.toString()); process.exit(1); }
  const have = fs.readdirSync(d).length; for (let k = have + 1; k <= 300; k++) fs.copyFileSync(path.join(d, `f_${String(have).padStart(4, '0')}.jpg`), path.join(d, `f_${String(k).padStart(4, '0')}.jpg`));
  console.log('frames', n);
}
const src = (c, f) => 'file://' + path.join(tmp, String(c), `f_${String(f + 1).padStart(4, '0')}.jpg`);
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 760, height: 240 }, deviceScaleFactor: 2 });
await p.goto('file://' + path.join(here, 'loop.html')); await p.evaluate(() => window.ready);
const LOOP = await p.evaluate(() => window.LOOP), N = Math.round(LOOP * FPS);
const F = await p.$('#F'); fs.mkdirSync(path.join(here, 'final'), { recursive: true });
const master = path.join(here, 'final', 'LOOP_wastaghareb_1440x400_60fps.mp4');
const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-i', '-', '-an', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', '14', '-r', String(FPS), '-movflags', '+faststart', master], { stdio: ['pipe', 'inherit', 'inherit'] });
for (let i = 0; i < N; i++) {
  const t = i / FPS;
  const need = await p.evaluate(t => window.need(t), t);
  await p.evaluate(async ([a, bb, t]) => { await window.setFrames(a, bb); window.renderAt(t); }, [src(need[0].c, need[0].f), need[1] ? src(need[1].c, need[1].f) : null, t]);
  const buf = await F.screenshot({ type: 'png' });
  if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
  if (i % 600 === 0) console.log('frame', i, '/', N);
}
ff.stdin.end(); await new Promise(r => ff.on('close', r)); await b.close();
spawnSync('ffmpeg', ['-loglevel', 'error', '-y', '-i', master, '-an', '-vf', 'scale=720:200:flags=lanczos', '-c:v', 'libx264', '-profile:v', 'main', '-level', '4.0', '-pix_fmt', 'yuv420p', '-crf', '14', '-preset', 'slow', '-r', String(FPS), '-movflags', '+faststart', path.join(here, 'final', 'LOOP_wastaghareb_LED_720x200_60fps.mp4')]);
console.log('LOOP_DONE', N, 'frames', LOOP, 's');
