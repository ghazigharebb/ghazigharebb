// verify every text/product box stays inside the 720x200 frame
import { createRequire } from 'module'; import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] }); const p = await b.newPage({ viewport: { width: 760, height: 1100 } });
await p.goto('file://' + path.resolve('boards.html')); await p.evaluate(() => document.fonts.ready);
const r = await p.evaluate(() => [...document.querySelectorAll('.f')].map((f, i) => { const fr = f.getBoundingClientRect();
  return [...f.querySelectorAll('.t3 .fc,.prod,.pill,.por')].map(e => { const q = e.getBoundingClientRect();
    return { i: i + 1, el: (e.textContent || e.getAttribute('src') || e.className.baseVal || '').slice(0, 18), l: Math.round(q.left - fr.left), r: Math.round(q.right - fr.left), t: Math.round(q.top - fr.top), b: Math.round(q.bottom - fr.top) } })
  .filter(o => o.l < 0 || o.r > 720 || o.t < 0 || o.b > 200) }).flat());
console.log(r.length ? r : 'all inside'); await b.close();
