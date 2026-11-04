# Scene 1 — anamorphic "pop-out" LED billboard: the screen is a glowing box, 3D letters fly out of it.
# usage: python s1_popout.py -- OUTDIR RESX RESY SAMPLES [frames: all | 10,40,70]
import bpy, bmesh, math, sys, os, random
from mathutils import Vector
A = sys.argv[sys.argv.index('--') + 1:]
OUT, RX, RY, SPP = A[0], int(A[1]), int(A[2]), int(A[3])
FR = A[4] if len(A) > 4 else 'all'
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, '..', '..', 'fonts', 'Anton.ttf')
FPS, N = 30, 153                      # local time u = f/30 - 0.25  (covers -0.25 .. 4.83 s)
U = lambda f: f / FPS - 0.25
clamp = lambda x, a=0, b=1: max(a, min(b, x))
prog = lambda t, a, b: clamp((t - a) / (b - a))
oCub = lambda x: 1 - (1 - x) ** 3
ioCub = lambda x: 4 * x ** 3 if x < .5 else 1 - (-2 * x + 2) ** 3 / 2
def oBack(x, s=1.6): return 1 + (s + 1) * (x - 1) ** 3 + s * (x - 1) ** 2
lerp = lambda a, b, x: a + (b - a) * x

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SPP; sc.cycles.use_denoising = True
sc.cycles.use_adaptive_sampling = True; sc.cycles.max_bounces = 6
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = RX, RY, 100
sc.render.fps = FPS; sc.frame_start, sc.frame_end = 0, N - 1
sc.render.use_motion_blur = True; sc.render.motion_blur_shutter = 0.45
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'
try:
    sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'AgX - Punchy'
except Exception:
    try: sc.view_settings.look = 'Punchy'
    except Exception: pass

W = bpy.data.worlds.new('w'); sc.world = W; W.use_nodes = True
W.node_tree.nodes['Background'].inputs[0].default_value = (0.01, 0.02, 0.06, 1); W.node_tree.nodes['Background'].inputs[1].default_value = 1

def mat(name, col, rough=.3, metal=0., emit=None, es=0., coat=0.):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    if coat: b.inputs['Coat Weight'].default_value = coat
    if emit: b.inputs['Emission Color'].default_value = (*emit, 1); b.inputs['Emission Strength'].default_value = es
    return m
def grid_mat(name, col, lines, es, scale):
    m = mat(name, col, .35); nt = m.node_tree; b = nt.nodes['Principled BSDF']
    br = nt.nodes.new('ShaderNodeTexBrick'); br.offset = 0; br.inputs['Scale'].default_value = scale
    br.inputs['Mortar Size'].default_value = .012; br.inputs['Brick Width'].default_value = .5; br.inputs['Row Height'].default_value = .25
    tc = nt.nodes.new('ShaderNodeTexCoord'); nt.links.new(tc.outputs['Object'], br.inputs['Vector'])
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = es
    nt.links.new(br.outputs['Fac'], mul.inputs[0]); nt.links.new(mul.outputs[0], b.inputs['Emission Strength'])
    b.inputs['Emission Color'].default_value = (*lines, 1); return m, mul

def plane(name, size, loc, rot, m):
    bpy.ops.mesh.primitive_plane_add(size=1, location=loc, rotation=rot); o = bpy.context.object; o.name = name
    o.scale = (size[0], size[1], 1); o.data.materials.append(m); return o

# ---------------- camera (static: the real screen is the frame) ----------------
D = 5.2
bpy.ops.object.camera_add(location=(0, -D, 0), rotation=(math.radians(90), 0, 0)); cam = bpy.context.object; sc.camera = cam
cam.data.lens = 35; cam.data.sensor_width = 36; cam.data.sensor_fit = 'HORIZONTAL'
HW = D * 18 / 35; HH = HW * RY / RX           # half extents of the view at the frame plane y=0

