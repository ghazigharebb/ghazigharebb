# WASTA GHAREB — full 20 s anamorphic "pop-out" LED ad, one continuous Blender scene, seamless loop.
# The screen is a glowing box; a stage/ledge comes OUT of it; everything pops out through the frame toward the viewer.
#   S1 0.0-4.5   3D letters WASTA GHAREB fly out of the box, gold stars fly at the viewer, neon "وەستا غەریب"
#   S2 4.5-10    ANKER power banks on a turntable half outside the screen, ANKER drops in, flipping sign لەم نزیکانە / COMING SOON
#   S3 10-15.5   adapter / cables / MagSafe on the turntable, energy rings, flipping sign بەردەستە / IN STOCK
#   S4 15.5-20   opening hours: 3D sky day->night, sun sets, moon rises, city lights, 3D clock 9->11, pop-up "9 AM" "11 PM"
#   every scene exits by flying THROUGH the screen past the camera.
# usage: python full3d.py -- OUTDIR RESX RESY SAMPLES [all | f1,f2,... | a-b]
import bpy, bmesh, math, sys, os, random, time
from mathutils import Vector
A = sys.argv[sys.argv.index('--') + 1:]
OUT, RX, RY, SPP = A[0], int(A[1]), int(A[2]), int(A[3])
FR = A[4] if len(A) > 4 else 'all'
HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '..', '..', 'fonts'); TEX = os.path.join(HERE, 'tex'); ASSETS = os.path.join(HERE, '..', '..', 'ad', 'assets')
FPS, N = 30, 600
clamp = lambda x, a=0., b=1.: max(a, min(b, x))
prog = lambda t, a, b: clamp((t - a) / (b - a))
oCub = lambda x: 1 - (1 - x) ** 3
ioCub = lambda x: 4 * x ** 3 if x < .5 else 1 - (-2 * x + 2) ** 3 / 2
def oBack(x, s=1.6): return 1 + (s + 1) * (x - 1) ** 3 + s * (x - 1) ** 2
lerp = lambda a, b, x: a + (b - a) * x
bump = lambda t, a, b: math.sin(math.pi * prog(t, a, b))
R90 = math.radians(90)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SPP; sc.cycles.use_denoising = True
sc.cycles.use_adaptive_sampling = True; sc.cycles.max_bounces = 6; sc.cycles.transparent_max_bounces = 40
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = RX, RY, 100
sc.render.fps = FPS; sc.frame_start, sc.frame_end = 0, N - 1
sc.render.use_motion_blur = True; sc.render.motion_blur_shutter = 0.45
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'
try: sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'AgX - Punchy'
except Exception: pass
W = bpy.data.worlds.new('w'); sc.world = W; W.use_nodes = True
W.node_tree.nodes['Background'].inputs[0].default_value = (0.01, 0.02, 0.06, 1)

KEYS = []  # (datablock, path) pairs to key every frame
def K(obj, *paths):
    for p in paths: KEYS.append((obj, p))
def mat(name, col, rough=.3, metal=0., emit=None, es=0., coat=0.):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    if coat: b.inputs['Coat Weight'].default_value = coat
    if emit: b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = es
    return m
def es_in(m): return m.node_tree.nodes['Principled BSDF'].inputs['Emission Strength']
def plane(name, w, h, loc, rot, m, parent=None):
    bpy.ops.mesh.primitive_plane_add(size=1, location=loc, rotation=rot); o = bpy.context.object; o.name = name
    o.scale = (w, h, 1); o.data.materials.append(m)
    if parent: o.parent = parent
    return o
def empty(name, loc=(0, 0, 0)):
    o = bpy.data.objects.new(name, None); sc.collection.objects.link(o); o.location = loc; o.rotation_mode = 'XYZ'; return o

# ---------------- camera (static — the real screen edge is the frame) ----------------
D = 5.2
bpy.ops.object.camera_add(location=(0, -D, 0), rotation=(R90, 0, 0)); cam = bpy.context.object; sc.camera = cam
cam.data.lens = 35; cam.data.sensor_width = 36; cam.data.sensor_fit = 'HORIZONTAL'; cam.data.clip_start = .05

# ---------------- the box, the frame and the ledge ----------------
OX, ZB, ZT, DEP = 2.3, -0.74, 0.74, 3.6
def grid_mat(name, col, lines, es, scale):
    m = mat(name, col, .35); nt = m.node_tree; b = nt.nodes['Principled BSDF']
    br = nt.nodes.new('ShaderNodeTexBrick'); br.offset = 0; br.inputs['Scale'].default_value = scale
    br.inputs['Mortar Size'].default_value = .012; br.inputs['Brick Width'].default_value = .5; br.inputs['Row Height'].default_value = .25
    tc = nt.nodes.new('ShaderNodeTexCoord'); nt.links.new(tc.outputs['Object'], br.inputs['Vector'])
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = es
    nt.links.new(br.outputs['Fac'], mul.inputs[0]); nt.links.new(mul.outputs[0], b.inputs['Emission Strength'])
    b.inputs['Emission Color'].default_value = (*lines, 1); return m, mul
