# WASTA GHAREB — "BREAKOUT" anamorphic LED ad (Blender/Cycles), full 720x200 frame, 20 s seamless loop @ 60 fps.
# A glossy black bezel is drawn flush with the real LED edges, so viewers read it as the screen's own frame.
# Everything arrives from deep space, grows, crosses the frame plane and breaks OUT over the bezel (casting
# reflections on it), then flies past the viewer.  Left: portrait screen, head breaking out of the top bezel.
#   S1 0-5      WASTA GHAREB letters from deep space, Kurdish gold name pops out over the bottom bezel, stars fly at you
#   S2 5-10.5   ANKER: turntable half out of the screen, power banks over the bezel, gold sign لەم نزیکانە / COMING SOON
#   S3 10.5-15.5 adapters & cables on the turntable, green sign بەردەستە / IN STOCK
#   S4 15.5-20  opening hours: giant 3D clock breaks out top+bottom, 9 AM - 11 PM, sky day->night far away
# usage: python breakout.py -- OUTDIR RESX RESY SPP [all | a-b | i,j]
import bpy, bmesh, math, sys, os, random, time
from mathutils import Vector
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen
A = sys.argv[sys.argv.index('--') + 1:]
OUT, RX, RY, SPP = A[0], int(A[1]), int(A[2]), int(A[3]); FR = A[4] if len(A) > 4 else 'all'
HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '..', '..', 'fonts'); ASSETS = os.path.join(HERE, '..', '..', 'ad', 'assets')
ANTON, KUFI = os.path.join(FONTS, 'Anton.ttf'), os.path.join(FONTS, 'NotoKufiArabic-Black.ttf')
FPS, DUR = 60, 20.0; NF = int(FPS * DUR)
clamp = lambda x, a=0., b=1.: max(a, min(b, x)); prog = lambda t, a, b: clamp((t - a) / (b - a)); lerp = lambda a, b, x: a + (b - a) * x
oCub = lambda x: 1 - (1 - x) ** 3; ioCub = lambda x: 4 * x ** 3 if x < .5 else 1 - (-2 * x + 2) ** 3 / 2
oQuint = lambda x: 1 - (1 - x) ** 5; ioSine = lambda x: -(math.cos(math.pi * x) - 1) / 2
def oBack(x, s=1.7): return 1 + (s + 1) * (x - 1) ** 3 + s * (x - 1) ** 2
bump = lambda t, a, b: math.sin(math.pi * prog(t, a, b)); frac = lambda x: x - math.floor(x)
R90 = math.radians(90)
D = 6.0; S_ = (2 * D * 18 / 50) / 720            # world units per px at the frame plane (y=0)
PX = lambda px: (px - 360) * S_; PZ = lambda py: (100 - py) * S_
def APP(px, py, y): k = (D + y) / D; return Vector((PX(px) * k, y, PZ(py) * k))   # world point that LOOKS like (px,py) at depth y
KS = lambda y: (D + y) / D                                                           # apparent-size -> world-size factor

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = SPP; sc.cycles.use_denoising = True
sc.cycles.use_adaptive_sampling = True; sc.cycles.max_bounces = 8; sc.cycles.transparent_max_bounces = 16
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = RX, RY, 100
sc.render.fps = FPS; sc.render.use_motion_blur = True; sc.render.motion_blur_shutter = .5
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'
sc.view_settings.view_transform = 'Standard'; sc.view_settings.look = 'None'
W = bpy.data.worlds.new('w'); sc.world = W; W.use_nodes = True; W.node_tree.nodes['Background'].inputs[0].default_value = (0, 0, 0, 1)
KEYS = []
def K(o, *ps):
    for p in ps: KEYS.append((o, p))
def mat(name, col, rough=.3, metal=0., emit=None, es=0., coat=0.):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    if coat: b.inputs['Coat Weight'].default_value = coat; b.inputs['Coat Roughness'].default_value = .04
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
HIDE = Vector((0, 80, -40))
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
def sprite(n, h):
    img = bpy.data.images.load(os.path.join(ASSETS, n + '.png')); m = bpy.data.materials.new(n); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    ti = nt.nodes.new('ShaderNodeTexImage'); ti.image = img; em = nt.nodes.new('ShaderNodeEmission'); trn = nt.nodes.new('ShaderNodeBsdfTransparent')
    mx = nt.nodes.new('ShaderNodeMixShader'); out = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(ti.outputs['Color'], em.inputs[0]); nt.links.new(ti.outputs['Alpha'], mx.inputs[0]); nt.links.new(trn.outputs[0], mx.inputs[1])
    nt.links.new(em.outputs[0], mx.inputs[2]); nt.links.new(mx.outputs[0], out.inputs[0])
    asp = img.size[0] / img.size[1]; w = h * asp
    bpy.ops.mesh.primitive_plane_add(size=1); o = bpy.context.object; o.name = n
    for v in o.data.vertices: v.co = Vector((v.co.x * w, 0, (v.co.y + .5) * h))
    o.data.materials.append(m); o.rotation_mode = 'XYZ'; K(o, 'location', 'scale', 'rotation_euler'); K(em.inputs[1], 'default_value')
    return o, em.inputs[1], w