# ---------------- box behind the screen + ledge coming out of it ----------------
OX, ZB, ZT, DEP = 2.3, -0.74, 0.74, 3.6       # opening half-width, floor, ceiling, depth
mwall, wall_mul = grid_mat('wall', (.006, .012, .035), (.15, .45, 1.), 1.5, 2.4)
mfloor = mat('floor', (.01, .02, .05), .08, .3, coat=1)
plane('back', (2 * OX, ZT - ZB), (0, DEP, (ZT + ZB) / 2), (math.radians(90), 0, 0), mwall)
plane('ceil', (2 * OX, DEP), (0, DEP / 2, ZT), (0, 0, 0), mwall)
plane('left', (DEP, ZT - ZB), (-OX, DEP / 2, (ZT + ZB) / 2), (math.radians(90), 0, math.radians(90)), mwall)
plane('right', (DEP, ZT - ZB), (OX, DEP / 2, (ZT + ZB) / 2), (math.radians(90), 0, math.radians(90)), mwall)
plane('floor', (2 * OX, DEP + 2.2), (0, DEP / 2 - 1.1, ZB), (0, 0, 0), mfloor)   # extends 2.2 units OUT of the screen
# frame (bezel) at y=0 with a hole
mframe = mat('frame', (.008, .014, .035), .45, .25, coat=.3)
bm = bmesh.new(); BIG = 6
pts = [(-BIG, -BIG), (BIG, -BIG), (BIG, BIG), (-BIG, BIG)]; hole = [(-OX, ZB), (OX, ZB), (OX, ZT), (-OX, ZT)]
vo = [bm.verts.new((x, 0, z)) for x, z in pts]; vi = [bm.verts.new((x, 0, z)) for x, z in hole]
for i in range(4): bm.faces.new((vo[i], vo[(i + 1) % 4], vi[(i + 1) % 4], vi[i]))
me = bpy.data.meshes.new('frame'); bm.to_mesh(me); fr = bpy.data.objects.new('frame', me); sc.collection.objects.link(fr)
fr.data.materials.append(mframe); sol = fr.modifiers.new('s', 'SOLIDIFY'); sol.thickness = .12; sol.offset = 1
bv = fr.modifiers.new('b', 'BEVEL'); bv.width = .03; bv.segments = 3
# neon tubes: around the opening + along the box edges (depth lines)
mneon = mat('neon', (0, 0, 0), .5, emit=(.2, .6, 1.), es=0)
mneon_g = mat('neonGold', (0, 0, 0), .5, emit=(1., .62, .15), es=0)
def tube(a, b, m, r=.018):
    a, b = Vector(a), Vector(b); d = b - a
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d.length, vertices=12, location=(a + b) / 2)
    o = bpy.context.object; o.rotation_mode = 'QUATERNION'; o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d)
    o.data.materials.append(m); return o
yy = -.13
for a, b in [((-OX, yy, ZB), (OX, yy, ZB)), ((OX, yy, ZB), (OX, yy, ZT)), ((OX, yy, ZT), (-OX, yy, ZT)), ((-OX, yy, ZT), (-OX, yy, ZB))]: tube(a, b, mneon_g, .022)
for x in (-OX + .02, OX - .02):
    for z in (ZB + .02, ZT - .02): tube((x, 0, z), (x, DEP, z), mneon)
for a, b in [((-OX, DEP - .02, ZB + .02), (OX, DEP - .02, ZB + .02)), ((-OX, DEP - .02, ZT - .02), (OX, DEP - .02, ZT - .02))]: tube(a, b, mneon)

# neon Kurdish sign floating mid-box above the letters
img = bpy.data.images.load(os.path.join(HERE, 'neon_ku.png')); asp = img.size[0] / img.size[1]
mku = bpy.data.materials.new('ku'); mku.use_nodes = True; nt = mku.node_tree; nt.nodes.clear()
ti = nt.nodes.new('ShaderNodeTexImage'); ti.image = img; em = nt.nodes.new('ShaderNodeEmission'); em.inputs['Color'].default_value = (1., .55, .08, 1)
mx = nt.nodes.new('ShaderNodeMixShader'); tr = nt.nodes.new('ShaderNodeBsdfTransparent'); out = nt.nodes.new('ShaderNodeOutputMaterial')
ku_mul = nt.nodes.new('ShaderNodeMath'); ku_mul.operation = 'MULTIPLY'; ku_mul.inputs[1].default_value = 0
nt.links.new(ti.outputs['Alpha'], mx.inputs[0]); nt.links.new(tr.outputs[0], mx.inputs[1]); nt.links.new(em.outputs[0], mx.inputs[2])
nt.links.new(ku_mul.outputs[0], em.inputs['Strength']); nt.links.new(ti.outputs['Alpha'], ku_mul.inputs[0]); nt.links.new(mx.outputs[0], out.inputs[0])
KH = .5; plane('ku', (KH * asp, KH), (XOFF if 'XOFF' in dir() else .12, 1.9, .47), (math.radians(90), 0, 0), mku)
# ---------------- 3D letters: white lacquer face + gold extrusion ----------------
mface = mat('face', (.95, .97, 1.), .28, 0, emit=(.92, .95, 1.), es=1.0, coat=.25)
mside = mat('gold', (1., .66, .22), .2, 1.)
TEXT, TW, XOFF = 'WASTA GHAREB', 4.05, .12
fnt = bpy.data.fonts.load(FONT)
def text_obj(body):
    cu = bpy.data.curves.new('t', 'FONT'); cu.body = body; cu.font = fnt; cu.size = 1; cu.align_x = 'LEFT'
    o = bpy.data.objects.new('t', cu); sc.collection.objects.link(o); return o
