# WASTA GHAREB — "BREAKOUT" anamorphic LED ad (Blender/Cycles), full 720x200 frame, 20 s seamless loop @ 60 fps.
# A glossy black bezel is drawn flush with the real LED edges, so viewers read it as the screen's own frame.
# Everything arrives from deep space, grows, crosses the frame plane and breaks OUT over the bezel (casting
# reflections on it), then flies past the viewer.  Left: portrait screen, head breaking out of the top bezel.
#   S1 0-5      WASTA GHAREB letters from deep space, Kurdish gold name pops out over the bottom bezel, stars fly at you
#   S2 5-10.5   ANKER: turntable half out of the screen, power banks over the bezel, gold sign لەم نزیکانە / COMING SOON
#   S3 10.5-15.5 adapters & cables on the turntable, green sign بەردەستە / IN STOCK
#   S4 15.5-20  opening hours: giant 3D clock breaks out top+bottom, 9 AM - 11 PM, sky day->night far away
# STORYBOARD stills: python stills.py -- OUTDIR RESX RESY SPP FRAMEID(1-5)
import bpy, bmesh, math, sys, os, random, time
from mathutils import Vector
import uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen
A = sys.argv[sys.argv.index('--') + 1:]
OUT, RX, RY, SPP = A[0], int(A[1]), int(A[2]), int(A[3]); FID = int(A[4])
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
# portrait screen: rotating light rays + the portrait (breaks out of the top bezel)
bpy.ops.mesh.primitive_plane_add(size=1, location=APP(102, 100, 1.3), rotation=(R90, 0, 0)); pbk = bpy.context.object; pbk.scale = (1.3, 1.5, 1)
pbk.data.materials.append(mat('pback', (0, 0, 0), 1, emit=(.012, .03, .085), es=1))
POR, _, PW = sprite('logo', 196 * S_ * KS(-.12)); POR.location = APP(102, 199, -.12)
# =============================== lights ===============================
def area(n, loc, tgt, size, e, col, sy=None):
    bpy.ops.object.light_add(type='AREA', location=loc); l = bpy.context.object; l.name = n; aim(l, tgt)
    l.data.shape = 'RECTANGLE'; l.data.size = size; l.data.size_y = sy or size; l.data.energy = e; l.data.color = col; return l
key = area('key', (1.2, -4.0, 2.4), (.5, 0, 0), 3.2, 380, (1, .97, .93))
fill = area('fill', (-2.5, -3.5, -1.0), (.5, 0, 0), 3, 90, (.6, .75, 1.))
rimA = area('rimA', (PX(458), 2.5, 1.6), (PX(458), -.5, 0), 3, 650, (1, 1, 1)); K(rimA.data, 'color')
sweep = area('sweep', (-4, -2.0, .2), (0, 0, .2), .2, 0, (1, 1, 1), sy=3); K(sweep, 'location'); K(sweep.data, 'energy')


# =============================== storyboard frames (clean, one hero per frame) ===============================
FZ = PZ(186)
bpy.ops.mesh.primitive_plane_add(size=1, location=(PX(458), 20.05, FZ)); fl = bpy.context.object; fl.scale = (60, 40, 1)
fl.data.materials.append(mat('floor', (.006, .01, .026), .14, .3, coat=.6))
accn.outputs[0].default_value = (.04, .1, .32, 1); rimA.data.color = (.55, .7, 1.); SKYMIX.default_value = 0; SKYN.default_value = 0
m_white = mat('white', (.94, .95, .98), .18, 0, emit=(1, 1, 1), es=.05, coat=1)
m_gold = mat('gold', (1., .71, .29), .16, 1.)
m_goldface = mat('goldface', (1., .78, .4), .2, 1., emit=(1., .6, .2), es=.15)
m_navy = mat('navy', (.015, .04, .14), .3, .2, coat=.6)
def T3(name, text, path, cpx, cpy, y, wpx, hpx, ext, bev, mf, ms):
    c = APP(cpx, cpy, y); objs, w, h = text3d(name, text, path, wpx * S_ * KS(y), hpx * S_ * KS(y), c.x, c.z, ext, bev, mf, ms, y=y); return objs, w, h
def put(n, cpx, bottom_py, y, hpx, tilt=0., floor=False):
    o, es, w = sprite(n, hpx * S_ * KS(y)); p = APP(cpx, bottom_py, y)
    if floor: p.z = FZ + .002
    o.location = p; o.rotation_euler = (0, math.radians(tilt), 0); es.default_value = 1; return o
