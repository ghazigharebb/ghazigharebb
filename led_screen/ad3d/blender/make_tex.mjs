// text textures (white on transparent) for Blender: Kurdish needs real Arabic-script shaping, so the browser draws them
import { createRequire } from 'module'; import fs from 'fs'; import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const f64 = f => fs.readFileSync(path.resolve('../../fonts/' + f)).toString('base64');
const T = [['soon_ku', 'لەم نزیکانە', 'K'], ['soon_en', 'COMING SOON', 'A'], ['stock_ku', 'بەردەستە', 'K'], ['stock_en', 'IN STOCK', 'A'],
  ['hours_title', 'کاتی کردنەوە', 'K'], ['hours_line', 'لە ٩ی بەیانی تا ١١ی شەو', 'K']];
const b = await chromium.launch(); const p = await b.newPage();
await p.setContent(`<style>@font-face{font-family:K;src:url(data:font/ttf;base64,${f64('NotoKufiArabic-Black.ttf')})}@font-face{font-family:A;src:url(data:font/ttf;base64,${f64('Anton.ttf')})}</style><canvas id=c></canvas>`);
for (const [n, s, f] of T) {
  const d = await p.evaluate(async ([s, f]) => { await document.fonts.load(`900 100px ${f}`, s); const c = document.getElementById('c'), g = c.getContext('2d');
    const font = `900 160px ${f}`; g.font = font; const m = g.measureText(s), pad = 30;
    const w = Math.ceil(m.width + pad * 2), a = Math.ceil(m.actualBoundingBoxAscent), dd = Math.ceil(m.actualBoundingBoxDescent);
    c.width = w; c.height = a + dd + pad * 2; g.font = font; g.direction = f === 'K' ? 'rtl' : 'ltr'; g.textAlign = 'center'; g.fillStyle = '#fff';
    g.fillText(s, w / 2, pad + a); return c.toDataURL().split(',')[1]; }, [s, f]);
  fs.writeFileSync(`tex/${n}.png`, Buffer.from(d, 'base64'));
}
await b.close();