# =============================== the fake screen frame ===============================
# px layout of the bezel (outer = the real LED edge)
BT, BB, BL, BR, DV0, DV1 = 12, 188, 10, 710, 194, 206
m_bezel = mat('bezel', (.006, .007, .009), .14, .0, coat=1)
m_lip = mat('lip', (.05, .055, .065), .25, .8)
def bar(px0, py0, px1, py1, name):
    x0, x1, z0, z1 = PX(px0), PX(px1), PZ(py1), PZ(py0); bpy.ops.mesh.primitive_cube_add(size=1, location=((x0 + x1) / 2, 0, (z0 + z1) / 2))
    o = bpy.context.object; o.name = name; o.scale = (x1 - x0, .16, z1 - z0); bpy.ops.object.transform_apply(scale=True)
    bv = o.modifiers.new('b', 'BEVEL'); bv.width = .012; bv.segments = 4; o.data.materials.append(m_bezel); return o
E = 40
bar(-E, -E, 720 + E, BT, 'top'); bar(-E, BB, 720 + E, 200 + E, 'bottom'); bar(-E, -E, BL, 200 + E, 'left'); bar(BR, -E, 720 + E, 200 + E, 'right'); bar(DV0, -E, DV1, 200 + E, 'div')
# thin metallic lip around both openings (catches light -> reads as a real frame)
def lip_rect(px0, py0, px1, py1):
    for a, b in (((px0, py0), (px1, py0)), ((px1, py0), (px1, py1)), ((px1, py1), (px0, py1)), ((px0, py1), (px0, py0))):
        p, q = Vector((PX(a[0]), -.081, PZ(a[1]))), Vector((PX(b[0]), -.081, PZ(b[1]))); d = q - p
        bpy.ops.mesh.primitive_cylinder_add(radius=.0035, depth=d.length, vertices=8, location=(p + q) / 2); c = bpy.context.object
        c.rotation_mode = 'QUATERNION'; c.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d); c.data.materials.append(m_lip)
lip_rect(BL, BT, DV0, BB); lip_rect(DV1, BT, BR, BB)
# invisible-from-camera wall that keeps the two "screens" separate (lies exactly on a camera ray)
m_void = mat('void', (0, 0, 0), 1.)
bm = bmesh.new(); xa = PX(200)
vs = [bm.verts.new((xa * KS(y), y, z * KS(y))) for y, z in ((.09, -1), (.09, 1), (70, 1), (70, -1))]; bm.faces.new(vs)
me = bpy.data.meshes.new('wall'); bm.to_mesh(me); wl = bpy.data.objects.new('wall', me); sc.collection.objects.link(wl); me.materials.append(m_void)

# =============================== camera + deep space ===============================
bpy.ops.object.camera_add(location=(0, -D, 0), rotation=(R90, 0, 0)); cam = bpy.context.object; sc.camera = cam
cam.data.lens = 50; cam.data.sensor_width = 36; cam.data.sensor_fit = 'HORIZONTAL'; cam.data.clip_start = .05
cam.data.dof.use_dof = True; cam.data.dof.focus_distance = D - .4; cam.data.dof.aperture_fstop = 4
ACC = [(.16, .45, 1.), (.06, .75, 1.), (1., .66, .1), (.55, .38, 1.)]; SB = [0, 5, 10.5, 15.5, 20]
# backdrop: radial accent glow  <-> day/night sky (S4)
bpy.ops.mesh.primitive_plane_add(size=1, location=(PX(458) * KS(60), 60, 0), rotation=(R90, 0, 0)); back = bpy.context.object; back.scale = (90, 40, 1)
mb = bpy.data.materials.new('back'); mb.use_nodes = True; nt = mb.node_tree; nt.nodes.clear()
tc = nt.nodes.new('ShaderNodeTexCoord'); gr = nt.nodes.new('ShaderNodeTexGradient'); gr.gradient_type = 'SPHERICAL'; mpn = nt.nodes.new('ShaderNodeMapping')
mpn.inputs['Scale'].default_value = (3.2, 7, 1); nt.links.new(tc.outputs['Generated'], mpn.inputs['Vector']); mpn.inputs['Location'].default_value = (-1.6, -3.5, 0)
nt.links.new(mpn.outputs[0], gr.inputs[0]); pw = nt.nodes.new('ShaderNodeMath'); pw.operation = 'POWER'; pw.inputs[1].default_value = 2.2; nt.links.new(gr.outputs['Fac'], pw.inputs[0])
accn = nt.nodes.new('ShaderNodeRGB'); K(accn.outputs[0], 'default_value')
glow = nt.nodes.new('ShaderNodeMix'); glow.data_type = 'RGBA'; glow.inputs[6].default_value = (.002, .004, .012, 1); nt.links.new(pw.outputs[0], glow.inputs[0]); nt.links.new(accn.outputs[0], glow.inputs[7])
sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc.outputs['Generated'], sep.inputs[0])
mr = nt.nodes.new('ShaderNodeMapRange'); mr.inputs['From Min'].default_value = .5; mr.inputs['From Max'].default_value = .62; nt.links.new(sep.outputs['Y'], mr.inputs[0])
def ramp(c0, c1, c2):
    r = nt.nodes.new('ShaderNodeValToRGB'); el = r.color_ramp.elements; el[0].color = (*c0, 1); el[1].color = (*c2, 1); el.new(.45).color = (*c1, 1); nt.links.new(mr.outputs[0], r.inputs[0]); return r