def make_pill(name, cpx, cpy, y, wpx, hpx, col, txt, font, tcol, offx_px=0, check=False):
    k = KS(y); w, h = wpx * S_ * k, hpx * S_ * k; g = empty(name); g.location = APP(cpx, cpy, y)
    bm = bmesh.new(); r = h / 2; pts = []
    for i in range(25): a = -math.pi / 2 + math.pi * i / 24; pts.append((w / 2 - r + math.cos(a) * r, math.sin(a) * r))
    for i in range(25): a = math.pi / 2 + math.pi * i / 24; pts.append((-w / 2 + r + math.cos(a) * r, math.sin(a) * r))
    th = .09; f = bm.faces.new([bm.verts.new((x, -th / 2, z)) for x, z in pts]); ex = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [q for q in ex['geom'] if isinstance(q, bmesh.types.BMVert)]: v.co.y += th
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces); me = bpy.data.meshes.new(name); bm.to_mesh(me); o = bpy.data.objects.new(name + 'b', me); sc.collection.objects.link(o)
    me.materials.append(col); o.parent = g; bv = o.modifiers.new('b', 'BEVEL'); bv.width = .018; bv.segments = 5; bv.limit_method = 'ANGLE'
    for p in me.polygons: p.use_smooth = True
    ox = offx_px * S_ * k
    tf, _, _ = text3d(name + 'F', txt, font, w * .74 - abs(ox), h * .58, ox, 0, .01, .003, tcol, tcol, y=0)
    for q in tf: q.parent = g; q.location = (q.location.x, -.05, q.location.z)
    if check:
        bpy.ops.mesh.primitive_cylinder_add(radius=h * .36, depth=.05, vertices=64, rotation=(R90, 0, 0)); c = bpy.context.object
        c.data.materials.append(mat('cw', (1, 1, 1), .25, 0, emit=(1, 1, 1), es=.4, coat=1)); c.parent = g; c.location = (-w / 2 + h * .5, -.06, 0)
        cu = bpy.data.curves.new('ck', 'CURVE'); cu.dimensions = '3D'; sp = cu.splines.new('POLY'); sp.points.add(2); u_ = h * .02
        for p, (x, z) in zip(sp.points, ((-8, -1), (-3, -7), (9, 8))): p.co = (-w / 2 + h * .5 + x * u_, -.09, z * u_, 1)
        cu.bevel_depth = 2.3 * u_; cu.bevel_resolution = 4; cu.use_fill_caps = True; ck = bpy.data.objects.new('ck', cu); sc.collection.objects.link(ck)
        ck.data.materials.append(mat('ckg', (.02, .55, .26), .3)); ck.parent = g
    return g

if FID == 1:   # brand
    T3('L', 'WASTA GHAREB', ANTON, 458, 70, -.35, 440, 66, .1, .012, m_white, m_gold)
    T3('K', 'وەستا غەریب', KUFI, 458, 148, .1, 250, 44, .06, .008, m_goldface, m_gold)
elif FID == 2:  # one hero power bank breaks out of the frame
    accn.outputs[0].default_value = (.02, .16, .3, 1); rimA.data.color = (.4, .85, 1.)
    put('pb_anker165', 330, 222, -1.05, 240, tilt=-9)
    m_cs = mat('cyanside', (.02, .42, .62), .2, 1.)
    T3('A', 'ANKER', ANTON, 568, 58, 0, 230, 60, .085, .01, m_white, m_cs)
    m_pb = mat('pbm', (.5, .9, 1.), .3, 0, emit=(.3, .85, 1.), es=4)
    T3('P', 'POWER BANK', ANTON, 568, 106, 0, 225, 25, .02, .004, m_pb, m_pb)
    make_pill('p', 568, 152, -.3, 182, 38, mat('pg', (1., .7, .18), .18, .85, emit=(1., .55, .1), es=.15, coat=1), 'COMING SOON', ANTON, m_navy)
elif FID == 3:  # coming soon line-up in depth
    accn.outputs[0].default_value = (.02, .16, .3, 1); rimA.data.color = (.4, .85, 1.)
    put('pb_maggo_stand', 262, 186, .7, 118, floor=True)
    put('pb_anker20k', 470, 186, .7, 124, tilt=6, floor=True)
    put('pb_qi2_blue', 366, 214, -.9, 205, tilt=-5)
    T3('S', 'لەم نزیکانە', KUFI, 612, 82, 0, 180, 42, .06, .008, m_goldface, m_gold)
    m_ws = mat('ws', (.95, .96, 1.), .25, 0, emit=(1, 1, 1), es=.6)
    T3('E', 'COMING SOON', ANTON, 612, 128, 0, 165, 26, .03, .005, m_ws, m_gold)
