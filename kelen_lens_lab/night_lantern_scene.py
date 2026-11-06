"""Demo scene for Kelen Lens Lab: "Fanûs" — a Kurdish woman with a lantern standing in a
moonlit lake; a Hawrami village glows on the far mountain.  Night, cinematic warm/cold light.
Run headless:  python night_lantern_scene.py OUT.png [RES_PERCENT] [SAMPLES] [LENS]"""
import sys, os, math, random, importlib.util
import bpy, bmesh
from mathutils import Vector, Matrix, noise

ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]   # works with `blender -b -P` and bpy
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.abspath('fanus.png')
PCT = int(ARGS[1]) if len(ARGS) > 1 else 100
SPP = int(ARGS[2]) if len(ARGS) > 2 else 256
LENS = ARGS[3] if len(ARGS) > 3 else 'SWIRL'

bpy.ops.wm.read_factory_settings(use_empty=True)
spec = importlib.util.spec_from_file_location("kelen_lens_lab", os.path.join(os.path.dirname(os.path.abspath(__file__)), "kelen_lens_lab.py"))
kll = importlib.util.module_from_spec(spec); spec.loader.exec_module(kll); kll.register()
sc = bpy.context.scene; col = sc.collection
R = random.Random(3)

def hexc(h):
    h = h.lstrip('#'); c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c)
def mat(name, color, rough=0.6, **kw):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*color, 1); b.inputs['Roughness'].default_value = rough
    for k, v in kw.items():
        b.inputs[k].default_value = (*v, 1) if isinstance(v, tuple) and len(v) == 3 else v
    return m
def emit(name, color, strength):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    for n in list(nt.nodes):
        if n.type != 'OUTPUT_MATERIAL': nt.nodes.remove(n)
    e = nt.nodes.new('ShaderNodeEmission'); e.inputs['Color'].default_value = (*color, 1); e.inputs['Strength'].default_value = strength
    nt.links.new(e.outputs[0], nt.nodes['Material Output'].inputs['Surface']); return m
def obj(name, bm, m, smooth=True):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    if smooth: me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
    me.materials.append(m); o = bpy.data.objects.new(name, me); col.objects.link(o); return o

# ---------------------------------------------------------------- geometry helpers
def loft(rings, seg=48, cap_top=True, pleat=None):
    """rings: list of (z, rx, ry, cx, cy). pleat(theta, t) -> radial multiplier."""
    bm = bmesh.new(); vs = []
    for k, (z, rx, ry, cx, cy) in enumerate(rings):
        t = k / (len(rings) - 1); row = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            f = pleat(a, t) if pleat else 1.0
            row.append(bm.verts.new((cx + math.cos(a) * rx * f, cy + math.sin(a) * ry * f, z)))
        vs.append(row)
    for k in range(len(vs) - 1):
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new((vs[k][i], vs[k][j], vs[k + 1][j], vs[k + 1][i]))
    if cap_top: bm.faces.new(vs[-1])
    bm.normal_update(); return bm
def tube(pts, radii, seg=16, flare_last=None):
    bm = bmesh.new(); rows = []
    for k, (p, r) in enumerate(zip(pts, radii)):
        p = Vector(p)
        d = (Vector(pts[min(k + 1, len(pts) - 1)]) - Vector(pts[max(k - 1, 0)])).normalized()
        a = d.orthogonal().normalized(); b = d.cross(a)
        rows.append([bm.verts.new(p + (a * math.cos(2 * math.pi * i / seg) + b * math.sin(2 * math.pi * i / seg)) * r) for i in range(seg)])
    for k in range(len(rows) - 1):
        for i in range(seg):
            j = (i + 1) % seg; bm.faces.new((rows[k][i], rows[k][j], rows[k + 1][j], rows[k + 1][i]))
    bm.faces.new(rows[0][::-1]); bm.faces.new(rows[-1])
    bm.normal_update(); return bm
def ico(r, loc, sc_=(1, 1, 1), sub=3):
    bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=r)
    bmesh.ops.scale(bm, vec=sc_, verts=bm.verts); bmesh.ops.translate(bm, vec=loc, verts=bm.verts); return bm

