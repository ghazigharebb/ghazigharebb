#!/usr/bin/env python3
"""
VEX Health — all color fix / apply.py

هەموو lib/ ی ئەپەکە دەگۆڕێت بۆ ئەوەی ڕەنگەکان (ڕووناک / تاریک / خۆکار) لە VexTheme بخوێنرێنەوە.
لەسەر کۆدی خۆت (یان هەر وەشانێکی ئەپەکە) دەتوانیت بیخەیتە کار — idempotent ـە (دووبارە کردنەوەی زیان نییە).

  python3 tools/color_fix/apply.py lib            # گۆڕین (فایلە ڕەسەنەکان دەگۆڕێت)
  python3 tools/color_fix/apply.py lib --dry      # تەنها ڕاپۆرت، هیچ شتێک ناگۆڕێت
  python3 tools/color_fix/apply.py lib --check    # پشکنین: ئایا هیچ شتێکی ماوە کە کۆمپایل ناکات؟

چی دەکات:
  1. `const` لەو شوێنانە لادەبات کە ڕەنگی دینامیکی (V.* HC.* HX.* BandColors.* ...) تێدایە.
  2. `static const X = V.tx` / `static final X = ...` ← getter.
  3. `this.color = V.mint` (بنیاتنەری const) ← `Color? color` + initializer (و const لەسەر بنیاتنەرەکە لادەبرێت).
  4. `Color(0xFF...)` ← `vk(0xFF...)` (لە ڕووناکدا بە نزیکترین ڕەنگی پاڵێتی دەگۆڕدرێت).
  5. `Colors.white` ← `kW` (یان وەک خۆی ئەگەر لەسەر زەمینەی ڕەنگاوڕەنگ بێت).
"""
import os
import re
import sys

# ------------------------------------------------------------------ ڕێکخستن
# پۆلە سەرەکییەکانی ڕەنگ کە getter بوون (V.prime و V.ai هێشتا const ـن)
DYN_CLASSES = {'V', 'HC', 'HX', 'BandColors'}
CONST_MEMBERS = {'V': {'prime', 'ai'}}
DYN_IDENTS = {'vk', 'vkRGBO', 'vkARGB', 'kW', 'kOnAcc', 'kOnPrime', 'VexTheme'}
# ئەو فایلانەی دەستکاری ڕەنگی دەستنووسکراو (vk / kW) ناکرێن (سپلاش، ڕیکلام، کامێرا)
EXEMPT_SUBSTR = ['splash/', 'sponsor_ad.dart', 'plus/pay_sheet.dart', 'food_scan.dart', 'scan/scan_', 'core/vex_theme.dart',
                 'core/theme.dart', 'health/hc.dart', '_data.dart', '/vx_', 'vex_wear', '/ble/']
# فایلەکان کە بەتەواوی پشتگوێ دەخرێن
SKIP_SUBSTR = ['core/vex_theme.dart', '_data.dart', '/vx_', '/ble/', 'vex_wear']
ACCENT_REFS = re.compile(r'\b(V\.(cy|mint|violet|coral|amber|orange|c2)|HC\.(c|c2|ok|wn|bd|hr|hr2|orange)|BandColors\.(dot|label))\b')
PRIME_RE = re.compile(r'V\.prime\b|8FF3F9[\s\S]*3CF08A|3CF08A[\s\S]*8FF3F9', re.I)
FILL_ARGS = {'decoration', 'color', 'gradient', 'backgroundColor', 'fillColor', 'foregroundDecoration', 'activeColor', 'selectedColor'}
PRIME_LITS = ('0xFF8FF3F9', '0xFF3CF08A')


# فایلەکان کە هەمیشە تاریک دەمێننەوە (پەڕەی پریمیۆم): V.* ← VD.* (const ی تاریکی پێشوو)
ISLAND_SUBSTR = ['plus/plus_page.dart']


def is_island(path):
    return any(s in path.replace('\\', '/') for s in ISLAND_SUBSTR)


def island_convert(src):
    out = re.sub(r'\bV\.(?!prime\b|ai\b)(\w+)', r'VD.\1', src)
    return out


# ------------------------------------------------------------------ tokenizer
class Tok:
    __slots__ = ('k', 't', 's', 'e')

    def __init__(self, k, t, s, e):
        self.k, self.t, self.s, self.e = k, t, s, e

    def __repr__(self):
        return f'{self.k}:{self.t}'


MULTI = ['??=', '...', '=>', '==', '!=', '<=', '>=', '??', '?.', '..', '&&', '||', '+=', '-=', '*=', '/=', '++', '--', '~/']


def skip_string(src, i):
    """i = ئەو شوێنەی string ی لێ دەست پێدەکات (دەگەڕێنێتەوە کۆتایی)"""
    n = len(src)
    raw = False
    if src[i] == 'r' and i + 1 < n and src[i + 1] in '\'"':
        raw = True
        i += 1
    q = src[i]
    triple = src[i:i + 3] == q * 3
    i += 3 if triple else 1
    while i < n:
        c = src[i]
        if c == '\\' and not raw:
            i += 2
            continue
        if not raw and c == '$' and i + 1 < n and src[i + 1] == '{':
            i = skip_interp(src, i + 2)
            continue
        if triple:
            if src[i:i + 3] == q * 3:
                return i + 3
        elif c == q:
            return i + 1
        elif c == '\n' and not triple:
            return i  # بەدی نەکراو؛ بۆ سەلامەتی
        i += 1
    return n


def skip_interp(src, i):
    depth = 1
    n = len(src)
    while i < n and depth:
        c = src[i]
        if c in '\'"':
            i = skip_string(src, i)
            continue
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
        i += 1
    return i