rd = ramp((.95, .45, .15), (.25, .35, .75), (.04, .14, .5)); rn = ramp((.25, .08, .32), (.06, .04, .18), (.006, .009, .035))
skyc = nt.nodes.new('ShaderNodeMix'); skyc.data_type = 'RGBA'; nt.links.new(rd.outputs[0], skyc.inputs[6]); nt.links.new(rn.outputs[0], skyc.inputs[7]); K(skyc.inputs[0], 'default_value')
fin = nt.nodes.new('ShaderNodeMix'); fin.data_type = 'RGBA'; nt.links.new(glow.outputs[2], fin.inputs[6]); nt.links.new(skyc.outputs[2], fin.inputs[7]); K(fin.inputs[0], 'default_value')
em = nt.nodes.new('ShaderNodeEmission'); em.inputs[1].default_value = 1; out = nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(fin.outputs[2], em.inputs[0]); nt.links.new(em.outputs[0], out.inputs[0]); back.data.materials.append(mb)
SKYN, SKYMIX = skyc.inputs[0], fin.inputs[0]
# warp streaks: thin light rods flying out of the depth (some cross the frame plane)
m_st = mat('streak', (0, 0, 0), .5, emit=(.75, .88, 1.), es=4); K(ES(m_st), 'default_value'); R = random.Random(3); streaks = []
for i in range(70):
    bpy.ops.mesh.primitive_cylinder_add(radius=R.uniform(.003, .006), depth=R.uniform(.25, .7), vertices=6, rotation=(R90, 0, 0)); o = bpy.context.object; o.data.materials.append(m_st)
    a = R.uniform(0, 6.283); r = R.uniform(.25, 1.0); streaks.append((o, math.cos(a) * r, math.sin(a) * r * .55, R.random())); K(o, 'location')
# travel = integral of speed (base + warp boosts at every scene change) -> periodic over 20 s
def speed(t): return 1 + sum(5 * math.exp(-((((t - c + 10) % 20) - 10) / .35) ** 2) for c in (0, 5, 10.5, 15.5))
TRAV = [0.]
for f in range(NF): TRAV.append(TRAV[-1] + speed(f / FPS) / FPS)
TT = TRAV[-1]
# portrait screen: rotating light rays + the portrait (breaks out of the top bezel)
m_ray = mat('ray', (0, 0, 0), .5, emit=(.2, .45, 1.), es=1.2); K(m_ray.node_tree.nodes['Principled BSDF'].inputs['Emission Color'], 'default_value')
rays = empty('rays', APP(102, 80, 1.0)); bm = bmesh.new()
for i in range(14):
    a0 = i * 2 * math.pi / 14; a1 = a0 + math.pi / 14 * .55
    v0 = bm.verts.new((0, 0, 0)); v1 = bm.verts.new((math.cos(a0) * .68, 0, math.sin(a0) * .68)); v2 = bm.verts.new((math.cos(a1) * .68, 0, math.sin(a1) * .68)); bm.faces.new((v0, v1, v2))
me = bpy.data.meshes.new('rays'); bm.to_mesh(me); ro = bpy.data.objects.new('raysm', me); sc.collection.objects.link(ro); ro.parent = rays; me.materials.append(m_ray); K(rays, 'rotation_euler')
bpy.ops.mesh.primitive_plane_add(size=1, location=APP(102, 100, 1.3), rotation=(R90, 0, 0)); pbk = bpy.context.object; pbk.scale = (1.3, 1.5, 1)
pbk.data.materials.append(mat('pback', (0, 0, 0), 1, emit=(.01, .03, .1), es=1))
POR, _, PW = sprite('logo', 196 * S_ * KS(-.12)); POR.location = APP(102, 199, -.12)
# =============================== lights ===============================
def area(n, loc, tgt, size, e, col, sy=None):
    bpy.ops.object.light_add(type='AREA', location=loc); l = bpy.context.object; l.name = n; aim(l, tgt)
    l.data.shape = 'RECTANGLE'; l.data.size = size; l.data.size_y = sy or size; l.data.energy = e; l.data.color = col; return l