mwall, wall_mul = grid_mat('wall', (.006, .012, .035), (.15, .45, 1.), 1.5, 2.4); K(wall_mul.inputs[1], 'default_value')
mfloor = mat('floor', (.01, .02, .05), .08, .3, coat=1)
plane('back', 2 * OX, ZT - ZB, (0, DEP, (ZT + ZB) / 2), (R90, 0, 0), mwall)
plane('ceil', 2 * OX, DEP, (0, DEP / 2, ZT), (0, 0, 0), mwall)
plane('left', DEP, ZT - ZB, (-OX, DEP / 2, (ZT + ZB) / 2), (R90, 0, R90), mwall)
plane('right', DEP, ZT - ZB, (OX, DEP / 2, (ZT + ZB) / 2), (R90, 0, R90), mwall)
plane('floor', 2 * OX, DEP + 2.2, (0, DEP / 2 - 1.1, ZB), (0, 0, 0), mfloor)
mframe = mat('frame', (.008, .014, .035), .45, .25, coat=.3)
bm = bmesh.new(); BIG = 6
vo = [bm.verts.new((x, 0, z)) for x, z in [(-BIG, -BIG), (BIG, -BIG), (BIG, BIG), (-BIG, BIG)]]
vi = [bm.verts.new((x, 0, z)) for x, z in [(-OX, ZB), (OX, ZB), (OX, ZT), (-OX, ZT)]]
for i in range(4): bm.faces.new((vo[i], vo[(i + 1) % 4], vi[(i + 1) % 4], vi[i]))
me = bpy.data.meshes.new('frame'); bm.to_mesh(me); fr = bpy.data.objects.new('frame', me); sc.collection.objects.link(fr)
fr.data.materials.append(mframe); s_ = fr.modifiers.new('s', 'SOLIDIFY'); s_.thickness = .12; s_.offset = 1
b_ = fr.modifiers.new('b', 'BEVEL'); b_.width = .03; b_.segments = 3
mneon = mat('neon', (0, 0, 0), .5, emit=(.2, .6, 1.), es=9); mneon_g = mat('neonGold', (0, 0, 0), .5, emit=(1., .62, .15), es=7)
def tube(a, b, m, r=.018):
    a, b = Vector(a), Vector(b); d = b - a
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d.length, vertices=12, location=(a + b) / 2)
    o = bpy.context.object; o.rotation_mode = 'QUATERNION'; o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d); o.data.materials.append(m); return o
yy = -.13
for a, b in [((-OX, yy, ZB), (OX, yy, ZB)), ((OX, yy, ZB), (OX, yy, ZT)), ((OX, yy, ZT), (-OX, yy, ZT)), ((-OX, yy, ZT), (-OX, yy, ZB))]: tube(a, b, mneon_g, .022)
for x in (-OX + .02, OX - .02):
    for z in (ZB + .02, ZT - .02): tube((x, 0, z), (x, DEP, z), mneon)
for a, b in [((-OX, DEP - .02, ZB + .02), (OX, DEP - .02, ZB + .02)), ((-OX, DEP - .02, ZT - .02), (OX, DEP - .02, ZT - .02))]: tube(a, b, mneon)

# ---------------- builders ----------------
fntA = bpy.data.fonts.load(os.path.join(FONTS, 'Anton.ttf'))
def text3d(body, cap, mface, mside, ext=.08, align='CENTER'):
    cu = bpy.data.curves.new('t', 'FONT'); cu.body = body; cu.font = fntA; cu.size = 1; cu.align_x = align; cu.align_y = 'BOTTOM_BASELINE'
    o = bpy.data.objects.new('t_' + body, cu); sc.collection.objects.link(o); bpy.context.view_layer.update()
    h = o.dimensions.y; cu.size = cap / h; cu.extrude = ext; cu.bevel_depth = ext * .1; cu.bevel_resolution = 3
    bpy.context.view_layer.objects.active = o
    for x in sc.objects: x.select_set(False)
    o.select_set(True); bpy.ops.object.convert(target='MESH'); o.select_set(False)
    o.data.materials.append(mface); o.data.materials.append(mside)
    for p in o.data.polygons: p.material_index = 0 if p.normal.z > .9 else 1; p.use_smooth = p.material_index == 1
    o.rotation_mode = 'XYZ'; return o
def text_width(body, cap):
    cu = bpy.data.curves.new('m', 'FONT'); cu.body = body; cu.font = fntA; cu.size = 1
    o = bpy.data.objects.new('m', cu); sc.collection.objects.link(o); bpy.context.view_layer.update()
    w, h = o.dimensions.x, o.dimensions.y; bpy.data.objects.remove(o); return w, h
def img_mat(name, path, mode, col=(1, 1, 1), strength=1.):
    img = bpy.data.images.load(path); m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    ti = nt.nodes.new('ShaderNodeTexImage'); ti.image = img; b = nt.nodes['Principled BSDF']
    if mode == 'photo':
        nt.links.new(ti.outputs['Color'], b.inputs['Base Color']); nt.links.new(ti.outputs['Color'], b.inputs['Emission Color'])
        b.inputs['Emission Strength'].default_value = strength; b.inputs['Roughness'].default_value = .35
    elif mode == 'dark':
        b.inputs['Base Color'].default_value = (.03, .035, .05, 1); b.inputs['Roughness'].default_value = .5
    elif mode == 'neon':
        b.inputs['Base Color'].default_value = (0, 0, 0, 1); b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = strength
    elif mode == 'paint':
        b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = .4
        b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = strength
    nt.links.new(ti.outputs['Alpha'], b.inputs['Alpha']); return m, img
