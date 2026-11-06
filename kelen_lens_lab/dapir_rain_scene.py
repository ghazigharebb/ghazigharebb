"""«Dapîr» — Kurdish grandmother with a hurricane lantern on a mountain porch, midday after rain.
Built entirely in Blender (Cycles) and shot through Kelen Lens Lab: 35mm anamorphic, f/1.2.
Run:  blender -b -P dapir_rain_scene.py -- out.png [RES_PERCENT] [SAMPLES]"""
import sys, os, math, random, importlib.util
import bpy, bmesh
from mathutils import Vector, Matrix, noise

ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.abspath('dapir.png')
PCT = int(ARGS[1]) if len(ARGS) > 1 else 100
SPP = int(ARGS[2]) if len(ARGS) > 2 else 192

bpy.ops.wm.read_factory_settings(use_empty=True)
HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("kelen_lens_lab", os.path.join(HERE, "kelen_lens_lab.py"))
kll = importlib.util.module_from_spec(spec); spec.loader.exec_module(kll); kll.register()
sc = bpy.context.scene; col = sc.collection
R = random.Random(21)

# ---------------------------------------------------------------- helpers
def hexc(h):
    h = h.lstrip('#'); c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c)
def node(nt, t, **kw):
    n = nt.nodes.new(t)
    for k, v in kw.items():
        if hasattr(n, k): setattr(n, k, v)
        else: n.inputs[k].default_value = v
    return n
def L(nt, a, ao, b, bi): nt.links.new(a.outputs[ao], b.inputs[bi])
def mat(name, color, rough=0.6, **kw):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*color, 1); b.inputs['Roughness'].default_value = rough
    for k, v in kw.items():
        b.inputs[k].default_value = (*v, 1) if isinstance(v, tuple) and len(v) == 3 else v
    return m
def obj(name, bm, m, smooth=True, parent=None):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    if smooth: me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
    if m: me.materials.append(m)
    o = bpy.data.objects.new(name, me); col.objects.link(o)
    if parent: o.parent = parent
    return o
def box(w, d, h, loc, rot=(0, 0, 0)):
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0); bmesh.ops.scale(bm, vec=(w, d, h), verts=bm.verts)
    bmesh.ops.transform(bm, matrix=Matrix.Translation(loc) @ Matrix.Rotation(rot[2], 4, 'Z') @ Matrix.Rotation(rot[1], 4, 'Y') @ Matrix.Rotation(rot[0], 4, 'X'), verts=bm.verts)
    return bm
def ico(r, loc, s=(1, 1, 1), sub=3):
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    bmesh.ops.scale(bm, vec=s, verts=bm.verts); bmesh.ops.translate(bm, vec=loc, verts=bm.verts); return bm
def cyl(r1, r2, h, loc, seg=24, caps=True):
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=caps, segments=seg, radius1=r1, radius2=r2, depth=h)
    bmesh.ops.translate(bm, vec=loc, verts=bm.verts); return bm
def tube(pts, radii, seg=16, scale_y=1.0):
    bm = bmesh.new(); rows = []
    for k, (p, r) in enumerate(zip(pts, radii)):
        p = Vector(p)
        d = (Vector(pts[min(k + 1, len(pts) - 1)]) - Vector(pts[max(k - 1, 0)])).normalized()
        up = Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))
        a = d.cross(up).normalized(); b = d.cross(a)
        rows.append([bm.verts.new(p + (a * math.cos(2 * math.pi * i / seg) * scale_y + b * math.sin(2 * math.pi * i / seg)) * r) for i in range(seg)])
    for k in range(len(rows) - 1):
        for i in range(seg):
            j = (i + 1) % seg; bm.faces.new((rows[k][i], rows[k][j], rows[k + 1][j], rows[k + 1][i]))
    bm.faces.new(rows[0][::-1]); bm.faces.new(rows[-1]); bm.normal_update(); return bm
def displace(o, size, strength, kind='CLOUDS'):
    t = bpy.data.textures.new('t', type=kind); t.noise_scale = size
    md = o.modifiers.new('d', 'DISPLACE'); md.texture = t; md.strength = strength; md.texture_coords = 'GLOBAL'
def subsurf(o, lv=2):
    md = o.modifiers.new('s', 'SUBSURF'); md.levels = md.render_levels = lv

# ---------------------------------------------------------------- materials
def wood_mat(name, base, wet=0.5):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    tc = node(nt, 'ShaderNodeTexCoord'); mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 1.0, 12.0)
    L(nt, tc, 'Object', mp, 'Vector')
    wv = node(nt, 'ShaderNodeTexWave', wave_type='BANDS', **{'Scale': 6.0, 'Distortion': 9.0, 'Detail': 6.0}); L(nt, mp, 'Vector', wv, 'Vector')
    nz = node(nt, 'ShaderNodeTexNoise', **{'Scale': 4.0, 'Detail': 10.0}); L(nt, tc, 'Object', nz, 'Vector')
    rp = node(nt, 'ShaderNodeValToRGB'); rp.color_ramp.elements[0].color = (*hexc('#120d0a'), 1); rp.color_ramp.elements[1].color = (*base, 1)
    mx = node(nt, 'ShaderNodeMix', data_type='FLOAT', **{'Factor': 0.5}); L(nt, wv, 'Fac', mx, 'A'); L(nt, nz, 'Fac', mx, 'B')
    L(nt, mx, 'Result', rp, 'Fac'); L(nt, rp, 'Color', b, 'Base Color')
    rr = node(nt, 'ShaderNodeMapRange', **{'To Min': 0.25 - wet * 0.2, 'To Max': 0.85}); L(nt, nz, 'Fac', rr, 'Value'); L(nt, rr, 'Result', b, 'Roughness')
    bp = node(nt, 'ShaderNodeBump', **{'Strength': 0.5, 'Distance': 0.01}); L(nt, wv, 'Fac', bp, 'Height'); L(nt, bp, 'Normal', b, 'Normal')
    return m
