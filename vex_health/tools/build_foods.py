#!/usr/bin/env python3
"""VEX Health — لیستی خواردنەکان دروست دەکات و دەیپشکنێت.

    python3 tools/build_foods.py

tools/foods_src.txt دەخوێنێتەوە، هەموو ژمارەکان دەپشکنێت (کالۆری بەرامبەر پڕۆتین/کارب/چەوری،
شەکر و ڕیشاڵ ≤ کارب، ناوی دووبارە...) و assets/data/foods.json دروست دەکات.
ئەگەر هەڵەیەک هەبێت، هیچ شتێک نانووسێت.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'tools', 'foods_src.txt')
OUT = os.path.join(ROOT, 'assets', 'data', 'foods.json')
ID_RE = re.compile(r'^[a-z][a-z0-9_]{1,40}$')


def num(s):
    v = float(s)
    return int(v) if v == int(v) else v


def main():
    cats, foods, errs, warns = [], [], [], []
    cat = None
    ids, names = set(), {}
    for ln, raw in enumerate(open(SRC, encoding='utf-8'), 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith('@cat'):
            k, t, e = [x.strip() for x in line[4:].split('|')]
            cat = k
            cats.append({'k': k, 't': t, 'e': e})
            continue
        parts = [x.strip() for x in line.split('|')]
        if len(parts) != 8:
            errs.append(f'{ln}: {len(parts)} بەش لە جیاتی 8')
            continue
        fid, ku, ar, en, al, emo, nut, units = parts
        if cat is None:
            errs.append(f'{ln}: پۆل دیاری نەکراوە')
        if not ID_RE.match(fid):
            errs.append(f'{ln}: id ی هەڵە {fid}')
        if fid in ids:
            errs.append(f'{ln}: id دووبارە {fid}')
        ids.add(fid)
        if ku in names:
            errs.append(f'{ln}: ناوی دووبارە «{ku}» (هەروەها دێڕی {names[ku]})')
        names[ku] = ln
        try:
            n = [float(x) for x in nut.split()]
        except ValueError:
            errs.append(f'{ln}: ژمارەی هەڵە')
            continue
        if len(n) != 6:
            errs.append(f'{ln}: پێویستە 6 ژمارە بێت')
            continue
        k, p, c, f, fib, sug = n
        if min(n) < 0:
            errs.append(f'{ln}: ژمارەی سالب')
        if p + c + f > 100.5:
            errs.append(f'{ln}: پڕۆتین+کارب+چەوری > 100g')
        if sug > c + 0.05:
            errs.append(f'{ln}: شەکر ({sug}) > کارب ({c})')
        if fib > c + 0.05:
            errs.append(f'{ln}: ڕیشاڵ ({fib}) > کارب ({c})')
        est = 4 * p + 4 * max(0.0, c - fib) + 2 * fib + 9 * f
        if k >= 20:
            dev = abs(est - k) / k
            # بۆ خواردنی کەم کالۆری (سەوزە، میوە) جیاوازی 12 kcal ئاساییە (USDA)
            if dev > 0.15 and not (k < 60 and abs(est - k) <= 12):
                errs.append(f'{ln}: {ku}: kcal {k} بەڵام لە پێکهاتەکانەوە {est:.0f} ({dev*100:.0f}%)')
            elif dev > 0.10:
                warns.append(f'{ln}: {ku}: {k} ⟷ {est:.0f} ({dev*100:.0f}%)')
        elif abs(est - k) > 8:
            errs.append(f'{ln}: {ku}: kcal {k} ⟷ {est:.0f}')
        us = []
        for u in [x.strip() for x in units.split(';') if x.strip()]:
            if '=' not in u:
                errs.append(f'{ln}: یەکەی هەڵە «{u}»')
                continue
            un, g = u.rsplit('=', 1)
            g = float(g)
            if g <= 0 or g > 1000:
                errs.append(f'{ln}: کێشی یەکە هەڵەیە «{u}»')
            us.append([un.strip(), num(g)])
        if not us:
            errs.append(f'{ln}: یەکە نییە')
        aliases = [a.strip() for a in re.split('[،,]', al) if a.strip()]
        foods.append({
            'id': fid, 'ku': ku, 'ar': ar, 'en': en, 'al': aliases, 'c': cat, 'e': emo,
            'n': [num(x) for x in n], 'u': us,
        })
    for w in warns:
        print('⚠️ ', w)
    if errs:
        for e in errs:
            print('❌', e)
        print(f'\n{len(errs)} هەڵە — هیچ شتێک نەنووسرا.')
        sys.exit(1)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8') as fh:
        json.dump({'v': 1, 'cats': cats, 'foods': foods}, fh, ensure_ascii=False, separators=(',', ':'))
    # لیستی Excel بۆ وێنەگرتن: ناوی فایلی هەر وێنەیەک
    import csv
    cat_t = {c['k']: c['t'] for c in cats}
    with open(os.path.join(ROOT, 'tools', 'foods_list.csv'), 'w', encoding='utf-8-sig', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(['#', 'ناوی فایلی وێنە', 'ناوی کوردی', 'عەرەبی', 'پۆل', 'یەکە', 'کێشی یەکە (g)', 'کالۆری یەکەیەک', 'kcal / 100g'])
        for i, f in enumerate(foods, 1):
            u = f['u'][0]
            w.writerow([i, f['id'] + '.webp', f['ku'], f['ar'], cat_t[f['c']], u[0], u[1], round(f['n'][0] * u[1] / 100), f['n'][0]])
    print(f'✓ {len(foods)} خواردن لە {len(cats)} پۆلدا ← {os.path.relpath(OUT, ROOT)} ({os.path.getsize(OUT)//1024} KB)')
    for c in cats:
        print(f"   {c['e']} {c['t']}: {sum(1 for f in foods if f['c'] == c['k'])}")


if __name__ == '__main__':
    main()