def text_plane(name, tex, h, mode, col, strength, parent=None, loc=(0, 0, 0), rot=(R90, 0, 0)):
    m, img = img_mat(name, os.path.join(TEX, tex + '.png'), mode, col, strength); asp = img.size[0] / img.size[1]
    return plane(name, h * asp, h, loc, rot, m, parent), m
def sprite(n, bh, bw):
    """photo cut-out with fake thickness: front photo + stacked dark silhouettes behind it"""
    path = os.path.join(ASSETS, n + '.png'); mp, img = img_mat(n, path, 'photo', strength=.15)
    md, _ = img_mat(n + '_d', path, 'dark'); asp = img.size[0] / img.size[1]
    h = min(bh, bw / asp); w = h * asp; e = empty('S_' + n)
    for k in range(7, 0, -1): plane(n + '_l%d' % k, w, h, (0, .006 * k, h / 2), (R90, 0, 0), md, e)
    plane(n + '_f', w, h, (0, 0, h / 2), (R90, 0, 0), mp, e)
    K(es_in(mp), 'default_value'); return e, mp
def sign(name, w, h, col, rough, metal, tex_front, tex_back, tcol, temit, th=.1):
    e = empty('SG_' + name); bm = bmesh.new(); r = h / 2; pts = []
    for k in range(25):  # pill outline in XZ, right cap then left cap
        a = -math.pi / 2 + math.pi * k / 24; pts.append((w / 2 - r + math.cos(a) * r, math.sin(a) * r))
    for k in range(25):
        a = math.pi / 2 + math.pi * k / 24; pts.append((-w / 2 + r + math.cos(a) * r, math.sin(a) * r))
    vs = [bm.verts.new((x, -th / 2, z)) for x, z in pts]; fc = bm.faces.new(vs)
    exr = bmesh.ops.extrude_face_region(bm, geom=[fc])
    for v in [g for g in exr['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.y += th
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); s = bpy.data.objects.new(name, me); sc.collection.objects.link(s); s.parent = e
    s.data.materials.append(mat(name, col, rough, metal, emit=col, es=.35, coat=1))
    bv = s.modifiers.new('b', 'BEVEL'); bv.width = .02; bv.segments = 4; bv.limit_method = 'ANGLE'
    for p_ in s.data.polygons: p_.use_smooth = True
    f, _ = text_plane(name + '_tf', tex_front, h * .62, 'paint', tcol, temit, e, (0, -th / 2 - .004, 0), (R90, 0, 0))
    b, _ = text_plane(name + '_tb', tex_back, h * .56, 'paint', tcol, temit, e, (0, th / 2 + .004, 0), (-R90, 0, 0))
    for o in (f, b):
        if o.scale[0] > w * .86: k = w * .86 / o.scale[0]; o.scale = (o.scale[0] * k, o.scale[1] * k, 1)
    return e

BASE = {}
def setT(o, loc, rot=None, s=1.):
    b = BASE.setdefault(o.name, tuple(o.scale))
    o.location = loc
    if rot is not None: o.rotation_euler = rot
    s = (s, s, s) if isinstance(s, (int, float)) else s
    o.scale = (b[0] * s[0], b[1] * s[1], b[2] * s[2])
HIDE = (0, 1.5, -3)
def fly_out(loc, q):  # exit path: straight at the viewer, passing beside the camera
    q2 = q * q; x, y, z = loc
    return (x * (1 + 1.6 * q2) + (.25 if x >= 0 else -.25) * q2, lerp(y, -D + .7, q2), z + .45 * q2)

# ======================= S1: WASTA GHAREB =======================
mface = mat('face', (.95, .97, 1.), .28, 0, emit=(.92, .95, 1.), es=1.0, coat=.25)
mgold = mat('gold', (1., .66, .22), .2, 1.)
TEXT, TW, XOFF, FX = 'WASTA GHAREB', 4.05, .12, .55
fw, _ = text_width(TEXT, 1); SIZE = TW / fw
_, ch1 = text_width('W', 1); letters = []
for i, ch in enumerate(TEXT):
    if ch == ' ': continue
    wp, _ = text_width(TEXT[:i + 1], 1); gw, _ = text_width(ch, 1)
    letters.append([text3d(ch, ch1 * SIZE, mface, mgold, .17), XOFF - TW / 2 + (wp - gw / 2) * SIZE])
for o, _ in letters: K(o, 'location', 'rotation_euler', 'scale')
img = bpy.data.images.load(os.path.join(TEX, 'ku_name.png'))
mku, _ = img_mat('ku', os.path.join(TEX, 'ku_name.png'), 'neon', (1., .55, .08), 0); asp = img.size[0] / img.size[1]
kuo = plane('ku', .5 * asp, .5, (XOFF, 1.9, .47), (R90, 0, 0), mku); K(es_in(mku), 'default_value'); K(kuo, 'location', 'scale'); KUS = tuple(kuo.scale)
def star_mesh():
    bm = bmesh.new(); pts = []
    for i in range(10):
        a = math.pi / 2 + i * math.pi / 5; r = .27 if i % 2 == 0 else .12; pts.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, 0)))
    f = bm.faces.new(pts); ex = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [e for e in ex['geom'] if isinstance(e, bmesh.types.BMVert)]: v.co.z += .05
    me = bpy.data.meshes.new('star'); bm.to_mesh(me); return me