WOOD = wood_mat('WetWood', hexc('#4a3b30'), 0.7)
WOOD_D = wood_mat('DarkWood', hexc('#2b221c'), 0.6)

def stone_mat():
    m = bpy.data.materials.new('WetStone'); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    tc = node(nt, 'ShaderNodeTexCoord')
    nz = node(nt, 'ShaderNodeTexNoise', **{'Scale': 3.0, 'Detail': 12.0, 'Roughness': 0.65}); L(nt, tc, 'Object', nz, 'Vector')
    rp = node(nt, 'ShaderNodeValToRGB'); rp.color_ramp.elements[0].color = (*hexc('#0e1213'), 1); rp.color_ramp.elements[1].color = (*hexc('#3a403f'), 1)
    L(nt, nz, 'Fac', rp, 'Fac'); L(nt, rp, 'Color', b, 'Base Color')
    wet = node(nt, 'ShaderNodeTexNoise', **{'Scale': 0.8, 'Detail': 3.0}); L(nt, tc, 'Object', wet, 'Vector')
    wr = node(nt, 'ShaderNodeMapRange', interpolation_type='SMOOTHSTEP', **{'From Min': 0.45, 'From Max': 0.6, 'To Min': 0.55, 'To Max': 0.08}); L(nt, wet, 'Fac', wr, 'Value'); L(nt, wr, 'Result', b, 'Roughness')
    bp = node(nt, 'ShaderNodeBump', **{'Strength': 0.6, 'Distance': 0.02}); L(nt, nz, 'Fac', bp, 'Height'); L(nt, bp, 'Normal', b, 'Normal')
    return m
STONE = stone_mat()
def ground_mat():
    m = bpy.data.materials.new('Mud'); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    tc = node(nt, 'ShaderNodeTexCoord'); nz = node(nt, 'ShaderNodeTexNoise', **{'Scale': 1.2, 'Detail': 12.0}); L(nt, tc, 'Object', nz, 'Vector')
    rp = node(nt, 'ShaderNodeValToRGB'); rp.color_ramp.elements[0].color = (*hexc('#151a17'), 1); rp.color_ramp.elements[1].color = (*hexc('#4a4f45'), 1)
    L(nt, nz, 'Fac', rp, 'Fac'); L(nt, rp, 'Color', b, 'Base Color')
    pz = node(nt, 'ShaderNodeTexNoise', **{'Scale': 0.35, 'Detail': 2.0}); L(nt, tc, 'Object', pz, 'Vector')
    pr = node(nt, 'ShaderNodeMapRange', interpolation_type='SMOOTHSTEP', **{'From Min': 0.52, 'From Max': 0.56, 'To Min': 0.7, 'To Max': 0.02}); L(nt, pz, 'Fac', pr, 'Value'); L(nt, pr, 'Result', b, 'Roughness')
    bp = node(nt, 'ShaderNodeBump', **{'Strength': 0.4}); L(nt, nz, 'Fac', bp, 'Height'); L(nt, bp, 'Normal', b, 'Normal')
    return m