def tokenize(src):
    toks = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in ' \t\r\n':
            i += 1
        elif src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j < 0 else j
        elif src.startswith('/*', i):
            d = 1
            i += 2
            while i < n and d:
                if src.startswith('/*', i):
                    d += 1
                    i += 2
                elif src.startswith('*/', i):
                    d -= 1
                    i += 2
                else:
                    i += 1
        elif c in '\'"' or (c == 'r' and i + 1 < n and src[i + 1] in '\'"' and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == '_'))):
            j = skip_string(src, i)
            toks.append(Tok('str', src[i:j], i, j))
            i = j
        elif c.isalpha() or c == '_' or c == '$':
            j = i + 1
            while j < n and (src[j].isalnum() or src[j] in '_$'):
                j += 1
            toks.append(Tok('id', src[i:j], i, j))
            i = j
        elif c.isdigit() or (c == '.' and i + 1 < n and src[i + 1].isdigit() and not (toks and toks[-1].k == 'id')):
            m = re.compile(r'0[xX][0-9a-fA-F_]+|\d[\d_]*\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?').match(src, i)
            j = m.end() if m else i + 1
            toks.append(Tok('num', src[i:j], i, j))
            i = j
        else:
            for m in MULTI:
                if src.startswith(m, i):
                    toks.append(Tok('p', m, i, i + len(m)))
                    i += len(m)
                    break
            else:
                toks.append(Tok('p', c, i, i + 1))
                i += 1
    return toks


def build_match(toks):
    """match[i] = شوێنی کەوانەی هاوتا، parent[i] = کەوانەی ناوەوەی دایک"""
    match, parent, stack = {}, [None] * len(toks), []
    pairs = {')': '(', ']': '[', '}': '{'}
    for i, t in enumerate(toks):
        parent[i] = stack[-1] if stack else None
        if t.k == 'p':
            if t.t in '([{':
                stack.append(i)
            elif t.t in pairs and stack:
                # دووپاتکردنەوە: ئەگەر کەوانەکە نەگونجا، بگەڕێ
                while stack and toks[stack[-1]].t != pairs[t.t]:
                    stack.pop()
                if stack:
                    o = stack.pop()
                    match[o] = i
                    match[i] = o
                    parent[i] = stack[-1] if stack else None
    return match, parent


# ------------------------------------------------------------------ شیکاری
class Ctx:
    def __init__(self):
        self.dyn_q = set()          # 'Class.name' ی گۆڕدراو بۆ getter
        self.dyn_priv = {}          # فایل -> {name}
        self.dyn_ctor = set()       # پۆلەکان کە const ـیان لێ لابراوە


def is_exempt(path):
    return any(s in path.replace('\\', '/') for s in EXEMPT_SUBSTR)


def is_skipped(path):
    return any(s in path.replace('\\', '/') for s in SKIP_SUBSTR)


def is_dyn(toks, i, ctx, path, count_raw=True):
    """ئایا ئەم تۆکنە ڕەنگی دینامیکی هەیە؟"""
    t = toks[i]
    if t.k != 'id':
        return False
    prev = toks[i - 1].t if i > 0 else ''
    if prev == '.':
        return False
    nxt = toks[i + 1].t if i + 1 < len(toks) else ''
    if t.t in DYN_CLASSES and nxt == '.' and i + 2 < len(toks):
        mem = toks[i + 2].t
        if mem in CONST_MEMBERS.get(t.t, ()):
            return False
        return True
    if t.t in DYN_IDENTS:
        return True
    if nxt == '.' and i + 2 < len(toks) and (t.t + '.' + toks[i + 2].t) in ctx.dyn_q:
        return True
    if t.t.startswith('_') and t.t in ctx.dyn_priv.get(path, ()):
        return True
    if count_raw and t.t == 'Color' and nxt == '(' and i + 2 < len(toks) and toks[i + 2].k == 'num' and not is_exempt(path):
        return True
    if t.t == 'Colors' and nxt == '.' and i + 2 < len(toks) and toks[i + 2].t == 'white' and not is_exempt(path):
        return True
    if (t.t == 'Color' and nxt == '.' and i + 2 < len(toks) and toks[i + 2].t in ('fromRGBO', 'fromARGB')
            and not is_exempt(path) and i + 4 < len(toks) and toks[i + 4].k == 'num'):
        return True
    if t.t in ctx.dyn_ctor and nxt in ('(', '.') and prev == 'const':
        return True
    return False


def range_dyn(toks, a, b, ctx, path):
    return any(is_dyn(toks, k, ctx, path) for k in range(a, b))


def parse_type(toks, j):
    """j ـەوە، جۆر دەخوێنێتەوە. دەگەڕێنێتەوە (کۆتایی) یان None"""
    n = len(toks)
    if j >= n or toks[j].k != 'id':
        return None
    j += 1
    if j + 1 < n and toks[j].t == '.' and toks[j + 1].k == 'id':
        j += 2
    if j < n and toks[j].t == '<':
        d = 0
        while j < n:
            if toks[j].t == '<':
                d += 1
            elif toks[j].t == '>':
                d -= 1
                if d == 0:
                    j += 1
                    break
            elif toks[j].t in (';', '{', '('):
                return None
            j += 1
    if j < n and toks[j].t == '?':
        j += 1
    return j


EXPR_PREV = {'=', '(', ',', '[', ':', '=>', '?', '??', '&&', '||', '+', '-', '*', '/', '!', '<', '>', '{', 'return', '...', '=='}


def const_kind(toks, i, parent):
    """const ی کام جۆرە؟ -> ('expr', end) | ('decl', typeEnd, nameIdx, eqIdx) | ('ctor',) """
    n = len(toks)
    prev = toks[i - 1].t if i > 0 else ''
    j = i + 1
    if j >= n:
        return ('other',)
    # declaration: const [Type] name =
    tend = parse_type(toks, j)
    if tend is not None and tend < n and toks[tend].k == 'id' and tend + 1 < n and toks[tend + 1].t == '=':
        return ('decl', tend, tend, tend + 1, j)
    if toks[j].k == 'id' and j + 1 < n and toks[j + 1].t == '=':
        return ('decl', None, j, j + 1, j)
    # constructor declaration: const Name( ... )  با prev ی نادەربڕین
    is_expr_prev = prev in EXPR_PREV or (toks[i - 1].k == 'id' and prev in ('return', 'else', 'case', 'in', 'await', 'yield')) if i > 0 else False
    if prev == '{' and parent[i] is not None:
        # { const Foo() } لەناو لیست/set یان کلاس؟ ئەگەر کەوانەی دایک ( بێ پارامیتەر، ئاسایی expression ـە
        pass
    k = j
    if toks[k].t == '<':  # const <T>[...]
        d = 0
        while k < n:
            if toks[k].t == '<':
                d += 1
            elif toks[k].t == '>':
                d -= 1
                if d == 0:
                    k += 1
                    break
            k += 1
    elif toks[k].k == 'id':
        k += 1
        while k + 1 < n and toks[k].t == '.' and toks[k + 1].k == 'id':
            k += 2
        if k < n and toks[k].t == '<':
            d = 0
            while k < n:
                if toks[k].t == '<':
                    d += 1
                elif toks[k].t == '>':
                    d -= 1
                    if d == 0:
                        k += 1
                        break
                k += 1
    if k < n and toks[k].t in '([{':
        return ('expr', k, is_expr_prev)
    return ('other',)