# ---------------------------------------------------------------- materials
VELVET = mat('Dress', hexc('#6a1028'), 0.55, **{'Sheen Weight': 1.0, 'Sheen Tint': hexc('#ff9a7a'), 'Sheen Roughness': 0.35})
VEST = mat('Kewa', hexc('#2a0d1c'), 0.5, **{'Sheen Weight': 0.8, 'Sheen Tint': hexc('#d9a35a')})
GOLD = mat('Gold', hexc('#8a6524'), 0.35, **{'Metallic': 1.0})
SCARF = mat('Scarf', hexc('#e6dccb'), 0.6, **{'Sheen Weight': 0.6, 'Subsurface Weight': 0.25})
SKIN = mat('Skin', hexc('#a06b54'), 0.5, **{'Subsurface Weight': 0.3})
BRASS = mat('Brass', hexc('#3b2a17'), 0.35, **{'Metallic': 1.0})
FLAME = emit('LanternGlass', (1.0, 0.55, 0.22), 28.0)

# ---------------------------------------------------------------- the woman (faces +Y, away from camera)
FIG = Vector((0.35, 12.0, 0.0))
fig = bpy.data.objects.new('Woman', None); col.objects.link(fig); fig.location = FIG; fig.rotation_euler = (0, 0, -0.35)
def part(name, bm, m):
    o = obj(name, bm, m); o.parent = fig; return o
skirt_rings = []
for k in range(14):
    t = k / 13; z = 0.98 - t * 1.42
    r = 0.15 + (0.52 - 0.15) * (t ** 1.35)
    skirt_rings.append((z, r * 1.05, r * 0.9, 0.05 * t * t, -0.07 * t * t))
part('skirt', loft(list(reversed(skirt_rings)), seg=72, cap_top=False,
     pleat=lambda a, t: 1.0 + (1 - t) * 0.07 * math.sin(11 * a + 1.3 * math.sin(3 * a)) + (1 - t) * 0.03 * math.sin(23 * a)), VELVET)
part('bodice', loft([(0.96, 0.15, 0.11, 0, 0), (1.12, 0.145, 0.1, 0, 0), (1.26, 0.17, 0.11, 0, 0), (1.38, 0.19, 0.1, 0, 0), (1.43, 0.12, 0.08, 0, 0)], seg=40), VEST)
bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=False, segments=48, radius1=0.17, radius2=0.165, depth=0.08); bmesh.ops.translate(bm, vec=(0, 0, 0.98), verts=bm.verts)
part('sash', bm, GOLD)
part('neck', tube([(0, 0.0, 1.40), (0, 0.01, 1.50)], [0.045, 0.042], 12), SKIN)
part('head', ico(0.095, (0, 0.02, 1.58), (0.92, 1.0, 1.08)), SKIN)
part('scarf', ico(0.112, (0, 0.035, 1.6), (0.95, 1.03, 1.05)), SCARF)
tail = [(0, 0.09, 1.6), (0.02, 0.13, 1.45), (0.05, 0.16, 1.28), (0.09, 0.2, 1.08), (0.14, 0.24, 0.9)]
part('scarf_tail', tube(tail, [0.08, 0.075, 0.07, 0.06, 0.03], 14), SCARF)
part('crown', tube([(-0.1, 0.0, 1.66), (0, -0.07, 1.68), (0.1, 0.0, 1.66)], [0.012, 0.012, 0.012], 8), GOLD)
# arms with wide Kurdish sleeves and their long hanging tips
def arm(side, pts, sleeve_tip):
    part('arm', tube(pts, [0.05, 0.05, 0.045, 0.04], 12), VEST)
    part('sleeve', tube([pts[1], pts[2], pts[3]], [0.06, 0.08, 0.11], 18), VEST)
    w = Vector(pts[3])
    part('sleeve_tip', tube([tuple(w), tuple(w + Vector(sleeve_tip) * 0.5), tuple(w + Vector(sleeve_tip))], [0.07, 0.05, 0.012], 10), VEST)
    part('hand', ico(0.035, tuple(Vector(pts[3]) + Vector((0, 0, -0.04))), (1, 0.7, 1.3), 2), SKIN)