MUD = ground_mat()
def skin_mat(name, henna=False):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    b.inputs['Roughness'].default_value = 0.55; b.inputs['Subsurface Weight'].default_value = 0.35
    b.inputs['Subsurface Radius'].default_value = (0.9, 0.35, 0.2); b.inputs['Subsurface Scale'].default_value = 0.01
    tc = node(nt, 'ShaderNodeTexCoord')
    base = node(nt, 'ShaderNodeTexNoise', **{'Scale': 40.0, 'Detail': 8.0}); L(nt, tc, 'Object', base, 'Vector')
    rp = node(nt, 'ShaderNodeValToRGB'); rp.color_ramp.elements[0].color = (*hexc('#6e4636'), 1); rp.color_ramp.elements[1].color = (*hexc('#a8775f'), 1)
    L(nt, base, 'Fac', rp, 'Fac'); out = rp; oo = 'Color'
    if henna:
        vo = node(nt, 'ShaderNodeTexVoronoi', feature='DISTANCE_TO_EDGE', **{'Scale': 26.0}); L(nt, tc, 'Object', vo, 'Vector')
        wv = node(nt, 'ShaderNodeTexWave', wave_type='RINGS', **{'Scale': 18.0, 'Distortion': 2.0}); L(nt, tc, 'Object', wv, 'Vector')
        e1 = node(nt, 'ShaderNodeMapRange', **{'From Min': 0.0, 'From Max': 0.06, 'To Min': 1.0, 'To Max': 0.0}); L(nt, vo, 'Distance', e1, 'Value')
        e2 = node(nt, 'ShaderNodeMapRange', interpolation_type='SMOOTHSTEP', **{'From Min': 0.7, 'From Max': 0.9}); L(nt, wv, 'Fac', e2, 'Value')
        mx = node(nt, 'ShaderNodeMath', operation='MAXIMUM'); L(nt, e1, 'Result', mx, 0); L(nt, e2, 'Result', mx, 1)
        hm = node(nt, 'ShaderNodeMix', data_type='RGBA'); hm.inputs['B'].default_value = (*hexc('#3a120a'), 1)
        f = node(nt, 'ShaderNodeMath', operation='MULTIPLY'); f.inputs[1].default_value = 0.85; L(nt, mx, 'Value', f, 0)
        L(nt, f, 'Value', hm, 'Factor'); L(nt, rp, 'Color', hm, 'A'); out = hm; oo = 'Result'
    L(nt, out, oo, b, 'Base Color')
    # wrinkles: stretched fine noise + wave lines
    mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 1.0, 6.0); L(nt, tc, 'Object', mp, 'Vector')
    wr = node(nt, 'ShaderNodeTexWave', wave_type='BANDS', bands_direction='Z', **{'Scale': 60.0, 'Distortion': 14.0, 'Detail': 4.0}); L(nt, mp, 'Vector', wr, 'Vector')
    fn = node(nt, 'ShaderNodeTexNoise', **{'Scale': 260.0, 'Detail': 4.0}); L(nt, tc, 'Object', fn, 'Vector')
    hm2 = node(nt, 'ShaderNodeMix', data_type='FLOAT', **{'Factor': 0.4}); L(nt, wr, 'Fac', hm2, 'A'); L(nt, fn, 'Fac', hm2, 'B')
    bp = node(nt, 'ShaderNodeBump', **{'Strength': 0.55, 'Distance': 0.0015}); L(nt, hm2, 'Result', bp, 'Height'); L(nt, bp, 'Normal', b, 'Normal')
    return m
FACE = skin_mat('FaceSkin'); HANDS = skin_mat('HennaHands', henna=True)
def scarf_mat():
    m = bpy.data.materials.new('FloralScarf'); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    b.inputs['Roughness'].default_value = 0.7; b.inputs['Sheen Weight'].default_value = 0.4
    tc = node(nt, 'ShaderNodeTexCoord')
    vo = node(nt, 'ShaderNodeTexVoronoi', **{'Scale': 22.0}); L(nt, tc, 'Object', vo, 'Vector')
    # petals: angle around each cell centre
    sub = node(nt, 'ShaderNodeVectorMath', operation='SUBTRACT'); L(nt, tc, 'Object', sub, 0); L(nt, vo, 'Position', sub, 1)
    sxyz = node(nt, 'ShaderNodeSeparateXYZ'); L(nt, sub, 'Vector', sxyz, 'Vector')
    at = node(nt, 'ShaderNodeMath', operation='ARCTAN2'); L(nt, sxyz, 'Z', at, 0); L(nt, sxyz, 'X', at, 1)
    m5 = node(nt, 'ShaderNodeMath', operation='MULTIPLY'); m5.inputs[1].default_value = 5.0; L(nt, at, 'Value', m5, 0)
    cs = node(nt, 'ShaderNodeMath', operation='COSINE'); L(nt, m5, 'Value', cs, 0)
    pr = node(nt, 'ShaderNodeMath', operation='MULTIPLY_ADD'); pr.inputs[1].default_value = 0.012; pr.inputs[2].default_value = 0.026; L(nt, cs, 'Value', pr, 0)
    lt = node(nt, 'ShaderNodeMath', operation='LESS_THAN'); L(nt, vo, 'Distance', lt, 0); L(nt, pr, 'Value', lt, 1)
    mixc = node(nt, 'ShaderNodeMix', data_type='RGBA'); mixc.inputs['A'].default_value = (*hexc('#0b0b0d'), 1); mixc.inputs['B'].default_value = (*hexc('#c9c6bd'), 1)
    L(nt, lt, 'Value', mixc, 'Factor'); L(nt, mixc, 'Result', b, 'Base Color')
    fb = node(nt, 'ShaderNodeTexNoise', **{'Scale': 400.0}); L(nt, tc, 'Object', fb, 'Vector')
    bp = node(nt, 'ShaderNodeBump', **{'Strength': 0.15}); L(nt, fb, 'Fac', bp, 'Height'); L(nt, bp, 'Normal', b, 'Normal')
    return m
SCARF = scarf_mat()
def knit_mat(name, c1, c2):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    b.inputs['Roughness'].default_value = 0.95; b.inputs['Sheen Weight'].default_value = 0.08; b.inputs['Sheen Tint'].default_value = (*c2, 1); b.inputs['Specular IOR Level'].default_value = 0.2
    tc = node(nt, 'ShaderNodeTexCoord'); mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 1.0, 0.25); L(nt, tc, 'Object', mp, 'Vector')
    wv = node(nt, 'ShaderNodeTexWave', wave_type='BANDS', bands_direction='Z', **{'Scale': 600.0, 'Distortion': 2.0}); L(nt, mp, 'Vector', wv, 'Vector')
    nz = node(nt, 'ShaderNodeTexNoise', **{'Scale': 8.0, 'Detail': 6.0}); L(nt, tc, 'Object', nz, 'Vector')
    rp = node(nt, 'ShaderNodeValToRGB'); rp.color_ramp.elements[0].color = (*c1, 1); rp.color_ramp.elements[1].color = (*c2, 1)
    L(nt, nz, 'Fac', rp, 'Fac'); L(nt, rp, 'Color', b, 'Base Color')
    bp = node(nt, 'ShaderNodeBump', **{'Strength': 0.25, 'Distance': 0.002}); L(nt, wv, 'Fac', bp, 'Height'); L(nt, bp, 'Normal', b, 'Normal')
    return m