elif FID == 4:  # adapter breaks out, cable behind
    accn.outputs[0].default_value = (.25, .16, .03, 1); rimA.data.color = (1., .8, .45)
    put('cable_coil', 470, 186, .8, 112, floor=True)
    put('adapter', 335, 214, -1.05, 200, tilt=-7)
    m_sl = mat('slate', (.35, .4, .5), .2, 1.)
    T3('D', 'ADAPTER', ANTON, 614, 40, 0, 185, 36, .08, .01, m_white, m_sl)
    T3('C', '& CABLE', ANTON, 614, 84, 0, 185, 36, .08, .01, m_goldface, m_gold)
    make_pill('g', 614, 144, -.3, 178, 42, mat('pgr', (.02, .62, .3), .16, .1, emit=(.05, .9, .4), es=.2, coat=1), 'بەردەستە', KUFI,
              mat('wt', (1, 1, 1), .3, 0, emit=(1, 1, 1), es=1.2), offx_px=20, check=True)
else:           # opening hours: giant clock breaks out top + bottom
    SKYMIX.default_value = 1; SKYN.default_value = 1; rimA.data.color = (.7, .55, 1.)
    CK = empty('clock'); CR = 94 * S_ * KS(-1.0); CK.location = APP(298, 100, -1.0)
    m_face = mat('cface', (.96, .96, .98), .25, 0, emit=(1, 1, 1), es=.3, coat=1)
    bpy.ops.mesh.primitive_cylinder_add(radius=CR, depth=.12, vertices=128, rotation=(R90, 0, 0)); c = bpy.context.object; c.data.materials.append(m_face); c.parent = CK
    bpy.ops.mesh.primitive_torus_add(major_radius=CR * 1.02, minor_radius=CR * .085, major_segments=128, minor_segments=24, rotation=(R90, 0, 0)); c = bpy.context.object; c.data.materials.append(m_gold); c.parent = CK
    bpy.ops.mesh.primitive_cylinder_add(radius=CR * 1.08, depth=.1, vertices=128, rotation=(R90, 0, 0), location=(0, .07, 0)); c = bpy.context.object; c.data.materials.append(m_navy); c.parent = CK
    m_hand = mat('hand', (.02, .05, .15), .3, .3)
    def hand(L, w, m, yo, ang):
        e = empty('hand'); bpy.ops.mesh.primitive_cube_add(size=1); c = bpy.context.object; c.scale = (w, .015, L); c.location = (0, 0, L / 2 - CR * .1)
        c.data.materials.append(m); c.parent = e; e.parent = CK; e.location = (0, yo, 0); e.rotation_euler = (0, ang, 0)
    hand(CR * .52, CR * .07, m_hand, -.075, (10 + 10 / 60) / 12 * 2 * math.pi); hand(CR * .78, CR * .045, m_goldface, -.09, 10 / 60 * 2 * math.pi)
    for i in range(60):
        a = i * math.pi / 30; big = i % 5 == 0; bpy.ops.mesh.primitive_cube_add(size=1); tk = bpy.context.object
        tk.scale = (CR * (.035 if big else .012), .01, CR * (.12 if big else .05)); tk.location = (math.sin(a) * CR * .84, -.062, math.cos(a) * CR * .84); tk.rotation_euler = (0, a, 0)
        tk.data.materials.append(m_hand); tk.parent = CK
    m_gt = mat('goldt', (1., .72, .3), .18, 1., emit=(1., .6, .15), es=.3)
    T3('T', 'کاتی کردنەوە', KUFI, 554, 40, .2, 285, 32, .05, .007, m_gt, m_gold)
    T3('H', '9 AM - 11 PM', ANTON, 554, 97, 0, 295, 52, .085, .012, m_white, m_gold)
    T3('N', 'لە ٩ی بەیانی تا ١١ی شەو', KUFI, 554, 153, -.2, 295, 28, .045, .006, mat('wl', (.95, .96, 1.), .25, 0, emit=(1, 1, 1), es=.45, coat=.5), m_gold)
sc.frame_set(0); os.makedirs(OUT, exist_ok=True); sc.render.filepath = os.path.join(OUT, 'board_%d.png' % FID); bpy.ops.render.render(write_still=True); print('done', FID, flush=True)
