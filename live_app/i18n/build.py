#!/usr/bin/env python3
"""Build the multi-language VXEN layer and patch the live app.
Usage: build.py SRC_HTML OUT_HTML"""
import json, re, sys, subprocess
sys.path.insert(0, '/tmp/scr/tr')
from tpl import T
from tpl_ov import OVX

SRC_HTML, OUT_HTML = sys.argv[1], sys.argv[2]
s = open(SRC_HTML, encoding='utf-8').read()
LANGS = ['en', 'kmr', 'ar', 'fa', 'tr']
MAPL = {'kmr': 'bd', 'ar': 'ar', 'fa': 'fa', 'tr': 'tr'}

# ---------------------------------------------------------------- old block
a = s.find('<script>/* VXEN')
b = s.find('})();\n</script>', a) + len('})();\n</script>')
blk = s[a:b]
i = blk.find('var D='); j = blk.find(';\nvar OV=')
D = json.loads(blk[i + 6:j])
k = blk.find('var SRC='); l = blk.find(';\nvar on=', k)
SRC_EN = json.loads(blk[k + 8:l].replace('<\\/', '</'))
ovsrc = blk[j + 2:k]  # "var OV=[...];\n"
OV_EN = json.loads(subprocess.run(['node', '-e', '''
const s=require('fs').readFileSync(0,'utf8');const OV=eval(s.slice(s.indexOf('[') , s.lastIndexOf(']')+1));
console.log(JSON.stringify(OV.map(o=>[o[0].source,o[1]])))'''], input=ovsrc, capture_output=True, text=True, check=True).stdout)
assert len(OV_EN) == 67, len(OV_EN)

# ---------------------------------------------------------------- dicts
M = json.load(open('/tmp/scr/tr/merged.json'))
DD = {'en': dict(D)}
for ku, en in M['en'].items():
    DD['en'][ku] = en
for L in ['kmr', 'ar', 'fa', 'tr']:
    DD[L] = dict(M['out'][MAPL[L]])

# recipes: new Sorani names + translations
REC = {}
for line in open('/tmp/scr/tr/recipes_out.tsv', encoding='utf-8'):
    p = line.rstrip('\n').split('\t')
    if len(p) != 7: continue
    rid, ckb, kmr, en, ar, fa, tr = p
    REC[rid] = (ckb, kmr, en, ar, fa, tr)
    DD['en'][ckb] = en; DD['kmr'][ckb] = kmr; DD['ar'][ckb] = ar; DD['fa'][ckb] = fa; DD['tr'][ckb] = tr

# Badini: one spelling for 'step'
for kk in list(DD['kmr']):
    DD['kmr'][kk] = DD['kmr'][kk].replace('هەنگاڤ', 'پێنگاڤ')
# extra entries found in testing
EXTRA = {
 'داشکان': {'en': 'off', 'kmr': 'داشکاندن', 'ar': 'خصم', 'fa': 'تخفیف', 'tr': 'indirim'},
 'کۆکا': {'en': 'Coke', 'kmr': 'کۆکا', 'ar': 'كوكا', 'fa': 'کوکا', 'tr': 'kola'},
 'مێشک': {'en': 'Brain', 'kmr': 'مێشک', 'ar': 'مخ', 'fa': 'مغز', 'tr': 'Beyin'},
 'زەڵاتە': {'en': 'Salad', 'kmr': 'زەلاتە', 'ar': 'سلطة', 'fa': 'سالاد', 'tr': 'Salata'},
 'تکە': {'en': 'Tikka', 'kmr': 'تکە', 'ar': 'تكة', 'fa': 'تکه', 'tr': 'Tikka'},
 'هەرمێ': {'en': 'pears', 'kmr': 'هەرمێ', 'ar': 'الكمثرى', 'fa': 'گلابی', 'tr': 'armut'},
}
for ku, m in EXTRA.items():
    for L, v in m.items():
        if L == 'en' and ku in DD['en']: continue
        DD[L][ku] = v