key = area('key', (1.2, -4.0, 2.4), (.5, 0, 0), 3.2, 380, (1, .97, .93))
fill = area('fill', (-2.5, -3.5, -1.0), (.5, 0, 0), 3, 90, (.6, .75, 1.))
rimA = area('rimA', (PX(458), 2.5, 1.6), (PX(458), -.5, 0), 3, 650, (1, 1, 1)); K(rimA.data, 'color')
sweep = area('sweep', (-4, -2.0, .2), (0, 0, .2), .2, 0, (1, 1, 1), sy=3); K(sweep, 'location'); K(sweep.data, 'energy')

# =============================== materials ===============================
m_white = mat('white', (.93, .95, 1.), .2, 0, emit=(1, 1, 1), es=.06, coat=1)
m_blue = mat('blueMetal', (.08, .25, .9), .22, 1.)
m_gold = mat('gold', (1., .71, .29), .16, 1.)
m_goldface = mat('goldface', (1., .78, .4), .2, 1., emit=(1., .6, .2), es=.18)
m_navy = mat('navy', (.015, .04, .14), .3, .2, coat=.6)
FAR = 34.
def fly_in(final, q, spread=.12):
    far = APP(458, 100, FAR) + (final - APP(458, 100, final.y)) * spread
    return far.lerp(final, q)
def fly_out(p, q):
    tgt = Vector((p.x * 2.6 + (.7 if p.x >= PX(458) else -.7), -D + .7, p.z * 2.4 + .2)); return p.lerp(tgt, q * q)
def group_anim(objs, t, t0, stag, dur, tx, ease=oQuint, spin=.5, order=None):
    seq = order or objs
    for n, o in enumerate(seq):
        fin = Vector((o['fx'], o['fy'], o['fz'])); q = prog(t, t0 + n * stag, t0 + n * stag + dur); qx = prog(t, tx + n * .02, tx + .5 + n * .02)
        if q <= 0 or qx >= 1: setT(o, HIDE, None, 0); continue
        e = ease(q); p = fly_in(fin, e); sg = 1 if n % 2 else -1
        if qx > 0: p = fly_out(p, qx)
        setT(o, p, (R90 + (1 - e) * .45, 0, (1 - e) * spin * sg + qx * .8 * sg), 1)
def T3(name, text, path, cpx, cpy, y, wpx, hpx, ext, bev, mf, ms):
    c = APP(cpx, cpy, y); objs, w, h = text3d(name, text, path, wpx * S_ * KS(y), hpx * S_ * KS(y), c.x, c.z, ext, bev, mf, ms, y=y)
    for o in objs: o['fy'] = y; K(o, 'location', 'rotation_euler', 'scale')
    return objs, w, h

