#!/usr/bin/env python3
"""پشکنینی فایلەکانی خواردن کامل: ئایا هەموو ٧٠١ خواردن وێنەیان هەیە و هەموو فایلە پێویستەکان شوێنی خۆیان دان؟
بەکارهێنان (لە فۆڵدەری خواردن_کامل):   python3 tools/check_assets.py
"""
import json, os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'food_full', 'web')
ROOT = os.path.normpath(ROOT)
bad = 0

def need(rel):
    global bad
    ok = os.path.exists(os.path.join(ROOT, rel))
    print(('✓ ' if ok else '✗ نییە: ') + rel)
    if not ok:
        bad += 1

for f in ['index.html', 'data/shim.js', 'data/vfdb.js', 'data/ads.js', 'data/band.js',
          'fonts/Sora.ttf', 'fonts/NotoSansArabic-Regular.ttf', 'fonts/NotoSansArabic-SemiBold.ttf',
          'fonts/NotoSansArabic-Bold.ttf', 'fonts/NotoSansArabic-ExtraBold.ttf']:
    need(f)

txt = open(os.path.join(ROOT, 'data', 'vfdb.js'), encoding='utf8').read()
m = re.match(r'\s*window\.VFDB\s*=\s*', txt)
db = json.loads(txt[m.end():].rstrip().rstrip(';'))
fids = [a[0] for a in db['f']]
img_dir = os.path.join(ROOT, 'img')
have = set(os.listdir(img_dir)) if os.path.isdir(img_dir) else set()
missing = [f for f in fids if f + '.webp' not in have]
print('\nخواردن:', len(fids), '| وێنە لە فۆڵدەر:', len(have), '| وێنەی ونبوو:', len(missing))
if missing:
    print('  ونبوو (یەکەم ١٠):', ', '.join(missing[:10]))
    print('  → هەموو بەشەکانی zip ی وێنەکان لە هەمان فۆڵدەر unzip کردووە؟')
    bad += 1
extra = sorted(x for x in have if x[:-5] not in set(fids))
if extra:
    print('وێنەی زیادە (کێشەنییە):', len(extra))
total = sum(os.path.getsize(os.path.join(img_dir, x)) for x in have) if have else 0
print('قەبارەی وێنەکان: %.1f MB' % (total / 1048576))
print('\n' + ('هەموو شتێک ڕێکە ✅' if not bad else 'کێشە هەیە ❌ (%d)' % bad))
sys.exit(1 if bad else 0)
