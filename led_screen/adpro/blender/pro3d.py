# WASTA GHAREB — photoreal 3D (Blender/Cycles) remake of the original 2D ad, scene by scene.
# Same layout, timing and story as led_screen/ad/index.html — but real geometry, studio light, glossy floor, DOF, motion blur.
# Kurdish text is real 3D: shaped with HarfBuzz from Noto Kufi Arabic and extruded (not an image).
# usage: python pro3d.py -- SCENE(1-4) OUTDIR RESX RESY SPP [all | i,j,k]
#   frame i of scene n  ->  local time u = i/30 - 0.25   (covers the wipe in/out the 2D compositor adds)
import bpy, bmesh, math, sys, os, random, time
from mathutils import Vector
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen

A = sys.argv[sys.argv.index('--') + 1:]
SCN, OUT, RX, RY, SPP = int(A[0]), A[1], int(A[2]), int(A[3]), int(A[4])
FR = A[5] if len(A) > 5 else 'all'
HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '..', '..', 'fonts'); ASSETS = os.path.join(HERE, '..', '..', 'ad', 'assets')
ANTON, KUFI = os.path.join(FONTS, 'Anton.ttf'), os.path.join(FONTS, 'NotoKufiArabic-Black.ttf')
LEN = {1: 4.5, 2: 5.5, 3: 5.5, 4: 4.5}[SCN]; FPS = 30; NF = round((LEN + .6) * FPS) + (0 if SCN in (1, 4) else 0)
U = lambda i: i / FPS - .25
clamp = lambda x, a=0., b=1.: max(a, min(b, x)); prog = lambda t, a, b: clamp((t - a) / (b - a)); lerp = lambda a, b, x: a + (b - a) * x
oCub = lambda x: 1 - (1 - x) ** 3; ioCub = lambda x: 4 * x ** 3 if x < .5 else 1 - (-2 * x + 2) ** 3 / 2
oExpo = lambda x: 1 if x >= 1 else 1 - 2 ** (-10 * x); ioSine = lambda x: -(math.cos(math.pi * x) - 1) / 2
def oBack(x, s=1.7): return 1 + (s + 1) * (x - 1) ** 3 + s * (x - 1) ** 2
bump = lambda t, a, b: math.sin(math.pi * prog(t, a, b)); frac = lambda x: x - math.floor(x)
R90 = math.radians(90)
# layout: the content area of the sign is 534x200 px (x 186..720). At the focus plane y=0 one px = S_ units.
D = 6.0; S_ = (2 * D * 18 / 50) / 534
PX = lambda px: (px - 453) * S_; PZ = lambda py: (100 - py) * S_
FLOOR = PZ(182)
ACC = {1: (.18, .48, 1.), 2: (.08, .78, 1.), 3: (1., .72, .12), 4: (.6, .42, 1.)}[SCN]

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SPP; sc.cycles.use_denoising = True
sc.cycles.use_adaptive_sampling = True; sc.cycles.max_bounces = 8; sc.cycles.transparent_max_bounces = 16
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = RX, RY, 100
sc.render.fps = FPS; sc.render.use_motion_blur = True; sc.render.motion_blur_shutter = .4
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'
sc.view_settings.view_transform = 'Standard'; sc.view_settings.look = 'None'; sc.view_settings.exposure = 0
W = bpy.data.worlds.new('w'); sc.world = W; W.use_nodes = True; W.node_tree.nodes['Background'].inputs[0].default_value = (.002, .004, .012, 1)

KEYS = []
def K(o, *ps):
    for p in ps: KEYS.append((o, p))
def mat(name, col, rough=.3, metal=0., emit=None, es=0., coat=0., spec=.5):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    if coat: b.inputs['Coat Weight'].default_value = coat; b.inputs['Coat Roughness'].default_value = .05
    if emit: b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = es
    return m
ES = lambda m: m.node_tree.nodes['Principled BSDF'].inputs['Emission Strength']
def empty(n, loc=(0, 0, 0)):
    o = bpy.data.objects.new(n, None); sc.collection.objects.link(o); o.location = loc; o.rotation_mode = 'XYZ'; return o
def aim(o, target): o.rotation_euler = (Vector(target) - o.location).to_track_quat('-Z', 'Y').to_euler()
def setT(o, loc=None, rot=None, s=None):
    if loc is not None: o.location = loc
    if rot is not None: o.rotation_euler = rot
    if s is not None: o.scale = (s, s, s) if isinstance(s, (int, float)) else s

# ---------------- camera ----------------
CAMZ = .55
bpy.ops.object.camera_add(location=(0, -D, CAMZ), rotation=(R90 - math.atan(CAMZ / D), 0, 0)); cam = bpy.context.object; sc.camera = cam
cam.data.lens = 50; cam.data.sensor_width = 36; cam.data.sensor_fit = 'HORIZONTAL'; cam.data.clip_start = .05
cam.data.dof.use_dof = True; cam.data.dof.focus_distance = D; cam.data.dof.aperture_fstop = 1.4; cam.data.dof.focus_distance = math.hypot(D, CAMZ)

