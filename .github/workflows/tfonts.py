# CI only: static instances of the variable fonts so google_fonts finds every weight offline
import urllib.request
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
src = {
    'NotoSansArabic': 'https://github.com/google/fonts/raw/main/ofl/notosansarabic/NotoSansArabic%5Bwdth,wght%5D.ttf',
    'NotoSans': 'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans%5Bwdth,wght%5D.ttf',
}
W = [('Regular', 400), ('Medium', 500), ('SemiBold', 600), ('Bold', 700), ('ExtraBold', 800), ('Black', 900)]
for fam, url in src.items():
    urllib.request.urlretrieve(url, '/tmp/v.ttf')
    for n, w in W:
        f = TTFont('/tmp/v.ttf')
        s = instancer.instantiateVariableFont(f, {'wght': w, 'wdth': 100})
        s.save('tfonts/%s-%s.ttf' % (fam, n))
        print(fam, n)

# NotoSansArabic + NotoSans (لاتینی) لە یەک فایلدا — وەک مۆبایل کە پیتی لاتینی بە فۆنتی سیستەم پیشان دەدات
from fontTools.merge import Merger
for n, w in W:
    try:
        ar = 'tfonts/NotoSansArabic-%s.ttf' % n
        m = Merger().merge([ar, 'tfonts/NotoSans-%s.ttf' % n])
        src = TTFont(ar)
        for t, attrs in [('hhea', ['ascent', 'descent', 'lineGap']),
                         ('OS/2', ['sTypoAscender', 'sTypoDescender', 'sTypoLineGap', 'usWinAscent', 'usWinDescent', 'fsSelection'])]:
            for a in attrs:
                setattr(m[t], a, getattr(src[t], a))
        m.save(ar)
        print('merged', n)
    except Exception as e:
        print('merge failed', n, e)

# Sora ی سووک (بەشێک لە ئەپ بەکاری دەهێنێت؛ لە مۆبایل لە ئینتەرنێتەوە دێت)
urllib.request.urlretrieve('https://github.com/google/fonts/raw/main/ofl/sora/Sora%5Bwght%5D.ttf', '/tmp/sora.ttf')
for n, w in [('Thin', 100), ('ExtraLight', 200), ('Light', 300)]:
    f = TTFont('/tmp/sora.ttf')
    instancer.instantiateVariableFont(f, {'wght': w}).save('tfonts/Sora-%s.ttf' % n)
    print('Sora', n)