OVR = {'ar': {'پرۆفایل': 'ملفي'}}
for L, m in OVR.items():
    for ku, v in m.items():
        if ku in DD[L]: DD[L][ku] = v
# portion unit
for L, v in {'en': 'Portion', 'kmr': 'بەش', 'ar': 'حصة', 'fa': 'وعده', 'tr': 'Porsiyon'}.items():
    DD[L].setdefault('بەش', v)

# ---------------------------------------------------------------- OV per language
MON = ['کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران', 'تەممووز', 'تەمموز', 'ئاب', 'ئەیلوول',
       'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم', 'ئۆکتۆبەر']
NB = '(?![ء-يٱ-ۓە۰-۹‌])'

def wrap(rep):
    """Protect literal parts of a replacement; $n stays translatable, $!n verbatim."""
    out = []
    for part in re.split(r'(\$!?\d)', rep):
        if not part: continue
        if re.fullmatch(r'\$\d', part):
            out.append(part)
        elif re.fullmatch(r'\$!\d', part):
            out.append('$' + part[2] + '')
        else:
            out.append('' + part.replace('$', '$$') + '')
    return ''.join(out)

OVL = {}
for L in LANGS:
    rules = []
    for pat, reps in T:
        if reps[L] is None: continue
        rules.append([pat, wrap(reps[L].replace('هەنگاڤ', 'پێنگاڤ') if L == 'kmr' else reps[L]), 'g'])
    if L == 'en':
        for n, (pat, rep) in enumerate(OV_EN):
            if n == 62: rep = rep.replace('$1', '$!1', 1)
            if n <= 15:
                rules.append([pat, rep, 'g'])          # dates/h/m: dictionary handles month names
            else:
                rules.append([pat, wrap(rep), 'g'])
    else:
        idx = LANGS.index(L) - 1
        for n, (pat, rep) in enumerate(OV_EN):
            if n <= 15: continue
            rules.append([pat, wrap(OVX[n][idx].replace('هەنگاڤ', 'پێنگاڤ') if L == 'kmr' else OVX[n][idx]), 'g'])
        rules.append(['(\\d+)\\s*ی\\s+(' + '|'.join(MON) + ')' + NB, '$1 $2', 'g'])
        hm = {'kmr': ('س', 'د'), 'ar': ('س', 'د'), 'fa': ('س', 'د'), 'tr': ('sa', 'dk')}[L]
        rules.append(['(\\d)ک' + NB, '$1' + wrap(hm[0]), 'g'])
        rules.append(['(\\d)خ' + NB, '$1' + wrap(hm[1]), 'g'])
    OVL[L] = rules

# ---------------------------------------------------------------- SRC per language
LN = {'en': 'English', 'kmr': 'Kurdish Badini (the Behdini dialect of Northern Kurdish, Arabic script, as written in Duhok)',
      'ar': 'Arabic (Modern Standard Arabic)', 'fa': 'Persian (Farsi)', 'tr': 'Turkish'}
SN = {'en': 'English', 'kmr': 'Kurdish Badini', 'ar': 'Arabic', 'fa': 'Persian', 'tr': 'Turkish'}
DAYS = {'kmr': "DAYS_S=['ش','ی','د','س','چ','پ','ئ']", 'ar': "DAYS_S=['س','ح','ن','ث','ر','خ','ج']",
        'fa': "DAYS_S=['ش','ی','د','س','چ','پ','ج']", 'tr': "DAYS_S=['Ct','Pz','Pt','Sa','Ça','Pe','Cu']"}