def span_of(toks, match, open_idx):
    return match.get(open_idx, open_idx)


# ------------------------------------------------------------------ کارکردن لەسەر یەک فایل
def analyse(path, src, ctx, collect_only=False):
    """edits ی ئەم فایلە دەگەڕێنێتەوە و ctx نوێ دەکاتەوە. changed=True ئەگەر ctx گۆڕا"""
    toks = tokenize(src)
    match, parent = build_match(toks)
    n = len(toks)
    edits = []  # (start, end, text)
    BIG = []    # ئەو بەشانەی بە تەواوی دەگۆڕدرێن؛ edit ی ناوەوەیان لادەبرێت
    changed = False
    notes = []
    exempt = is_exempt(path)
    used = set()  # تۆکنە دەستکاریکراوەکان

    def mark(a, b):
        for k in range(a, b):
            used.add(k)

    # ---------- 1) const decl / expr / ctor
    handled_ctor = set()
    for i, t in enumerate(toks):
        if not (t.k == 'id' and t.t == 'const'):
            continue
        kind = const_kind(toks, i, parent)
        if kind[0] == 'decl':
            _, tend, nameIdx, eqIdx, tstart = kind
            # کۆتایی initializer
            e = eqIdx + 1
            depth = 0
            while e < n:
                x = toks[e].t
                if toks[e].k == 'p':
                    if x in '([{':
                        depth += 1
                    elif x in ')]}':
                        depth -= 1
                        if depth < 0:
                            break
                    elif x == ';' and depth == 0:
                        break
                e += 1
            if range_dyn(toks, eqIdx + 1, e, ctx, path):
                prev = toks[i - 1].t if i > 0 else ''
                nm = toks[nameIdx].t
                enclosing = parent[i]
                is_static = prev == 'static'
                multi = split_declarators(toks, eqIdx, e)
                if (is_static or enclosing is None) and len(multi) > 1:
                    # const Color a = x, b = y;  ←  Color get a => x; Color get b => y;
                    tname = src[toks[i + 1].s:toks[tend].s].strip() if tend is not None else ''
                    pre = 'static ' if is_static else ''
                    parts = []
                    for (ni, a, b) in multi:
                        ex = src[toks[a].s:toks[b - 1].e]
                        parts.append(f'{pre}{(tname + " ") if tname else ""}get {toks[ni].t} => {ex};')
                    stmt_end = toks[e].e if e < n and toks[e].t == ';' else toks[e - 1].e
                    start = toks[i - 1].s if is_static else t.s
                    if not collect_only:
                        edits.append((start, stmt_end, ('\n' + ('  ' if is_static else '')).join(parts)))
                        BIG.append((start, stmt_end))
                        mark(i, e)
                    for (ni, a, b) in multi:
                        nm2 = toks[ni].t
                        if nm2.startswith('_'):
                            ss = ctx.dyn_priv.setdefault(path, set())
                            if nm2 not in ss:
                                ss.add(nm2)
                                changed = True
                        cls = enclosing_class(toks, parent, i)
                        if cls and (cls + '.' + nm2) not in ctx.dyn_q:
                            ctx.dyn_q.add(cls + '.' + nm2)
                            changed = True
                    continue
                if is_static or enclosing is None:
                    # getter
                    if not collect_only:
                        edits.append((t.s, toks[i + 1].s, ''))  # const
                        if tend is None:
                            first = toks[eqIdx + 1]
                            typ = 'Color ' if first.t in ('Color', 'vk', 'V', 'HC', 'BandColors', 'kW') else ''
                            edits.append((toks[nameIdx].s, toks[nameIdx].s, typ + 'get '))
                        else:
                            edits.append((toks[nameIdx].s, toks[nameIdx].s, 'get '))
                        edits.append((toks[eqIdx].s, toks[eqIdx].e, '=>'))
                        edits += cache_edits(toks, src, path, tend, i + 1, eqIdx, e, nm, enclosing_class(toks, parent, i))
                        mark(i, eqIdx + 1)
                    # ناوەکە بکە بە دینامیک
                    if nm.startswith('_'):
                        s = ctx.dyn_priv.setdefault(path, set())
                        if nm not in s:
                            s.add(nm)
                            changed = True
                    # پۆلی دایک
                    cls = enclosing_class(toks, parent, i)
                    q = (cls + '.' + nm) if cls else None
                    if q and q not in ctx.dyn_q:
                        ctx.dyn_q.add(q)
                        changed = True
                    if not cls and not nm.startswith('_'):
                        if nm not in DYN_IDENTS:
                            DYN_IDENTS.add(nm)
                            changed = True
                else:
                    if not collect_only:
                        edits.append((t.s, t.e, 'final'))
                        mark(i, i + 1)
            continue
        if kind[0] == 'expr':
            k = kind[1]
            # دەستپێکی ctor decl؟
            isctor = False
            if not kind[2]:
                isctor = True
            if isctor:
                # ئەگەر ctor decl بێت، کۆتاییەکەی ( ... ) ـە و دوای ئەوە : یان ; یان { دێت
                # (هەندێک جاریش expression ـە؛ پشکنینی نەرم)
                close = match.get(k, k)
                after = toks[close + 1].t if close + 1 < n else ''
                if after in (':', '{', ';', '=>') and toks[i - 1].t in (';', '}', '{', ')', ']') or (i > 0 and toks[i - 1].t in ('static', 'factory')):
                    continue
            close = match.get(k, k)
            if range_dyn(toks, i + 1, close + 1, ctx, path):
                if not collect_only:
                    edits.append((t.s, toks[i + 1].s, ''))
                    mark(i, i + 1)

    # ---------- 2) static final / top-level final ← getter
    for i, t in enumerate(toks):
        if not (t.k == 'id' and t.t == 'final'):
            continue
        prev = toks[i - 1].t if i > 0 else ''
        late = prev == 'late'
        class_level = in_class_body(toks, parent, i)
        if late and not class_level:
            continue
        j = i + 1
        tend = parse_type(toks, j)
        nameIdx = eqIdx = None
        if tend is not None and tend < n and toks[tend].k == 'id' and tend + 1 < n and toks[tend + 1].t == '=':
            nameIdx, eqIdx = tend, tend + 1
        elif toks[j].k == 'id' and j + 1 < n and toks[j + 1].t == '=':
            nameIdx, eqIdx, tend = j, j + 1, None
        else:
            continue
        member = prev == 'static' or (parent[i] is None) or class_level
        if not member:
            continue
        e = eqIdx + 1
        depth = 0
        while e < n:
            x = toks[e].t
            if toks[e].k == 'p':
                if x in '([{':
                    depth += 1
                elif x in ')]}':
                    depth -= 1
                    if depth < 0:
                        break
                elif x == ';' and depth == 0:
                    break
            e += 1
        if not range_dyn(toks, eqIdx + 1, e, ctx, path):
            continue
        nm = toks[nameIdx].t
        if not collect_only:
            edits.append(((toks[i - 1].s if late else t.s), toks[i + 1].s, ''))
            if tend is None:
                first = toks[eqIdx + 1]
                typ = 'Color ' if first.t in ('Color', 'vk', 'V', 'HC', 'BandColors', 'kW') else ''
                edits.append((toks[nameIdx].s, toks[nameIdx].s, typ + 'get '))
            else:
                edits.append((toks[nameIdx].s, toks[nameIdx].s, 'get '))
            edits.append((toks[eqIdx].s, toks[eqIdx].e, '=>'))
            if not class_level or prev == 'static':
                edits += cache_edits(toks, src, path, tend, j, eqIdx, e, nm, enclosing_class(toks, parent, i))
            mark(i, eqIdx + 1)
        if nm.startswith('_'):
            s = ctx.dyn_priv.setdefault(path, set())
            if nm not in s:
                s.add(nm)
                changed = True
        cls = enclosing_class(toks, parent, i)
        if cls and (cls + '.' + nm) not in ctx.dyn_q:
            ctx.dyn_q.add(cls + '.' + nm)
            changed = True

    # ---------- 4) Color(0x...) ← vk(...) ؛ Colors.white ← kW
    if not exempt:
        for i, t in enumerate(toks):
            if i in used:
                continue
            nxt = toks[i + 1].t if i + 1 < n else ''
            prev = toks[i - 1].t if i > 0 else ''
            if t.k == 'id' and t.t == 'Color' and nxt == '(' and prev != '.' and i + 2 < n and toks[i + 2].k == 'num' and i + 3 < n and toks[i + 3].t == ')':
                # گرادیەنتی prime وەک خۆی بمێنێتەوە
                if in_prime_list(toks, parent, match, i, src):
                    continue
                if not collect_only:
                    edits.append((t.s, t.e, 'vk'))
            elif (t.k == 'id' and t.t == 'Color' and nxt == '(' and prev not in ('.', 'const') and i + 4 < n
                  and toks[i + 2].k == 'id' and toks[i + 3].t == '.' and toks[i + 4].t in ('color', 'c', 'col') and i + 5 < n and toks[i + 5].t == ')'):
                # Color(d.color) / Color(p.c) ← vk(...)
                if not collect_only:
                    edits.append((t.s, t.e, 'vk'))
            elif (t.k == 'id' and t.t == 'Color' and nxt == '(' and prev != '.' and i + 2 < n and toks[i + 2].k != 'num'
                  and not (i + 4 < n and toks[i + 3].t == '.' and toks[i + 4].t in ('color', 'c', 'col'))):
                notes.append(f'REVIEW Color(...): {os.path.basename(path)}:{line_of(src, t.s)}  `{src[t.s:toks[min(i + 6, n - 1)].e][:50]}`')
            elif (t.k == 'id' and t.t == 'Color' and nxt == '.' and prev != '.' and i + 4 < n and toks[i + 2].t in ('fromRGBO', 'fromARGB')
                  and toks[i + 3].t == '(' and toks[i + 4].k == 'num'):
                if not collect_only:
                    edits.append((t.s, toks[i + 2].e, 'vkRGBO' if toks[i + 2].t == 'fromRGBO' else 'vkARGB'))
            elif t.k == 'id' and t.t == 'Colors' and nxt == '.' and i + 2 < n and toks[i + 2].t == 'white' and prev != '.':
                kind = fill_kind(toks, parent, match, src, i)
                if kind == 'accent':
                    continue
                rep = 'kOnPrime' if kind == 'prime' else 'kW'
                if not collect_only:
                    edits.append((t.s, toks[i + 2].e, rep))
            elif t.k == 'id' and t.t in ('V', 'HC') and nxt == '.' and i + 2 < n and toks[i + 2].t == 'ink' and prev != '.':
                kind = fill_kind(toks, parent, match, src, i)
                if kind == 'accent':
                    if not collect_only:
                        edits.append((t.s, toks[i + 2].e, 'kOnAcc'))

    # ---------- 3) پارامیتەری default ی دینامیک
    fn_inits = {}    # لەشی function -> [ 'p ??= EXPR;' ]
    ctor_inits = {}  # ctor-close-paren-index -> [ 'name = name ?? EXPR' ]
    for i, t in enumerate(toks):
        if not (t.k == 'p' and t.t == '='):
            continue
        if i < 2 or toks[i - 1].k != 'id':
            continue
        # کۆتایی expression
        e = i + 1
        depth = 0
        while e < n:
            x = toks[e]
            if x.k == 'p':
                if x.t in '([{':
                    depth += 1
                elif x.t in ')]}':
                    depth -= 1
                    if depth < 0:
                        break
                elif x.t in (',', ';') and depth == 0:
                    break
            e += 1
        if not range_dyn(toks, i + 1, e, ctx, path):
            continue
        if toks[i - 2].t == '..' or toks[i - 2].t == '?..':
            continue
        # لەناو لیستی پارامیتەرە؟
        p = parent[i]
        if p is None:
            continue
        brace = None
        if toks[p].t in '{[':
            brace = p
            p = parent[p]
            if p is None or toks[p].t != '(':
                continue
            if toks[brace].t == '{' and toks[brace - 1].t not in (',', '('):
                continue
        elif toks[p].t != '(':
            continue
        # decl نەک call: ئەگەر پێش ( ناوێک بێت و پێش ئەوە const/جۆر/class...
        name_i = p - 1
        if name_i >= 0 and toks[name_i].t == '>':  # name<T>(
            d = 0
            while name_i >= 0:
                if toks[name_i].t == '>':
                    d += 1
                elif toks[name_i].t == '<':
                    d -= 1
                    if d == 0:
                        name_i -= 1
                        break
                name_i -= 1
        if name_i < 0 or toks[name_i].k != 'id':
            continue
        # ctor ی ناو پۆل: Name( یان Name.named(
        start = name_i
        if start >= 2 and toks[start - 1].t == '.' and toks[start - 2].k == 'id':
            start -= 2
        cname = toks[start].t
        has_const = start > 0 and toks[start - 1].t == 'const'
        cls = enclosing_class(toks, parent, start)
        is_ctor = (cname == cls)
        pname = toks[i - 1].t
        field_formal = i >= 3 and toks[i - 2].t == '.' and toks[i - 3].t == 'this'
        if not is_ctor and not field_formal:
            # function / method: `Type p = EXPR` ← `Type? p` + `p ??= EXPR;` لە سەرەتای لەشی function
            close = match.get(p, p)
            nb = toks[close + 1] if close + 1 < n else None
            okt = i >= 3 and toks[i - 2].k == 'id' and toks[i - 3].t in ('{', ',', '(', '[') and not toks[i - 2].t in ('final', 'var', 'required')
            if nb is not None and nb.t in ('{', '=>') and okt:
                typ = toks[i - 2].t
                expr_txt = render_range(src, edits, toks[i + 1].s, toks[e - 1].e)
                if not collect_only:
                    edits.append((toks[i - 2].s, toks[e - 1].e, f'{typ}? {pname}'))
                    BIG.append((toks[i - 2].s, toks[e - 1].e))
                    mark(i - 2, e)
                    fn_inits.setdefault(close + 1, []).append(f'{pname} ??= {expr_txt};')
                continue
        if not is_ctor or not field_formal:
            notes.append(f'MANUAL default: {os.path.basename(path)}:{line_of(src, t.s)}  `{pname} = ...` (ڕەنگی دینامیک لە پارامیتەری ئەو function ـە)')
            continue
        # this.x = EXPR  ←  `Color? x`  +  initializer
        expr_txt = render_range(src, edits, toks[i + 1].s, toks[e - 1].e)
        # جۆری field: دەگەڕێین لە پۆلەکە بۆ `final TYPE x;`
        ftype = find_field_type(toks, parent, start, pname) or 'Color'
        if not ftype.endswith('?'):
            qtype = ftype + '?'
        else:
            qtype = ftype
        if not collect_only:
            # `this.x = EXPR` ← `QTYPE x`
            edits.append((toks[i - 3].s, toks[e - 1].e, f'{qtype} {pname}'))
            BIG.append((toks[i - 3].s, toks[e - 1].e))
            mark(i - 3, e)
            close = match[p]
            ctor_inits.setdefault((close, start, has_const), []).append(f'{pname} = {pname} ?? {expr_txt}')
        if cls not in ctx.dyn_ctor:
            ctx.dyn_ctor.add(cls)
            changed = True

    # لەشی function: p ??= EXPR
    if not collect_only:
        for bi, stmts in fn_inits.items():
            b = toks[bi]
            txt = ' '.join(stmts)
            if b.t == '{':
                edits.append((b.e, b.e, ' ' + txt))
            else:  # =>  expr ;
                k = bi + 1
                depth = 0
                while k < n:
                    x = toks[k]
                    if x.k == 'p':
                        if x.t in '([{':
                            depth += 1
                        elif x.t in ')]}':
                            depth -= 1
                        elif x.t == ';' and depth == 0:
                            break
                    k += 1
                edits.append((b.s, b.e, '{ ' + txt + ' return'))
                edits.append((toks[k].s, toks[k].e, '; }'))

    # initializer list و لادانی const ی بنیاتنەر
    if not collect_only:
        for (close, start, has_const), inits in ctor_inits.items():
            if has_const:
                edits.append((toks[start - 1].s, toks[start].s, ''))
            nxt = toks[close + 1].t if close + 1 < n else ''
            txt = ', '.join(inits)
            if nxt == ':':
                edits.append((toks[close + 1].e, toks[close + 1].e, ' ' + txt + ','))
            else:
                edits.append((toks[close].e, toks[close].e, ' : ' + txt))

    # edit ـەکانی ناو بەشێکی گۆڕدراوی تەواو لادەبرێن
    if BIG:
        keep = []
        for (s0, e0, tx) in edits:
            inside = any(bs <= s0 and e0 <= be and (s0, e0) != (bs, be) and not (tx and (s0, e0) in BIG) for bs, be in BIG)
            if not inside:
                keep.append((s0, e0, tx))
        edits = keep
    return edits, changed, notes, toks


