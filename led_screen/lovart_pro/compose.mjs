// node compose.mjs ITEM CLIP.mp4 OUTDIR  -> OUTDIR/ITEM_1440x400_60fps.mp4 + OUTDIR/ITEM_LED_720x200_60fps.mp4 (no audio)
// Seedance clip -> cropped to the 520x200 content window, motion-interpolated to 60 fps -> portrait panel + text composited on top.
import { createRequire } from 'module';
import { spawnSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const [item, clip, outDir] = process.argv.slice(2);
const FPS = 60, DUR = 5, N = FPS * DUR;
const tmp = path.resolve(process.env.TMPDIR_FRAMES || '/tmp', 'frames_' + item);
fs.rmSync(tmp, { recursive: true, force: true }); fs.mkdirSync(tmp, { recursive: true }); fs.mkdirSync(outDir, { recursive: true });
// crop the 21:9 clip to 2.6:1 around the vertical centre, 2x resolution, 60 fps motion-compensated
const vf = `crop=iw:iw/2.6,scale=1040:400:flags=lanczos,minterpolate=fps=${FPS}:mi_mode=mci:mc_mode=aobmc:vsbmc=1,trim=duration=${DUR}`;
let r = spawnSync('ffmpeg', ['-loglevel', 'error', '-y', '-i', clip, '-vf', vf, '-q:v', '2', '-frames:v', String(N), path.join(tmp, 'f_%04d.jpg')]);
if (r.status) { console.error(r.stderr.toString()); process.exit(1); }
const frames = fs.readdirSync(tmp).filter(f => f.endsWith('.jpg')).sort();
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 760, height: 240 }, deviceScaleFactor: 2 });
await p.goto('file://' + path.resolve(path.dirname(new URL(import.meta.url).pathname), 'compose.html'));
await p.evaluate(() => window.ready); await p.evaluate(n => window.setItem(n), item);
const F = await p.$('#F');
const master = path.join(outDir, `${item}_1440x400_60fps.mp4`);
const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-i', '-', '-an',
  '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-preset', 'slow', '-crf', '14', '-r', String(FPS), '-movflags', '+faststart', master], { stdio: ['pipe', 'inherit', 'inherit'] });
for (let i = 0; i < N; i++) {
  const fr = frames[Math.min(i, frames.length - 1)];
  await p.evaluate(async ([src, t]) => { await window.setFrame(src); window.renderAt(t); }, ['file://' + path.join(tmp, fr), i / FPS]);
  const buf = await F.screenshot({ type: 'png' });
  if (!ff.stdin.write(buf)) await new Promise(res => ff.stdin.once('drain', res));
}
ff.stdin.end(); await new Promise(res => ff.on('close', res)); await b.close();
spawnSync('ffmpeg', ['-loglevel', 'error', '-y', '-i', master, '-an', '-vf', 'scale=720:200:flags=lanczos', '-c:v', 'libx264', '-profile:v', 'main', '-level', '4.0',
  '-pix_fmt', 'yuv420p', '-crf', '14', '-preset', 'slow', '-r', String(FPS), '-movflags', '+faststart', path.join(outDir, `${item}_LED_720x200_60fps.mp4`)]);
fs.rmSync(tmp, { recursive: true, force: true });
console.log('done', item, frames.length, 'source frames');