mstar = mat('starGold', (1., .7, .2), .18, 1., emit=(1., .6, .15), es=.6); smesh = star_mesh(); smesh.materials.append(mstar)
stars = []
for i in range(5):
    o = bpy.data.objects.new('star%d' % i, smesh); sc.collection.objects.link(o); o.rotation_mode = 'XYZ'; stars.append(o); K(o, 'location', 'rotation_euler', 'scale')
def S1(t, f):
    kq = prog(t, .25, .9); kf = 1 if kq >= 1 else kq * (math.sin(t * 140) > 0)
    es_in(mku).default_value = 5 * kf * (1 - prog(t, 4.2, 4.5))
    vis = .25 < t < 4.5; kuo.location = (XOFF, 1.9, .47) if vis else HIDE; kuo.scale = KUS if vis else (0, 0, 0)
    for i, (o, x) in enumerate(letters):
        s0 = .3 + i * .055; q = prog(t, s0, s0 + .8); qx = prog(t, 4.3 + i * .03, 4.85 + i * .03)
        if q <= 0 or qx >= 1: setT(o, HIDE, (R90, 0, 0), 0); continue
        e = oBack(q, 1.9); ez = oCub(q)
        y = lerp(DEP - .3, -FX, e); z = lerp(0., ZB, ez) + math.sin(q * math.pi) * .55
        hp = prog(t, 2.75 + i * .07, 3.3 + i * .07); hop = math.sin(math.pi * hp); y -= hop * .6; z += hop * .3
        z += math.sin(t * 2.2 + i * .7) * .015 * prog(t, 1.6, 2.)
        sgn = 1 if i % 2 else -1; spin = ((1 - ez) * math.pi + ioCub(hp) * math.pi * 2) * sgn
        loc = (lerp(x * .25, x, ez), y, z)
        if qx > 0: loc = fly_out(loc, qx); spin += qx * 1.2 * sgn
        setT(o, loc, (R90 + (1 - ez) * math.radians(-70), 0, spin), min(1, q * 6))
    for i, o in enumerate(stars):
        q = prog(t, 1.75 + i * .06, 2.75 + i * .06); a = (i - 2) * .55
        if q <= 0 or q >= 1: setT(o, HIDE, None, 0); continue
        e = q ** 1.6
        setT(o, (math.sin(a) * lerp(.1, 2.4, e), lerp(1.2, -D + .4, e), lerp(-.1, .55 - abs(i - 2) * .25, e) + math.sin(q * math.pi) * .35),
             (R90 + q * 2, q * 5 * (1 if i % 2 else -1), 0), lerp(.6, 1.4, e))

# ======================= turntable (S2 + S3) =======================
TCX, TCY, TR = -.82, .12, .98
mdisc = mat('disc', (.02, .04, .1), .15, .5, coat=1)
bpy.ops.mesh.primitive_cylinder_add(radius=TR + .32, depth=.06, vertices=96, location=(0, 0, 0)); disc = bpy.context.object; disc.data.materials.append(mdisc)
mring = mat('ring', (0, 0, 0), .5, emit=(.2, .75, 1.), es=8)
bpy.ops.mesh.primitive_torus_add(major_radius=TR + .32, minor_radius=.018, major_segments=128, minor_segments=8); ring = bpy.context.object; ring.data.materials.append(mring)
ring.parent = disc; ring.location = (0, 0, .03)
K(disc, 'location', 'rotation_euler', 'scale'); K(es_in(mring), 'default_value'); K(mring.node_tree.nodes['Principled BSDF'].inputs['Emission Color'], 'default_value')
mpulse = mat('pulse', (0, 0, 0), .5, emit=(1., .75, .25), es=0)
bpy.ops.mesh.primitive_torus_add(major_radius=1, minor_radius=.012, major_segments=128, minor_segments=6); pulse = bpy.context.object; pulse.data.materials.append(mpulse)
K(pulse, 'location', 'scale'); K(es_in(mpulse), 'default_value')
def turntable(t, items, t0, t1, nsteps, step0, stepdt, ek=1.):
    """items: list of (empty, mat). scene window t0..t1 (exit starts at t1-.15)"""
    v = t - t0; n = len(items); qx_any = prog(t, t1 - .15, t1 + .35)
    st = sum(ioCub(prog(v, step0 + k * stepdt, step0 + .48 + k * stepdt)) for k in range(nsteps)); b0 = -st * 2 * math.pi / n
    for i, (o, m) in enumerate(items):
        q = prog(v, .15 + i * .09, .85 + i * .09); qx = prog(t, t1 - .15 + i * .04, t1 + .3 + i * .04)
        if q <= 0 or qx >= 1: setT(o, HIDE, (0, 0, 0), 0); es_in(m).default_value = 0; continue
        th = b0 + i * 2 * math.pi / n; d = (math.cos(th) + 1) / 2
        slot = (TCX + math.sin(th) * TR, TCY - math.cos(th) * TR, ZB + .03)
        e = oBack(q, 1.4); ez = oCub(q)
        loc = (lerp(TCX * .3, slot[0], ez), lerp(DEP - .4, slot[1], e), slot[2] + math.sin(q * math.pi) * .5)
        bob = .025 * math.sin(t * 2.3 + i * 1.7) * prog(v, 1, 1.3); loc = (loc[0], loc[1], loc[2] + bob + .03)
        yaw = -th * .22 + (1 - ez) * math.pi * (1 if i % 2 else -1)
        if qx > 0: loc = fly_out(loc, qx); yaw += qx * 2
        setT(o, loc, (0, 0, yaw), min(1, q * 5))
        es_in(m).default_value = ek * ((.25 + .55 * prog(v, .6, 1.3)) * (.55 + .45 * d) + .5 * bump(v, 2.2 + i * .1, 2.9 + i * .1))
    ap = oBack(prog(v, -.05, .45), 1.5); ex = prog(t, t1 + .05, t1 + .45)
    return ap * (1 - ex), v