arm(-1, [(-0.17, 0, 1.38), (-0.22, 0.0, 1.22), (-0.25, 0.02, 1.05), (-0.25, 0.04, 0.9)], (-0.02, 0.03, -0.42))
arm(1, [(0.17, 0, 1.38), (0.26, -0.02, 1.2), (0.36, -0.06, 1.02), (0.44, -0.08, 0.9)], (0.02, 0.05, -0.38))
# lantern (fanûs) hanging from the right hand
LAN = Vector((0.47, -0.09, 0.66))
part('handle', tube([(0.44, -0.08, 0.86), (0.47, -0.09, 0.8), (0.47, -0.09, 0.78)], [0.006, 0.006, 0.006], 6), BRASS)
part('glass', ico(0.06, tuple(LAN), (1, 1, 1.45), 3), FLAME)
for dx, dy in ((-0.06, -0.06), (0.06, -0.06), (-0.06, 0.06), (0.06, 0.06)):
    part('post', tube([tuple(LAN + Vector((dx, dy, -0.1))), tuple(LAN + Vector((dx, dy, 0.1)))], [0.006, 0.006], 6), BRASS)
bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=8, radius1=0.09, radius2=0.015, depth=0.07)
bmesh.ops.translate(bm, vec=tuple(LAN + Vector((0, 0, 0.13))), verts=bm.verts); part('cap', bm, BRASS)
bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=8, radius1=0.085, radius2=0.085, depth=0.03)
bmesh.ops.translate(bm, vec=tuple(LAN + Vector((0, 0, -0.11))), verts=bm.verts); part('base', bm, BRASS)
lamp = bpy.data.lights.new('LanternLight', 'POINT'); lamp.energy = 55; lamp.shadow_soft_size = 0.04; lamp.color = (1.0, 0.58, 0.26)
lo = bpy.data.objects.new('LanternLight', lamp); col.objects.link(lo); lo.parent = fig; lo.location = LAN
focus = bpy.data.objects.new('FocusTarget', None); col.objects.link(focus); focus.parent = fig; focus.location = (0.2, 0, 1.2)

# ---------------------------------------------------------------- water: horizontal ripples + rings around her
water_m = bpy.data.materials.new('Lake'); water_m.use_nodes = True; nt = water_m.node_tree; b = nt.nodes['Principled BSDF']
b.inputs['Base Color'].default_value = (*hexc('#03070c'), 1); b.inputs['Roughness'].default_value = 0.035
b.inputs['Specular IOR Level'].default_value = 0.6
tc = nt.nodes.new('ShaderNodeTexCoord')
mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (0.25, 1.0, 1.0)
nt.links.new(tc.outputs['Object'], mp.inputs['Vector'])
wv = nt.nodes.new('ShaderNodeTexWave'); wv.wave_type = 'BANDS'; wv.bands_direction = 'Y'
wv.inputs['Scale'].default_value = 0.9; wv.inputs['Distortion'].default_value = 6.0; wv.inputs['Detail'].default_value = 3.0
nt.links.new(mp.outputs['Vector'], wv.inputs['Vector'])
mp2 = nt.nodes.new('ShaderNodeMapping'); mp2.inputs['Location'].default_value = (-FIG.x, -FIG.y, 0)
nt.links.new(tc.outputs['Object'], mp2.inputs['Vector'])
rg = nt.nodes.new('ShaderNodeTexWave'); rg.wave_type = 'RINGS'; rg.rings_direction = 'SPHERICAL'
rg.inputs['Scale'].default_value = 1.6; rg.inputs['Distortion'].default_value = 0.6
nt.links.new(mp2.outputs['Vector'], rg.inputs['Vector'])
gr = nt.nodes.new('ShaderNodeTexGradient'); gr.gradient_type = 'SPHERICAL'
gsc = nt.nodes.new('ShaderNodeMapping'); gsc.inputs['Scale'].default_value = (0.3, 0.3, 0.3); nt.links.new(mp2.outputs['Vector'], gsc.inputs['Vector'])
nt.links.new(gsc.outputs['Vector'], gr.inputs['Vector'])
mx = nt.nodes.new('ShaderNodeMix'); mx.data_type = 'FLOAT'
nt.links.new(gr.outputs['Fac'], mx.inputs['Factor']); nt.links.new(wv.outputs['Fac'], mx.inputs['A']); nt.links.new(rg.outputs['Fac'], mx.inputs['B'])
bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.22; bp.inputs['Distance'].default_value = 0.05
nt.links.new(mx.outputs['Result'], bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], b.inputs['Normal'])
bm = bmesh.new(); bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=1500)
obj('Lake', bm, water_m, smooth=False)