# ---------------- studio: glossy floor with a faint scrolling grid, glowing horizon backdrop ----------------
bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 14, FLOOR)); floor = bpy.context.object
mf = mat('floor', (.006, .01, .028), .32, .2, coat=.25); nt = mf.node_tree; bsdf = nt.nodes['Principled BSDF']
tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping'); br = nt.nodes.new('ShaderNodeTexBrick'); br.offset = 0
br.inputs['Scale'].default_value = 1.6; br.inputs['Mortar Size'].default_value = .012; br.inputs['Brick Width'].default_value = .5; br.inputs['Row Height'].default_value = .5
mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = .22
nt.links.new(tc.outputs['Object'], mp.inputs['Vector']); nt.links.new(mp.outputs[0], br.inputs['Vector']); nt.links.new(br.outputs['Fac'], mul.inputs[0])
nt.links.new(mul.outputs[0], bsdf.inputs['Emission Strength']); bsdf.inputs['Emission Color'].default_value = (*ACC, 1)
floor.data.materials.append(mf); grid_loc = mp.inputs['Location']; K(grid_loc, 'default_value')
bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 14, FLOOR + 30 - .01), rotation=(R90, 0, 0)); back = bpy.context.object
def backdrop_mat():
    m = bpy.data.materials.new('backdrop'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (0, (30 - .5) / 3.2, 0)
    mp.inputs['Scale'].default_value = (1 / 9, 1 / 3.2, 1); gr = nt.nodes.new('ShaderNodeTexGradient'); gr.gradient_type = 'SPHERICAL'
    cr = nt.nodes.new('ShaderNodeValToRGB'); e = cr.color_ramp.elements; e[0].color = (.003, .006, .018, 1); e[1].color = (*[c * .06 for c in ACC], 1); e[1].position = 1
    em = nt.nodes.new('ShaderNodeEmission'); em.inputs[1].default_value = 1.; out = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(tc.outputs['Object'], mp.inputs['Vector']); nt.links.new(mp.outputs[0], gr.inputs[0]); nt.links.new(gr.outputs['Fac'], cr.inputs[0])
    nt.links.new(cr.outputs[0], em.inputs[0]); nt.links.new(em.outputs[0], out.inputs[0]); return m, em
mback, back_em = backdrop_mat(); back.data.materials.append(mback); K(back_em.inputs[1], 'default_value')
# bokeh: small glowing orbs far behind the focus plane (become real out-of-focus discs)
bok = []
if False:
    R = random.Random(5); mb = mat('bok', (0, 0, 0), .5, emit=ACC, es=6); mbw = mat('bokw', (0, 0, 0), .5, emit=(1, 1, 1), es=4)
    for i in range(26):
        bpy.ops.mesh.primitive_ico_sphere_add(radius=R.uniform(.025, .06), subdivisions=2); o = bpy.context.object; o.data.materials.append(mbw if i % 4 == 0 else mb)
        bok.append((o, R.uniform(-7, 7), R.uniform(4, 9), R.uniform(-.2, 2.6), R.choice((1, 2, 3)) * .25, R.uniform(0, 6.28))); K(o, 'location')
# ---------------- lights ----------------
def area(n, loc, tgt, size, e, col, sy=None):
    bpy.ops.object.light_add(type='AREA', location=loc); l = bpy.context.object; l.name = n; aim(l, tgt)
    l.data.shape = 'RECTANGLE'; l.data.size = size; l.data.size_y = sy or size; l.data.energy = e; l.data.color = col; return l
key = area('key', (.6, -4.2, 3.2), (0, 0, 0), 4, 520, (1, .97, .93))
rimL = area('rimL', (-4, 2.6, 1.4), (0, 0, 0), 2.2, 420, ACC); rimR = area('rimR', (4, 2.6, 1.4), (0, 0, 0), 2.2, 420, ACC)
top = area('top', (0, .5, 3.4), (0, .5, 0), 6, 160, (1, 1, 1), sy=.6)
sweep = area('sweep', (-5, -2.4, .2), (0, 0, .2), .25, 0, (1, 1, 1), sy=3.5); K(sweep, 'location'); K(sweep.data, 'energy')
spots = []
for sx in (-1, 1):
    bpy.ops.object.light_add(type='SPOT', location=(sx * 1.6, 1.5, 4.2)); s = bpy.context.object; s.data.energy = 420; s.data.color = ACC
    s.data.spot_size = math.radians(22); s.data.spot_blend = .6; spots.append((s, sx)); K(s, 'rotation_euler')
def STAGE(t, u, glints=()):
    grid_loc.default_value = (0, -u * .35, 0)
    back_em.inputs[1].default_value = 1.
    for o, x0, y0, z0, k, ph in bok:
        o.location = (((x0 + u * k * 1.2 + 7) % 14) - 7, y0, z0 + math.sin(u * .63 + ph) * .15)
    for s, sx in spots:
        a = math.sin(2 * math.pi * u / 10 + (0 if sx < 0 else math.pi)) * .45
        s.location = (sx * 1.6, 1.5, 4.2); aim(s, (sx * 1.6 + math.tan(a) * 4, 1.5, FLOOR))
    p = 0
    for a_, b_ in glints:
        q = prog(u, a_, b_)
        if 0 < q < 1: p = q
    sweep.location = (lerp(-5, 5, ioSine(p)), -2.4, .2); sweep.data.energy = 1100 * math.sin(math.pi * p)

# ---------------- real 3D type (HarfBuzz shaping -> bezier outlines -> extruded mesh) ----------------
class Pen(BasePen):
    def __init__(s, gs): super().__init__(gs); s.cs = []; s.c = None
    def _moveTo(s, p): s.c = [('M', p)]
    def _lineTo(s, p): s.c.append(('L', p))
    def _curveToOne(s, a, b, p): s.c.append(('C', a, b, p))
    def _closePath(s):
        if s.c and len(s.c) > 1: s.cs.append(s.c)
        s.c = None
    _endPath = _closePath
_fonts = {}
def shape(text, path):
    if path not in _fonts:
        _fonts[path] = (hb.Font(hb.Face(hb.Blob.from_file_path(path))), TTFont(path))
    f, tt = _fonts[path]; buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties(); hb.shape(f, buf, {})
    gs = tt.getGlyphSet(); order = tt.getGlyphOrder(); x = 0; out = []
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        pen = Pen(gs); gs[order[info.codepoint]].draw(pen)
        if pen.cs: out.append((x + pos.x_offset, pos.y_offset, pen.cs))
        x += pos.x_advance
    return out
def lerp2(a, b, k): return (a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k)
def text3d(name, text, path, maxW, maxH, cx, cz, ext, bev, mface, mside, y=0.):
    """returns list of glyph objects (origin at glyph ink centre, standing, facing camera) sorted left->right"""
    gl = shape(text, path); xs = []; zs = []
    for gx, gy, cs in gl:
        for c in cs:
            for seg in c:
                for p in seg[1:]: xs.append(p[0] + gx); zs.append(p[1] + gy)
    x0, x1, z0, z1 = min(xs), max(xs), min(zs), max(zs); k = min(maxW / (x1 - x0), maxH / (z1 - z0))
    ox, oz = (x0 + x1) / 2, (z0 + z1) / 2; objs = []
    for gi, (gx, gy, cs) in enumerate(gl):
        pts_all = [(p[0] + gx, p[1] + gy) for c in cs for seg in c for p in seg[1:]]
        gcx = (min(p[0] for p in pts_all) + max(p[0] for p in pts_all)) / 2; gcz = (min(p[1] for p in pts_all) + max(p[1] for p in pts_all)) / 2
        T = lambda p: ((p[0] + gx - gcx) * k, (p[1] + gy - gcz) * k, 0)
        cu = bpy.data.curves.new(f'{name}{gi}', 'CURVE'); cu.dimensions = '2D'; cu.fill_mode = 'BOTH'
        for c in cs:
            pts = [[c[0][1], None, None]]
            for seg in c[1:]:
                if seg[0] == 'L': pr = pts[-1][0]; pts[-1][2] = lerp2(pr, seg[1], 1 / 3); pts.append([seg[1], lerp2(pr, seg[1], 2 / 3), None])
                else: pts[-1][2] = seg[1]; pts.append([seg[3], seg[2], None])
            if abs(pts[-1][0][0] - pts[0][0][0]) < 1e-6 and abs(pts[-1][0][1] - pts[0][0][1]) < 1e-6:
                pts[0][1] = pts[-1][1]; pts.pop()
            else:
                pr = pts[-1][0]; pts[-1][2] = lerp2(pr, pts[0][0], 1 / 3); pts[0][1] = lerp2(pr, pts[0][0], 2 / 3)
            sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(pts) - 1)
            for bp, (co, hl, hr) in zip(sp.bezier_points, pts):
                bp.handle_left_type = bp.handle_right_type = 'FREE'; bp.co = T(co); bp.handle_left = T(hl); bp.handle_right = T(hr)
            sp.use_cyclic_u = True
        cu.extrude = ext; cu.bevel_depth = bev; cu.bevel_resolution = 3
        o = bpy.data.objects.new(f'{name}{gi}', cu); sc.collection.objects.link(o)
        for x in sc.objects: x.select_set(False)
        bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.convert(target='MESH'); o.select_set(False)
        o.data.materials.append(mface); o.data.materials.append(mside)
        for p in o.data.polygons: p.material_index = 0 if p.normal.z > .9 else 1; p.use_smooth = p.material_index == 1
        o.rotation_mode = 'XYZ'; o.rotation_euler = (R90, 0, 0)
        fx, fz = cx + (gcx - ox) * k, cz + (gcz - oz) * k; o.location = (fx, y, fz); o['fx'], o['fz'] = fx, fz
        objs.append(o)
    objs.sort(key=lambda o: o['fx']); return objs, (x1 - x0) * k, (z1 - z0) * k
