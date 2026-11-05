// sample the whole timeline every 1/15 s and report any product/text whose painted box leaves the 720x200 frame
import { createRequire } from 'module'; import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] }); const p = await b.newPage({ viewport: { width: 760, height: 240 } });
await p.goto('file://' + path.resolve('anim.html') + '?capture'); await p.evaluate(() => window.ready);
const bad = await p.evaluate(() => { const F = document.getElementById('F').getBoundingClientRect(), out = [];
  for (let t = 0; t < 46; t += 1 / 15) { window.renderAt(t);
    for (const e of document.querySelectorAll('.pw > img:last-of-type, .t, .el > svg')) { const host = e.closest('.el'); if (!host || host.style.visibility === 'hidden' || +host.style.opacity < .35) continue;
      const r = e.getBoundingClientRect(); const o = { t: +t.toFixed(2), l: r.left - F.left, r: r.right - F.left, tp: r.top - F.top, bt: r.bottom - F.top };
      if (o.tp < -1 || o.bt > 201 || o.r > 721) out.push(o) } } return out });
console.log(bad.length ? JSON.stringify(bad.slice(0, 15)) + ' ... ' + bad.length : 'nothing leaves the frame'); await b.close();