def split_declarators(toks, eqIdx, e):
    """`= a, b = c, d = e` ← [(nameIdx, startExpr, endExpr)] (تەنها کاتێک چەند ناوێک هەبێ)"""
    out, depth, start, name = [], 0, eqIdx + 1, eqIdx - 1
    k = eqIdx + 1
    while k < e:
        x = toks[k]
        if x.k == 'p':
            if x.t in '([{':
                depth += 1
            elif x.t in ')]}':
                depth -= 1
            elif x.t == ',' and depth == 0:
                out.append((name, start, k))
                # دوای کۆما: name = ...
                name, start = k + 1, k + 3
                k += 2
        k += 1
    out.append((name, start, e))
    return out


SIMPLE_TYPES = {'Color', 'TextStyle', 'String', 'double', 'int', 'bool', 'num', 'LinearGradient', 'RadialGradient',
                'BoxDecoration', 'Gradient', 'BorderSide', 'Border', 'BoxShadow'}


def cache_edits(toks, src, path, tend, j, eqIdx, e, nm, cls):
    """getter ی لیست/map/پۆل ← vexCache<T>('key', () => expr)  (تا لە هەر فریمێکدا دروست نەکرێتەوە)"""
    if tend is None or toks[j].t in SIMPLE_TYPES or toks[j].t == 'Widget':
        return []
    typ = src[toks[j].s:toks[tend - 1].e]
    key = f"{os.path.basename(path)}:{(cls + '.') if cls else ''}{nm}"
    last = toks[e - 1].e
    return [(toks[eqIdx].e, toks[eqIdx].e, f" vexCache<{typ}>('{key}', () =>"), (last, last, ')')]


