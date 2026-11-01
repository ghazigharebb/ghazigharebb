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
