"""«Dapîr» (realistic environment) — the same scene rebuilt with real Poly Haven assets (CC0):
misty pine-forest HDRI, scanned wood / slate / forest-mud materials, lantern, stump, mossy rocks, ferns, firs.
First run fetch_polyhaven.py to download the assets next to this script (./polyhaven).
Run:  blender -b -P dapir_real_scene.py -- out.png [RES_PERCENT] [SAMPLES]"""
import sys, os, math, random, importlib.util
import bpy, bmesh
from mathutils import Vector, Matrix, noise

ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.abspath('dapir.png')
PCT = int(ARGS[1]) if len(ARGS) > 1 else 100
SPP = int(ARGS[2]) if len(ARGS) > 2 else 192
HDRI_ROT = float(ARGS[3]) if len(ARGS) > 3 else 140.0

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

# ---------------------------------------------------------------- real assets (Poly Haven, CC0)
ASSETS = os.environ.get('KELEN_ASSETS', os.path.join(HERE, 'polyhaven'))
def pbr(name, tex, scale=1.0, rough_mul=1.0, darken=1.0):
    d = os.path.join(ASSETS, 'tex', tex)
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    tc = node(nt, 'ShaderNodeTexCoord'); mp = node(nt, 'ShaderNodeMapping'); mp.inputs['Scale'].default_value = (scale, scale, scale)
    L(nt, tc, 'Object', mp, 'Vector')
    def img(fn, noncolor):
        for ext in ('jpg', 'png'):
            p = os.path.join(d, fn + '.' + ext)
            if os.path.exists(p):
                n = nt.nodes.new('ShaderNodeTexImage'); n.image = bpy.data.images.load(p, check_existing=True)
                n.projection = 'BOX'; n.projection_blend = 0.3
                if noncolor: n.image.colorspace_settings.name = 'Non-Color'
                L(nt, mp, 'Vector', n, 'Vector'); return n
        return None
    dif, rgh, nor = img('Diffuse', False), img('Rough', True), img('nor_gl', True)
    if dif:
        mul = node(nt, 'ShaderNodeMix', data_type='RGBA', blend_type='MULTIPLY'); mul.inputs['Factor'].default_value = 1.0
        mul.inputs['B'].default_value = (darken, darken, darken, 1); L(nt, dif, 'Color', mul, 'A'); L(nt, mul, 'Result', b, 'Base Color')
    if rgh:
        mr = node(nt, 'ShaderNodeMath', operation='MULTIPLY'); mr.inputs[1].default_value = rough_mul
        L(nt, rgh, 'Color', mr, 0); L(nt, mr, 'Value', b, 'Roughness')
    if nor:
        nm = node(nt, 'ShaderNodeNormalMap'); L(nt, nor, 'Color', nm, 'Color'); L(nt, nm, 'Normal', b, 'Normal')
    return m
TEMPLATES = {}
def model(aid):
    if aid not in TEMPLATES:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, 'models', aid, aid + '.gltf'))
        new = [o for o in bpy.data.objects if o not in before]
        for o in new:
            for c in list(o.users_collection): c.objects.unlink(o)
        TEMPLATES[aid] = new
    return TEMPLATES[aid]
def place(aid, loc, rot=0.0, s=1.0, height=None):
    tpl = model(aid)
    root = bpy.data.objects.new(aid, None); col.objects.link(root)
    mapping = {}
    for o in tpl:
        c = o.copy(); col.objects.link(c); mapping[o] = c
    for o, c in mapping.items():
        c.parent = mapping.get(o.parent, root)
    if height:
        zs = [ (o.matrix_world @ Vector(cn)).z for o in tpl if o.type == 'MESH' for cn in o.bound_box ]
        s = height / max(1e-6, max(zs) - min(zs))
    root.location = loc; root.rotation_euler = (0, 0, rot); root.scale = (s, s, s)
    return root, mapping
def world_bbox(objs):
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for o in objs if o.type == 'MESH' for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi

PLANKS = pbr('Planks', 'dark_wooden_planks', 0.55, 0.45, 0.62)
TIMBER = pbr('Timber', 'brown_planks_05', 0.9, 0.55, 0.5)
SLATE = pbr('SlateWall', 'castle_wall_slates', 0.5, 0.55, 0.7)
MUD = pbr('ForestMud', 'brown_mud_leaves_01', 0.4, 0.38, 0.55)