CARDIGAN = knit_mat('Cardigan', hexc('#2e2a25'), hexc('#5a5248'))
SKIRT = knit_mat('Skirt', hexc('#0c0b0d'), hexc('#1f1c20'))
METAL = mat('LanternTin', hexc('#9ea3a3'), 0.32, **{'Metallic': 1.0})
RUST = mat('Rust', hexc('#4a3424'), 0.7, **{'Metallic': 0.4})
GLASS = mat('Glass', (1, 1, 1), 0.05, **{'Transmission Weight': 1.0, 'IOR': 1.45})
def emit(name, color, strength):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    for n in list(nt.nodes):
        if n.type != 'OUTPUT_MATERIAL': nt.nodes.remove(n)
    e = nt.nodes.new('ShaderNodeEmission'); e.inputs['Color'].default_value = (*color, 1); e.inputs['Strength'].default_value = strength
    nt.links.new(e.outputs[0], nt.nodes['Material Output'].inputs['Surface']); return m
FLAME = emit('Flame', (1.0, 0.62, 0.25), 60.0)

# ---------------------------------------------------------------- porch (wood), left valley side is -X
SEAT = Vector((0.55, 2.15, 0.44))
obj('PorchDeck', box(3.2, 4.2, 0.08, (2.05, 3.4, 0.40)), WOOD_D, smooth=False)
for i in range(10):
    obj('Plank', box(3.25, 0.4, 0.03, (2.05, 1.5 + i * 0.42, 0.455), (0, 0, R.uniform(-0.01, 0.01))), WOOD, smooth=False)
obj('Joist', box(0.16, 4.3, 0.22, (0.5, 3.4, 0.28)), WOOD_D, smooth=False)
for (x, y) in ((0.42, 3.1), (0.42, 6.1), (3.3, 3.1)):
    o = obj('Post', box(0.15, 0.15, 2.5, (x, y, 1.65), (0, 0, R.uniform(-0.05, 0.05))), WOOD, smooth=False)
    displace(o, 0.4, 0.008)
for k in range(9):
    obj('Rafter', box(4.6, 0.11, 0.13, (1.4, 1.2 + k * 0.62, 2.88), (0, 0.06, 0)), WOOD_D, smooth=False)
obj('Beam', box(0.22, 6.5, 0.24, (0.42, 3.6, 2.8)), WOOD, smooth=False)
for k in range(26):
    obj('RoofBoard', box(4.4, 0.24, 0.025, (1.5, 0.9 + k * 0.23, 3.0), (0, 0.06, R.uniform(-0.01, 0.01))), WOOD_D, smooth=False)
obj('Wall', box(0.3, 7.0, 3.2, (3.6, 3.6, 1.6)), STONE, smooth=False)

# ---------------------------------------------------------------- ground: wet rocky path, valley falling away, misty forested mountains
def Hg(x, y):
    h = 0.06 * noise.fractal(Vector((x * 0.6, y * 0.6, 0)), 0.8, 2.0, 4)
    drop = max(0.0, (-x - 5.0)) + max(0.0, (y - 14.0)) * 0.8
    h -= drop * drop * 0.12 + drop * 1.2
    far = max(0.0, y - 90.0)
    h += far * 0.55 + 22 * noise.fractal(Vector((x * 0.01, y * 0.01, 3)), 0.6, 2.0, 5) * min(1.0, far / 40)
    h += max(0.0, -x - 70) * 0.5
    h += 34 * math.exp(-((x + 34) ** 2 / 500 + (y - 62) ** 2 / 900)) + 22 * math.exp(-((x + 75) ** 2 / 700 + (y - 40) ** 2 / 500))
    return h
NX, NY = 160, 160
xs = [-220 + 260 * i / (NX - 1) for i in range(NX)]
ys = [-2 + 400 * ((j / (NY - 1)) ** 1.8) for j in range(NY)]
bm = bmesh.new(); grid = []
for y in ys:
    grid.append([bm.verts.new((x, y, Hg(x, y))) for x in xs])
for j in range(NY - 1):
    for i in range(NX - 1):
        bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
obj('Ground', bm, MUD)
for i in range(70):   # flat wet stones on the path
    x = R.uniform(-4.5, 0.2); y = R.uniform(2.5, 14); s = R.uniform(0.12, 0.4)
    bmx = ico(s, (x, y, Hg(x, y) - s * 0.08), (1.4, 1.0, 0.3), 3)
    o = obj('Stone', bmx, STONE); o.rotation_euler = (0, 0, R.random() * 6); displace(o, 0.2, 0.05)
# forest on the valley slopes (linked duplicates, two tree kinds)
LEAF = mat('Foliage', hexc('#1d2b22'), 0.8)
def tree_mesh(kind):
    bm = bmesh.new()
    if kind == 0:
        for i in range(4):
            bmesh.ops.create_cone(bm, cap_ends=True, segments=8, radius1=1.6 - i * 0.35, radius2=0.1, depth=2.2, matrix=Matrix.Translation((0, 0, 1.5 + i * 1.2)))
    else:
        for i in range(5):
            bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.3, matrix=Matrix.Translation((R.uniform(-0.9, 0.9), R.uniform(-0.9, 0.9), 2.5 + R.uniform(0, 1.6))))
    me = bpy.data.meshes.new('tree%d' % kind); bm.to_mesh(me); bm.free(); me.materials.append(LEAF); return me