# ---------------- S1 ----------------
L1, _, _ = T3('L', 'WASTA GHAREB', ANTON, 458, 64, .45, 440, 64, .09, .012, m_white, m_blue)
KU1, KW1, _ = T3('K', 'وەستا غەریب', KUFI, 458, 151, -.9, 300, 56, .07, .009, m_goldface, m_gold)
stars = []
for i in range(5):
    bm = bmesh.new(); vs = []; r = .085
    for k in range(10): a = math.pi / 2 + k * math.pi / 5; rr = r if k % 2 == 0 else r * .45; vs.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, 0)))
    f = bm.faces.new(vs); ex = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [g for g in ex['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.z += .03
    me = bpy.data.meshes.new('st'); bm.to_mesh(me); o = bpy.data.objects.new('st%d' % i, me); sc.collection.objects.link(o); me.materials.append(m_gold)
    o.rotation_mode = 'XYZ'; stars.append(o); K(o, 'location', 'rotation_euler', 'scale')
def S1(t):
    tt = t if t < 10 else t - 20
    group_anim(L1, tt, .15, .06, 1.1, 4.55)
    for n, o in enumerate(L1):   # hop wave toward the viewer
        if o.scale[0] > 0 and tt < 4.55:
            h = bump(tt, 2.8 + n * .07, 3.35 + n * .07); o.location = o.location + Vector((0, -.9 * h, .12 * h))
    q = prog(tt, .9, 2.1); qx = prog(tt, 4.6, 5.15)
    for o in KU1:
        fin = Vector((o['fx'], o['fy'], o['fz']))
        if q <= 0 or qx >= 1: setT(o, HIDE, None, 0); continue
        e = oBack(q, 1.25); p = fly_in(fin, e, .3)
        if qx > 0: p = fly_out(p, qx)
        setT(o, p, (R90 + (1 - min(e, 1)) * .3, 0, 0), 1)
    for i, o in enumerate(stars):
        q = prog(tt, 3.0 + i * .08, 4.1 + i * .08)
        if q <= 0 or q >= 1: setT(o, HIDE, None, 0); continue
        a = (i - 2) * .62; st = APP(458, 120, .6); e = q ** 1.7
        p = Vector((st.x + math.sin(a) * lerp(.05, 2.8, e), lerp(st.y, -D + .6, e), st.z + lerp(0, .45 - abs(i - 2) * .3, e) + math.sin(q * math.pi) * .3))
        setT(o, p, (R90 + q * 2, q * 4 * (1 if i % 2 else -1), 0), lerp(.5, 1.3, e))

# ---------------- carousel scenes ----------------
def podium(name):
    g = empty(name); m_pod = mat(name + 'm', (.02, .035, .08), .12, .4, coat=1); m_rim = mat(name + 'r', (0, 0, 0), .5, emit=(1, 1, 1), es=9)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.25, depth=.08, vertices=128); d = bpy.context.object; d.data.materials.append(m_pod); d.parent = g; d.location = (0, 0, -.04)
    bv = d.modifiers.new('b', 'BEVEL'); bv.width = .02; bv.segments = 3
    bpy.ops.mesh.primitive_torus_add(major_radius=1.26, minor_radius=.013, major_segments=160, minor_segments=8); r = bpy.context.object; r.data.materials.append(m_rim); r.parent = g; r.location = (0, 0, -.008)
    K(g, 'location', 'scale'); K(m_rim.node_tree.nodes['Principled BSDF'].inputs['Emission Color'], 'default_value'); return g, m_rim
def make_pill(name, wpx, hpx, y, col, tf_txt, tf_font, tb_txt, tb_font, tcol_m, offx_px=0):
    k = KS(y); w, h = wpx * S_ * k, hpx * S_ * k; g = empty(name)
    bm = bmesh.new(); r = h / 2; pts = []
    for i in range(25): a = -math.pi / 2 + math.pi * i / 24; pts.append((w / 2 - r + math.cos(a) * r, math.sin(a) * r))
    for i in range(25): a = math.pi / 2 + math.pi * i / 24; pts.append((-w / 2 + r + math.cos(a) * r, math.sin(a) * r))
    th = .1; f = bm.faces.new([bm.verts.new((x, -th / 2, z)) for x, z in pts]); ex = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [q for q in ex['geom'] if isinstance(q, bmesh.types.BMVert)]: v.co.y += th
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); me = bpy.data.meshes.new(name); bm.to_mesh(me); o = bpy.data.objects.new(name + 'b', me); sc.collection.objects.link(o)
    me.materials.append(col); o.parent = g; bv = o.modifiers.new('b', 'BEVEL'); bv.width = .02; bv.segments = 5; bv.limit_method = 'ANGLE'
    for p in me.polygons: p.use_smooth = True
    ox = offx_px * S_ * k
    tf, _, _ = text3d(name + 'F', tf_txt, tf_font, w * .76 - abs(ox), h * .6, ox, 0, .012, .003, tcol_m, tcol_m, y=0)
    tb, _, _ = text3d(name + 'B', tb_txt, tb_font, w * .76 - abs(ox), h * .54, ox, 0, .012, .003, tcol_m, tcol_m, y=0)
    for q in tf: q.parent = g; q.location = (q.location.x, -.056, q.location.z)
    for q in tb: q.parent = g; q.location = (q.location.x, .056, -q.location.z); q.rotation_euler = (-R90, 0, 0)
    K(g, 'location', 'rotation_euler', 'scale'); return g, w, h
CY, RRAD = .3, .72
PZW = -.6
def carousel(t, t0, t1, g, mr, items, cxw, steps0, stepdt, sil_on):
    v = t - t0; n = len(items); q = prog(v, 0, 1.1); qx = prog(t, t1 - .4, t1 + .1)
    if q <= 0 or qx >= 1:
        setT(g, HIDE, None, 0)
        for o, es, w in items: setT(o, HIDE, None, 0)
        return []
    e = oQuint(q); base = Vector((cxw, CY, PZW))
    gp = fly_in(base, e, .2)
    if qx > 0: gp = fly_out(gp, qx)
    setT(g, gp, None, 1)
    st = sum(ioCub(prog(v, steps0 + k * stepdt, steps0 + .46 + k * stepdt)) for k in range(n)); b0 = -st * 2 * math.pi / n
    sil = 1 - ioCub(prog(v, 1.0, 1.7)) if sil_on else 0; pos = []
    for i, (o, es, w) in enumerate(items):
        th = b0 + i * 2 * math.pi / n; d = (math.cos(th) + 1) / 2
        off = Vector((math.sin(th) * RRAD, -math.cos(th) * RRAD, .002 + (.02 + .02 * math.sin(2 * math.pi * v / 2.75 + i))))
        setT(o, gp + off, (0, 0, 0), .55 + .45 * d)
        es.default_value = max(.03, 1 - max(sil, (1 - d) * .45)) + .3 * bump(v, 2.2 + i * .1, 2.9 + i * .1)
        pos.append((gp + off, d))
    return pos