# ---------------------------------------------------------------- porch
SEAT = Vector((0.55, 2.15, 0.44))
obj('PorchDeck', box(3.2, 4.2, 0.08, (2.05, 3.4, 0.40)), TIMBER, smooth=False)
for i in range(10):
    obj('Plank', box(3.25, 0.4, 0.035, (2.05, 1.5 + i * 0.42, 0.455), (0, 0, R.uniform(-0.01, 0.01))), PLANKS, smooth=False)
obj('Joist', box(0.16, 4.3, 0.22, (0.5, 3.4, 0.28)), TIMBER, smooth=False)
for (x, y) in ((0.42, 3.1), (0.42, 6.1), (3.3, 3.1)):
    obj('Post', box(0.15, 0.15, 2.5, (x, y, 1.65), (0, 0, R.uniform(-0.05, 0.05))), TIMBER, smooth=False)
for k in range(9):
    obj('Rafter', box(4.6, 0.11, 0.13, (1.4, 1.2 + k * 0.62, 2.88), (0, 0.06, 0)), TIMBER, smooth=False)
obj('Beam', box(0.22, 6.5, 0.24, (0.42, 3.6, 2.8)), TIMBER, smooth=False)
for k in range(26):
    obj('RoofBoard', box(4.4, 0.24, 0.025, (1.5, 0.9 + k * 0.23, 3.0), (0, 0.06, R.uniform(-0.01, 0.01))), PLANKS, smooth=False)
obj('Wall', box(0.3, 7.0, 3.2, (3.6, 3.6, 1.6)), SLATE, smooth=False)

# ---------------------------------------------------------------- forest floor, rocks, ferns, firs
def Hg(x, y):
    return 0.08 * noise.fractal(Vector((x * 0.35, y * 0.35, 0)), 0.8, 2.0, 4) - 0.05
NX = 180
bm = bmesh.new(); grid = []
for j in range(NX):
    y = -4 + 64 * j / (NX - 1)
    grid.append([bm.verts.new((x, y, Hg(x, y))) for x in [-34 + 40 * i / (NX - 1) for i in range(NX)]])
for j in range(NX - 1):
    for i in range(NX - 1):
        bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
obj('ForestFloor', bm, MUD)
place('rock_moss_set_01', (-1.5, 3.3, Hg(-1.5, 3.3)), 0.6, 0.45)
place('boulder_01', (-3.4, 8.5, Hg(-3.4, 8.5) - 0.1), 1.9, 0.7)
for (x, y, r) in ((-0.5, 1.6, 0.2), (-1.1, 2.6, 2.1), (-2.3, 4.4, 4.0), (-0.2, 3.9, 1.0), (0.05, 5.6, 3.3), (-2.9, 2.3, 5.1), (-1.8, 6.2, 0.7)):
    place('fern_02', (x, y, Hg(x, y)), r, R.uniform(0.8, 1.25))
for i in range(22):
    x = R.uniform(-4.5, 0.25); y = R.uniform(1.0, 11)
    place('grass_medium_01', (x, y, Hg(x, y)), R.random() * 6, R.uniform(0.7, 1.2))
for (x, y) in ((-0.3, 2.9), (-2.6, 5.4), (0.1, 7.0)):
    place('nettle_plant', (x, y, Hg(x, y)), R.random() * 6, 1.0)

# ---------------------------------------------------------------- the real lantern on a real stump
LP = Vector((0.86, 1.62, 0.0))
place('tree_stump_01', (-0.9, 1.3, Hg(-0.9, 1.3)), 1.2, height=0.45)     # a stump in the wet foreground
lan, lm = place('Lantern_01', (LP.x, LP.y, 0.472), 2.6, 1.2)              # lantern beside her on the porch boards
glass = [c for o, c in lm.items() if 'glass' in o.name.lower()]
for g in glass:
    g.data = g.data.copy(); g.data.materials.clear(); g.data.materials.append(GLASS)
hi = Vector((0, 0, 0.472))
glo, ghi = world_bbox(glass or list(lm.values()))
FL = (glo + ghi) / 2 + Vector((0, 0, -0.005))
print('stump top', round(hi.z, 3), 'lantern bbox', [round(v, 3) for v in glo], [round(v, 3) for v in ghi])
obj('Flame', ico(0.009, tuple(FL), (0.75, 0.75, 2.0), 3), FLAME)
lamp = bpy.data.lights.new('LanternLight', 'POINT'); lamp.energy = 26; lamp.shadow_soft_size = 0.01; lamp.color = (1.0, 0.6, 0.3)
lo_ = bpy.data.objects.new('LanternLight', lamp); col.objects.link(lo_); lo_.location = FL