def line_of(src, pos):
    return src.count('\n', 0, pos) + 1


def enclosing_class(toks, parent, i):
    """ناوی نزیکترین class ی دەوری i"""
    p = parent[i]
    while p is not None:
        if toks[p].t == '{':
            # بگەڕێ دواوە بۆ `class Name`
            j = p - 1
            depth = 0
            while j >= 0 and toks[j].t not in (';', '}', '{') :
                if toks[j].k == 'id' and toks[j].t in ('class', 'mixin', 'extension', 'enum') and j + 1 < len(toks):
                    return toks[j + 1].t
                j -= 1
            # کلاس نییە (function body) — بچۆ سەرەوە
        p = parent[p]
    return None


def in_class_body(toks, parent, i):
    b = parent[i]
    if b is None or toks[b].t != '{':
        return False
    j = b - 1
    while j >= 0 and toks[j].t not in (';', '}', '{'):
        if toks[j].t in ('class', 'mixin', 'extension', 'enum'):
            return True
        j -= 1
    return False


def find_field_type(toks, parent, ctor_start, pname):
    cls_brace = None
    p = parent[ctor_start]
    if p is None:
        return None
    # `final TYPE pname;` لەناو هەمان class body
    for j in range(len(toks) - 3):
        if parent[j] == p and toks[j].t == 'final':
            tend = parse_type(toks, j + 1)
            if tend is not None and toks[tend].t == pname and toks[tend + 1].t in (';', '='):
                return ''.join(x.t if x.k == 'p' else (' ' + x.t if False else x.t) for x in toks[j + 1:tend]) if tend - (j + 1) > 1 else toks[j + 1].t
    return None