def star_obj(r, m):
    bm = bmesh.new(); vs = []
    for i in range(10):
        a = math.pi / 2 + i * math.pi / 5; rr = r if i % 2 == 0 else r * .45; vs.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, 0)))
    f = bm.faces.new(vs); ex = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [g for g in ex['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.z += r * .35
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, 0, -r * .175))
    me = bpy.data.meshes.new('star'); bm.to_mesh(me); o = bpy.data.objects.new('star', me); sc.collection.objects.link(o)
    me.materials.append(m); bv = o.modifiers.new('b', 'BEVEL'); bv.width = r * .06; bv.segments = 2; o.rotation_mode = 'XYZ'; return o
def pill(name, w, h, th, m):
    bm = bmesh.new(); r = h / 2; pts = []
    for k in range(25): a = -math.pi / 2 + math.pi * k / 24; pts.append((w / 2 - r + math.cos(a) * r, math.sin(a) * r))
    for k in range(25): a = math.pi / 2 + math.pi * k / 24; pts.append((-w / 2 + r + math.cos(a) * r, math.sin(a) * r))
    f = bm.faces.new([bm.verts.new((x, -th / 2, z)) for x, z in pts]); ex = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [g for g in ex['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.y += th
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); me = bpy.data.meshes.new(name); bm.to_mesh(me)
    o = bpy.data.objects.new(name, me); sc.collection.objects.link(o); me.materials.append(m)
    bv = o.modifiers.new('b', 'BEVEL'); bv.width = .025; bv.segments = 5; bv.limit_method = 'ANGLE'
    for p in me.polygons: p.use_smooth = True
    return o
def sprite(n, h_front, wmax_ratio):
    img = bpy.data.images.load(os.path.join(ASSETS, n + '.png')); m = bpy.data.materials.new(n); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    ti = nt.nodes.new('ShaderNodeTexImage'); ti.image = img; em = nt.nodes.new('ShaderNodeEmission'); trn = nt.nodes.new('ShaderNodeBsdfTransparent')
    mx = nt.nodes.new('ShaderNodeMixShader'); out = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(ti.outputs['Color'], em.inputs[0]); nt.links.new(ti.outputs['Alpha'], mx.inputs[0]); nt.links.new(trn.outputs[0], mx.inputs[1])
    nt.links.new(em.outputs[0], mx.inputs[2]); nt.links.new(mx.outputs[0], out.inputs[0])
    asp = img.size[0] / img.size[1]; h = min(h_front, h_front * wmax_ratio / asp); w = h * asp
    bpy.ops.mesh.primitive_plane_add(size=1); o = bpy.context.object; o.name = n
    for v in o.data.vertices: v.co = Vector((v.co.x * w, 0, (v.co.y + .5) * h))   # standing, bottom at origin, facing -Y
    o.data.materials.append(m); o.rotation_mode = 'XYZ'; K(o, 'location', 'scale', 'rotation_euler'); K(em.inputs[1], 'default_value')
    return o, em.inputs[1]

# ---------------- shared materials ----------------
m_white = mat('white', (.93, .95, 1.), .2, 0, emit=(1, 1, 1), es=.05, coat=1)
m_blue = mat('blueMetal', (.08, .25, .9), .22, 1.)
m_gold = mat('gold', (1., .71, .29), .16, 1.)
m_goldface = mat('goldface', (1., .78, .4), .2, 1., emit=(1., .6, .2), es=.15)
m_navy = mat('navy', (.015, .04, .14), .3, .2, coat=.6)
HIDE = (0, 30, -20)
def podium(cx, cy):
    m_pod = mat('podium', (.02, .035, .08), .12, .4, coat=1); m_rim = mat('podrim', (0, 0, 0), .5, emit=ACC, es=10)
    g = empty('podium')
    bpy.ops.mesh.primitive_cylinder_add(radius=1.32, depth=.09, vertices=128); d = bpy.context.object; d.data.materials.append(m_pod); d.parent = g; d.location = (0, 0, -.045)
    bv = d.modifiers.new('b', 'BEVEL'); bv.width = .02; bv.segments = 3
    bpy.ops.mesh.primitive_torus_add(major_radius=1.33, minor_radius=.014, major_segments=160, minor_segments=8); r = bpy.context.object; r.data.materials.append(m_rim); r.parent = g; r.location = (0, 0, -.01)
    mdot = mat('dot', (0, 0, 0), .5, emit=(1, 1, 1), es=40)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=.03, segments=16, ring_count=8); dot = bpy.context.object; dot.data.materials.append(mdot); dot.parent = g
    K(g, 'location'); K(dot, 'location'); return g, dot

