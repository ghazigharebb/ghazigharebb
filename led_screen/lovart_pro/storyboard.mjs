// node storyboard.mjs -> storyboard/board_<n>.png (1440x400 each) + storyboard/ALL_storyboard.png
import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const here = path.dirname(new URL(import.meta.url).pathname), root = path.resolve(here, '../..');
const META = {
  pb_anker165: ['#d4a24c', '1 — Anker 165W · زێڕی ئیمپراتۆری'], pb_maggo_stand: ['#b3122a', '2 — MagGo Stand · سووری یاقووتی'],
  pb_qi2_blue: ['#1f5fd6', '3 — Qi2 · شینی یاقووتی'], pb_anker20k: ['#109467', '4 — Anker 20K · سەوزی زومڕودی'],
  pb_instacord: ['#7b3fc4', '5 — InstaCord · مۆری شاهانە'], adapter: ['#c9d3e0', '6 — ئەداپتەر · پلاتینی زیوی'],
  cable_coil: ['#c06a2b', '7 — کێبڵ · مسی برۆنزی'], magsafe: ['#8e1b3d', '8 — MagSafe · سووری شەرابی'], hours: ['#d4a24c', '9 — کاتی کردنەوە · زێڕ و شەو']
};
const items = [];
for (const l of fs.readFileSync(path.join(here, 'colors.txt'), 'utf8').split('\n')) {
  const [n, f] = l.split(' '); if (!f || f.startsWith('FAIL') || !META[n]) continue;
  items.push([n, 'file://' + path.join(root, f), ...META[n]]);
}
const out = path.join(here, 'storyboard'); fs.mkdirSync(out, { recursive: true });
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 760, height: 2400 }, deviceScaleFactor: 2 });
await p.goto('file://' + path.join(here, 'storyboard.html'));
await p.evaluate(it => window.build(it), items); await p.waitForTimeout(500);
const fs_ = await p.$$('.f');
for (let i = 0; i < fs_.length; i++) await fs_[i].screenshot({ path: path.join(out, `board_${i + 1}_${items[i][0]}.png`) });
await (await p.$('body')).screenshot({ path: path.join(out, 'ALL_storyboard.png') });
await b.close(); console.log('boards', items.length);