# ---------------------------------------------------------------- mountains, village lights, moon, sky
def ridge(dist, base_h, amp, color, strength, seed, x0=-420, x1=420):
    bm = bmesh.new(); top = []; bot = []
    n = 220
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        h = base_h + amp * (0.5 + 0.5 * noise.fractal(Vector((x * 0.012 + seed, seed, 0)), 0.7, 2.0, 5))
        h *= 1.0 - 0.55 * math.exp(-((x + 20) / 140) ** 2) * (seed % 2)
        top.append(bm.verts.new((x, dist, h))); bot.append(bm.verts.new((x, dist, -3)))
    for i in range(n):
        bm.faces.new((bot[i], bot[i + 1], top[i + 1], top[i]))
    return obj('Ridge', bm, emit('Ridge%d' % seed, color, strength), smooth=False)
ridge(520, 8, 22, hexc('#2a4560'), 0.6, 3)
ridge(330, 3, 12, hexc('#142638'), 0.5, 8)
ridge(210, 0.8, 6, hexc('#08111b'), 0.45, 5)
# Hawrami village on the near ridge: stepped rows of warm windows
WIN = emit('Window', (1.0, 0.62, 0.28), 45.0)
bm = bmesh.new()
for row in range(6):
    for k in range(11 - row):
        if R.random() < 0.55: continue
        x = -44 + row * 2.2 + k * 3.6 + R.uniform(-0.8, 0.8)
        z = 1.4 + row * 1.0 + R.uniform(-0.2, 0.2)
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.15, matrix=Matrix.Translation((x, 205, z)))
obj('VillageLights', bm, WIN)
moon_m = bpy.data.materials.new('Moon'); moon_m.use_nodes = True; nt = moon_m.node_tree
for n in list(nt.nodes):
    if n.type != 'OUTPUT_MATERIAL': nt.nodes.remove(n)
e = nt.nodes.new('ShaderNodeEmission'); nz = nt.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 0.08
cr = nt.nodes.new('ShaderNodeValToRGB'); cr.color_ramp.elements[0].position = 0.45; cr.color_ramp.elements[0].color = (*hexc('#9fb2d0'), 1)
cr.color_ramp.elements[1].position = 0.6; cr.color_ramp.elements[1].color = (*hexc('#f2f5ff'), 1)
nt.links.new(nz.outputs['Fac'], cr.inputs['Fac']); nt.links.new(cr.outputs['Color'], e.inputs['Color']); e.inputs['Strength'].default_value = 2.6
nt.links.new(e.outputs[0], nt.nodes['Material Output'].inputs['Surface'])
MOON_DIR = Vector((-0.012, 1.0, math.tan(math.radians(10.5)))).normalized()
obj('Moon', ico(24, tuple(MOON_DIR * 900), (1, 1, 1), 4), moon_m)
sun = bpy.data.lights.new('Moonlight', 'SUN'); sun.energy = 1.1; sun.color = (0.62, 0.74, 1.0); sun.angle = math.radians(1.5)
so = bpy.data.objects.new('Moonlight', sun); col.objects.link(so)
so.rotation_euler = (-MOON_DIR).to_track_quat('-Z', 'Y').to_euler()
world = bpy.data.worlds.new('Night'); sc.world = world; world.use_nodes = True; wn = world.node_tree
bg = wn.nodes['Background']; tcw = wn.nodes.new('ShaderNodeTexCoord'); sp = wn.nodes.new('ShaderNodeSeparateXYZ')
wn.links.new(tcw.outputs['Generated'], sp.inputs['Vector'])
ramp = wn.nodes.new('ShaderNodeValToRGB'); cr = ramp.color_ramp
cr.elements[0].position = 0.5; cr.elements[0].color = (*hexc('#38597a'), 1)
cr.elements[1].position = 0.72; cr.elements[1].color = (*hexc('#03060c'), 1)
el = cr.elements.new(0.55); el.color = (*hexc('#1a3550'), 1)
wn.links.new(sp.outputs['Z'], ramp.inputs['Fac']); wn.links.new(ramp.outputs['Color'], bg.inputs['Color']); bg.inputs['Strength'].default_value = 1.0