def save_frames(state):
    t0 = time.time()
    for f in range(NF):
        state(U(f), f)
        for o, p in KEYS: o.keyframe_insert(p, frame=f)
    for a in bpy.data.actions:
        for fc in getattr(a, 'fcurves', []):
            for k in fc.keyframe_points: k.interpolation = 'LINEAR'
    print('keyed', NF, 'frames in', round(time.time() - t0, 1), 's', flush=True)
    os.makedirs(OUT, exist_ok=True); sc.frame_start, sc.frame_end = 0, NF - 1
    frames = range(NF) if FR == 'all' else [int(x) for x in FR.split(',')]
    for f in frames:
        p = os.path.join(OUT, 's%d_%04d.png' % (SCN, f))
        if os.path.exists(p): continue
        t1 = time.time(); sc.frame_set(f); sc.render.filepath = p; bpy.ops.render.render(write_still=True)
        print('frame', f, round(time.time() - t1, 1), 's', flush=True)

# ======================================================================================
if SCN == 1:   # WASTA GHAREB — letters slam in from in front of the lens, gold Kurdish name pops up right-to-left
    let, LW, LH = text3d('L', 'WASTA GHAREB', ANTON, PX(458 + 235) - PX(458 - 235), 84 * S_, PX(458), PZ(74), .085, .012, m_white, m_blue)
    ku, KW, KH = text3d('K', 'وەستا غەریب', KUFI, 300 * S_, 50 * S_, PX(458), PZ(152), .05, .008, m_goldface, m_gold)
    for o in let + ku: K(o, 'location', 'rotation_euler', 'scale')
    stars = []
    for sgn in (-1, 1):
        for j in range(3):
            s = star_obj((7 if j == 0 else 5.5) * S_ * 1.1, m_gold); s['x'] = PX(458) + sgn * (KW / 2 + (24 + j * 17) * S_); s['j'] = j; s['sg'] = sgn
            stars.append(s); K(s, 'location', 'rotation_euler', 'scale')
    camv = Vector((0, -D, 0)); chars = [c for c in 'WASTA GHAREB']; idx = [i for i, c in enumerate(chars) if c != ' ']
    def state(u, f):
        STAGE(f / FPS, u, ((1.75, 2.45), (3.55, 4.2)))
        for n, o in enumerate(let):
            i = idx[n]; q = prog(u, .12 + i * .045, .62 + i * .045); fin = Vector((o['fx'], 0, o['fz']))
            if q <= 0: setT(o, HIDE, None, 0); continue
            e = oExpo(q); st = camv + (fin - camv) / 3.4
            setT(o, st.lerp(fin, e), (R90 + (1 - e) * .5, 0, (1 - e) * .6 * (1 if n % 2 else -1)), 1)
        n = len(ku)
        for r, o in enumerate(sorted(ku, key=lambda o: -o['fx'])):
            a = .95 + r * (.45 / max(1, n - 1)); q = prog(u, a, a + .32)
            if q <= 0: setT(o, HIDE, None, 0); continue
            e = oBack(q, 1.8); setT(o, (o['fx'], 0, o['fz'] - (1 - min(1, e)) * .12), (R90 * e, 0, 0), min(1, q * 3))
        for s in stars:
            q = oBack(prog(u, 1.45 + s['j'] * .08, 1.8 + s['j'] * .08), 2.4)
            if q <= 0: setT(s, HIDE, None, 0); continue
            setT(s, (s['x'], -.02, PZ(150)), (R90, u * .6 * s['sg'], 0), max(0, q))
    save_frames(state)