WATER = {
 'kmr': "⏰ هەتا نوکە دڤیا تە <b class=\"num\">${expMl.toLocaleString('en')} ml</b> ڤەخواربان. هێشتا تو <b class=\"num\">${(expMl-ml).toLocaleString('en')} ml</b> ل پاش ماینە، ئێک ژ پەرداخان هەلبژێرە.",
 'ar': "⏰ كان يجب أن تشرب حتى الآن <b class=\"num\">${expMl.toLocaleString('en')} ml</b>. ما زلت متأخراً بمقدار <b class=\"num\">${(expMl-ml).toLocaleString('en')} ml</b>، اختر أحد الأكواب.",
 'fa': "⏰ تا الان باید <b class=\"num\">${expMl.toLocaleString('en')} ml</b> آب می‌نوشیدید. هنوز <b class=\"num\">${(expMl-ml).toLocaleString('en')} ml</b> عقب هستید؛ یکی از لیوان‌ها را انتخاب کنید.",
 'tr': "⏰ Şimdiye kadar <b class=\"num\">${expMl.toLocaleString('en')} ml</b> içmiş olman gerekiyordu. <b class=\"num\">${(expMl-ml).toLocaleString('en')} ml</b> gerideysin, bir bardak seç.",
}
NAMES = {
 'kmr': 'the common Kurdish Badini name (e.g. برنج، شلەیا فاسۆلیێ، کەباب، نان، دۆلمە، زەلاتە، مریشک، پیتزا)',
 'ar': 'the common Arabic name (e.g. أرز، فاصولياء، كباب، خبز، دولمة، سلطة، دجاج، بيتزا)',
 'fa': 'the common Persian name (e.g. برنج، خورش لوبیا، کباب، نان، دلمه، سالاد، مرغ، پیتزا)',
 'tr': 'the common Turkish name (e.g. pilav, kuru fasulye, kebap, ekmek, dolma, salata, tavuk, pizza)',
}
UNITS = {
 'kmr': 'in a natural Kurdish Badini unit (پارچە، قاپ، دانە، پەرداخ، کەڤچک، قوتی، شیش، لەفە، کاسە)',
 'ar': 'in a natural Arabic unit (شريحة، صحن، قطعة، كوب، ملعقة، علبة، سيخ، لفافة، وعاء)',
 'fa': 'in a natural Persian unit (برش، بشقاب، عدد، لیوان، قاشق، قوطی، سیخ، ساندویچ، کاسه)',
 'tr': 'in a natural Turkish unit (dilim, tabak, adet, bardak, kaşık, kutu, şiş, dürüm, kase)',
}
UW_ALL = ("const L_UW={'piece':'piece','plate':'plate','glass':'glass','cup':'cup','slice':'slice','tbsp':'tbsp','tsp':'tsp','ladle':'ladle','bowl':'plate','can':'piece','skewer':'piece','wrap':'piece','spoon':'tbsp','item':'piece',"
          "'قطعة':'piece','حبة':'piece','صحن':'plate','طبق':'plate','كوب':'glass','كأس':'glass','فنجان':'cup','شريحة':'slice','ملعقة كبيرة':'tbsp','ملعقة صغيرة':'tsp','ملعقة':'tbsp','مغرفة':'ladle','وعاء':'plate','علبة':'piece','سيخ':'piece','لفافة':'piece',"
          "'عدد':'piece','تکه':'slice','برش':'slice','بشقاب':'plate','لیوان':'glass','قاشق غذاخوری':'tbsp','قاشق چای‌خوری':'tsp','قاشق':'tbsp','ملاقه':'ladle','کاسه':'plate','قوطی':'piece','ساندویچ':'piece',"
          "'adet':'piece','tane':'piece','tabak':'plate','bardak':'glass','fincan':'cup','dilim':'slice','yemek kaşığı':'tbsp','çay kaşığı':'tsp','kaşık':'tbsp','kepçe':'ladle','kase':'plate','kutu':'piece','şiş':'piece','dürüm':'piece','porsiyon':'piece',"
          "'کەڤچک':'tbsp','قوتی':'piece','شیش':'piece','دانە':'piece',")