TREES = [tree_mesh(0), tree_mesh(1)]
n = 0
while n < 1400:
    x = R.uniform(-140, 20); y = R.uniform(10, 200)
    if x > -6 and y < 16: continue
    if math.hypot(x, y - 2) < 22: continue
    z = Hg(x, y)
    o = bpy.data.objects.new('tree', TREES[R.random() < 0.45]); col.objects.link(o)
    s = R.uniform(1.4, 3.2); o.location = (x, y, z - 0.3); o.scale = (s, s, s * R.uniform(0.9, 1.4)); o.rotation_euler = (0, 0, R.random() * 6); n += 1

# ---------------------------------------------------------------- the grandmother (local +X = facing direction)
dap = bpy.data.objects.new('Dapir', None); col.objects.link(dap)
dap.location = SEAT; dap.rotation_euler = (0, 0, math.radians(245)); dap.scale = (1, -1, 1)   # faces left & slightly toward camera; mirrored so the cigarette hand is camera-side
def P(o, bm, m, smooth=True):
    return obj(o, bm, m, smooth, parent=dap)
# skirt over bent legs: hips -> knees -> shins down to the ground
o = P('Skirt', tube([(-0.12, 0, 0.06), (0.1, 0, 0.1), (0.36, 0, 0.12), (0.44, 0, -0.05), (0.47, 0, -0.3), (0.5, 0, -0.44)],
                   [0.17, 0.2, 0.19, 0.17, 0.2, 0.24], 32, scale_y=1.45), SKIRT)
subsurf(o, 1); displace(o, 0.15, 0.015)
for s in (-1, 1):
    P('Shoe', ico(0.06, (0.6, s * 0.1, -0.42), (1.8, 0.8, 0.6), 2), mat('Shoe', hexc('#0b0b0b'), 0.4))
# torso in the cardigan, slightly hunched
rings = [(0.06, 0.2, 0.15, -0.02), (0.25, 0.17, 0.13, 0.0), (0.42, 0.19, 0.14, 0.03), (0.55, 0.21, 0.13, 0.05), (0.6, 0.12, 0.09, 0.07)]
bm = bmesh.new(); vs = []
for z, rx, ry, cx in rings:
    vs.append([bm.verts.new((cx + math.cos(2 * math.pi * i / 32) * ry, math.sin(2 * math.pi * i / 32) * rx, z)) for i in range(32)])
for k in range(len(vs) - 1):
    for i in range(32):
        j = (i + 1) % 32; bm.faces.new((vs[k][i], vs[k][j], vs[k + 1][j], vs[k + 1][i]))
bm.faces.new(vs[-1]); o = P('Cardigan', bm, CARDIGAN); subsurf(o, 2)
# arms: left hand resting on the knee, right hand raised with the cigarette near the chin
L_SH, R_SH = Vector((0.06, 0.2, 0.55)), Vector((0.06, -0.2, 0.55))
P('ArmL', tube([tuple(L_SH), (0.18, 0.24, 0.32), (0.36, 0.14, 0.17)], [0.06, 0.05, 0.042], 16), CARDIGAN)
P('ArmR', tube([tuple(R_SH), (0.16, -0.3, 0.34), (0.3, -0.27, 0.5)], [0.06, 0.05, 0.042], 16), CARDIGAN)
def hand(base, fwd, up, curl, name):
    fwd = Vector(fwd).normalized(); up = Vector(up).normalized(); side = fwd.cross(up)
    P(name + 'Palm', ico(0.042, tuple(base), (1, 1, 1), 3), HANDS).scale = (1.0, 1.0, 1.0)
    for i, off in enumerate((-0.022, -0.007, 0.008, 0.022)):
        st = Vector(base) + fwd * 0.035 + side * off
        mid = st + fwd * 0.03 - up * 0.012 * curl
        tip = mid + fwd * (0.022 - 0.004 * abs(i - 1.5)) - up * 0.02 * curl
        P(name + 'Finger', tube([tuple(st), tuple(mid), tuple(tip)], [0.0095, 0.0085, 0.007], 10), HANDS)
    th0 = Vector(base) + side * 0.03 + fwd * 0.005
    P(name + 'Thumb', tube([tuple(th0), tuple(th0 + fwd * 0.03 + side * 0.012), tuple(th0 + fwd * 0.05 + up * 0.01)], [0.011, 0.009, 0.008], 10), HANDS)
hand((0.4, 0.13, 0.15), (1, -0.1, -0.5), (0, 0, 1), 1.6, 'HandL')
hand((0.33, -0.27, 0.54), (0.55, 0.0, 0.8), (-0.8, 0, 0.55), 0.6, 'HandR')
# cigarette + glowing tip
cig0 = Vector((0.37, -0.25, 0.6)); cdir = Vector((0.8, -0.3, 0.25)).normalized()
P('Cigarette', tube([tuple(cig0), tuple(cig0 + cdir * 0.075)], [0.0042, 0.0042], 10), mat('Paper', hexc('#e9e4da'), 0.6))
P('Ember', ico(0.0048, tuple(cig0 + cdir * 0.077), (1, 1, 1), 2), emit('Ember', (1.0, 0.3, 0.05), 40.0))
# neck + head (sculpted with gaussian bumps), facing +X
HEAD = Vector((0.11, 0.0, 0.79))
P('Neck', tube([(0.06, 0, 0.58), (0.1, 0, 0.69)], [0.05, 0.045], 14), FACE)
bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=5, radius=1.0)
def bump(v, c, r, a):
    d = (v - Vector(c)).length; return a * math.exp(-(d / r) ** 2)