def in_prime_list(toks, parent, match, i, src):
    """ڕەنگی ناو `gradient: LinearGradient(colors: [... 8FF3F9 ...])` (زەمینەی کاڵی دوگمە/ئاڤاتار) ← وەک خۆی دەمێنێتەوە.
    (گرادیەنتی دەق و ShaderMask و painter ـەکان دەگۆڕدرێن)"""
    p = parent[i]
    if p is None or toks[p].t != '[' or p not in match:
        return False
    txt = src[toks[p].s:toks[match[p]].e]
    if '8FF3F9' not in txt.upper():
        return False
    if p < 2 or toks[p - 1].t != ':' or toks[p - 2].t != 'colors':
        return False
    call = parent[p]
    if call is None or toks[call].t != '(' or call < 1:
        return False
    if toks[call - 1].t not in ('LinearGradient', 'RadialGradient', 'SweepGradient'):
        return False
    k = call - 2
    steps = 0
    while k >= 1 and steps < 12 and toks[k].t not in (',', ';', '{', '(', '['):
        if toks[k].t == ':' and toks[k - 1].t == 'gradient':  # gradient: [cond ?] LinearGradient(
            return True
        k -= 1
        steps += 1
    return False


def split_args(toks, match, o):
    """argument ـەکانی ( ... ) : لیستی (a, b) ی تۆکنەکان"""
    c = match.get(o, o)
    args, s, d = [], o + 1, 0
    for k in range(o + 1, c):
        x = toks[k]
        if x.k == 'p':
            if x.t in '([{':
                d += 1
            elif x.t in ')]}':
                d -= 1
            elif x.t == ',' and d == 0:
                args.append((s, k))
                s = k + 1
    if s < c:
        args.append((s, c))
    return args


def fill_kind(toks, parent, match, src, i):
    """لەسەر چ زەمینەیەکە؟  'prime' | 'accent' | 'none'"""
    p = parent[i]
    levels = 0
    cur = i
    while p is not None and levels < 9:
        if toks[p].t == '(':
            for (a, b) in split_args(toks, match, p):
                if a <= cur < b:
                    continue
                if b - a >= 3 and toks[a].k == 'id' and toks[a + 1].t == ':' and toks[a].t in FILL_ARGS:
                    k = classify_value(toks, match, src, a + 2, b, toks[a].t)
                    if k:
                        return k
        cur = p
        p = parent[p]
        levels += 1
    return 'none'


def classify_value(toks, match, src, a, b, argname):
    """بەهای arg ی (decoration / color / gradient ...)"""
    if a >= b:
        return None
    if argname == 'decoration':
        if toks[a].k == 'id' and toks[a].t in ('BoxDecoration', 'ShapeDecoration') and a + 1 < b and toks[a + 1].t == '(':
            for (x, y) in split_args(toks, match, a + 1):
                if y - x >= 3 and toks[x].k == 'id' and toks[x + 1].t == ':' and toks[x].t in ('color', 'gradient'):
                    k = classify_value(toks, match, src, x + 2, y, toks[x].t)
                    if k:
                        return k
        return None
    txt = src[toks[a].s:toks[b - 1].e].strip()
    return classify_fill(txt, argname)