def pill_anim(g, t, t0, flip_t, tx, fin):
    q = prog(t, t0, t0 + .7); qx = prog(t, tx, tx + .5)
    if q <= 0 or qx >= 1: setT(g, HIDE, None, 0); return
    e = oBack(q, 1.3); p = fly_in(fin, min(e, 1.08), .25)
    if qx > 0: p = fly_out(p, qx)
    fl = ioCub(prog(t, flip_t, flip_t + .4)) * math.pi
    setT(g, p, (fl + (1 - min(1, e)) * -1.0, 0, 0), 1 + .03 * math.sin(2 * math.pi * t / 1.25))

# S2
pod2, rim2 = podium('pod2'); CX2 = PX(356) * KS(CY)
H0 = 160 * S_ * KS(CY - RRAD)
it2 = [sprite(n, H0) for n in ['pb_anker165', 'pb_maggo_stand', 'pb_anker20k', 'pb_qi2_blue', 'pb_instacord']]
for o, es, w in it2:   # keep wide products inside the box width
    if w > H0 * .8: k = H0 * .8 / w; [v.co.__setitem__(slice(0, 3), (v.co.x * k, v.co.y, v.co.z * k)) for v in o.data.vertices]
m_cside = mat('cyanside', (.02, .42, .62), .2, 1.)
AN2, _, _ = T3('A', 'ANKER', ANTON, 612, 44, .2, 200, 58, .08, .01, m_white, m_cside)
m_pb = mat('pbm', (.5, .9, 1.), .3, 0, emit=(.3, .85, 1.), es=5)
PB2, _, _ = T3('P', 'POWER BANK', ANTON, 612, 97, .2, 205, 27, .02, .004, m_pb, m_pb)
m_pg = mat('pillgold', (1., .7, .18), .18, .85, emit=(1., .55, .1), es=.2, coat=1)
pill2, _, _ = make_pill('pill2', 205, 46, -.6, m_pg, 'لەم نزیکانە', KUFI, 'COMING SOON', ANTON, m_navy)
def S2(t):
    carousel(t, 5, 10.6, pod2, rim2, it2, CX2, 1.6, .72, True)
    group_anim(AN2, t, 5.4, .07, .9, 10.1); group_anim(PB2, t, 5.9, .03, .7, 10.12, spin=.2)
    pill_anim(pill2, t, 6.1, 8.0, 10.15, APP(605, 150, -.6))
# S3
pod3, rim3 = podium('pod3'); CX3 = PX(356) * KS(CY)
it3 = [sprite(n, H0) for n in ['adapter', 'cable_closeup', 'magsafe', 'cable_coil']]
for o, es, w in it3:
    if w > H0 * .85: k = H0 * .85 / w; [v.co.__setitem__(slice(0, 3), (v.co.x * k, v.co.y, v.co.z * k)) for v in o.data.vertices]
m_slate = mat('slate', (.35, .4, .5), .2, 1.)
AD3, _, _ = T3('D', 'ADAPTER', ANTON, 618, 38, .2, 185, 38, .08, .01, m_white, m_slate)
CB3, _, _ = T3('C', '& CABLE', ANTON, 618, 82, .2, 185, 38, .08, .01, m_goldface, m_gold)
m_gp = mat('pillgreen', (.02, .62, .3), .16, .1, emit=(.05, .9, .4), es=.25, coat=1)
m_wt = mat('wtext', (1, 1, 1), .3, 0, emit=(1, 1, 1), es=1.2)
pill3, PW3, PH3 = make_pill('pill3', 185, 46, -.6, m_gp, 'بەردەستە', KUFI, 'IN STOCK', ANTON, m_wt, offx_px=26)
ck = empty('check'); bpy.ops.mesh.primitive_cylinder_add(radius=PH3 * .4, depth=.06, vertices=64, rotation=(R90, 0, 0)); c = bpy.context.object
c.data.materials.append(mat('cw', (1, 1, 1), .25, 0, emit=(1, 1, 1), es=.5, coat=1)); c.parent = ck; c.location = (-PW3 / 2 + PH3 * .5, -.07, 0)
cu = bpy.data.curves.new('ckc', 'CURVE'); cu.dimensions = '3D'; sp = cu.splines.new('POLY'); sp.points.add(2); u_ = PH3 * .022
for p, (x, z) in zip(sp.points, ((-8, -1), (-3, -7), (9, 8))): p.co = (-PW3 / 2 + PH3 * .5 + x * u_, -.105, z * u_, 1)
cu.bevel_depth = 2.4 * u_; cu.bevel_resolution = 4; cu.use_fill_caps = True; cko = bpy.data.objects.new('cko', cu); sc.collection.objects.link(cko)
cko.data.materials.append(mat('ckg', (.02, .6, .28), .3)); cko.parent = ck; ck.parent = pill3
m_sp = mat('spark', (0, 0, 0), .5, emit=(1., .8, .35), es=40); sparks = []; R = random.Random(9)
for i in range(30):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=R.uniform(.008, .018), subdivisions=1); o = bpy.context.object; o.data.materials.append(m_sp)
    a = R.uniform(0, 6.283); sparks.append((o, math.cos(a), math.sin(a), R.uniform(1.2, 3.6))); K(o, 'location', 'scale')