for v in bm.verts:
    p = v.co.copy(); q = Vector((p.x * 0.09, p.y * 0.075, p.z * 0.105))
    n_ = p.normalized(); amt = 0.0
    amt += bump(p, (0.95, 0, -0.05), 0.2, 0.22)     # nose
    amt += bump(p, (0.85, 0, 0.32), 0.28, 0.06)     # brow ridge
    amt -= bump(p, (0.8, 0.33, 0.18), 0.17, 0.09)   # eye sockets
    amt -= bump(p, (0.8, -0.33, 0.18), 0.17, 0.09)
    amt += bump(p, (0.62, 0.55, 0.02), 0.25, 0.05)  # cheekbones
    amt += bump(p, (0.62, -0.55, 0.02), 0.25, 0.05)
    amt -= bump(p, (0.65, 0.45, -0.3), 0.25, 0.07)  # hollow cheeks (old age)
    amt -= bump(p, (0.65, -0.45, -0.3), 0.25, 0.07)
    amt += bump(p, (0.82, 0, -0.62), 0.22, 0.06)    # chin
    amt -= bump(p, (0.92, 0, -0.38), 0.12, 0.05)    # mouth (lips pressed, toothless)
    amt += bump(p, (0.4, 0, -0.75), 0.4, -0.08)     # tapered jaw
    v.co = Vector((q.x + n_.x * amt * 0.09, q.y + n_.y * amt * 0.075, q.z + n_.z * amt * 0.105)) + HEAD
face = P('Head', bm, FACE)
for s in (-1, 1):
    eye = HEAD + Vector((0.071, s * 0.026, 0.016))
    P('Eye', ico(0.0105, tuple(eye), (1, 1, 1), 2), mat('Eye', hexc('#1a1410'), 0.08, **{'Coat Weight': 1.0}))
    P('Lid', ico(0.0125, tuple(eye + Vector((-0.002, 0, 0.004))), (1, 1, 0.55), 2), FACE)
# deq tattoo dots on the chin (tiny dark bumps)
TAT = mat('Deq', hexc('#1d2a2c'), 0.6)
for (dy, dz) in ((0, -0.07), (0.012, -0.078), (-0.012, -0.078), (0, -0.088), (0, -0.058), (0.008, 0.035), (-0.008, 0.035), (0, 0.042)):
    P('Deq', ico(0.0028, tuple(HEAD + Vector((0.086 if dz < 0 else 0.084, dy, dz))), (0.4, 1, 1), 1), TAT)
# floral headscarf: dome over the head, open at the face, wrapped down around neck and shoulders
bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=5, radius=1.0)
kill = [v for v in bm.verts if v.co.x > 0.35 and -0.62 < v.co.z < 0.62 and abs(v.co.y) < 0.72]
bmesh.ops.delete(bm, geom=kill, context='VERTS')
for v in bm.verts:
    p = v.co; v.co = Vector((p.x * 0.108, p.y * 0.098, p.z * 0.122)) + HEAD + Vector((-0.012, 0, 0.008))
o = P('Scarf', bm, SCARF); md = o.modifiers.new('sol', 'SOLIDIFY'); md.thickness = 0.008; displace(o, 0.05, 0.006)
o = P('ScarfWrap', tube([(0.02, 0.1, 0.6), (0.1, 0.0, 0.66), (0.02, -0.12, 0.6), (-0.04, -0.06, 0.5), (-0.05, 0.08, 0.47)],
                         [0.07, 0.075, 0.07, 0.06, 0.05], 18), SCARF)
subsurf(o, 1); displace(o, 0.04, 0.01)
o = P('ScarfTail', tube([(-0.05, -0.05, 0.72), (-0.09, -0.08, 0.6), (-0.1, -0.09, 0.45), (-0.08, -0.1, 0.32)], [0.05, 0.06, 0.055, 0.03], 14, scale_y=1.8), SCARF)
displace(o, 0.05, 0.008)

# ---------------------------------------------------------------- hurricane lantern on a wet stump (camera-right, in front of her)
LP = Vector((0.92, 1.72, 0.0))
stump = obj('Stump', cyl(0.2, 0.18, 0.5, tuple(LP + Vector((0, 0, 0.25))), 28), WOOD_D); displace(stump, 0.1, 0.02)
obj('StumpTop', cyl(0.185, 0.185, 0.01, tuple(LP + Vector((0, 0, 0.505))), 28), mat('Rings', hexc('#5b4636'), 0.3))
T = LP + Vector((0, 0, 0.51))
obj('Tank', cyl(0.075, 0.07, 0.07, tuple(T + Vector((0, 0, 0.035))), 32), METAL)
obj('TankRim', cyl(0.06, 0.05, 0.02, tuple(T + Vector((0, 0, 0.08))), 32), RUST)
gl = obj('Globe', ico(0.055, tuple(T + Vector((0, 0, 0.15))), (1, 1, 1.25), 4), GLASS)
for a in range(4):
    ang = a * math.pi / 2 + 0.4; d = Vector((math.cos(ang), math.sin(ang), 0))
    obj('Wire', tube([tuple(T + d * 0.064 + Vector((0, 0, 0.09))), tuple(T + d * 0.07 + Vector((0, 0, 0.15))), tuple(T + d * 0.06 + Vector((0, 0, 0.215)))], [0.002, 0.002, 0.002], 6), METAL)