tmp = text_obj(TEXT); bpy.context.view_layer.update(); fullw = tmp.dimensions.x; caph = tmp.dimensions.y
bpy.data.objects.remove(tmp)
SIZE = TW / fullw; TOTW = TW
letters = []; prev = 0.
for i, ch in enumerate(TEXT):
    t = text_obj(TEXT[:i + 1]); g1 = text_obj(ch); bpy.context.view_layer.update(); w = t.dimensions.x * SIZE; gw = g1.dimensions.x * SIZE
    bpy.data.objects.remove(t); bpy.data.objects.remove(g1)
    if ch != ' ':
        cu = bpy.data.curves.new('L' + ch, 'FONT'); cu.body = ch; cu.font = fnt; cu.size = SIZE; cu.align_x = 'CENTER'; cu.align_y = 'BOTTOM_BASELINE'
        cu.extrude = .17; cu.bevel_depth = .012; cu.bevel_resolution = 3
        o = bpy.data.objects.new('L' + ch, cu); sc.collection.objects.link(o)
        bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.convert(target='MESH'); o.select_set(False)
        o.data.materials.append(mface); o.data.materials.append(mside)
        for p in o.data.polygons: p.material_index = 0 if p.normal.z > .9 else 1   # local +Z = front after standing up
        for p in o.data.polygons: p.use_smooth = p.material_index == 1
        letters.append((o, XOFF - TOTW / 2 + w - gw / 2))
    prev = w
# ---------------- stars + sparks ----------------
def star_mesh():
    bm = bmesh.new(); pts = []
    for i in range(10):
        a = math.pi / 2 + i * math.pi / 5; r = .27 if i % 2 == 0 else .12; pts.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, 0)))
    f = bm.faces.new(pts); ext = bmesh.ops.extrude_face_region(bm, geom=[f]); 
    for v in [e for e in ext['geom'] if isinstance(e, bmesh.types.BMVert)]: v.co.z += .05
    me = bpy.data.meshes.new('star'); bm.to_mesh(me); return me
mstar = mat('starGold', (1., .7, .2), .18, 1., emit=(1., .6, .15), es=.6)
smesh = star_mesh(); stars = []
for i in range(5):
    o = bpy.data.objects.new('star%d' % i, smesh); sc.collection.objects.link(o); o.data.materials.append(mstar) if not o.data.materials else None; stars.append(o)
mspark = mat('spark', (0, 0, 0), .5, emit=(1., .75, .3), es=25)
R = random.Random(4); sparks = []
for i in range(46):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=.012 + R.random() * .012, subdivisions=1); o = bpy.context.object; o.data.materials.append(mspark)
    a = R.uniform(-2.6, 2.6); sparks.append((o, Vector((math.sin(a) * R.uniform(.6, 2.6), -R.uniform(1.5, 5.), R.uniform(.4, 2.4))), R.uniform(0, .12)))
# ---------------- lights ----------------
def area(name, loc, rot, size, e, col, shape='RECTANGLE', sy=None):
    bpy.ops.object.light_add(type='AREA', location=loc, rotation=rot); l = bpy.context.object; l.name = name
    l.data.shape = shape; l.data.size = size; l.data.size_y = sy or size; l.data.energy = e; l.data.color = col; return l
key = area('key', (0.6, -3.2, 2.6), (math.radians(52), 0, math.radians(8)), 3.5, 650, (1., .95, .9))
rim = area('rim', (0, 1.6, .4), (math.radians(-90), 0, 0), 3.8, 180, (.25, .5, 1.), sy=.6)
sweep = area('sweep', (-4, -2.2, .2), (math.radians(90), 0, 0), .25, 0, (1, 1, 1), sy=3.)
fill = area('fill', (0, -3, -1.2), (math.radians(115), 0, 0), 4, 60, (.4, .6, 1.))