def classify_fill(txt, arg):
    t = txt.strip()
    if PRIME_RE.search(t) or '8FF3F9' in t.upper():
        return 'prime'
    if 'Gradient' in t:
        if ACCENT_REFS.search(t) or re.search(r'0xFF(?:3C|2F|FF[0-9A-F]|9B|8B|14|3D|1A|7B|4D)', t, re.I):
            return 'accent'
        return None
    if re.fullmatch(r'(V\.(cy|mint|violet|coral|amber|orange)|HC\.(c|ok|wn|bd|hr|orange)|BandColors\.dot)', t):
        return 'accent'
    return None


def render_range(src, edits, a, b):
    """src[a:b] دوای جێبەجێکردنی edit ـەکانی ناو ئەو بەشە"""
    inner = [(s0 - a, e0 - a, tx) for (s0, e0, tx) in edits if s0 >= a and e0 <= b]
    return apply_edits(src[a:b], inner)


def apply_edits(src, edits):
    edits = sorted(edits, key=lambda e: (e[0], e[1]), reverse=True)
    out = src
    last = None
    for s, e, txt in edits:
        if last is not None and e > last:
            continue  # لەیەکدان؛ پشتگوێ بخە
        out = out[:s] + txt + out[e:]
        last = s
    return out


# ------------------------------------------------------------------ لینت (پشکنینی ماوە)
def lint(path, src, ctx):
    """کێشە دەگەڕێنێتەوە کە دوای گۆڕین نابێ بمێنن"""
    toks = tokenize(src)
    match, parent = build_match(toks)
    n = len(toks)
    probs = []
    for i, t in enumerate(toks):
        if t.k == 'id' and t.t == 'const':
            kind = const_kind(toks, i, parent)
            if kind[0] == 'expr' and kind[2]:
                close = match.get(kind[1], kind[1])
                if range_dyn(toks, i + 1, close + 1, ctx, path):
                    probs.append((line_of(src, t.s), 'const لەگەڵ ڕەنگی دینامیک'))
            elif kind[0] == 'decl':
                e = kind[3] + 1
                depth = 0
                while e < n:
                    x = toks[e]
                    if x.k == 'p':
                        if x.t in '([{':
                            depth += 1
                        elif x.t in ')]}':
                            depth -= 1
                            if depth < 0:
                                break
                        elif x.t == ';' and depth == 0:
                            break
                    e += 1
                if range_dyn(toks, kind[3] + 1, e, ctx, path):
                    probs.append((line_of(src, t.s), 'const decl لەگەڵ ڕەنگی دینامیک'))
    for i, t in enumerate(toks):
        if t.k == 'p' and t.t == '=' and i > 0 and toks[i - 1].k == 'id':
            p = parent[i]
            if p is None:
                continue
            if toks[p].t in '{[':
                q = parent[p]
                if q is None or toks[q].t != '(':
                    continue
                if toks[p].t == '{' and toks[p - 1].t not in (',', '('):
                    continue
                p = q
            if toks[p].t != '(':
                continue
            e = i + 1
            depth = 0
            while e < n:
                x = toks[e]
                if x.k == 'p':
                    if x.t in '([{':
                        depth += 1
                    elif x.t in ')]}':
                        depth -= 1
                        if depth < 0:
                            break
                    elif x.t in (',', ';') and depth == 0:
                        break
                e += 1
            if i >= 2 and toks[i - 2].t in ('..', '?..'):
                continue
            if range_dyn(toks, i + 1, e, ctx, path):
                probs.append((line_of(src, t.s), 'default param لەگەڵ ڕەنگی دینامیک'))
    return probs



# ------------------------------------------------------------------ پاڵێتی کلاسەکان (V / HC / HX / BandColors)
PAL_V = ['bg', 'surf', 'surf2', 'line', 'line2', 'cy', 'c2', 'mint', 'violet', 'coral', 'amber', 'orange', 'tx', 'mu', 'track', 'nav', 'sheet', 'ink']
PAL_HC = {'bg': 'hBg', 'bg2': 'hBg2', 'card': 'hCard', 'line': 'hLine', 'c': 'hC', 'c2': 'hC2', 'tx': 'hTx', 'mu': 'hMu',
          'track': 'hTrack', 'glow': 'hGlow', 'ok': 'hOk', 'wn': 'hWn', 'bd': 'hBd', 'nd': 'hNd', 'orange': 'hOrange',
          'hr': 'hHr', 'hr2': 'hHr2', 'ink': 'hInk'}
PAL_BAND = {'dot': 'V.coral', 'label': 'V.amber', 'mute': 'V.mu'}
EXPORT_LINE = ("export 'vex_theme.dart' show VexTheme, VexMode, VexPal, ThemeModePicker, VD, kDarkIslandChrome, "
               "vk, vkRGBO, vkARGB, kW, kOnAcc, kOnPrime, vexHex, vexMapHex, vexCache;")