for zz in (0.12, 0.18):
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=False, segments=32, radius1=0.069, radius2=0.069, depth=0.004); bmesh.ops.translate(bm, vec=tuple(T + Vector((0, 0, zz))), verts=bm.verts)
    obj('Ring', bm, METAL)
obj('Cap', cyl(0.06, 0.035, 0.035, tuple(T + Vector((0, 0, 0.235))), 32), METAL)
obj('Chimney', cyl(0.03, 0.03, 0.03, tuple(T + Vector((0, 0, 0.265))), 24), METAL)
for s in (-1, 1):   # side air tubes
    obj('AirTube', tube([tuple(T + Vector((s * 0.085, 0, 0.06))), tuple(T + Vector((s * 0.09, 0, 0.2))), tuple(T + Vector((s * 0.05, 0, 0.25)))], [0.006, 0.006, 0.006], 8), METAL)
obj('Bail', tube([tuple(T + Vector((-0.09, 0, 0.2))), tuple(T + Vector((-0.05, 0, 0.33))), tuple(T + Vector((0.05, 0, 0.33))), tuple(T + Vector((0.09, 0, 0.2)))], [0.0025] * 4, 6), METAL)
FL = T + Vector((0, 0, 0.14))
obj('Flame', ico(0.011, tuple(FL), (0.75, 0.75, 1.9), 3), FLAME)
lamp = bpy.data.lights.new('LanternLight', 'POINT'); lamp.energy = 14; lamp.shadow_soft_size = 0.012; lamp.color = (1.0, 0.6, 0.3)
lo = bpy.data.objects.new('LanternLight', lamp); col.objects.link(lo); lo.location = FL

# ---------------------------------------------------------------- rain, drips, smoke
RAIN = mat('Rain', (0.9, 0.95, 1.0), 0.0, **{'Transmission Weight': 0.6, 'Emission Color': (0.75, 0.85, 0.9), 'Emission Strength': 0.18})
bm = bmesh.new()
for i in range(700):
    y = R.uniform(1.2, 30); x = R.uniform(-0.8, 0.8) * y * 0.75 - 0.6; z = R.uniform(0, 0.75 * y + 1)
    if 0.0 < x < 3.6 and y < 7 and z < 3.0: continue      # sheltered under the porch roof
    length = R.uniform(0.15, 0.3) * (1 + y * 0.02)
    bmesh.ops.create_cone(bm, cap_ends=False, segments=3, radius1=0.0006 + y * 0.00008, radius2=0.0006 + y * 0.00008, depth=length,
                          matrix=Matrix.Translation((x, y, z)) @ Matrix.Rotation(0.06, 4, 'Y'))
obj('Rain', bm, RAIN, smooth=False)
bm = bmesh.new()
for i in range(28):  # drips from the roof edge
    y = R.uniform(1.2, 6.5); z = R.uniform(0.6, 2.85)
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.006, matrix=Matrix.Translation((-0.8, y, z)) @ Matrix.Diagonal((1, 1, 3.5, 1)))
obj('Drips', bm, RAIN)
smk = bpy.data.materials.new('Smoke'); smk.use_nodes = True; nt = smk.node_tree; nt.nodes.remove(nt.nodes['Principled BSDF'])
pv = node(nt, 'ShaderNodeVolumePrincipled'); tcs = node(nt, 'ShaderNodeTexCoord')
nzs = node(nt, 'ShaderNodeTexNoise', **{'Scale': 18.0, 'Detail': 6.0, 'Distortion': 2.0}); L(nt, tcs, 'Object', nzs, 'Vector')
dr = node(nt, 'ShaderNodeMapRange', **{'From Min': 0.45, 'From Max': 0.75, 'To Min': 0.0, 'To Max': 9.0}); L(nt, nzs, 'Fac', dr, 'Value')
L(nt, dr, 'Result', pv, 'Density'); pv.inputs['Color'].default_value = (0.85, 0.88, 0.9, 1)
L(nt, pv, 'Volume', nt.nodes['Material Output'], 'Volume')
sp = [cig0 + cdir * 0.08]
for k in range(9):
    sp.append(sp[-1] + Vector((math.sin(k * 1.3) * 0.025 - 0.012, math.cos(k * 0.9) * 0.012, 0.04)))
o = P('SmokeWisp', tube([tuple(p) for p in sp], [0.003 + 0.0025 * k for k in range(len(sp))], 12), smk)
o.parent = dap