# ---------------------------------------------------------------- night haze (lantern halo), fireflies, reeds
vm = bpy.data.materials.new('Haze'); vm.use_nodes = True; nt = vm.node_tree
nt.nodes.remove(nt.nodes['Principled BSDF'])
pv = nt.nodes.new('ShaderNodeVolumePrincipled'); pv.inputs['Density'].default_value = 0.009; pv.inputs['Anisotropy'].default_value = 0.55
pv.inputs['Color'].default_value = (0.86, 0.9, 1.0, 1)
nt.links.new(pv.outputs[0], nt.nodes['Material Output'].inputs['Volume'])
bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0); bmesh.ops.scale(bm, vec=(30, 40, 9), verts=bm.verts); bmesh.ops.translate(bm, vec=(0, 21, 4.4), verts=bm.verts)
haze = obj('Haze', bm, vm, smooth=False)
FLY = emit('Firefly', (1.0, 0.86, 0.45), 70.0)
bm = bmesh.new()
for i in range(24):
    y = R.uniform(3.0, 19); x = FIG.x + R.uniform(-0.2, 0.2) * y; z = R.uniform(0.15, 0.08 * y + 0.7)
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=R.uniform(0.005, 0.011), matrix=Matrix.Translation((x, y, z)))
obj('Fireflies', bm, FLY)
REED = mat('Reed', hexc('#0b0f0b'), 0.8)
for side in (-1, 1):
    bm = bmesh.new()
    for i in range(26):
        x = side * R.uniform(0.9, 1.9); y = R.uniform(3.2, 5.5); h = R.uniform(0.6, 1.8); lean = R.uniform(-0.25, 0.25) - side * 0.15
        pts = [(x, y, -0.2), (x + lean * 0.3, y, h * 0.5), (x + lean, y + 0.05, h)]
        t = tube(pts, [0.012, 0.009, 0.002], 5); bmesh.ops.translate(t, vec=(0, 0, 0), verts=t.verts)
        me = bpy.data.meshes.new('r'); t.to_mesh(me); t.free(); bm.from_mesh(me); bpy.data.meshes.remove(me)
    obj('Reeds', bm, REED)

# ---------------------------------------------------------------- camera
cam = bpy.data.cameras.new('Cam'); cam.lens = 85; cam.sensor_fit = 'AUTO'
co = bpy.data.objects.new('Cam', cam); col.objects.link(co); sc.camera = co
co.location = (0.15, 0.0, 0.72)
co.rotation_euler = (math.radians(90 + 3.6), 0, 0)
cam.dof.use_dof = True; cam.dof.focus_object = focus; cam.dof.aperture_fstop = 1.4; cam.dof.aperture_blades = 0

# ---------------------------------------------------------------- render + Kelen Lens Lab
r = sc.render; r.engine = 'CYCLES'; r.resolution_x = 1080; r.resolution_y = 1350; r.resolution_percentage = PCT
r.compositor_device = 'CPU'; r.film_transparent = False
cy = sc.cycles; cy.device = 'CPU'; cy.samples = SPP; cy.use_adaptive_sampling = True; cy.adaptive_threshold = 0.02
cy.use_denoising = True; cy.max_bounces = 6; cy.diffuse_bounces = 2; cy.glossy_bounces = 3; cy.volume_bounces = 1
cy.transmission_bounces = 2; cy.caustics_reflective = False; cy.caustics_refractive = False
cy.use_auto_tile = True; cy.tile_size = 256
vs = sc.view_settings; vs.view_transform = 'AgX'
try: vs.look = 'AgX - Medium High Contrast'
except Exception: pass
vs.exposure = 0.4

s = sc.kelen_lens
s.lens = LENS; s.strength = 1.0; s.fstop = 1.4; s.focus_object = focus
s.bloom = 0.6; s.halation = 0.5; s.streaks = 0.0; s.aberration = 0.3; s.vignette = 0.45; s.grain = 0.4
kll.apply_all(sc, s, co)
r.filepath = OUT
bpy.ops.wm.save_as_mainfile(filepath=os.path.splitext(OUT)[0] + '.blend')
bpy.ops.render.render(write_still=True)
print('done', OUT)