def convert_palettes(path, src):
    """`static const Color x = Color(..)` لەناو V / HC / BandColors ← getter ی VexTheme ؛ HX ← vexHex(HC.x)"""
    changed = False
    for cname in ('V', 'HC', 'HX', 'BandColors'):
        toks = tokenize(src)
        match, parent = build_match(toks)
        cls = None
        for i, t in enumerate(toks):
            if t.t == 'class' and i + 2 < len(toks) and toks[i + 1].t == cname and toks[i + 2].t == '{':
                cls = i + 2
                break
        if cls is None:
            continue
        end = match[cls]
        edits = []
        i = cls + 1
        while i < end:
            t = toks[i]
            if (t.t == 'static' and toks[i + 1].t == 'const' and parent[i] == cls):
                # static const TYPE NAME = EXPR ;
                ti = i + 2
                typ = toks[ti].t
                ni = ti + 1
                if toks[ni].k == 'id' and toks[ni + 1].t == '=':
                    e = ni + 2
                    d = 0
                    while e < end:
                        x = toks[e]
                        if x.k == 'p':
                            if x.t in '([{':
                                d += 1
                            elif x.t in ')]}':
                                d -= 1
                            elif x.t == ';' and d == 0:
                                break
                        e += 1
                    name = toks[ni].t
                    expr = src[toks[ni + 2].s:toks[e - 1].e]
                    new = None
                    if typ == 'Color':
                        if cname == 'V' and name in PAL_V:
                            new = f'static Color get {name} => VexTheme.I.p.{name};'
                        elif cname == 'HC' and name in PAL_HC:
                            new = f'static Color get {name} => VexTheme.I.p.{PAL_HC[name]};'
                        elif cname == 'BandColors' and name in PAL_BAND:
                            new = f'static Color get {name} => {PAL_BAND[name]};'
                        else:
                            new = f'static Color get {name} => {expr.replace("Color(", "vk(", 1) if expr.startswith("Color(") else expr};'
                    elif typ == 'String' and cname == 'HX':
                        if name in PAL_HC:
                            new = f'static String get {name} => vexHex(HC.{name});'
                        else:
                            new = f'static String get {name} => vexMapHex({expr});'
                    if new:
                        edits.append((t.s, toks[e].e, new))
                    i = e
            i += 1
        if edits:
            src = apply_edits(src, edits)
            changed = True
    if changed:
        low = src
        if 'vex_theme.dart' not in low:
            if re.search(r"^import 'vx_en\.dart';", low, re.M):
                low = re.sub(r"^(import 'vx_en\.dart';)", "import 'vex_theme.dart';\n\\1", low, count=1, flags=re.M)
                low = re.sub(r"^(export 'vx_en\.dart' show)", EXPORT_LINE + "\n\\1", low, count=1, flags=re.M)
        if 'vex_theme.dart' not in low and 'class V ' in low:
            # دوا import
            ms = list(re.finditer(r"^import .*;$", low, re.M))
            if ms:
                pos = ms[-1].end()
                low = low[:pos] + "\nimport 'vex_theme.dart';\n" + EXPORT_LINE + low[pos:]
        src = low
    return src, changed


NEED_IMPORT_RE = re.compile(r'\b(vexCache|vk|kW|kOnAcc|kOnPrime|vkRGBO|vkARGB|vexHex|vexMapHex|VexTheme)\b')


def ensure_import(path, src, root):
    """ئەگەر فایل vk / kW ... بەکاردەهێنێت بەڵام theme.dart ی import نەکردووە، import ی بۆ زیاد دەکات"""
    if path.replace('\\', '/').endswith('core/theme.dart') or path.replace('\\', '/').endswith('core/vex_theme.dart'):
        return src
    body = re.sub(r"^(import|export) .*$", '', src, flags=re.M)
    if not NEED_IMPORT_RE.search(body):
        return src
    if re.search(r"^import '[^']*(?:core/)?(?:vex_)?theme\.dart';", src, re.M):
        return src
    rel = os.path.relpath(os.path.join(root, 'core', 'theme.dart'), os.path.dirname(path)).replace('\\', '/')
    ms = list(re.finditer(r"^import .*;$", src, re.M))
    line = f"import '{rel}';"
    if ms:
        pos = ms[-1].end()
        return src[:pos] + '\n' + line + src[pos:]
    return line + '\n' + src


# ------------------------------------------------------------------ main
def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    flags = {a for a in sys.argv[1:] if a.startswith('--')}
    if not args:
        print(__doc__)
        sys.exit(1)
    root = args[0]
    files = []
    for dp, dn, fn in os.walk(root):
        for f in fn:
            if f.endswith('.dart'):
                p = os.path.join(dp, f)
                if not is_skipped(p):
                    files.append(p)
    files.sort()
    islands = [p for p in files if is_island(p)]
    files = [p for p in files if not is_island(p)]
    for p in islands:
        src = open(p, encoding='utf-8').read()
        out = island_convert(src)
        if re.search(r'\b(HC|HX|BandColors)\.', out):
            print(f'  ! {p}: HC/HX ماوە (دورگەی تاریک تەنها V پشتگیری دەکات)')
        if out != src and '--dry' not in flags and '--check' not in flags:
            open(p, 'w', encoding='utf-8').write(out)
            print(f'  {p} (دورگەی تاریک)')
    srcs = {p: open(p, encoding='utf-8').read() for p in files}
    ctx = Ctx()
    if '--check' not in flags:
        for p in files:
            if any(k in srcs[p] for k in ('class V {', 'class HC {', 'class HX {', 'class BandColors {')):
                out, ch = convert_palettes(p, srcs[p])
                if ch:
                    srcs[p] = out
                    print(f'  پاڵێت: {p}')
                    if '--dry' not in flags:
                        open(p, 'w', encoding='utf-8').write(out)

    # --- fixpoint (کۆکردنەوەی ناوە دینامیکەکان)
    for _ in range(8):
        any_change = False
        for p in files:
            _, ch, _, _ = analyse(p, srcs[p], ctx, collect_only=True)
            any_change |= ch
        if not any_change:
            break

    if '--check' in flags:
        total = 0
        for p in files:
            for ln, msg in lint(p, srcs[p], ctx):
                print(f'{p}:{ln}: {msg}')
                total += 1
        print(f'پشکنین: {total} کێشە')
        sys.exit(1 if total else 0)

    changed_files = set()
    all_notes = []
    for rnd in range(4):  # دووبارە تا هیچ گۆڕانکارییەک نەمێنێت
        round_changes = 0
        all_notes = []
        for p in files:
            edits, _, notes, _ = analyse(p, srcs[p], ctx)
            all_notes += notes
            if not edits:
                continue
            out = ensure_import(p, apply_edits(srcs[p], edits), root)
            if out != srcs[p]:
                round_changes += 1
                changed_files.add(p)
                srcs[p] = out
                if '--dry' not in flags:
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(out)
        if '--dry' in flags or not round_changes:
            break
    for p in sorted(changed_files):
        print(f'  {p}')
    changed_files = len(changed_files)
    print(f'\nفایلی گۆڕدراو: {changed_files}')
    if ctx.dyn_ctor:
        print('بنیاتنەرە بێ-const بووەکان (const ی بانگکردنیان لابرا):', ', '.join(sorted(ctx.dyn_ctor)))
    for nline in all_notes:
        print(nline)
    if '--dry' not in flags:
        print('\nدووبارە بەکاربهێنە تا هیچ گۆڕانکارییەکی نوێ نەمێنێت، پاشان: python3 tools/color_fix/apply.py lib --check')


if __name__ == '__main__':
    main()
