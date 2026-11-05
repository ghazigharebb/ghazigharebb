// screenshots each 720x200 board at 2x (1440x400) plus one sheet with all five
import { createRequire } from 'module';
import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 760, height: 1100 }, deviceScaleFactor: 2 });
await p.goto('file://' + path.resolve('boards.html'));
await p.evaluate(() => document.fonts.ready);
await p.waitForTimeout(800);
const frames = await p.$$('.f');
for (let i = 0; i < frames.length; i++) await frames[i].screenshot({ path: `board_${i + 1}.png` });
await (await p.$('body')).screenshot({ path: 'all_5_boards.png' });
await b.close();