# ---------------------------------------------------------------- mist (teal), sky, light
haze = bpy.data.materials.new('Mist'); haze.use_nodes = True; nt = haze.node_tree; nt.nodes.remove(nt.nodes['Principled BSDF'])
pv = node(nt, 'ShaderNodeVolumePrincipled', **{'Density': 0.0055, 'Anisotropy': 0.3}); pv.inputs['Color'].default_value = (0.7, 0.86, 0.9, 1)
L(nt, pv, 'Volume', nt.nodes['Material Output'], 'Volume')
obj('MistFar', box(300, 380, 220, (-152, 196, 40)), haze, smooth=False)
obj('MistBack', box(150, 330, 220, (75, 220, 40)), haze, smooth=False)
haze2 = bpy.data.materials.new('MistNear'); haze2.use_nodes = True; nt = haze2.node_tree; nt.nodes.remove(nt.nodes['Principled BSDF'])
pv = node(nt, 'ShaderNodeVolumePrincipled', **{'Density': 0.025, 'Anisotropy': 0.2}); pv.inputs['Color'].default_value = (0.75, 0.88, 0.92, 1)
L(nt, pv, 'Volume', nt.nodes['Material Output'], 'Volume')
obj('MistValley', box(40, 40, 30, (-26, 26, -10)), haze2, smooth=False)
world = bpy.data.worlds.new('Overcast'); sc.world = world; world.use_nodes = True; wn = world.node_tree
bg = wn.nodes['Background']; tcw = wn.nodes.new('ShaderNodeTexCoord'); spw = wn.nodes.new('ShaderNodeSeparateXYZ')
wn.links.new(tcw.outputs['Generated'], spw.inputs['Vector'])
rp = wn.nodes.new('ShaderNodeValToRGB'); rp.color_ramp.elements[0].position = 0.5; rp.color_ramp.elements[0].color = (*hexc('#9fc3c8'), 1)
rp.color_ramp.elements[1].position = 0.85; rp.color_ramp.elements[1].color = (*hexc('#5f8790'), 1)
wn.links.new(spw.outputs['Z'], rp.inputs['Fac']); wn.links.new(rp.outputs['Color'], bg.inputs['Color']); bg.inputs['Strength'].default_value = 1.6
# soft overcast key from the open valley side (big area light), no hard sun
kl = bpy.data.lights.new('SkyKey', 'AREA'); kl.energy = 160; kl.size = 4; kl.color = (0.72, 0.88, 0.95)
ko = bpy.data.objects.new('SkyKey', kl); col.objects.link(ko); ko.location = (-2.4, -1.6, 2.6)
ko.rotation_euler = (SEAT + Vector((0, 0, 0.6)) - ko.location).to_track_quat('-Z', 'Y').to_euler()

# ---------------------------------------------------------------- camera: 35mm anamorphic, f/1.2
focus = bpy.data.objects.new('Focus', None); col.objects.link(focus); focus.location = dap.matrix_world @ HEAD if False else SEAT + Vector((-0.05, -0.05, 0.75))
cam = bpy.data.cameras.new('Cam'); cam.lens = 35; cam.sensor_fit = 'AUTO'
co = bpy.data.objects.new('Cam', cam); col.objects.link(co); sc.camera = co
co.location = (1.35, -1.25, 1.02)
tgt = Vector((-0.55, 3.0, 0.9))
co.rotation_euler = (tgt - co.location).to_track_quat('-Z', 'Y').to_euler()

r = sc.render; r.engine = 'CYCLES'; r.resolution_x = 1080; r.resolution_y = 1440; r.resolution_percentage = PCT
r.compositor_device = 'CPU'
cy = sc.cycles; cy.device = 'CPU'; cy.samples = SPP; cy.use_adaptive_sampling = True; cy.adaptive_threshold = 0.02
cy.use_denoising = True; cy.max_bounces = 8; cy.diffuse_bounces = 3; cy.glossy_bounces = 3; cy.transmission_bounces = 6; cy.volume_bounces = 1
cy.caustics_reflective = False; cy.caustics_refractive = False; cy.use_auto_tile = True; cy.tile_size = 256
cy.volume_step_rate = 4.0
vs = sc.view_settings; vs.view_transform = 'AgX'
try: vs.look = 'AgX - Medium High Contrast'
except Exception: pass
vs.exposure = 0.2

s = sc.kelen_lens
s.lens = 'ANAMORPHIC'; s.strength = 1.0; s.fstop = 1.2; s.focus_object = focus
s.bloom = 0.35; s.halation = 0.6; s.streaks = 0.3; s.aberration = 0.3; s.vignette = 0.55; s.grain = 0.45
kll.apply_all(sc, s, co)
# teal film grade inserted before the output
tree = sc.compositing_node_group; go = [n for n in tree.nodes if n.type == 'GROUP_OUTPUT'][0]
src = go.inputs[0].links[0].from_socket
cb = tree.nodes.new('CompositorNodeColorBalance')
for nm, val in (('Lift', (0.92, 1.0, 1.02, 1)), ('Gamma', (0.96, 1.02, 1.05, 1)), ('Gain', (1.06, 1.0, 0.95, 1))):
    for i in cb.inputs:
        if i.name == nm and i.type == 'RGBA': i.default_value = val
hs = tree.nodes.new('CompositorNodeHueSat'); hs.inputs['Saturation'].default_value = 0.82
tree.links.new(src, cb.inputs['Image']); tree.links.new(cb.outputs['Image'], hs.inputs['Image']); tree.links.new(hs.outputs['Image'], go.inputs[0])
r.filepath = OUT
bpy.ops.wm.save_as_mainfile(filepath=os.path.splitext(OUT)[0] + '.blend')
bpy.ops.render.render(write_still=True)
print('done', OUT)