elif SCN in (2, 3):
    if SCN == 2:
        CX, NAMES, HF, WR = PX(338), ['pb_anker165', 'pb_maggo_stand', 'pb_anker20k', 'pb_qi2_blue', 'pb_instacord'], 1.26, .77
        STEP0, STEPDT = 1.3, .84
    else:
        CX, NAMES, HF, WR = PX(352), ['adapter', 'cable_closeup', 'magsafe', 'cable_coil'], 1.24, .8
        STEP0, STEPDT = 1.15, .95
    CY, RR = .3, .84
    pod, pdot = podium(CX, CY)
    items = [sprite(n, HF, WR) for n in NAMES]
    TX = PX(592) if SCN == 2 else PX(620)
    if SCN == 2:
        m_cyanside = mat('cyanside', (.02, .42, .62), .2, 1.)
        ank, AW, AH = text3d('A', 'ANKER', ANTON, 226 * S_, 60 * S_, TX, PZ(42), .07, .01, m_white, m_cyanside)
        m_pb = mat('pb', (.4, .85, 1.), .3, 0, emit=(.25, .8, 1.), es=3)
        pbt, _, _ = text3d('P', 'POWER BANK', ANTON, 226 * S_, 26 * S_, TX, PZ(98), .015, .003, m_pb, m_pb)
        PW, PH = 224 * S_, 50 * S_
        m_pg = mat('pillgold', (1., .7, .18), .18, .85, emit=(1., .55, .1), es=.2, coat=1)
        tf, _, _ = text3d('SF', 'لەم نزیکانە', KUFI, PW * .82, PH * .62, 0, 0, .012, .003, m_navy, m_navy, y=0)
        tb, _, _ = text3d('SB', 'COMING SOON', ANTON, PW * .82, PH * .56, 0, 0, .012, .003, m_navy, m_navy, y=0)
        pillc = (TX, PZ(153)); PCOL = m_pg
    else:
        m_slate = mat('slate', (.35, .4, .5), .2, 1.)
        ad1, _, _ = text3d('D', 'ADAPTER', ANTON, 178 * S_, 40 * S_, TX, PZ(34), .07, .01, m_white, m_slate)
        ad2, _, _ = text3d('C', '& CABLE', ANTON, 178 * S_, 40 * S_, TX, PZ(84), .07, .01, m_goldface, m_gold)
        PW, PH = 170 * S_, 50 * S_
        m_pg = mat('pillgreen', (.02, .62, .3), .16, .1, emit=(.05, .9, .4), es=.25, coat=1)
        m_wt = mat('wtext', (1, 1, 1), .3, 0, emit=(1, 1, 1), es=1.2)
        tf, _, _ = text3d('SF', 'بەردەستە', KUFI, 124 * S_, 34 * S_, 12 * S_, 0, .012, .003, m_wt, m_wt, y=0)
        tb, _, _ = text3d('SB', 'IN STOCK', ANTON, 124 * S_, 29 * S_, 12 * S_, 0, .012, .003, m_wt, m_wt, y=0)
        pillc = (TX + 10 * S_, PZ(152)); PCOL = m_pg
    pg = empty('pillg'); pb_ = pill('pill', PW, PH, .1, PCOL); pb_.parent = pg
    for o in tf: o.parent = pg; o.location = (o.location.x, -.056, o.location.z)
    for o in tb: o.parent = pg; o.location = (o.location.x, .056, -o.location.z); o.rotation_euler = (-R90, 0, 0)
    K(pg, 'location', 'rotation_euler', 'scale')
    if SCN == 3:   # white check badge
        cb = empty('check'); m_cw = mat('cw', (1, 1, 1), .25, 0, emit=(1, 1, 1), es=.5, coat=1)
        bpy.ops.mesh.primitive_cylinder_add(radius=19 * S_, depth=.07, vertices=64, rotation=(R90, 0, 0)); c = bpy.context.object; c.data.materials.append(m_cw); c.parent = cb
        cu = bpy.data.curves.new('ck', 'CURVE'); cu.dimensions = '3D'; sp = cu.splines.new('POLY'); sp.points.add(2)
        for p, (x, z) in zip(sp.points, ((-8, -1), (-3, -7), (9, 8))): p.co = (x * S_, -.045, z * S_, 1)
        cu.bevel_depth = 2.3 * S_; cu.bevel_resolution = 4; cu.use_fill_caps = True; ck = bpy.data.objects.new('ck', cu); sc.collection.objects.link(ck)
        ck.data.materials.append(mat('ckg', (.02, .6, .28), .3)); ck.parent = cb; K(cb, 'location', 'scale', 'rotation_euler')
        m_bolt = mat('bolt', (0, 0, 0), .5, emit=(1., .82, .45), es=30); bolts = []
        for j in range(2):
            cu = bpy.data.curves.new('b%d' % j, 'CURVE'); cu.dimensions = '3D'; sp = cu.splines.new('POLY'); sp.points.add(11); cu.bevel_depth = .006; cu.bevel_resolution = 2
            o = bpy.data.objects.new('bolt%d' % j, cu); sc.collection.objects.link(o); o.data.materials.append(m_bolt); bolts.append(o); K(o, 'scale')
            for p in sp.points: K(p, 'co')
        m_sp = mat('spark', (0, 0, 0), .5, emit=(1., .8, .35), es=40); sparks = []; R = random.Random(9)
        for i in range(26):
            bpy.ops.mesh.primitive_ico_sphere_add(radius=R.uniform(.008, .016), subdivisions=1); o = bpy.context.object; o.data.materials.append(m_sp)
            a = R.uniform(0, 6.283); sparks.append((o, math.cos(a), math.sin(a), R.uniform(150, 480) * S_)); K(o, 'location', 'scale')
    nsteps = len(NAMES)
    def state(u, f):
        STAGE(f / FPS, u, ((2.1, 2.8), (4.2, 4.9)) if SCN == 3 else ())
        rise = oCub(prog(u, 0, .6)); yo = -(1 - rise) * 70 * S_
        pod.location = (CX, CY, FLOOR + yo); da = 2 * math.pi * u / 2.75 * (1 if SCN == 2 else -1)
        pdot.location = (math.cos(da) * 1.33, math.sin(da) * 1.33, 0)
        sil = 1 - ioCub(prog(u, .7, 1.5)) if SCN == 2 else 0
        st = sum(ioCub(prog(u, STEP0 + k * STEPDT, STEP0 + .48 + k * STEPDT)) for k in range(nsteps)); b0 = -st * 2 * math.pi / nsteps
        pos = []
        for i, (o, es) in enumerate(items):
            th = b0 + i * 2 * math.pi / nsteps; d = (math.cos(th) + 1) / 2
            x, y = CX + math.sin(th) * RR, CY - math.cos(th) * RR; bob = (2.5 + 2.5 * math.sin(2 * math.pi * u / 2.75 + i)) * S_
            s = .53 + .47 * d; setT(o, (x, y, FLOOR + yo + bob + .002), (0, 0, 0), s)
            es.default_value = max(.035, 1 - max(sil, (1 - d) * .45)) + .35 * bump(u, 2.2 + i * .1, 2.9 + i * .1) * (SCN == 2)
            pos.append((x, y, FLOOR + yo + HF * s * .55, d))
        if SCN == 2:
            for i, o in enumerate(ank):
                q = prog(u, .25 + i * .06, .6 + i * .06)
                if q <= 0: setT(o, HIDE, None, 0); continue
                setT(o, (o['fx'], 0, o['fz'] + (1 - oBack(q, 2)) * 60 * S_), None, min(1, q * 2.5))
            n = len(pbt)
            for i, o in enumerate(pbt):
                q = prog(u, .55 + i / n * .4, .62 + i / n * .4)
                setT(o, (o['fx'], 0, o['fz']) if q > 0 else HIDE, None, oCub(q) if q > 0 else 0)
            ent = oBack(prog(u, .9, 1.25), 1.6); fl = ioCub(prog(u, 2.95, 3.3)); pulse = 1 + .04 * math.sin(2 * math.pi * u / 1.375)
            setT(pg, (pillc[0], -.05, pillc[1]) if ent > 0 else HIDE, (fl * math.pi, 0, 0), max(0, ent) * pulse if ent > 0 else 0)
        else:
            for k, (grp, a0) in enumerate(((ad1, .35), (ad2, .5))):
                q = oBack(prog(u, a0, a0 + .4), 1.8)
                for o in grp: setT(o, (o['fx'], 0, o['fz']) if q > 0 else HIDE, (R90 * clamp(q, 0, 1.2), 0, 0), 1 if q > 0 else 0)
            e = oBack(prog(u, 1.0, 1.35), 2.2); fl = ioCub(prog(u, 3.0, 3.35))
            stamp = lerp(1.7, 1, clamp(e)) * clamp(e * 2)
            setT(pg, (pillc[0], -.05, pillc[1]) if e > 0 else HIDE, (fl * math.pi, 0, 0), stamp if e > 0 else 0)
            cp = oBack(prog(u, 1.25, 1.6), 2.5)
            setT(cb, (TX - 75 * S_, -.09, PZ(152)) if cp > 0 else HIDE, (0, 0, 0), cp if cp > 0 else 0)
            front = max(pos, key=lambda p: p[3]); others = sorted([p for p in pos if p is not front], key=lambda p: -p[3])
            R = random.Random(int(u * 18))
            for j, o in enumerate(bolts):
                w = frac(u * 1.15 + j * .5); on = 1 < u < 5.4 and w < .2; tg = others[j]
                o.scale = (1, 1, 1) if on else (0, 0, 0)
                a, b = Vector((front[0], front[1] - .02, front[2])), Vector((tg[0], tg[1] - .02, tg[2]))
                for k, p in enumerate(o.data.splines[0].points):
                    t_ = k / 11; j_ = (R.uniform(-1, 1) * .07) if 0 < k < 11 else 0; c = a.lerp(b, t_)
                    p.co = (c.x, c.y, c.z + j_, 1)
            dd = u - .6
            for o, cx_, cz_, v in sparks:
                if 0 < dd < .8:
                    dist = v * (1 - math.exp(-4 * dd)) / 4; setT(o, (CX + cx_ * dist, CY - RR - .05, FLOOR + .3 + cz_ * dist * .55 - dd * dd * .4), None, 1 - dd / .8)
                else: setT(o, HIDE, None, 0)
    save_frames(state)