SRCL = {'en': SRC_EN}
for L in ['kmr', 'ar', 'fa', 'tr']:
    m = {}
    for kk, v in SRC_EN:
        m[kk] = None
    rows = []
    for kk, v in SRC_EN:
        if kk.startswith('DAYS_S'): nv = DAYS[L]
        elif kk.startswith('⏰'): nv = WATER[L]
        elif kk == 'Central Kurdish (Sorani, Arabic script)': nv = 'plain, natural, modern ' + LN[L]
        elif kk == 'Kurdish Sorani (Arabic script)': nv = 'natural, modern ' + LN[L]
        elif kk == 'short Kurdish Sorani phrase': nv = 'short ' + SN[L] + ' phrase'
        elif kk == 'Kurdish Sorani sentences': nv = SN[L] + ' sentences'
        elif kk == 'Kurdish Sorani sentence': nv = SN[L] + ' sentence'
        elif kk == 'Use Kurdish Sorani in Arabic script only': nv = 'Use natural, modern ' + LN[L] + ' only'
        elif kk == '3 short Kurdish actions': nv = '3 short ' + SN[L] + ' actions'
        elif kk == '(Kurdish Sorani users)': nv = '(' + SN[L] + '-speaking users)'
        elif kk == 'for Kurdish Sorani speakers': nv = 'for ' + SN[L] + ' speakers'
        elif kk.startswith('the common Kurdish name'): nv = NAMES[L]
        elif kk.startswith('in a natural Kurdish unit'): nv = UNITS[L]
        elif kk == 'main ingredients in Kurdish': nv = 'main ingredients in ' + SN[L]
        elif kk == "The person's note, in Kurdish:": nv = "The person's note (in " + SN[L] + "):"
        elif kk.startswith("const L_UW="): nv = UW_ALL
        elif kk == 'short Kurdish': nv = 'short ' + SN[L]
        else: raise SystemExit('unhandled SRC ' + kk)
        rows.append([kk, nv])
    SRCL[L] = rows

# ---------------------------------------------------------------- JS
def js(o):
    return json.dumps(o, ensure_ascii=False).replace('</', '<\\/')

dict_tags = ''.join('<script type="application/json" id="vxd-%s">%s</script>' % (L, js(DD[L])) for L in LANGS)
CODE = open('/tmp/scr/tr/vxml.js', encoding='utf-8').read()
CODE = CODE.replace('/*OVL*/', js(OVL)).replace('/*SRCL*/', js(SRCL))
newblk = dict_tags + '<script>' + CODE + '</script>'
s = s[:a] + newblk + s[b:]

# ---------------------------------------------------------------- recipe DB names / units
nrec = 0
for rid, (ckb, kmr, en, ar, fa, tr) in REC.items():
    m = re.search(r'\["' + re.escape(rid) + r'","((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)"', s)
    if not m:
        print('recipe not found', rid); continue
    alias = fa if rid.startswith('fa_') else ar
    s = s[:m.start()] + '["%s","%s","%s"' % (rid, ckb, alias) + s[m.end():]
    nrec += 1
print('recipes patched', nrec)
s = s.replace('[1,"پۆرسن","part",', '[1,"بەش","part",').replace('[1,"پۆرسن (', '[1,"بەش (')
print('پۆرسن left', s.count('پۆرسن'))

