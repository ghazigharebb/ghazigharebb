#!/usr/bin/env python3
"""زیادکردنی دەقەکانی دۆخی ڕووکار بۆ فەرهەنگی ٥ زمانەکە (kXxLit).
بەکارهێنان:  python3 tools/color_fix/i18n_apply.py lib/core
- ئەگەر کلیلەکە لە Lit دا هەبوو، بەهاکەی دەگۆڕێت؛ ئەگەر نا، زیاد دەکرێت (دووبارەبوونەوە نابێت).
- فایلەکانی تر دەست ناکەون. دووبارە جێبەجێکردن بێ کێشەیە."""
import json, re, sys, os
core = sys.argv[1] if len(sys.argv) > 1 else 'lib/core'
data = json.load(open(os.path.join(os.path.dirname(__file__), 'color_i18n.json'), encoding='utf8'))
def esc(s): return s.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$')
for L, ent in data.items():
    f = os.path.join(core, f'vx_{L}_data.dart')
    s = open(f, encoding='utf8').read()
    head = f'const Map<String, String> k{L.capitalize()}Lit = {{\n'
    if head not in s:
        print('SKIP (no Lit map):', f); continue
    a = s.index(head) + len(head); b = s.index('\n};', a); body = s[a:b]
    add = rep = 0
    for k, v in ent.items():
        kk = k if '\\' in k else esc(k)
        line = f'  "{kk}": "{v}",'
        pat = re.compile(r'^  "' + re.escape(kk) + r'": ".*",$', re.M)
        if pat.search(body): body = pat.sub(lambda m: line, body, 1); rep += 1
        else: body = line + '\n' + body; add += 1
    open(f, 'w', encoding='utf8').write(s[:a] + body + s[b:])
    print(f'{L}: +{add} ~{rep}')