else:  # SCN 4 — opening hours: day -> night time-lapse behind real 3D type and a 3D clock
    msky = bpy.data.materials.new('sky'); msky.use_nodes = True; nt = msky.node_tree; nt.nodes.clear()
    tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc.outputs['Object'], sep.inputs[0])
    mr = nt.nodes.new('ShaderNodeMapRange'); mr.inputs['From Min'].default_value = -30; mr.inputs['From Max'].default_value = -22; nt.links.new(sep.outputs['Y'], mr.inputs[0])
    def ramp(c0, c1, c2):
        r = nt.nodes.new('ShaderNodeValToRGB'); el = r.color_ramp.elements; el[0].color = (*c0, 1); el[1].color = (*c2, 1); el.new(.4).color = (*c1, 1); nt.links.new(mr.outputs[0], r.inputs[0]); return r
    rd = ramp((.95, .45, .15), (.22, .32, .7), (.03, .12, .45)); rn = ramp((.22, .07, .3), (.05, .035, .16), (.006, .009, .035))
    mixn = nt.nodes.new('ShaderNodeMix'); mixn.data_type = 'RGBA'; nt.links.new(rd.outputs[0], mixn.inputs[6]); nt.links.new(rn.outputs[0], mixn.inputs[7])
    em = nt.nodes.new('ShaderNodeEmission'); nt.links.new(mixn.outputs[2], em.inputs[0]); out = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(em.outputs[0], out.inputs[0])
    back.data.materials.clear(); back.data.materials.append(msky); NF_ = mixn.inputs[0]; K(NF_, 'default_value'); K(em.inputs[1], 'default_value'); SKYS = em.inputs[1]
    mf.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (.5, .4, 1., 1)
    msun = mat('sun', (0, 0, 0), .5, emit=(1., .55, .18), es=4); bpy.ops.mesh.primitive_uv_sphere_add(radius=.55, segments=48, ring_count=24); sun = bpy.context.object; sun.data.materials.append(msun)
    mmoon = mat('moon', (.85, .88, 1.), .6, emit=(.85, .9, 1.), es=3); bpy.ops.mesh.primitive_uv_sphere_add(radius=.46, segments=48, ring_count=24); moon = bpy.context.object; moon.data.materials.append(mmoon)
    mocc = mat('occ', (0, 0, 0), 1., emit=(.01, .015, .05), es=1); bpy.ops.mesh.primitive_uv_sphere_add(radius=.42, segments=32, ring_count=16); occ = bpy.context.object; occ.data.materials.append(mocc); occ.parent = moon; occ.location = (.22, -.3, .14)
    for o in (sun, moon): K(o, 'location')
    K(ES(msun), 'default_value'); K(ES(mmoon), 'default_value'); K(ES(mocc), 'default_value')
    mst = mat('stars', (0, 0, 0), .5, emit=(1, 1, 1), es=0); R = random.Random(21)
    for i in range(70):
        bpy.ops.mesh.primitive_ico_sphere_add(radius=R.uniform(.02, .05), subdivisions=1, location=(R.uniform(-14, 14), 13.6, R.uniform(1.2, 9))); bpy.context.object.data.materials.append(mst)
    K(ES(mst), 'default_value')
    # city: real boxes with lit windows, on the horizon
    mc = mat('city', (.006, .008, .02), .5, emit=(1., .78, .4), es=0); nt = mc.node_tree; b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); sp = nt.nodes.new('ShaderNodeSeparateXYZ'); cbx = nt.nodes.new('ShaderNodeCombineXYZ'); brk = nt.nodes.new('ShaderNodeTexBrick'); brk.offset = 0
    nt.links.new(tc.outputs['Object'], sp.inputs[0]); nt.links.new(sp.outputs['X'], cbx.inputs['X']); nt.links.new(sp.outputs['Z'], cbx.inputs['Y']); nt.links.new(cbx.outputs[0], brk.inputs['Vector'])
    brk.inputs['Scale'].default_value = 14; brk.inputs['Mortar Size'].default_value = .1; brk.inputs['Brick Width'].default_value = .35; brk.inputs['Row Height'].default_value = .3
    brk.inputs['Color1'].default_value = (0, 0, 0, 1); brk.inputs['Color2'].default_value = (1, 1, 1, 1); brk.inputs['Bias'].default_value = .2
    inv = nt.nodes.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1; nt.links.new(brk.outputs['Fac'], inv.inputs[1])
    bw = nt.nodes.new('ShaderNodeRGBToBW'); nt.links.new(brk.outputs['Color'], bw.inputs[0]); m1 = nt.nodes.new('ShaderNodeMath'); m1.operation = 'MULTIPLY'
    nt.links.new(inv.outputs[0], m1.inputs[0]); nt.links.new(bw.outputs[0], m1.inputs[1]); m2 = nt.nodes.new('ShaderNodeMath'); m2.operation = 'MULTIPLY'
    nt.links.new(m1.outputs[0], m2.inputs[0]); nt.links.new(m2.outputs[0], b.inputs['Emission Strength']); CITY = m2.inputs[1]; K(CITY, 'default_value')
    R = random.Random(77); x = -4.6
    while False:
        w = R.uniform(.22, .48); h = R.uniform(.12, .5); y = R.uniform(3.0, 4.0)
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x + w / 2, y, FLOOR + h / 2)); c = bpy.context.object; c.scale = (w, R.uniform(.5, .9), h)
        bpy.ops.object.transform_apply(scale=True); c.data.materials.append(mc); x += w + R.uniform(.02, .15)
    # type + clock
    m_gt = mat('goldt', (1., .72, .3), .18, 1., emit=(1., .6, .15), es=.35)
    tit, TW_, _ = text3d('T', 'کاتی کردنەوە', KUFI, 280 * S_, 32 * S_, PX(460), PZ(30), .045, .007, m_gt, m_gold)
    h1, _, _ = text3d('H', '9 AM', ANTON, 130 * S_, 58 * S_, PX(350), PZ(100), .085, .012, m_white, m_blue)
    h2, _, _ = text3d('I', '11 PM', ANTON, 130 * S_, 58 * S_, PX(570), PZ(100), .085, .012, m_white, m_blue)
    m_wl = mat('wline', (.95, .96, 1.), .25, 0, emit=(1, 1, 1), es=.5, coat=.5)
    ln, LNW, _ = text3d('N', 'لە ٩ی بەیانی تا ١١ی شەو', KUFI, 400 * S_, 30 * S_, PX(460), PZ(165), .04, .006, m_wl, m_blue)
    for o in tit + h1 + h2 + ln: K(o, 'location', 'rotation_euler', 'scale')
    clk = empty('clock'); CR = 27 * S_
    m_face = mat('face', (.96, .96, .98), .25, 0, emit=(1, 1, 1), es=.35, coat=1)
    bpy.ops.mesh.primitive_cylinder_add(radius=CR, depth=.06, vertices=96, rotation=(R90, 0, 0)); c = bpy.context.object; c.data.materials.append(m_face); c.parent = clk
    bpy.ops.mesh.primitive_torus_add(major_radius=CR * 1.02, minor_radius=CR * .1, major_segments=96, minor_segments=16, rotation=(R90, 0, 0)); c = bpy.context.object; c.data.materials.append(m_gold); c.parent = clk
    m_hand = mat('hand', (.02, .05, .15), .3, .3)
    def hand(L, w, m, yoff):
        e = empty('hand'); bpy.ops.mesh.primitive_cube_add(size=1); c = bpy.context.object; c.scale = (w, .01, L); c.location = (0, 0, L / 2 - CR * .08)
        c.data.materials.append(m); c.parent = e; e.parent = clk; e.location = (0, yoff, 0); return e
    hh = hand(CR * .55, CR * .1, m_hand, -.045); hm = hand(CR * .8, CR * .06, m_gt, -.055)
    for i in range(12):
        a = i * math.pi / 6; bpy.ops.mesh.primitive_cube_add(size=1); tk = bpy.context.object; tk.scale = (CR * .05, .01, CR * (.1 if i % 3 else .16))
        tk.location = (math.sin(a) * CR * .78, -.035, math.cos(a) * CR * .78); tk.rotation_euler = (0, a, 0); tk.data.materials.append(m_hand); tk.parent = clk
    K(clk, 'location', 'scale', 'rotation_euler'); K(hh, 'rotation_euler'); K(hm, 'rotation_euler')
    dots = []
    for s_ in (-1, 1):
        for i in range(3):
            bpy.ops.mesh.primitive_uv_sphere_add(radius=1.6 * S_, segments=12, ring_count=6); d = bpy.context.object; d.data.materials.append(m_gt)
            d['x'] = PX(460) + s_ * (36 + i * 9) * S_; d['i'] = i; dots.append(d); K(d, 'location', 'scale')
    def flip_in(grp, q):
        for o in grp: setT(o, (o['fx'], 0, o['fz']) if q > 0 else HIDE, (R90 * clamp(q, 0, 1.2), 0, 0), 1 if q > 0 else 0)
    def state(u, f):
        STAGE(f / FPS, u)
        n = ioCub(prog(u, 1.7, 3.1)); NF_.default_value = n; SKYS.default_value = .75
        k = (D + 13) / D
        sy = lerp(-.45, PZ(96), oCub(prog(u, .05, .85))) - ioCub(prog(u, 1.5, 2.6)) * .9
        sun.location = (PX(248) * k, 13, sy * k); ES(msun).default_value = 4
        my = lerp(-.45, PZ(58), oCub(prog(u, 2.15, 3.0))); moon.location = (PX(680) * k, 13, my * k)
        ES(mocc).default_value = 1; ES(mst).default_value = 6 * n
        CITY.default_value = 5 * clamp(n * 1.6)
        e = lambda j: oBack(prog(u, .15 + j * .15, .55 + j * .15), 1.8)
        flip_in(tit, e(0)); flip_in(h1, e(1)); flip_in(h2, e(2))
        cs = oBack(prog(u, .4, .8), 2)
        setT(clk, (PX(460), -.02, PZ(100)) if cs > 0 else HIDE, (0, 0, 0), cs if cs > 0 else 0)
        hr = 9 + 14 * ioCub(prog(u, .7, 3.5)); hh.rotation_euler = (0, hr / 12 * 2 * math.pi, 0); hm.rotation_euler = (0, hr * 2 * math.pi, 0)
        dp = oCub(prog(u, .6, 1.0))
        for d in dots: setT(d, (d['x'], 0, PZ(100)) if d['i'] / 3 < dp else HIDE, None, 1 if d['i'] / 3 < dp else 0)
        m = len(ln)
        for r, o in enumerate(sorted(ln, key=lambda o: -o['fx'])):
            a = .75 + r * (.5 / max(1, m - 1)); q = prog(u, a, a + .25)
            setT(o, (o['fx'], 0, o['fz'] - (1 - oCub(q)) * .06) if q > 0 else HIDE, (R90, 0, 0), oBack(q, 2) if q > 0 else 0)
    save_frames(state)
