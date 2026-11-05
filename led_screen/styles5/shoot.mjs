// screenshots the 5 style frames (2x) and the labelled sheet with all five
import { createRequire } from 'module';
import path from 'path';
const { chromium } = createRequire(import.meta.url)('playwright');
const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 770, height: 1400 }, deviceScaleFactor: 2 });
await p.goto('file://' + path.resolve('styles.html'));
await p.evaluate(() => document.fonts.ready);
await p.waitForTimeout(800);
const fs = await p.$$('.f');
for (let i = 0; i < fs.length; i++) await fs[i].screenshot({ path: `style_${i + 1}.png` });
await (await p.$('body')).screenshot({ path: 'all_5_styles.png' });
await b.close();