# ---------------------------------------------------------------- profile language sheet (inside an escaped page string)
PS = "(function(){var EN=false;try{EN=JSON.parse(localStorage.getItem('vexlang'))==='en'}catch(e){}\\n"
pa = s.find(PS); pb = s.find("};})();\\nfunction load()", pa)
assert pa > 0 and pb > pa, (pa, pb)
NEWP = """(function(){var LC='ckb';try{LC=JSON.parse(localStorage.getItem('vexlang'))||'ckb'}catch(e){}
var ROWS=[['ckb','کوردی سۆرانی','☀️'],['kmr','کوردی بادینی','☀️'],['en','English','🇬🇧'],['ar','العربية','🇸🇦'],['fa','فارسی','🇮🇷'],['tr','Türkçe','🇹🇷']];
if(!ROWS.some(function(r){return r[0]===LC}))LC='ckb';
var sm=document.querySelector('#lang small');if(sm){sm.setAttribute('translate','no');sm.textContent=ROWS.filter(function(r){return r[0]===LC})[0][1]}
$('lang').onclick=function(){
 sheet('<h3>زمان</h3><div class="muted" style="margin:4px 0 12px;font-size:13px">زمانی ئەپەکە هەڵبژێرە</div>'+ROWS.map(function(r){var on=r[0]===LC;return '<button class="row" data-lg="'+r[0]+'" style="--k:#3cf08a;width:100%;margin-bottom:8px"><span class="ri">'+r[2]+'</span><div translate="no" dir="'+((r[0]==='en'||r[0]==='tr')?'ltr':'rtl')+'">'+r[1]+'</div><span class="chev">'+(on?'✓':'')+'</span></button>'}).join(''));
 $('shc').onclick=function(e){var b=e.target.closest('[data-lg]');if(!b)return;var c=b.dataset.lg;if(c===LC){closeS();return}try{localStorage.setItem('vexlang',JSON.stringify(c))}catch(x){}try{parent.location.reload()}catch(x){location.reload()}};
"""
enc = json.dumps(NEWP, ensure_ascii=False)[1:-1].replace('</', '<\\/')
s = s[:pa] + enc + s[pb:]

# ---------------------------------------------------------------- onboarding LANGS -> 6 languages
la = s.find('const LANGS=') + len('const LANGS=')
dec = json.JSONDecoder()
LG, end = dec.raw_decode(s, la)
keep = ['en', 'ckb', 'kmr', 'ar', 'fa', 'tr']
LG = [x for x in LG if x['c'] in keep]
assert [x['c'] for x in LG] == keep
G = {x['c']: x for x in LG}
G['kmr']['t'].update({'wp': 'ساخلەمی، خوارن و وەرزش د ئێک ئەپێ دا، ب زیرەکیا دەستکرد.',
    'cta': 'دەست پێ بکە', 'yes': 'بەلێ، من VEX Band هەیە', 'yesp': 'دل، خەو، ستریس + 6 هەیڤێن Plus ب خۆڕایی',
    'alt': 'من بەری نوکە ئەکاونتەک هەیە · چوونا ژوورڤە'})
G['tr']['t'].update({'pick': 'Dilini seç', 'pickSub': "İstediğin zaman Ayarlar'dan değiştirebilirsin", 'wt': 'Hoş geldin',
    'cta': 'Başla', 'terms': "Devam ederek VEX Kullanım Koşulları'nı ve Gizlilik Politikası'nı kabul etmiş olursun.",
    'bt': "VEX Band'in var mı?", 'bp': 'Uygulamayı senin için ayarlayalım:', 'w1': 'Hoş geldin',
    'alt': 'Zaten hesabım var · Giriş yap'})
s = s[:la] + json.dumps(LG, ensure_ascii=False) + s[end:]

for old, new in [
    ("if((pickL==='en')!==(_p==='en')){location.reload();return}", "if(pickL!==_p){location.reload();return}"),
    ("${isKu()?f[1]:FEN[i*8+k]}", "${curCode()!=='en'?f[1]:FEN[i*8+k]}"),
    ("$('voAlt').dir=cur==='welcome'?dirOf():'rtl';", "$('voAlt').dir=dirOf();"),
    ('<div class="lg-hero" id="lgHero"', '<div class="lg-hero" id="lgHero" translate="no"'),
    ('<button type="button" class="lg-c${', '<button type="button" translate="no" class="lg-c${'),
    ('<button class="vo-lc" id="voLc"', '<button class="vo-lc" id="voLc" translate="no"'),
]:
    assert s.count(old) == 1, old
    s = s.replace(old, new)

open(OUT_HTML, 'w', encoding='utf-8').write(s)
print('dict sizes', {L: len(DD[L]) for L in LANGS})
print('ov sizes', {L: len(OVL[L]) for L in LANGS})
