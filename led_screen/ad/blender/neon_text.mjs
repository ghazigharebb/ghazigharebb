// renders the Kurdish name as a white-on-transparent PNG (for the neon sign texture inside Blender)
import { createRequire } from 'module'; import fs from 'fs'; import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const font = fs.readFileSync(path.resolve('../../fonts/NotoKufiArabic-Black.ttf')).toString('base64');
const b = await chromium.launch(); const p = await b.newPage();
await p.setContent(`<style>@font-face{font-family:K;src:url(data:font/ttf;base64,${font})}</style><canvas id=c width=1400 height=300></canvas>`);
const data = await p.evaluate(async () => { await document.fonts.load('900 200px K', 'وەستا غەریب'); const c = document.getElementById('c'), g = c.getContext('2d');
  g.font = '900 170px K'; g.direction = 'rtl'; g.textAlign = 'center'; g.fillStyle = '#fff'; g.fillText('وەستا غەریب', 700, 215); return c.toDataURL().split(',')[1]; });
fs.writeFileSync('neon_ku.png', Buffer.from(data, 'base64')); await b.close();
