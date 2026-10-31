# فۆنتی تاقیکردنەوە: NotoSansArabic + NotoSans (لاتینی) لە یەک فایلدا
import sys, urllib.request, os
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools.merge import Merger
out = 'tfonts/merged'
os.makedirs(out, exist_ok=True)
url = 'https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans%5Bwdth,wght%5D.ttf'
urllib.request.urlretrieve(url, '/tmp/ns.ttf')
for name, w in [('Regular', 400), ('SemiBold', 600), ('Bold', 700)]:
    v = TTFont('/tmp/ns.ttf')
    lat = instancer.instantiateVariableFont(v, {'wght': w, 'wdth': 100})
    lat.save('/tmp/lat.ttf')
    m = Merger()
    f = m.merge(['assets/fonts/NotoSansArabic-%s.ttf' % name, '/tmp/lat.ttf'])
    f.save('%s/NotoAr-%s.ttf' % (out, name))
    print('merged', name)