def S3(t):
    carousel(t, 10.5, 15.65, pod3, rim3, it3, CX3, 1.4, .85, False)
    group_anim(AD3, t, 10.9, .05, .9, 15.15); group_anim(CB3, t, 11.05, .05, .9, 15.18)
    pill_anim(pill3, t, 11.5, 13.4, 15.2, APP(620, 148, -.6))
    dd = t - 11.6; c = APP(356, 185, -.5)
    for o, cx_, cz_, v in sparks:
        if 0 < dd < .9: dist = v * (1 - math.exp(-3 * dd)) / 3; setT(o, (c.x + cx_ * dist, c.y - dist * .6, c.z + abs(cz_) * dist * .5 - dd * dd * .5), None, 1 - dd / .9)
        else: setT(o, HIDE, None, 0)

# S4 — clock + type, sky time-lapse far away
CK = empty('clock'); CR = 92 * S_ * KS(-1.0)
m_face = mat('cface', (.96, .96, .98), .25, 0, emit=(1, 1, 1), es=.3, coat=1)
bpy.ops.mesh.primitive_cylinder_add(radius=CR, depth=.12, vertices=128, rotation=(R90, 0, 0)); c = bpy.context.object; c.data.materials.append(m_face); c.parent = CK
bpy.ops.mesh.primitive_torus_add(major_radius=CR * 1.02, minor_radius=CR * .085, major_segments=128, minor_segments=24, rotation=(R90, 0, 0)); c = bpy.context.object; c.data.materials.append(m_gold); c.parent = CK
bpy.ops.mesh.primitive_cylinder_add(radius=CR * 1.08, depth=.1, vertices=128, rotation=(R90, 0, 0), location=(0, .07, 0)); c = bpy.context.object; c.data.materials.append(m_navy); c.parent = CK
m_hand = mat('hand', (.02, .05, .15), .3, .3)
def hand(L, w, m, yo):
    e = empty('hand'); bpy.ops.mesh.primitive_cube_add(size=1); c = bpy.context.object; c.scale = (w, .015, L); c.location = (0, 0, L / 2 - CR * .1)
    bv = c.modifiers.new('b', 'BEVEL'); bv.width = w * .3; bv.segments = 2; c.data.materials.append(m); c.parent = e; e.parent = CK; e.location = (0, yo, 0); return e
HH = hand(CR * .52, CR * .07, m_hand, -.075); HM = hand(CR * .78, CR * .045, m_goldface, -.09)
for i in range(60):
    a = i * math.pi / 30; big = i % 5 == 0; bpy.ops.mesh.primitive_cube_add(size=1); tk = bpy.context.object
    tk.scale = (CR * (.035 if big else .012), .01, CR * (.12 if big else .05)); tk.location = (math.sin(a) * CR * .84, -.062, math.cos(a) * CR * .84); tk.rotation_euler = (0, a, 0)
    tk.data.materials.append(m_hand); tk.parent = CK