# ======================= S2: ANKER coming soon =======================
PB = ['pb_anker165', 'pb_maggo_stand', 'pb_anker20k', 'pb_qi2_blue', 'pb_instacord']
s2items = [sprite(n, 1.05, .82) for n in PB]
for e, _ in s2items: K(e, 'location', 'rotation_euler', 'scale')
mfaceC = mat('faceC', (.95, .99, 1.), .25, 0, emit=(.9, .97, 1.), es=1.1, coat=.3); msideC = mat('sideC', (.1, .65, 1.), .2, 1.)
anker = []; aw, _ = text_width('ANKER', 1); ASZ = .5; ach = text_width('A', 1)[1]
for i, ch in enumerate('ANKER'):
    wp, _ = text_width('ANKER'[:i + 1], 1); gw, _ = text_width(ch, 1)
    o = text3d(ch, ASZ, mfaceC, msideC, .12); x = 1.45 - aw * ASZ / ach / 2 + (wp - gw / 2) * ASZ / ach
    anker.append((o, x)); K(o, 'location', 'rotation_euler', 'scale')
mpb = mat('pbneon', (0, 0, 0), .5, emit=(.25, .8, 1.), es=0)
pbt = text3d('POWER BANK', .19, mpb, mpb, .01); K(pbt, 'location', 'rotation_euler', 'scale'); K(es_in(mpb), 'default_value')
sign2 = sign('soon', 1.55, .4, (1., .62, .08), .25, .6, 'soon_ku', 'soon_en', (.02, .05, .16), .0); K(sign2, 'location', 'rotation_euler', 'scale')
def S2(t, f):
    ap, v = turntable(t, s2items, 4.5, 10.0, 5, 1.3, .84, 1.)
    for i, (o, x) in enumerate(anker):
        q = prog(v, .3 + i * .06, .75 + i * .06); qx = prog(t, 9.85 + i * .03, 10.35 + i * .03)
        if q <= 0 or qx >= 1: setT(o, HIDE, (R90, 0, 0), 0); continue
        loc = (x, -.35, lerp(1.6, .02, oBack(q, 2.2)))
        rot = (R90, 0, 0)
        if qx > 0: loc = fly_out(loc, qx)
        setT(o, loc, rot, 1)
    q = prog(v, .55, .95); qx = prog(t, 9.9, 10.4)
    if q <= 0 or qx >= 1: setT(pbt, HIDE, (R90, 0, 0), 0); es_in(mpb).default_value = 0
    else:
        loc = (1.45, -.25, -.25); setT(pbt, fly_out(loc, qx) if qx > 0 else loc, (R90, 0, 0), (q, 1, 1)); es_in(mpb).default_value = 10
    return ap, v
def flip_sign(sg, t, v, t1, x0):
    q = prog(v, .9, 1.3); qx = prog(t, t1 - .1, t1 + .4)
    if q <= 0 or qx >= 1: setT(sg, HIDE, (0, 0, 0), 0); return
    fl = ioCub(prog(v, 2.95, 3.45)) * math.pi
    loc = (x0, -.55, ZB + .2 + .02 + .015 * math.sin(t * 3));
    if qx > 0: loc = fly_out(loc, qx)
    setT(sg, loc, (fl + (1 - oBack(q, 2)) * -1.2, 0, 0), oBack(q, 2.2))

# ======================= S3: adapter & cables =======================
S3N = ['adapter', 'cable_closeup', 'magsafe', 'cable_coil']
s3items = [sprite(n, 1.1, .95) for n in S3N]
for e, _ in s3items: K(e, 'location', 'rotation_euler', 'scale')
msideS = mat('sideS', (.75, .8, .9), .15, 1.)
t_ad = text3d('ADAPTER', .3, mface, msideS, .09); t_cb = text3d('& CABLE', .3, mat('faceG', (1, .8, .35), .25, .6, emit=(1., .7, .2), es=.7, coat=.3), mgold, .09)
for o in (t_ad, t_cb): K(o, 'location', 'rotation_euler', 'scale')
sign3 = sign('stock', 1.45, .4, (.0, .42, .14), .25, .2, 'stock_ku', 'stock_en', (1, 1, 1), 3.); K(sign3, 'location', 'rotation_euler', 'scale')
def S3(t, f):
    ap, v = turntable(t, s3items, 10.0, 15.5, 4, 1.15, .95, .3)
    for k, (o, z, d0) in enumerate(((t_ad, .3, .35), (t_cb, -.12, .5))):
        q = prog(v, d0, d0 + .45); qx = prog(t, 15.4 + k * .05, 15.9 + k * .05)
        if q <= 0 or qx >= 1: setT(o, HIDE, (R90, 0, 0), 0); continue
        loc = (1.45, -.35, z); rot = (R90 * oBack(q, 1.8), 0, 0)   # stands up like a pop-up book
        if qx > 0: loc = fly_out(loc, qx)
        setT(o, loc, rot, 1)
    pu = [prog(v, 1.63 + k * .95, 2.3 + k * .95) for k in range(4)]; pq = max(pu)
    pk = max(range(4), key=lambda k: pu[k] if 0 < pu[k] < 1 else -1)
    pq = pu[pk] if 0 < pu[pk] < 1 else 0
    if pq > 0: setT(pulse, (TCX, TCY, ZB + .06), None, (TR + .3) * lerp(1, 1.7, oCub(pq))); es_in(mpulse).default_value = 14 * (1 - pq)
    else: setT(pulse, HIDE, None, 0); es_in(mpulse).default_value = 0
    return ap, v

