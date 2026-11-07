# Shape Kurdish/Arabic text with HarfBuzz and export each shaped glyph as an SVG path (font units, y-up).
# usage: shape_text.py <font.woff2|ttf> <text> <out.json>
import sys, json, io
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.basePen import decomposeQuadraticSegment
fontpath, text, out = sys.argv[1], sys.argv[2], sys.argv[3]
tt = TTFont(fontpath); tt.flavor = None
buf = io.BytesIO(); tt.save(buf); data = buf.getvalue()
face = hb.Face(data); font = hb.Font(face)
b = hb.Buffer(); b.add_str(text); b.guess_segment_properties()
b.direction = 'rtl'; b.script = 'Arab'; b.language = 'ckb'
hb.shape(font, b, {'kern': True, 'liga': True})
gs = tt.getGlyphSet(); order = tt.getGlyphOrder()
def rec_to_path(ops):
    # explicit absolute commands only: M L Q C Z (TrueType qCurveTo may carry several implied on-curve points)
    out = []; cur = None
    f = lambda p: f'{p[0]:.2f} {p[1]:.2f}'
    for op, pts in ops:
        if op == 'moveTo': out.append('M' + f(pts[0])); cur = pts[0]
        elif op == 'lineTo': out.append('L' + f(pts[0])); cur = pts[0]
        elif op == 'curveTo': out.append('C' + ' '.join(f(p) for p in pts)); cur = pts[-1]
        elif op == 'qCurveTo':
            if pts[-1] is None: raise SystemExit('closed quadratic contour without on-curve point (not handled)')
            for a, b in decomposeQuadraticSegment(pts): out.append('Q' + f(a) + ' ' + f(b))
            cur = pts[-1]
        elif op in ('closePath', 'endPath'): out.append('Z')
    return ' '.join(out)

x = 0; glyphs = []
for info, pos in zip(b.glyph_infos, b.glyph_positions):
    name = order[info.codepoint]
    pen = RecordingPen(); gs[name].draw(pen)
    d = rec_to_path(pen.value)
    if d:
        glyphs.append({'d': d, 'x': x + pos.x_offset, 'y': pos.y_offset, 'cluster': info.cluster, 'name': name})
    x += pos.x_advance
upm = tt['head'].unitsPerEm
json.dump({'upm': upm, 'width': x, 'glyphs': glyphs, 'asc': tt['hhea'].ascent, 'desc': tt['hhea'].descent}, open(out, 'w'))
print('upm', upm, 'width', x, 'glyphs', len(glyphs), [g['name'] for g in glyphs])