bpy.ops.mesh.primitive_uv_sphere_add(radius=CR * .06, segments=16, ring_count=8, location=(0, -.1, 0)); c = bpy.context.object; c.data.materials.append(m_gold); c.parent = CK
K(CK, 'location', 'rotation_euler', 'scale'); K(HH, 'rotation_euler'); K(HM, 'rotation_euler')
m_gt = mat('goldt', (1., .72, .3), .18, 1., emit=(1., .6, .15), es=.35)
TI4, _, _ = T3('T', 'کاتی کردنەوە', KUFI, 550, 38, .3, 300, 34, .05, .007, m_gt, m_gold)
HR4, _, _ = T3('H', '9 AM - 11 PM', ANTON, 550, 97, 0., 315, 56, .085, .012, m_white, m_blue)
m_wl = mat('wline', (.95, .96, 1.), .25, 0, emit=(1, 1, 1), es=.45, coat=.5)
LN4, _, _ = T3('N', 'لە ٩ی بەیانی تا ١١ی شەو', KUFI, 550, 156, -.5, 320, 30, .045, .006, m_wl, m_blue)
msun = mat('sun', (0, 0, 0), .5, emit=(1., .55, .18), es=5); bpy.ops.mesh.primitive_uv_sphere_add(radius=1.6, segments=48, ring_count=24); SUN = bpy.context.object; SUN.data.materials.append(msun)
mmoon = mat('moon', (.85, .88, 1.), .6, emit=(.85, .9, 1.), es=3); bpy.ops.mesh.primitive_uv_sphere_add(radius=1.3, segments=48, ring_count=24); MOON = bpy.context.object; MOON.data.materials.append(mmoon)
mocc = mat('occ', (0, 0, 0), 1., emit=(.006, .009, .035), es=1); bpy.ops.mesh.primitive_uv_sphere_add(radius=1.2, segments=32, ring_count=16); oc = bpy.context.object; oc.data.materials.append(mocc); oc.parent = MOON; oc.location = (.6, -.9, .4)
K(SUN, 'location'); K(MOON, 'location')
def S4(t):
    h = t - 15.5
    q = prog(h, .1, 1.4); qx = prog(t, 19.45, 19.95)
    if q <= 0 or qx >= 1: setT(CK, HIDE, None, 0)
    else:
        fin = APP(298, 100, -1.0); e = oBack(q, 1.2); p = fly_in(fin, e, .2)
        if qx > 0: p = fly_out(p, qx)
        setT(CK, p, (math.sin(t * 1.3) * .08, 0, (1 - min(1, e)) * 2.5 + math.sin(t * .9) * .12), 1)
    hr = 9 + 14 * ioCub(prog(h, 1.2, 3.8)); HH.rotation_euler = (0, hr / 12 * 2 * math.pi, 0); HM.rotation_euler = (0, hr * 2 * math.pi, 0)
    group_anim(TI4, t, 16.0, .03, .9, 19.42, spin=.2)
    group_anim(HR4, t, 16.25, .04, .9, 19.45)
    group_anim(LN4, t, 16.5, .02, .9, 19.48, spin=.15, order=sorted(LN4, key=lambda o: -o['fx']))
    k = KS(50)
    sy = lerp(-.9, .25, oCub(prog(h, .2, 1.2))) - ioCub(prog(h, 2.0, 3.0)) * 1.3
    SUN.location = (PX(398) * k, 50, sy * k) if 0 < h < 4.5 else HIDE
    my = lerp(-.9, PZ(32), oCub(prog(h, 2.4, 3.3))); MOON.location = (PX(690) * k, 50, my * k) if 0 < h < 4.5 else HIDE

# =============================== master ===============================
def scene_mix(t):
    for i in range(4):
        if SB[i] <= t < SB[i + 1]:
            if t - SB[i] < .3 : p = .5 + (t - SB[i]) / .6; return mix3(ACC[i - 1], ACC[i], p)
            if SB[i + 1] - t < .3: p = .5 - (SB[i + 1] - t) / .6; return mix3(ACC[i], ACC[(i + 1) % 4], p)
            return ACC[i]
    return ACC[0]
mix3 = lambda a, b, p: tuple(lerp(a[j], b[j], clamp(p)) for j in range(3))
GL = [(2.3, 3.0), (6.8, 7.6), (12.4, 13.1)]
def STATE(f):
    t = f / FPS; acc = scene_mix(t)
    accn.outputs[0].default_value = (*[c * .32 for c in acc], 1); rimA.data.color = acc
    m_ray.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (*acc, 1)
    sk = prog(t, 15.5, 16.0) * (1 - prog(t, 19.55, 20.0)); SKYMIX.default_value = sk; SKYN.default_value = ioCub(prog(t, 17.2, 18.6))
    ES(m_st).default_value = 4 * (1 - .85 * sk)
    for o, ox, oz, ph in streaks:
        y = 52 - frac(ph + TRAV[f] / TT * 6) * 56; o.location = (PX(458) + ox * 2.0, y, oz * 2.0)
    rays.rotation_euler = (0, 2 * math.pi * t / 20, 0); s = 1 + .012 * math.sin(2 * math.pi * t / 4); POR.scale = (s, s, s)
    p = 0
    for a, b in GL:
        q = prog(t, a, b)
        if 0 < q < 1: p = q
    sweep.location = (lerp(-4.5, 4.5, ioSine(p)), -2.0, .2); sweep.data.energy = 1200 * math.sin(math.pi * p)
    for m in (rim2, rim3): m.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (*acc, 1)
    S1(t); S2(t); S3(t); S4(t)

t0 = time.time()
for f in range(NF):
    STATE(f)
    for o, p in KEYS: o.keyframe_insert(p, frame=f)
for a in bpy.data.actions:
    for fc in getattr(a, 'fcurves', []):
        for k in fc.keyframe_points: k.interpolation = 'LINEAR'
print('keyed', NF, 'frames in', round(time.time() - t0, 1), 's', flush=True)
os.makedirs(OUT, exist_ok=True); sc.frame_start, sc.frame_end = 0, NF - 1
if FR == 'all': frames = range(NF)
elif '-' in FR: a, b = map(int, FR.split('-')); frames = range(a, b + 1)
else: frames = [int(x) for x in FR.split(',')]
for f in frames:
    pth = os.path.join(OUT, 'b_%04d.png' % f)
    if os.path.exists(pth): continue
    t1 = time.time(); sc.frame_set(f); sc.render.filepath = pth; bpy.ops.render.render(write_still=True)
    print('frame', f, round(time.time() - t1, 1), 's', flush=True)