# ======================= S4: opening hours =======================
msky = bpy.data.materials.new('sky'); msky.use_nodes = True; nt = msky.node_tree; nt.nodes.clear()
tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc.outputs['Generated'], sep.inputs[0])
def ramp(c0, c1, c2):
    r = nt.nodes.new('ShaderNodeValToRGB'); el = r.color_ramp.elements; el[0].color = (*c0, 1); el[1].color = (*c2, 1); el.new(.45).color = (*c1, 1)
    nt.links.new(sep.outputs['Y'], r.inputs[0]); return r
rd = ramp((1., .45, .12), (.35, .45, .85), (.05, .2, .65)); rn = ramp((.25, .08, .35), (.06, .05, .2), (.01, .015, .06))
mix = nt.nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'; nt.links.new(rd.outputs[0], mix.inputs[6]); nt.links.new(rn.outputs[0], mix.inputs[7])
em = nt.nodes.new('ShaderNodeEmission'); nt.links.new(mix.outputs[2], em.inputs[0]); out = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(em.outputs[0], out.inputs[0])
skyF, skyS = mix.inputs[0], em.inputs[1]; K(skyF, 'default_value'); K(skyS, 'default_value')
sky = plane('sky', 2 * OX - .04, ZT - ZB - .02, (0, DEP - .03, 0), (R90, 0, 0), msky); K(sky, 'location', 'scale')
msun = mat('sun', (0, 0, 0), .5, emit=(1., .6, .2), es=0); bpy.ops.mesh.primitive_uv_sphere_add(radius=.24, segments=32, ring_count=16); sun = bpy.context.object; sun.data.materials.append(msun)
mmoon = mat('moon', (0, 0, 0), .5, emit=(.85, .9, 1.), es=0); bpy.ops.mesh.primitive_uv_sphere_add(radius=.2, segments=32, ring_count=16); moon = bpy.context.object; moon.data.materials.append(mmoon)
mocc = mat('occ', (0, 0, 0), .9, emit=(.02, .03, .1), es=1); bpy.ops.mesh.primitive_uv_sphere_add(radius=.18, segments=32, ring_count=16); occ = bpy.context.object; occ.data.materials.append(mocc); occ.parent = moon; occ.location = (.1, -.12, .07)
for o in (sun, moon): K(o, 'location', 'scale')
K(es_in(msun), 'default_value'); K(es_in(mmoon), 'default_value')
mcity, city_mul = grid_mat('city', (.004, .006, .02), (1., .75, .35), 0, 2.6); K(city_mul.inputs[1], 'default_value')
nd = mcity.node_tree.nodes; lk = mcity.node_tree.links; br = [n for n in nd if n.type == 'TEX_BRICK'][0]
br.inputs['Mortar Size'].default_value = .09; br.inputs['Brick Width'].default_value = .35; br.inputs['Row Height'].default_value = .3
br.inputs['Color1'].default_value = (0, 0, 0, 1); br.inputs['Color2'].default_value = (1, 1, 1, 1); br.inputs['Bias'].default_value = .25
inv = nd.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1; lk.new(br.outputs['Fac'], inv.inputs[1])
bw = nd.new('ShaderNodeRGBToBW'); lk.new(br.outputs['Color'], bw.inputs[0]); m2 = nd.new('ShaderNodeMath'); m2.operation = 'MULTIPLY'
lk.new(inv.outputs[0], m2.inputs[0]); lk.new(bw.outputs[0], m2.inputs[1]); lk.new(m2.outputs[0], city_mul.inputs[0])
tcn = [n for n in nd if n.type == 'TEX_COORD'][0]; sp = nd.new('ShaderNodeSeparateXYZ'); cb = nd.new('ShaderNodeCombineXYZ')
lk.new(tcn.outputs['Object'], sp.inputs[0]); lk.new(sp.outputs['X'], cb.inputs['X']); lk.new(sp.outputs['Z'], cb.inputs['Y']); lk.new(sp.outputs['Y'], cb.inputs['Z'])
lk.new(cb.outputs[0], br.inputs['Vector'])
city = empty('city'); R = random.Random(9); x = -OX + .05
while x < OX - .1:
    w = R.uniform(.18, .38); h = R.uniform(.25, .7); bpy.ops.mesh.primitive_cube_add(size=1); b = bpy.context.object
    b.scale = (w, R.uniform(.2, .35), h); b.location = (x + w / 2, R.uniform(2.6, 3.2), ZB + h / 2); b.data.materials.append(mcity); b.parent = city; x += w + R.uniform(.0, .06)