# ---------------------------------------------------------------- the grandmother (local +X = facing direction)
dap = bpy.data.objects.new('Dapir', None); col.objects.link(dap)
dap.location = SEAT; dap.rotation_euler = (0, 0, math.radians(222)); dap.scale = (1, -1, 1)   # faces left & slightly toward camera; mirrored so the cigarette hand is camera-side
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

# ---------------------------------------------------------------- misty pine-forest HDRI, light mist for depth
world = bpy.data.worlds.new('MistyPines'); sc.world = world; world.use_nodes = True; wn = world.node_tree
bg = wn.nodes['Background']
env_t = wn.nodes.new('ShaderNodeTexEnvironment'); env_t.image = bpy.data.images.load(os.path.join(ASSETS, 'hdri', 'misty_pines_4k.hdr'))
mpw = wn.nodes.new('ShaderNodeMapping'); tcw = wn.nodes.new('ShaderNodeTexCoord'); mpw.inputs['Rotation'].default_value = (0, 0, math.radians(HDRI_ROT))
wn.links.new(tcw.outputs['Generated'], mpw.inputs['Vector']); wn.links.new(mpw.outputs['Vector'], env_t.inputs['Vector'])
wn.links.new(env_t.outputs['Color'], bg.inputs['Color']); bg.inputs['Strength'].default_value = 0.45
haze = bpy.data.materials.new('Mist'); haze.use_nodes = True; nt = haze.node_tree; nt.nodes.remove(nt.nodes['Principled BSDF'])
pv = node(nt, 'ShaderNodeVolumePrincipled', **{'Density': 0.012, 'Anisotropy': 0.2}); pv.inputs['Color'].default_value = (0.78, 0.9, 0.92, 1)
L(nt, pv, 'Volume', nt.nodes['Material Output'], 'Volume')
obj('Mist', box(40, 52, 30, (-14, 34, 14)), haze, smooth=False)
kl = bpy.data.lights.new('SkyKey', 'AREA'); kl.energy = 70; kl.size = 4; kl.color = (0.75, 0.88, 0.95)
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
vs.exposure = -0.1

s = sc.kelen_lens
s.lens = 'ANAMORPHIC'; s.strength = 1.0; s.fstop = 1.2; s.focus_object = focus
s.bloom = 0.35; s.halation = 0.6; s.streaks = 0.3; s.aberration = 0.3; s.vignette = 0.55; s.grain = 0.45
kll.apply_all(sc, s, co)
# teal film grade inserted before the output
tree = sc.compositing_node_group; go = [n for n in tree.nodes if n.type == 'GROUP_OUTPUT'][0]
src = go.inputs[0].links[0].from_socket
cb = tree.nodes.new('CompositorNodeColorBalance')
for nm, val in (('Lift', (0.88, 0.99, 1.02, 1)), ('Gamma', (0.9, 1.0, 1.04, 1)), ('Gain', (1.05, 0.98, 0.92, 1))):
    for i in cb.inputs:
        if i.name == nm and i.type == 'RGBA': i.default_value = val
hs = tree.nodes.new('CompositorNodeHueSat'); hs.inputs['Saturation'].default_value = 0.75
tree.links.new(src, cb.inputs['Image']); tree.links.new(cb.outputs['Image'], hs.inputs['Image']); tree.links.new(hs.outputs['Image'], go.inputs[0])
r.filepath = OUT
NO_RENDER = os.environ.get('KELEN_NO_RENDER') == '1'
if NO_RENDER:
    # ready-to-open file: pack every texture/HDRI inside, frame the camera view, look through the camera
    bpy.ops.file.pack_all()
    for scr in bpy.data.screens:
        for area in scr.areas:
            if area.type == 'VIEW_3D':
                for sp_ in area.spaces:
                    if sp_.type == 'VIEW_3D':
                        sp_.shading.type = 'MATERIAL'
                        sp_.region_3d.view_perspective = 'CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=os.path.splitext(OUT)[0] + '.blend', compress=True)
if not NO_RENDER:
    bpy.ops.render.render(write_still=True)
print('done', OUT)