# ---------------- animation (keyframe every frame) ----------------
FX = .55
def key_all(f):
    u = U(f); sc.frame_set(f)
    on = prog(u, -.05, .35); flick = 1 if on >= 1 else (on * (0.35 + 0.65 * (math.sin(u * 90) > -.2)))
    for m, e in ((mneon, 9.), (mneon_g, 7.)):
        n = m.node_tree.nodes['Principled BSDF'].inputs['Emission Strength']; n.default_value = e * flick; n.keyframe_insert('default_value', frame=f)
    wall_mul.inputs[1].default_value = 1.5 * flick * (1 + .35 * math.sin(u * 2.4)); wall_mul.inputs[1].keyframe_insert('default_value', frame=f)
    kq = prog(u, .25, .9); kf = 1 if kq >= 1 else kq * (math.sin(u * 140) > 0)
    ku_mul.inputs[1].default_value = 5 * kf; ku_mul.inputs[1].keyframe_insert('default_value', frame=f)
    rim.data.energy = 180 * flick; rim.data.keyframe_insert('energy', frame=f)
    for i, (o, x) in enumerate(letters):
        s0 = .3 + i * .055; q = prog(u, s0, s0 + .8)
        if q <= 0: o.scale = (0, 0, 0); o.location = (x * .25, DEP - .3, 0); o.rotation_euler = (math.radians(90), 0, 0)
        else:
            e = oBack(q, 1.9); ez = oCub(q)
            y = lerp(DEP - .3, -FX, e); z = lerp(.0, ZB, ez) + math.sin(q * math.pi) * .55
            hp = prog(u, 2.75 + i * .07, 3.3 + i * .07); hop = math.sin(math.pi * hp)
            y -= hop * .6; z += hop * .3
            bob = math.sin(u * 2.2 + i * .7) * .015 * prog(u, 1.6, 2.)
            o.location = (lerp(x * .25, x, ez), y, z + bob)
            spin = ((1 - ez) * math.pi + ioCub(hp) * math.pi * 2) * (1 if i % 2 else -1)
            o.rotation_euler = (math.radians(90) + (1 - ez) * math.radians(-70), 0, spin)
            sc_ = min(1, q * 6); o.scale = (sc_, sc_, sc_)
        o.keyframe_insert('location', frame=f); o.keyframe_insert('rotation_euler', frame=f); o.keyframe_insert('scale', frame=f)
    for i, o in enumerate(stars):
        q = prog(u, 1.75 + i * .06, 2.75 + i * .06); a = (i - 2) * .55
        if q <= 0 or q >= 1: o.scale = (0, 0, 0); o.location = (0, 1.5, 0)
        else:
            e = q ** 1.6; o.location = (math.sin(a) * lerp(.1, 2.4, e), lerp(1.2, -D + .4, e), lerp(-.1, .55 + abs(i - 2) * -.25, e) + math.sin(q * math.pi) * .35)
            s = lerp(.6, 1.4, e); o.scale = (s, s, s); o.rotation_euler = (math.radians(90) + q * 2, q * 5 * (1 if i % 2 else -1), 0)
        o.keyframe_insert('location', frame=f); o.keyframe_insert('scale', frame=f); o.keyframe_insert('rotation_euler', frame=f)
    for o, v, d in sparks:
        q = prog(u, 1.12 + d, 2.1 + d)
        if q <= 0 or q >= 1: o.scale = (0, 0, 0); o.location = (0, -FX, ZB + .1)
        else:
            k = 1 - (1 - q) ** 2; o.location = (v.x * k, -FX + v.y * k, ZB + .1 + v.z * k - 1.6 * q * q); s = 1 - q * .6; o.scale = (s, s, s)
        o.keyframe_insert('location', frame=f); o.keyframe_insert('scale', frame=f)
    p = prog(u, 2.2, 3.1); sweep.location = (lerp(-4.2, 4.2, ioCub(p)), -2.2, .2); sweep.data.energy = 900 * math.sin(math.pi * p)
    sweep.keyframe_insert('location', frame=f); sweep.data.keyframe_insert('energy', frame=f)
for f in range(N): key_all(f)
for a in bpy.data.actions:
    for fc in getattr(a, 'fcurves', []):
        for k in fc.keyframe_points: k.interpolation = 'LINEAR'

os.makedirs(OUT, exist_ok=True)
frames = range(N) if FR == 'all' else [int(x) for x in FR.split(',')]
import time
for f in frames:
    t0 = time.time(); sc.frame_set(f); sc.render.filepath = os.path.join(OUT, 's1_%04d.png' % f); bpy.ops.render.render(write_still=True)
    print('frame', f, round(time.time() - t0, 1), 's', flush=True)