K(city, 'location', 'scale')
mclock = mat('clockface', (.95, .95, 1.), .3, emit=(1, 1, 1), es=.6, coat=.5)
clk = empty('clock'); bpy.ops.mesh.primitive_cylinder_add(radius=.34, depth=.08, vertices=64); cf = bpy.context.object; cf.data.materials.append(mclock); cf.parent = clk; cf.rotation_euler = (R90, 0, 0)
bpy.ops.mesh.primitive_torus_add(major_radius=.35, minor_radius=.04, major_segments=64, minor_segments=12); tr_ = bpy.context.object; tr_.data.materials.append(mgold); tr_.parent = clk; tr_.rotation_euler = (R90, 0, 0)
mhand = mat('hand', (.02, .04, .12), .3); mhandG = mat('handG', (1., .55, .1), .3, emit=(1., .55, .1), es=2)
def hand(L, wdt, m):
    e = empty('h'); bpy.ops.mesh.primitive_cube_add(size=1); c = bpy.context.object; c.scale = (wdt, .02, L); c.location = (0, 0, L / 2 - .02); c.data.materials.append(m); c.parent = e; e.parent = clk; e.location = (0, -.07, 0); return e
hh, hm = hand(.19, .035, mhand), hand(.28, .022, mhandG)
for i in range(12):
    a = i * math.pi / 6; bpy.ops.mesh.primitive_cube_add(size=1); tk = bpy.context.object; tk.scale = (.02, .02, .05 if i % 3 else .08)
    tk.location = (math.sin(a) * .27, -.045, math.cos(a) * .27); tk.rotation_euler = (0, a, 0); tk.data.materials.append(mhand); tk.parent = clk
K(clk, 'location', 'rotation_euler', 'scale'); K(hh, 'rotation_euler'); K(hm, 'rotation_euler')
t9 = text3d('9 AM', .4, mface, mgold, .12); t11 = text3d('11 PM', .4, mface, mgold, .12)
for o in (t9, t11): K(o, 'location', 'rotation_euler', 'scale')
htit, mht = text_plane('htitle', 'hours_title', .3, 'neon', (1., .6, .12), 0, loc=HIDE); hl, mhl = text_plane('hline', 'hours_line', .22, 'neon', (1, 1, 1), 0, loc=HIDE)
for o in (htit, hl): K(o, 'location', 'scale')
K(es_in(mht), 'default_value'); K(es_in(mhl), 'default_value')
def S4(t, f):
    h = t - 15.5; on = prog(h, -.1, .4) * (1 - prog(t, 19.45, 19.85)); n = ioCub(prog(h, 1.7, 3.1))
    skyF.default_value = n; skyS.default_value = 2.2 * on * lerp(1., .8, n)
    setT(sky, (0, DEP - .03, 0) if on > 0 else HIDE, None, 1 if on > 0 else 0)
    sy = lerp(-1.2, .3, oCub(prog(h, .05, .85))) - ioCub(prog(h, 1.5, 2.6)) * 1.5
    setT(sun, (-1.55, DEP - .35, sy) if on > 0 else HIDE, None, 1 if on > 0 else 0); es_in(msun).default_value = 30 * on
    my = lerp(-1.2, .42, oCub(prog(h, 2.15, 3.0)))
    setT(moon, (1.85, DEP - .35, my) if on > 0 else HIDE, None, 1 if on > 0 else 0); es_in(mmoon).default_value = 6 * on
    setT(city, (0, 0, (1 - oCub(on)) * -1.2) if on > 0 else HIDE, None, 1 if on > 0 else 0); city_mul.inputs[1].default_value = 4 * clamp(n * 1.4) * on
    wall_mul.inputs[1].default_value = 1.5 * (1 - .8 * on)
    # 3D clock (pops out) and pop-up times
    q = prog(h, .4, .8); qx = prog(t, 19.5, 19.95)
    if q <= 0 or qx >= 1: setT(clk, HIDE, (0, 0, 0), 0)
    else:
        loc = (.12, -.62, ZB + .4 + .02 * math.sin(t * 2.5)); setT(clk, fly_out(loc, qx) if qx > 0 else loc, (0, 0, (1 - oBack(q, 2)) * 3), oBack(q, 2.2))
    hr = 9 + 14 * ioCub(prog(h, .7, 3.5)); hh.rotation_euler = (0, hr / 12 * 2 * math.pi, 0); hm.rotation_euler = (0, hr * 2 * math.pi, 0)
    for k, (o, x, d0) in enumerate(((t9, -1.32, .3), (t11, 1.58, .45))):
        q = prog(h, d0, d0 + .5); qx = prog(t, 19.5 + k * .05, 19.95 + k * .05)
        if q <= 0 or qx >= 1: setT(o, HIDE, (0, 0, 0), 0); continue
        loc = (x, -.45, ZB + .01); rot = (R90 * oBack(q, 1.7), 0, 0)
        if qx > 0: loc = fly_out(loc, qx)
        setT(o, loc, rot, 1)
    for o, m, z, d0, s in ((htit, mht, .5, .15, 7), (hl, mhl, .14, .75, 5)):
        q = prog(h, d0, d0 + .4); fo = 1 - prog(t, 19.4, 19.75)
        if q <= 0 or fo <= 0: setT(o, HIDE, None, 0); es_in(m).default_value = 0
        else: setT(o, (.12, 1.15, z), None, (lerp(.3, 1, oBack(q, 2)), lerp(.3, 1, oBack(q, 2)), 1)); es_in(m).default_value = s * clamp(q * 2) * fo

# ======================= sparks (burst at every scene start) =======================
mspark = mat('spark', (0, 0, 0), .5, emit=(1., .75, .3), es=25)
R = random.Random(4); sparks = []
for i in range(46):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=.012 + R.random() * .012, subdivisions=1); o = bpy.context.object; o.data.materials.append(mspark)
    a = R.uniform(-2.6, 2.6); sparks.append((o, Vector((math.sin(a) * R.uniform(.6, 2.6), -R.uniform(1.5, 5.), R.uniform(.4, 2.4))), R.uniform(0, .12))); K(o, 'location', 'scale')
BURSTS = [(1.12, (0, -FX, ZB + .1)), (5.35, (TCX, TCY - TR, ZB + .2)), (10.95, (TCX, TCY - TR, ZB + .2)), (16.2, (.12, -.62, ZB + .4))]
def SPARKS(t):
    for o, v, d in sparks:
        st = None
        for t0, org in BURSTS:
            q = prog(t, t0 + d, t0 + 1. + d)
            if 0 < q < 1: st = (q, org)
        if not st: setT(o, HIDE, None, 0); continue
        q, org = st; k = 1 - (1 - q) ** 2
        setT(o, (org[0] + v.x * k, org[1] + v.y * k, org[2] + v.z * k - 1.6 * q * q), None, 1 - q * .6)

# ======================= lights =======================
def area(name, loc, rot, size, e, col, sy=None):
    bpy.ops.object.light_add(type='AREA', location=loc, rotation=rot); l = bpy.context.object; l.name = name
    l.data.shape = 'RECTANGLE'; l.data.size = size; l.data.size_y = sy or size; l.data.energy = e; l.data.color = col; return l
key = area('key', (0.6, -3.2, 2.6), (math.radians(52), 0, math.radians(8)), 3.5, 650, (1., .95, .9))
rim = area('rim', (0, 1.6, .4), (math.radians(-90), 0, 0), 3.8, 180, (.25, .5, 1.), sy=.6)
sweep = area('sweep', (-4, -2.2, .2), (R90, 0, 0), .25, 0, (1, 1, 1), sy=3.)
fill = area('fill', (0, -3, -1.2), (math.radians(115), 0, 0), 4, 60, (.4, .6, 1.))
K(sweep, 'location'); K(sweep.data, 'energy'); K(rim.data, 'energy')
SWEEPS = [2.2, 7.0, 12.6, 18.3]
def LIGHTS(t):
    p = max((prog(t, s, s + .9) for s in SWEEPS), key=lambda x: x if 0 < x < 1 else -1); p = p if 0 < p < 1 else 0
    sweep.location = (lerp(-4.2, 4.2, ioCub(p)), -2.2, .2); sweep.data.energy = 900 * math.sin(math.pi * p)
    rim.data.energy = 180

ring_col = mring.node_tree.nodes['Principled BSDF'].inputs['Emission Color']
def frame_state(f):
    t = f / FPS
    S1(t, f); LIGHTS(t); SPARKS(t)
    ap2, _ = S2(t, f); flip_sign(sign2, t, t - 4.5, 10.0, 1.45)
    ap3, _ = S3(t, f); flip_sign(sign3, t, t - 10.0, 15.5, 1.45)
    S4(t, f)
    if t < 15.5: wall_mul.inputs[1].default_value = 1.5
    ap = max(ap2, ap3)
    if ap > 0.001:
        g = prog(t, 9.8, 10.2); setT(disc, (TCX, TCY, ZB + .03 - (1 - ap) * .4), (0, 0, t * .25), (ap, ap, 1))
        ring_col.default_value = (lerp(.2, 1., g), lerp(.75, .72, g), lerp(1., .25, g), 1) if t < 15.6 else (1, .72, .25, 1)
        es_in(mring).default_value = 8
    else: setT(disc, HIDE, None, 0); es_in(mring).default_value = 0

t0 = time.time()
for f in range(N):
    frame_state(f)
    for o, p in KEYS: o.keyframe_insert(p, frame=f)
print('keyed in', round(time.time() - t0, 1), 's', flush=True)
for a in bpy.data.actions:
    for fc in getattr(a, 'fcurves', []):
        for k in fc.keyframe_points: k.interpolation = 'LINEAR'
os.makedirs(OUT, exist_ok=True)
if FR == 'all': frames = range(N)
elif '-' in FR: a, b = map(int, FR.split('-')); frames = range(a, b + 1)
else: frames = [int(x) for x in FR.split(',')]
for f in frames:
    p = os.path.join(OUT, 'f_%04d.png' % f)
    if os.path.exists(p): continue
    t1 = time.time(); sc.frame_set(f); sc.render.filepath = p; bpy.ops.render.render(write_still=True)
    print('frame', f, round(time.time() - t1, 1), 's', flush=True)
