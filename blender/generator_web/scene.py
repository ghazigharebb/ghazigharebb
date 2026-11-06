"""«تۆڕی مۆلیدە» — Generator Web. Cinematic anamorphic still, Blender 4.5 / Cycles.

python scene.py -- render <w> <h> <samples> <out.png> [border x0 x1 y0 y1]
python scene.py -- save <out.blend>
"""
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['none']
MODE = argv[0]
random.seed(11)
R = random.Random(11)

bpy.ops.wm.read_factory_settings(use_empty=True)
S = bpy.context.scene
C = S.collection

def link(nt, a, b): nt.links.new(a, b)

def new_mat(name):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; p = nt.nodes["Principled BSDF"]
    return m, nt, p

def node(nt, t, **kw):
    n = nt.nodes.new(t)
    for k, v in kw.items():
        if k in n.inputs: n.inputs[k].default_value = v
        else: setattr(n, k, v)
    return n

def math_node(nt, op, a, b=None):
    n = nt.nodes.new("ShaderNodeMath"); n.operation = op
    for i, v in enumerate((a, b)):
        if v is None: continue
        if isinstance(v, (int, float)): n.inputs[i].default_value = v
        else: link(nt, v, n.inputs[i])
    return n.outputs[0]

def obj_from_bm(name, bm, mat=None):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); C.objects.link(o)
    if mat: o.data.materials.append(mat)
    return o

def box(name, center, size, mat=None, bevel=0.0):
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2])) + Vector(center)
    o = obj_from_bm(name, bm, mat)
    if bevel > 0:
        b = o.modifiers.new("bev", 'BEVEL'); b.width = bevel; b.segments = 2; b.limit_method = 'ANGLE'
    return o

def cyl(name, p0, p1, r, mat=None, verts=12):
    p0, p1 = Vector(p0), Vector(p1); d = p1 - p0
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=verts, radius1=r, radius2=r, depth=d.length)
    o = obj_from_bm(name, bm, mat)
    o.location = (p0 + p1) / 2
    o.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    return o

# ============================================================ MATERIALS
def concrete(name, base, dirt=0.5, wet=0.0, scale=1.0, streak=True):
    m, nt, p = new_mat(name)
    tc = node(nt, "ShaderNodeTexCoord")
    n1 = node(nt, "ShaderNodeTexNoise", **{"Scale": 3.0 * scale, "Detail": 10.0, "Roughness": 0.62})
    link(nt, tc.outputs["Object"], n1.inputs["Vector"])
    n2 = node(nt, "ShaderNodeTexNoise", **{"Scale": 22.0 * scale, "Detail": 12.0, "Roughness": 0.72})
    link(nt, tc.outputs["Object"], n2.inputs["Vector"])
    # vertical rain-stain streaks
    mp = node(nt, "ShaderNodeMapping"); mp.inputs["Scale"].default_value = (1.6, 1.6, 0.45)
    link(nt, tc.outputs["Object"], mp.inputs["Vector"])
    n3 = node(nt, "ShaderNodeTexNoise", **{"Scale": 2.5, "Detail": 4.0})
    link(nt, mp.outputs[0], n3.inputs["Vector"])
    cr = node(nt, "ShaderNodeValToRGB")
    cr.color_ramp.elements[0].position = 0.3; cr.color_ramp.elements[0].color = tuple(c * (1 - 0.55 * dirt) for c in base) + (1,)
    cr.color_ramp.elements[1].position = 0.7; cr.color_ramp.elements[1].color = base + (1,)
    link(nt, n1.outputs["Fac"], cr.inputs["Fac"])
    col = cr.outputs["Color"]
    if streak:
        sr = node(nt, "ShaderNodeValToRGB")
        sr.color_ramp.elements[0].position = 0.40; sr.color_ramp.elements[0].color = (0.62, 0.60, 0.57, 1)
        sr.color_ramp.elements[1].position = 0.70; sr.color_ramp.elements[1].color = (1, 1, 1, 1)
        link(nt, n3.outputs["Fac"], sr.inputs["Fac"])
        mx = node(nt, "ShaderNodeMix", data_type='RGBA', blend_type='MULTIPLY'); mx.inputs[0].default_value = 0.8 * dirt
        link(nt, col, mx.inputs[6]); link(nt, sr.outputs["Color"], mx.inputs[7]); col = mx.outputs[2]
    link(nt, col, p.inputs["Base Color"])
    p.inputs["Roughness"].default_value = 0.9 - 0.55 * wet
    bmp = node(nt, "ShaderNodeBump", **{"Strength": 0.6, "Distance": 0.012})
    link(nt, n2.outputs["Fac"], bmp.inputs["Height"]); link(nt, bmp.outputs["Normal"], p.inputs["Normal"])
    return m

def metal(name, base, rough=0.45, rust=0.3, metallic=0.85):
    m, nt, p = new_mat(name)
    tc = node(nt, "ShaderNodeTexCoord")
    n = node(nt, "ShaderNodeTexNoise", **{"Scale": 8.0, "Detail": 9.0, "Roughness": 0.65})
    link(nt, tc.outputs["Object"], n.inputs["Vector"])
    cr = node(nt, "ShaderNodeValToRGB")
    cr.color_ramp.elements[0].position = 0.55; cr.color_ramp.elements[0].color = base + (1,)
    cr.color_ramp.elements[1].position = 0.75; cr.color_ramp.elements[1].color = (0.16, 0.07, 0.03, 1)
    link(nt, n.outputs["Fac"], cr.inputs["Fac"])
    if rust > 0: link(nt, cr.outputs["Color"], p.inputs["Base Color"])
    else: p.inputs["Base Color"].default_value = base + (1,)
    rr = node(nt, "ShaderNodeMapRange"); rr.inputs[3].default_value = rough; rr.inputs[4].default_value = 0.95
    rr.inputs[1].default_value = 0.55; rr.inputs[2].default_value = 0.75
    link(nt, n.outputs["Fac"], rr.inputs[0]); link(nt, rr.outputs[0], p.inputs["Roughness"])
    mm = node(nt, "ShaderNodeMapRange"); mm.inputs[3].default_value = metallic; mm.inputs[4].default_value = 0.0
    mm.inputs[1].default_value = 0.55; mm.inputs[2].default_value = 0.75
    link(nt, n.outputs["Fac"], mm.inputs[0]); link(nt, mm.outputs[0], p.inputs["Metallic"])
    return m

def plain(name, col, rough=0.5, metallic=0.0, emit=None, strength=0.0, coat=0.0):
    m, nt, p = new_mat(name)
    p.inputs["Base Color"].default_value = col + (1,)
    p.inputs["Roughness"].default_value = rough; p.inputs["Metallic"].default_value = metallic
    p.inputs["Coat Weight"].default_value = coat
    if emit:
        p.inputs["Emission Color"].default_value = emit + (1,); p.inputs["Emission Strength"].default_value = strength
    return m

def emissive(name, col, strength):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    e = node(nt, "ShaderNodeEmission"); e.inputs["Color"].default_value = col + (1,); e.inputs["Strength"].default_value = strength
    link(nt, e.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    return m

def curtain(name, col, strength, seed):
    """window interior: warm glow through a curtain with folds + silhouette of furniture"""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    tc = node(nt, "ShaderNodeTexCoord")
    mp = node(nt, "ShaderNodeMapping"); mp.inputs["Scale"].default_value = (14.0, 14.0, 0.4)
    mp.inputs["Location"].default_value = (seed, seed * 1.7, 0)
    link(nt, tc.outputs["Object"], mp.inputs["Vector"])
    w = node(nt, "ShaderNodeTexWave", wave_type='BANDS', bands_direction='X')
    w.inputs["Scale"].default_value = 1.2; w.inputs["Distortion"].default_value = 2.0; w.inputs["Detail"].default_value = 3.0
    link(nt, mp.outputs[0], w.inputs["Vector"])
    nz = node(nt, "ShaderNodeTexNoise", **{"Scale": 3.0, "Detail": 2.0})
    link(nt, tc.outputs["Object"], nz.inputs["Vector"])
    f = math_node(nt, 'MULTIPLY', math_node(nt, 'ADD', math_node(nt, 'MULTIPLY', w.outputs["Fac"], 0.6), 0.4),
                  math_node(nt, 'ADD', math_node(nt, 'MULTIPLY', nz.outputs["Fac"], 0.9), 0.35))
    e = node(nt, "ShaderNodeEmission"); e.inputs["Color"].default_value = col + (1,)
    st = math_node(nt, 'MULTIPLY', f, strength)
    link(nt, st, e.inputs["Strength"])
    link(nt, e.outputs[0], nt.nodes["Material Output"].inputs["Surface"])
    return m


def grimy_paint(name, base, rust_amt=0.45):
    m, nt, p = new_mat(name)
    tc = node(nt, "ShaderNodeTexCoord")
    sep = node(nt, "ShaderNodeSeparateXYZ"); link(nt, tc.outputs["Generated"], sep.inputs[0])
    n = node(nt, "ShaderNodeTexNoise", **{"Scale": 9.0, "Detail": 12.0, "Roughness": 0.68})
    link(nt, tc.outputs["Object"], n.inputs["Vector"])
    mp = node(nt, "ShaderNodeMapping"); mp.inputs["Scale"].default_value = (4.5, 4.5, 0.9)
    link(nt, tc.outputs["Object"], mp.inputs["Vector"])
    st = node(nt, "ShaderNodeTexNoise", **{"Scale": 3.0, "Detail": 6.0}); link(nt, mp.outputs[0], st.inputs["Vector"])
    # paint vs rust
    cr = node(nt, "ShaderNodeValToRGB")
    cr.color_ramp.elements[0].position = 0.50; cr.color_ramp.elements[0].color = base + (1,)
    cr.color_ramp.elements[1].position = 0.50 + 0.25 * (1 - rust_amt); cr.color_ramp.elements[1].color = (0.11, 0.045, 0.018, 1)
    link(nt, n.outputs["Fac"], cr.inputs["Fac"])
    # vertical run-off streaks (darken)
    sr = node(nt, "ShaderNodeValToRGB")
    sr.color_ramp.elements[0].position = 0.40; sr.color_ramp.elements[0].color = (0.62, 0.56, 0.50, 1)
    sr.color_ramp.elements[1].position = 0.64; sr.color_ramp.elements[1].color = (1, 1, 1, 1)
    link(nt, st.outputs["Fac"], sr.inputs["Fac"])
    m1 = node(nt, "ShaderNodeMix", data_type='RGBA', blend_type='MULTIPLY'); m1.inputs[0].default_value = 1.0
    link(nt, cr.outputs["Color"], m1.inputs[6]); link(nt, sr.outputs["Color"], m1.inputs[7])
    # dirt rising from the ground (splash zone)
    g = node(nt, "ShaderNodeMapRange"); g.inputs[1].default_value = 0.0; g.inputs[2].default_value = 0.35
    g.inputs[3].default_value = 0.25; g.inputs[4].default_value = 1.0
    link(nt, sep.outputs[2], g.inputs[0])
    m2 = node(nt, "ShaderNodeMix", data_type='RGBA', blend_type='MULTIPLY'); m2.inputs[0].default_value = 1.0
    link(nt, m1.outputs[2], m2.inputs[6]); link(nt, g.outputs[0], m2.inputs[7])
    link(nt, m2.outputs[2], p.inputs["Base Color"])
    rr = node(nt, "ShaderNodeMapRange"); rr.inputs[3].default_value = 0.42; rr.inputs[4].default_value = 0.9
    link(nt, st.outputs["Fac"], rr.inputs[0]); link(nt, rr.outputs[0], p.inputs["Roughness"])
    bmp = node(nt, "ShaderNodeBump", **{"Strength": 0.25, "Distance": 0.003}); link(nt, n.outputs["Fac"], bmp.inputs["Height"])
    link(nt, bmp.outputs["Normal"], p.inputs["Normal"])
    return m

M_WALL = [concrete(f"Wall{i}", c, dirt=0.75, wet=0.15, scale=1.0 + 0.3 * i) for i, c in enumerate([
    (0.42, 0.38, 0.32), (0.35, 0.33, 0.30), (0.47, 0.42, 0.34), (0.30, 0.29, 0.28), (0.40, 0.36, 0.30)])]
M_SLAB = concrete("Slab", (0.32, 0.31, 0.29), dirt=0.9, wet=0.2)
M_FRAME = metal("WinFrame", (0.06, 0.06, 0.06), rough=0.35, rust=0.2, metallic=0.6)
M_BARS = metal("Bars", (0.05, 0.05, 0.05), rough=0.4, rust=0.4)
M_SHUTTER = metal("Shutter", (0.30, 0.31, 0.30), rough=0.35, rust=0.35)
M_AC = plain("AC", (0.55, 0.54, 0.50), rough=0.45)
M_TANK = plain("Tank", (0.03, 0.03, 0.03), rough=0.4, coat=0.3)
M_TANK2 = plain("Tank2", (0.55, 0.52, 0.45), rough=0.5)
M_DISH = plain("Dish", (0.55, 0.55, 0.55), rough=0.35, metallic=0.2)
M_WIRE = [plain("WireBlk", (0.012, 0.012, 0.012), rough=0.22, coat=0.6),
          plain("WireGry", (0.08, 0.08, 0.08), rough=0.25, coat=0.6),
          plain("WireRed", (0.25, 0.02, 0.02), rough=0.25, coat=0.6),
          plain("WireBlu", (0.02, 0.05, 0.18), rough=0.25, coat=0.6),
          plain("WireWht", (0.40, 0.40, 0.38), rough=0.3, coat=0.6)]
M_POLE = concrete("Pole", (0.35, 0.34, 0.32), dirt=0.8, wet=0.3, scale=3.0, streak=False)
M_GEN = grimy_paint("GenBody", (0.42, 0.24, 0.025))
M_DARKMETAL = metal("DarkMetal", (0.04, 0.04, 0.045), rough=0.45, rust=0.15)
M_BOARD = metal("Board", (0.22, 0.24, 0.24), rough=0.4, rust=0.25, metallic=0.5)
M_BREAKER = plain("Breaker", (0.65, 0.64, 0.6), rough=0.4)
M_CHAIR = plain("Chair", (0.62, 0.62, 0.58), rough=0.35)
M_BAG = plain("Bag", (0.01, 0.01, 0.012), rough=0.15, coat=0.6)
M_CURB = concrete("Curb", (0.42, 0.42, 0.40), dirt=0.8, wet=0.5, scale=4.0, streak=False)

# ---- wet asphalt with puddles + rain ripples
def asphalt():
    m, nt, p = new_mat("Asphalt")
    tc = node(nt, "ShaderNodeTexCoord")
    grain = node(nt, "ShaderNodeTexNoise", **{"Scale": 180.0, "Detail": 8.0, "Roughness": 0.7})
    link(nt, tc.outputs["Object"], grain.inputs["Vector"])
    pud = node(nt, "ShaderNodeTexNoise", **{"Scale": 0.45, "Detail": 6.0, "Roughness": 0.62})
    link(nt, tc.outputs["Object"], pud.inputs["Vector"])
    pmask = node(nt, "ShaderNodeMapRange"); pmask.inputs[1].default_value = 0.50; pmask.inputs[2].default_value = 0.56
    link(nt, pud.outputs["Fac"], pmask.inputs[0])
    patch = node(nt, "ShaderNodeTexNoise", **{"Scale": 1.2, "Detail": 5.0})
    link(nt, tc.outputs["Object"], patch.inputs["Vector"])
    cr = node(nt, "ShaderNodeValToRGB")
    cr.color_ramp.elements[0].color = (0.020, 0.020, 0.021, 1); cr.color_ramp.elements[1].color = (0.075, 0.072, 0.068, 1)
    link(nt, patch.outputs["Fac"], cr.inputs["Fac"])
    dark = node(nt, "ShaderNodeMix", data_type='RGBA'); dark.inputs[7].default_value = (0.012, 0.012, 0.013, 1)
    link(nt, pmask.outputs[0], dark.inputs[0]); link(nt, cr.outputs["Color"], dark.inputs[6])
    link(nt, dark.outputs[2], p.inputs["Base Color"])
    rough = node(nt, "ShaderNodeMapRange"); rough.inputs[3].default_value = 0.32; rough.inputs[4].default_value = 0.015
    link(nt, pmask.outputs[0], rough.inputs[0])
    gr = math_node(nt, 'ADD', rough.outputs[0], math_node(nt, 'MULTIPLY', grain.outputs["Fac"], math_node(nt, 'SUBTRACT', 1.0, pmask.outputs[0])))
    gr2 = math_node(nt, 'MULTIPLY', gr, 0.75)
    link(nt, gr2, p.inputs["Roughness"])
    p.inputs["Specular IOR Level"].default_value = 0.6
    # ripples: voronoi rings
    vor = node(nt, "ShaderNodeTexVoronoi", feature='F1'); vor.inputs["Scale"].default_value = 9.0; vor.inputs["Randomness"].default_value = 1.0
    link(nt, tc.outputs["Object"], vor.inputs["Vector"])
    ring = math_node(nt, 'SINE', math_node(nt, 'MULTIPLY', vor.outputs["Distance"], 95.0))
    fade = math_node(nt, 'POWER', math_node(nt, 'SUBTRACT', 1.0, math_node(nt, 'MULTIPLY', vor.outputs["Distance"], 2.6)), 3.0)
    rip = math_node(nt, 'MULTIPLY', math_node(nt, 'MULTIPLY', ring, math_node(nt, 'MAXIMUM', fade, 0.0)), pmask.outputs[0])
    b1 = node(nt, "ShaderNodeBump", **{"Strength": 0.25, "Distance": 0.002})
    link(nt, rip, b1.inputs["Height"])
    b2 = node(nt, "ShaderNodeBump", **{"Strength": 0.45, "Distance": 0.004})
    link(nt, math_node(nt, 'MULTIPLY', grain.outputs["Fac"], math_node(nt, 'SUBTRACT', 1.0, pmask.outputs[0])), b2.inputs["Height"])
    link(nt, b1.outputs["Normal"], b2.inputs["Normal"])
    link(nt, b2.outputs["Normal"], p.inputs["Normal"])
    return m
M_ASPH = asphalt()

# ============================================================ STREET
W_FACE = 4.9           # building faces at x = ±4.9
SW = 1.3               # sidewalk width
L = 95.0
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.5)
for v in bm.verts: v.co = Vector((v.co.x * 2 * (W_FACE - SW), v.co.y * L + L / 2 - 5, 0))
road = obj_from_bm("Road", bm, M_ASPH)
for side in (-1, 1):
    box(f"Sidewalk{side}", (side * (W_FACE - SW / 2), L / 2 - 5, 0.07), (SW, L, 0.14), M_CURB)
    box(f"Curb{side}", (side * (W_FACE - SW + 0.06), L / 2 - 5, 0.075), (0.14, L, 0.15), M_CURB, bevel=0.015)

# ============================================================ BUILDINGS
windows = []   # (center Vector, side, floor) for wire anchors
def building(side, y0, width, floors, mat, setback=0.0, shop=True, seed=0):
    rnd = random.Random(seed)
    fh = 3.15
    H = floors * fh + 0.25
    face = side * (W_FACE + setback)
    depth = 12.0
    cx = face + side * depth / 2
    body = box(f"B{seed}", (cx, y0 + width / 2, H / 2), (depth, width - 0.02, H), mat)
    cutters = []
    nwin = max(1, int(width // 2.7))
    for fl in range(floors):
        z0 = fl * fh
        if fl == 0 and shop:
            # rolling shutter shop opening
            sw = min(width - 1.0, 3.6)
            sc = y0 + width / 2 + rnd.uniform(-0.3, 0.3)
            cutters.append(((face, sc, 1.45), (0.9, sw, 2.9)))
            sh = box(f"Shutter{seed}", (face + side * 0.25, sc, 1.45), (0.04, sw, 2.9), M_SHUTTER)
            # corrugation via array of thin ribs
            for k in range(28):
                box(f"Rib{seed}_{k}", (face + side * 0.22, sc, 0.1 + k * 0.103), (0.03, sw, 0.035), M_SHUTTER)
            box(f"ShutterBox{seed}", (face + side * 0.12, sc, 3.0), (0.3, sw + 0.2, 0.3), M_SHUTTER)
            continue
        for k in range(nwin):
            wy = y0 + (k + 0.5) * width / nwin + rnd.uniform(-0.15, 0.15)
            ww, wh = rnd.choice([(1.2, 1.4), (1.5, 1.4), (1.0, 1.3)])
            wz = z0 + 0.95 + wh / 2
            cutters.append(((face, wy, wz), (0.62, ww, wh)))
            windows.append((Vector((face, wy, wz)), side, fl, ww, wh))
            # frame
            fx = face + side * 0.12
            for dz in (-wh / 2, wh / 2):
                box(f"Fr{seed}_{fl}_{k}h{dz}", (fx, wy, wz + dz), (0.06, ww, 0.06), M_FRAME)
            for dy in (-ww / 2, 0, ww / 2):
                box(f"Fr{seed}_{fl}_{k}v{dy}", (fx, wy + dy, wz), (0.06, 0.06, wh), M_FRAME)
            # interior glow (generator-powered: most windows lit, warm, varied)
            lit = rnd.random()
            if lit < 0.80:
                col = rnd.choice([(1.0, 0.42, 0.10), (1.0, 0.50, 0.16), (1.0, 0.36, 0.08), (1.0, 0.58, 0.24)])
                strength = rnd.uniform(2.5, 7.0)
                if rnd.random() < 0.12: col, strength = (0.45, 0.65, 1.0), rnd.uniform(0.8, 1.8)   # TV light
                mt = curtain(f"Cur{seed}_{fl}_{k}", col, strength, rnd.uniform(0, 100))
            else:
                mt = emissive(f"Dark{seed}_{fl}_{k}", (0.02, 0.02, 0.03), 0.05)
            box(f"In{seed}_{fl}_{k}", (face + side * 0.26, wy, wz), (0.02, ww + 0.2, wh + 0.2), mt)
            # security grille on lower floors
            if fl <= 1 and rnd.random() < 0.7:
                for j in range(int(ww / 0.12) + 1):
                    box(f"Bar{seed}_{fl}_{k}_{j}", (face - side * 0.06, wy - ww / 2 + j * 0.12, wz), (0.018, 0.018, wh + 0.06), M_BARS)
                for dz in (-wh / 2 + 0.05, 0, wh / 2 - 0.05):
                    box(f"BarH{seed}_{fl}_{k}{dz}", (face - side * 0.06, wy, wz + dz), (0.02, ww + 0.06, 0.03), M_BARS)
            # AC unit under some windows
            if rnd.random() < 0.45:
                ac = box(f"AC{seed}_{fl}_{k}", (face - side * 0.22, wy + rnd.uniform(-0.3, 0.3), z0 + 0.55), (0.32, 0.82, 0.55), M_AC, bevel=0.02)
                cyl(f"ACfan{seed}_{fl}_{k}", (face - side * 0.39, ac.location.y, ac.location.z), (face - side * 0.385, ac.location.y, ac.location.z), 0.2, M_DARKMETAL, 16)
                # condensate drip pipe
                cyl(f"ACpipe{seed}_{fl}_{k}", (face - side * 0.1, ac.location.y + 0.35, z0 + 0.3), (face - side * 0.1, ac.location.y + 0.35, z0 - 0.6), 0.008, M_DARKMETAL, 6)
        # floor slab line / balcony
        if fl >= 1:
            box(f"Slab{seed}_{fl}", (face - side * 0.06, y0 + width / 2, z0), (0.14, width, 0.2), M_SLAB)
            if rnd.random() < 0.4:
                by = y0 + width * rnd.uniform(0.3, 0.7); bw = rnd.uniform(2.0, 3.2)
                box(f"Balc{seed}_{fl}", (face - side * 0.55, by, z0 + 0.05), (1.1, bw, 0.14), M_SLAB)
                for j in range(int(bw / 0.13)):
                    box(f"Rail{seed}_{fl}_{j}", (face - side * 1.07, by - bw / 2 + j * 0.13 + 0.05, z0 + 0.6), (0.02, 0.02, 1.0), M_BARS)
                box(f"RailT{seed}_{fl}", (face - side * 1.07, by, z0 + 1.1), (0.05, bw, 0.05), M_BARS)
    # boolean cut windows/shops
    if cutters:
        bmc = bmesh.new()
        for c, s in cutters:
            t = bmesh.ops.create_cube(bmc, size=1.0)
            for v in t['verts']: v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2])) + Vector(c)
        cut = obj_from_bm(f"Cut{seed}", bmc); cut.hide_render = True; cut.hide_viewport = True
        bo = body.modifiers.new("cut", 'BOOLEAN'); bo.object = cut; bo.solver = 'EXACT'
    # roof parapet, water tanks, dish
    box(f"Par{seed}", (face - side * 0.1, y0 + width / 2, H + 0.45), (0.2, width, 0.9), mat)
    for t in range(rnd.randint(1, 3)):
        tx = face + side * rnd.uniform(1.5, 4.5); ty = y0 + rnd.uniform(1.0, width - 1.0)
        tm = M_TANK if rnd.random() < 0.6 else M_TANK2
        cyl(f"Tank{seed}_{t}", (tx, ty, H + 0.6), (tx, ty, H + 1.85), 0.55, tm, 20)
        for lx, ly in ((0.45, 0.45), (-0.45, 0.45), (0.45, -0.45), (-0.45, -0.45)):
            cyl(f"TankLeg{seed}_{t}{lx}{ly}", (tx + lx, ty + ly, H), (tx + lx, ty + ly, H + 0.6), 0.025, M_BARS, 6)
    if rnd.random() < 0.7:
        dx = face + side * rnd.uniform(0.8, 2.5); dy = y0 + rnd.uniform(1, width - 1)
        cyl(f"DishPole{seed}", (dx, dy, H), (dx, dy, H + 1.3), 0.02, M_BARS, 6)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, segments=24, ring_count=12, location=(dx, dy, H + 1.4))
        d = bpy.context.object; d.name = f"Dish{seed}"; d.scale = (1, 1, 0.28)
        d.rotation_euler = (math.radians(rnd.uniform(45, 70)), 0, math.radians(rnd.uniform(130, 230)))
        d.data.materials.append(M_DISH)
    return H

# lots along both sides
heights = {}
for side, seed0 in ((-1, 100), (1, 200)):
    y = -2.0; i = 0
    while y < 85:
        w = R.uniform(6.0, 9.5)
        fl = R.choice([2, 2, 3, 3, 3, 4])
        h = building(side, y, w, fl, R.choice(M_WALL), setback=R.choice([0, 0, 0, 0.35]), seed=seed0 + i)
        heights[(side, i)] = (y, w, h)
        y += w; i += 1

# ============================================================ POLES + DISTRIBUTION
def pole(name, x, y, h=8.5):
    cyl(name, (x, y, 0), (x, y, h), 0.13, M_POLE, 12)
    box(name + "Arm", (x, y, h - 0.6), (1.8, 0.12, 0.12), M_POLE)
    box(name + "Arm2", (x, y, h - 1.4), (1.3, 0.1, 0.1), M_POLE)
    return Vector((x, y, h))
P1 = pole("Pole1", -3.25, 10.0, 8.6)
P2 = pole("Pole2", 3.25, 27.0, 8.4)
P3 = pole("Pole3", -3.25, 44.0, 8.2)
P4 = pole("Pole4", 3.25, 61.0, 8.0)

# ============================================================ WIRES
wire_objs = []
def wire(p0, p1, sag=None, r=None, mat=None, n=24, droop_end=None):
    p0, p1 = Vector(p0), Vector(p1)
    span = (p1 - p0).length
    if sag is None: sag = span * R.uniform(0.03, 0.075) + 0.05
    if r is None: r = R.uniform(0.0045, 0.009)
    cv = bpy.data.curves.new("W", 'CURVE'); cv.dimensions = '3D'; cv.bevel_depth = r; cv.bevel_resolution = 2
    sp = cv.splines.new('POLY'); sp.points.add(n - 1)
    side_wob = Vector((R.uniform(-1, 1), R.uniform(-1, 1), 0)) * span * 0.006
    for i in range(n):
        t = i / (n - 1)
        p = p0.lerp(p1, t)
        p.z -= sag * 4 * t * (1 - t)
        p += side_wob * math.sin(math.pi * t)
        sp.points[i].co = (p.x, p.y, p.z, 1)
    o = bpy.data.objects.new("Wire", cv); C.objects.link(o)
    o.data.materials.append(mat or R.choices(M_WIRE, weights=[6, 3, 1, 1, 1])[0])
    wire_objs.append(o)
    return o

def pole_pt(P, spread=0.85, drop=1.9):
    return Vector((P.x + R.uniform(-spread, spread), P.y + R.uniform(-0.08, 0.08), P.z - 0.55 - R.uniform(0, drop)))

# trunk bundles pole->pole (thick, many)
for A, B in ((P1, P2), (P2, P3), (P3, P4)):
    for k in range(14):
        wire(pole_pt(A, 0.8, 1.2), pole_pt(B, 0.8, 1.2), sag=R.uniform(0.6, 1.3), r=R.uniform(0.006, 0.011))
# pole -> every window/balcony (the web)
poles = [P1, P2, P3, P4]
for (wc, side, fl, ww, wh) in windows:
    if R.random() < 0.15: continue
    P = min(poles, key=lambda q: (q - wc).length)
    if (P - wc).length > 26: continue
    nw = R.choice([1, 1, 2, 2, 3])
    for _ in range(nw):
        anchor = Vector((wc.x - side * 0.08, wc.y + R.uniform(-ww / 2, ww / 2), wc.z + wh / 2 + R.uniform(0.05, 0.5)))
        wire(pole_pt(P), anchor)
        # drop along wall into the window
        if R.random() < 0.5:
            wire(anchor, Vector((anchor.x, anchor.y + R.uniform(-0.2, 0.2), wc.z + R.uniform(-0.2, 0.3))), sag=0.02, n=6)
# generator -> board -> pole1 riser bundle
GEN = Vector((-3.55, 8.2, 0.0))
BOARD = Vector((-3.05, 9.75, 1.75))
for k in range(26):
    a = Vector((BOARD.x + R.uniform(-0.25, 0.25), BOARD.y + R.uniform(-0.15, 0.15), BOARD.z + 0.55))
    b = Vector((P1.x + R.uniform(-0.18, 0.18), P1.y + R.uniform(-0.18, 0.18), P1.z - 0.7 - R.uniform(0, 1.6)))
    wire(a, b, sag=R.uniform(-0.15, 0.25), n=12, r=R.uniform(0.006, 0.01))
for k in range(5):  # thick feeders from generator to board
    wire(Vector((GEN.x + 0.4, GEN.y + 0.9, 0.9 + k * 0.08)), Vector((BOARD.x, BOARD.y - 0.2 + k * 0.08, BOARD.z - 0.45)),
         sag=0.35, r=0.016, mat=M_WIRE[0], n=14)
# loose / dead wires and tangles around poles
for P in poles:
    for k in range(10):
        a = pole_pt(P, 0.3, 2.5); b = pole_pt(P, 0.3, 2.5)
        wire(a, b + Vector((R.uniform(-0.6, 0.6), R.uniform(-0.6, 0.6), 0)), sag=R.uniform(0.2, 0.8), n=10)
    for k in range(3):   # hanging loose ends
        a = pole_pt(P, 0.6, 1.0)
        wire(a, a + Vector((R.uniform(-1.2, 1.2), R.uniform(-1.5, 1.5), -R.uniform(1.5, 3.5))), sag=0.3, n=10)
# cross-street direct wires (house to house)
for k in range(25):
    a, b = R.sample(windows, 2)
    if a[1] == b[1] or abs(a[0].y - b[0].y) > 12: continue
    wire(a[0] + Vector((0, 0, a[4] / 2 + 0.4)), b[0] + Vector((0, 0, b[4] / 2 + 0.4)))

# ============================================================ GENERATOR + BOARD + PROPS
gen = box("Generator", (GEN.x, GEN.y, 0.95), (1.25, 2.6, 1.7), M_GEN, bevel=0.04)
box("GenBase", (GEN.x, GEN.y, 0.08), (1.35, 2.75, 0.16), M_DARKMETAL)
for k in range(14):   # louvres
    box(f"Louvre{k}", (GEN.x + 0.635, GEN.y - 0.9 + k * 0.045 * 0 + 0, 0.55 + k * 0.06), (0.03, 0.9, 0.025), M_DARKMETAL)
box("GenDoor", (GEN.x + 0.63, GEN.y + 0.6, 1.0), (0.02, 1.0, 1.25), M_GEN)
box("GenPanel", (GEN.x + 0.64, GEN.y + 0.65, 1.35), (0.02, 0.38, 0.28), M_DARKMETAL)
box("GenDisplay", (GEN.x + 0.652, GEN.y + 0.65, 1.42), (0.005, 0.16, 0.06), emissive("Display", (0.25, 1.0, 0.45), 6.0))
for k in range(3):
    box(f"GenLed{k}", (GEN.x + 0.652, GEN.y + 0.55 + k * 0.08, 1.30), (0.005, 0.02, 0.02),
        emissive(f"Led{k}", [(1, 0.1, 0.05), (0.2, 1, 0.2), (1, 0.6, 0.1)][k], 15.0))
# exhaust stack
cyl("Exhaust", (GEN.x - 0.3, GEN.y - 1.0, 1.75), (GEN.x - 0.3, GEN.y - 1.0, 3.2), 0.06, M_DARKMETAL, 12)
cyl("ExhaustCap", (GEN.x - 0.3, GEN.y - 1.0, 3.2), (GEN.x - 0.15, GEN.y - 1.0, 3.32), 0.07, M_DARKMETAL, 12)
# corrugated roof sheet over generator (makeshift shelter)
sheet = box("Shelter", (GEN.x + 0.15, GEN.y + 0.2, 2.75), (1.8, 3.4, 0.03), metal("Rusty", (0.12, 0.10, 0.08), rough=0.55, rust=0.7, metallic=0.4))
sheet.rotation_euler = (0, math.radians(8), 0)
for (px, py) in ((-4.6, 6.6), (-4.6, 9.8), (-2.6, 6.6), (-2.6, 9.8)):
    cyl(f"ShelterPost{px}{py}", (px, py, 0.14), (px, py, 2.68 + (px + 4.6) * 0.07 * -1), 0.035, M_BARS, 8)
# bare bulb hanging under the shelter — the key light
BULB = Vector((-3.0, 6.6, 2.25))
cyl("BulbCord", (BULB.x, BULB.y, 2.68), (BULB.x, BULB.y, BULB.z + 0.06), 0.004, M_WIRE[0], 6)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.045, location=BULB); bulb = bpy.context.object; bulb.name = "Bulb"
bulb.data.materials.append(emissive("BulbGlow", (1.0, 0.62, 0.28), 60.0))
bulb.visible_shadow = False
bpy.ops.object.light_add(type='POINT', location=BULB + Vector((0, 0, -0.06)))
kl = bpy.context.object; kl.name = "KeyBulb"; kl.data.energy = 250; kl.data.color = (1.0, 0.58, 0.26); kl.data.shadow_soft_size = 0.035

# distribution board on pole1
box("BoardBox", (BOARD.x, BOARD.y, BOARD.z), (0.22, 0.75, 0.95), M_BOARD, bevel=0.01)
door = box("BoardDoor", (BOARD.x + 0.33, BOARD.y - 0.42, BOARD.z), (0.02, 0.72, 0.92), M_BOARD)
door.rotation_euler = (0, 0, math.radians(-65))
for r_ in range(5):
    for c_ in range(6):
        bz = BOARD.z + 0.32 - r_ * 0.16; byy = BOARD.y - 0.28 + c_ * 0.11
        box(f"Brk{r_}{c_}", (BOARD.x + 0.12, byy, bz), (0.05, 0.09, 0.12), M_BREAKER)
        if R.random() < 0.6:
            box(f"BrkLed{r_}{c_}", (BOARD.x + 0.148, byy, bz + 0.04), (0.004, 0.012, 0.012),
                emissive(f"BL{r_}{c_}", (1.0, 0.08, 0.04) if R.random() < 0.7 else (0.2, 1.0, 0.25), 25.0))
# monobloc chair + tea glass + stool
def chair(x, y, rot):
    g = []
    g.append(box("ChairSeat", (x, y, 0.45), (0.46, 0.46, 0.04), M_CHAIR, bevel=0.015))
    g.append(box("ChairBack", (x - 0.22, y, 0.75), (0.04, 0.44, 0.55), M_CHAIR, bevel=0.015))
    for dx in (-0.2, 0.2):
        for dy in (-0.2, 0.2):
            l = cyl("ChairLeg", (x + dx * 1.1, y + dy * 1.1, 0.14), (x + dx, y + dy, 0.45), 0.022, M_CHAIR, 8); g.append(l)
    for o in g:
        o.rotation_euler.z += rot
chair(-2.35, 6.2, math.radians(25))
box("Stool", (-2.0, 7.0, 0.36), (0.3, 0.3, 0.04), M_DARKMETAL)
for dx in (-0.12, 0.12):
    for dy in (-0.12, 0.12):
        cyl("StoolLeg", (-2.0 + dx, 7.0 + dy, 0.14), (-2.0 + dx, 7.0 + dy, 0.35), 0.012, M_DARKMETAL, 6)
m_tea = plain("Tea", (0.35, 0.06, 0.01), rough=0.05, coat=1.0)
cyl("TeaGlass", (-2.0, 7.0, 0.38), (-2.0, 7.0, 0.47), 0.024, m_tea, 12)
# fuel jerrycans
for k in range(3):
    box(f"Jerry{k}", (-4.35, 6.2 + k * 0.38, 0.39), (0.2, 0.34, 0.48), grimy_paint(f"JC{k}", [(0.04, 0.07, 0.025), (0.12, 0.018, 0.01), (0.05, 0.06, 0.03)][k], 0.3), bevel=0.03)
# trash bags along walls
for k in range(9):
    side = R.choice([-1, 1]); yy = R.uniform(4, 60)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.32, location=(side * (W_FACE - 0.35), yy, 0.4))
    b = bpy.context.object; b.scale = (1, R.uniform(0.8, 1.3), R.uniform(0.7, 1.0)); b.data.materials.append(M_BAG)
    d = b.modifiers.new("d", 'DISPLACE'); t = bpy.data.textures.new("bt", 'CLOUDS'); t.noise_scale = 0.15; d.texture = t; d.strength = 0.08
    bpy.ops.object.shade_smooth()

# open shop with cold fluorescent light (colour contrast)
SHOP_Y = 19.5
box("ShopBack", (W_FACE + 3.2, SHOP_Y, 1.5), (0.1, 3.4, 3.0), concrete("ShopWall", (0.55, 0.6, 0.58), dirt=0.4))
box("ShopFloor", (W_FACE + 1.6, SHOP_Y, 0.02), (3.2, 3.4, 0.04), M_CURB)
box("ShopTube", (W_FACE + 1.4, SHOP_Y, 2.75), (0.05, 1.2, 0.05), emissive("Tube", (0.55, 1.0, 0.85), 40.0))
bpy.ops.object.light_add(type='AREA', location=(W_FACE + 1.4, SHOP_Y, 2.7))
sl = bpy.context.object; sl.data.shape = 'RECTANGLE'; sl.data.size = 0.08; sl.data.size_y = 1.2
sl.data.energy = 140; sl.data.color = (0.55, 1.0, 0.85)
for k in range(4):   # shelves silhouettes
    box(f"Shelf{k}", (W_FACE + 2.9, SHOP_Y, 0.5 + k * 0.5), (0.4, 3.0, 0.03), M_DARKMETAL)
    for j in range(10):
        if R.random() < 0.8:
            box(f"Goods{k}{j}", (W_FACE + 2.9, SHOP_Y - 1.4 + j * 0.3, 0.6 + k * 0.5),
                (0.25, 0.2, R.uniform(0.1, 0.25)), plain(f"G{k}{j}", (R.random() * 0.5, R.random() * 0.4, R.random() * 0.4), 0.4))

# distant warm sodium glow down the street (depth + backlit rain)
for (x, y, e) in ((2.6, 72, 900), (-2.0, 88, 1400)):
    bpy.ops.object.light_add(type='POINT', location=(x, y, 5.5)); l = bpy.context.object
    l.data.energy = e; l.data.color = (1.0, 0.55, 0.22); l.data.shadow_soft_size = 0.2
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(x, y, 5.5)); bpy.context.object.data.materials.append(emissive(f"Sod{y}", (1, 0.55, 0.22), 40))
# big soft glow far down the street (city glow in the fog) to silhouette the web
bpy.ops.object.light_add(type='AREA', location=(0, 120, 14)); fg = bpy.context.object
fg.data.shape = 'DISK'; fg.data.size = 30; fg.data.energy = 16000; fg.data.color = (0.62, 0.78, 1.0)
fg.rotation_euler = (math.radians(-80), 0, 0)
# cool moonlit sky fill
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(35), math.radians(-25), math.radians(160)))
moon = bpy.context.object; moon.data.energy = 0.03; moon.data.color = (0.55, 0.7, 1.0); moon.data.angle = math.radians(3)

# ============================================================ ATMOSPHERE
def fog_volume():
    m = bpy.data.materials.new("Fog"); m.use_nodes = True; nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    tc = node(nt, "ShaderNodeTexCoord")
    nz = node(nt, "ShaderNodeTexNoise", **{"Scale": 0.18, "Detail": 3.0})
    link(nt, tc.outputs["Object"], nz.inputs["Vector"])
    hz = node(nt, "ShaderNodeSeparateXYZ"); link(nt, tc.outputs["Object"], hz.inputs[0])
    # denser near the ground, thinning upward
    hfall = math_node(nt, 'EXPONENT', math_node(nt, 'MULTIPLY', hz.outputs[2], -0.12))
    dens = math_node(nt, 'MULTIPLY', math_node(nt, 'MULTIPLY', math_node(nt, 'ADD', nz.outputs["Fac"], 0.3), hfall), 0.026)
    v = node(nt, "ShaderNodeVolumePrincipled"); v.inputs["Anisotropy"].default_value = 0.55
    v.inputs["Color"].default_value = (0.70, 0.82, 0.92, 1)
    link(nt, dens, v.inputs["Density"])
    link(nt, v.outputs[0], nt.nodes["Material Output"].inputs["Volume"])
    return m
fogbox = box("FogBox", (0, 45, 9), (9.7, 100, 18), fog_volume())
fogbox.visible_shadow = False
# generator exhaust smoke plume
def smoke():
    m = bpy.data.materials.new("Smoke"); m.use_nodes = True; nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    tc = node(nt, "ShaderNodeTexCoord")
    sep = node(nt, "ShaderNodeSeparateXYZ"); link(nt, tc.outputs["Generated"], sep.inputs[0])
    mp = node(nt, "ShaderNodeMapping"); mp.inputs["Scale"].default_value = (3, 3, 1.2)
    link(nt, tc.outputs["Generated"], mp.inputs["Vector"])
    nz = node(nt, "ShaderNodeTexNoise", **{"Scale": 4.0, "Detail": 8.0, "Roughness": 0.6, "Distortion": 1.2})
    link(nt, mp.outputs[0], nz.inputs["Vector"])
    # radial falloff from axis, widening with height
    dx = math_node(nt, 'SUBTRACT', sep.outputs[0], 0.5); dy = math_node(nt, 'SUBTRACT', sep.outputs[1], 0.5)
    rr = math_node(nt, 'SQRT', math_node(nt, 'ADD', math_node(nt, 'MULTIPLY', dx, dx), math_node(nt, 'MULTIPLY', dy, dy)))
    width = math_node(nt, 'ADD', 0.06, math_node(nt, 'MULTIPLY', sep.outputs[2], 0.42))
    radial = math_node(nt, 'MAXIMUM', math_node(nt, 'SUBTRACT', 1.0, math_node(nt, 'DIVIDE', rr, width)), 0.0)
    topfade = math_node(nt, 'SUBTRACT', 1.0, sep.outputs[2])
    shape = math_node(nt, 'MULTIPLY', math_node(nt, 'MULTIPLY', radial, topfade), math_node(nt, 'POWER', nz.outputs["Fac"], 2.2))
    v = node(nt, "ShaderNodeVolumePrincipled"); v.inputs["Color"].default_value = (0.5, 0.5, 0.52, 1); v.inputs["Anisotropy"].default_value = 0.6
    link(nt, math_node(nt, 'MULTIPLY', shape, 16.0), v.inputs["Density"])
    link(nt, v.outputs[0], nt.nodes["Material Output"].inputs["Volume"])
    return m
sm = box("Smoke", (GEN.x - 0.1, GEN.y - 0.6, 3.25 + 2.6), (3.0, 3.0, 5.2), smoke())
sm.rotation_euler = (math.radians(-8), math.radians(14), 0)

# world: very dark blue-grey overcast night
w = bpy.data.worlds.new("Night"); S.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.0035, 0.0055, 0.008, 1)
w.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0


# ============================================================ DECALS, GENERATOR DETAIL, OIL SHEEN
TEX = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tex")
if not os.path.isdir(TEX): TEX = os.path.abspath("tex")
def decal(name, img, center, u_axis, v_axis, w, h, rough=0.55, base_mat=None):
    """flat painted decal; u_axis = image left->right in world, v_axis = image bottom->top"""
    c, u, v = Vector(center), Vector(u_axis).normalized(), Vector(v_axis).normalized()
    bm = bmesh.new(); uvl = bm.loops.layers.uv.new()
    corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
    vs = [bm.verts.new(c + u * (cu * w / 2) + v * (cv * h / 2)) for cu, cv in corners]
    f = bm.faces.new(vs)
    for lp, (cu, cv) in zip(f.loops, corners): lp[uvl].uv = ((cu + 1) / 2, (cv + 1) / 2)
    m, nt, p = new_mat(name)
    t = node(nt, "ShaderNodeTexImage"); t.image = bpy.data.images.load(os.path.join(TEX, img))
    link(nt, t.outputs["Color"], p.inputs["Base Color"]); link(nt, t.outputs["Alpha"], p.inputs["Alpha"])
    p.inputs["Roughness"].default_value = rough
    o = obj_from_bm(name, bm, m)
    return o

# generator: lid overhang, door seams, handles, stickers, soot
box("GenLid", (GEN.x, GEN.y, 1.83), (1.33, 2.68, 0.06), M_GEN, bevel=0.02)
for dy in (-1.2, -0.05, 1.12):
    box(f"GenSeam{dy}", (GEN.x + 0.627, GEN.y + dy, 1.0), (0.006, 0.012, 1.45), M_DARKMETAL)
for dy in (0.15, 1.0):
    box(f"GenHandle{dy}", (GEN.x + 0.645, GEN.y + dy, 1.1), (0.03, 0.03, 0.16), M_DARKMETAL)
box("GenSticker", (GEN.x + 0.629, GEN.y + 0.62, 0.62), (0.004, 0.22, 0.14), plain("Sticker", (0.85, 0.65, 0.02), 0.5))
box("GenPlate", (GEN.x + 0.629, GEN.y + 0.9, 1.62), (0.004, 0.18, 0.07), plain("Plate", (0.6, 0.6, 0.58), 0.3, metallic=0.9))
decal("SignGen", "sign_gen.png", (GEN.x, GEN.y - 1.303, 1.18), (1, 0, 0), (0, 0, 1), 1.12, 0.49)
# soot streak above exhaust area on lid
box("Soot", (GEN.x - 0.2, GEN.y - 0.85, 1.863), (0.6, 0.5, 0.002), plain("SootM", (0.01, 0.01, 0.01), 0.9))
# danger sign on the board side facing camera
decal("SignDanger", "sign_danger.png", (BOARD.x, BOARD.y - 0.377, BOARD.z + 0.12), (1, 0, 0), (0, 0, 1), 0.2, 0.117)
# "for rent" on the nearest right-hand shutter
shut = sorted([o for o in bpy.data.objects if o.name.startswith("Shutter2") and not o.name.startswith("ShutterBox")],
              key=lambda o: abs(sum((o.matrix_world @ v.co).y for v in o.data.vertices) / 8 - 6))[0]
ys = [(shut.matrix_world @ v.co) for v in shut.data.vertices]
sy = sum(v.y for v in ys) / 8; sxx = min(v.x for v in ys)
decal("SignRent", "sign_rent.png", (sxx - 0.035, sy, 1.55), (0, -1, 0), (0, 0, 1), 1.6, 0.69, rough=0.4)

# oil spill with thin-film iridescence under/around the generator
m, nt, p = new_mat("Oil")
tc = node(nt, "ShaderNodeTexCoord")
nz = node(nt, "ShaderNodeTexNoise", **{"Scale": 1.4, "Detail": 6.0, "Roughness": 0.6})
link(nt, tc.outputs["Object"], nz.inputs["Vector"])
mr = node(nt, "ShaderNodeMapRange"); mr.inputs[1].default_value = 0.48; mr.inputs[2].default_value = 0.53
link(nt, nz.outputs["Fac"], mr.inputs[0]); link(nt, mr.outputs[0], p.inputs["Alpha"])
p.inputs["Base Color"].default_value = (0.005, 0.005, 0.005, 1); p.inputs["Roughness"].default_value = 0.02
if "Thin Film Thickness" in p.inputs:
    th = node(nt, "ShaderNodeMapRange"); th.inputs[3].default_value = 250; th.inputs[4].default_value = 750
    n2 = node(nt, "ShaderNodeTexNoise", **{"Scale": 6.0, "Detail": 4.0}); link(nt, tc.outputs["Object"], n2.inputs["Vector"])
    link(nt, n2.outputs["Fac"], th.inputs[0]); link(nt, th.outputs[0], p.inputs["Thin Film Thickness"])
    p.inputs["Thin Film IOR"].default_value = 1.5
bm = bmesh.new(); bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.5)
for v in bm.verts: v.co = Vector((v.co.x * 3.2 - 2.4, v.co.y * 4.5 + 7.6, 0.003))
obj_from_bm("OilSpill", bm, m)


# front radiator grille on the generator
for k in range(11):
    box(f"Grille{k}", (GEN.x, GEN.y - 1.31, 0.3 + k * 0.052), (1.0, 0.03, 0.022), M_DARKMETAL)
box("GrilleBack", (GEN.x, GEN.y - 1.29, 0.56), (1.02, 0.01, 0.6), plain("GrilleDark", (0.005, 0.005, 0.005), 0.6))
# wall clutter on the near-left facade: electricity meters, wire drops, old patches
lf = -W_FACE
for k, yy in enumerate((0.6, 1.5, 2.3)):
    box(f"Meter{k}", (lf + 0.08, yy, 1.85), (0.14, 0.32, 0.42), M_BOARD, bevel=0.01)
    box(f"MeterWin{k}", (lf + 0.152, yy, 1.95), (0.004, 0.16, 0.1), plain(f"MW{k}", (0.25, 0.3, 0.3), 0.05))
    wire(Vector((lf + 0.1, yy, 2.07)), Vector((lf + 0.05, yy + R.uniform(-0.4, 0.4), 6.6)), sag=0.03, n=8, r=0.007)
    wire(Vector((lf + 0.1, yy + 0.1, 1.64)), Vector((lf + 0.05, yy + 0.3, 0.2)), sag=0.05, n=8, r=0.006)
for k in range(9):   # bundles running along the facade
    z = 3.05 + k * 0.035
    wire(Vector((lf + 0.06, -4.0, z)), Vector((lf + 0.06, 9.5, z + R.uniform(-0.05, 0.05))), sag=R.uniform(0.04, 0.12), n=20, r=0.006)
for k in range(5):   # clamps
    box(f"Clamp{k}", (lf + 0.05, -3 + k * 2.6, 3.18), (0.04, 0.03, 0.36), M_DARKMETAL)
# repaired plaster patches
for k in range(6):
    box(f"Patch{k}", (lf + 0.005, R.uniform(-3.5, 2.8), R.uniform(0.5, 5.5)), (0.012, R.uniform(0.3, 1.1), R.uniform(0.2, 0.7)),
        concrete(f"PatchM{k}", (0.52, 0.5, 0.46), dirt=0.6, scale=2.0, streak=False))


# foreground wires very close to camera (defocused layer for depth)
for k, (y, z0, z1, sg) in enumerate(((2.2, 4.0, 4.5, 1.6), (3.4, 4.6, 4.2, 1.3), (1.2, 3.6, 3.9, 1.25), (4.6, 5.2, 4.9, 1.1))):
    wire(Vector((-W_FACE + 0.05, y, z0)), Vector((W_FACE - 0.05, y + R.uniform(-0.8, 0.8), z1)), sag=sg, r=0.009, n=30, mat=M_WIRE[0])

# ============================================================ CAMERA (anamorphic 2.39:1)
bpy.ops.object.camera_add(); cam = bpy.context.object; S.camera = cam
cam.location = (1.25, -4.2, 0.62)
target = Vector((-0.6, 20.0, 4.6))
cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam.rotation_euler.y += math.radians(-0.8)          # a whisper of dutch
cd = cam.data; cd.lens = 35; cd.sensor_fit = 'HORIZONTAL'; cd.sensor_width = 36
cd.clip_start = 0.05; cd.clip_end = 400
cd.dof.use_dof = True; cd.dof.focus_object = None
cd.dof.focus_distance = (Vector((GEN.x, GEN.y, 1.5)) - cam.location).length
cd.dof.aperture_fstop = 2.2
cd.dof.aperture_ratio = 0.5        # vertical oval bokeh (anamorphic)
cd.dof.aperture_blades = 0

# ============================================================ RENDER + COMPOSITOR
S.render.engine = 'CYCLES'; S.cycles.device = 'CPU'
S.cycles.use_adaptive_sampling = True; S.cycles.adaptive_threshold = 0.02
S.cycles.use_denoising = True; S.cycles.denoiser = 'OPENIMAGEDENOISE'
S.cycles.denoising_input_passes = 'RGB_ALBEDO_NORMAL'; S.cycles.denoising_prefilter = 'ACCURATE'
S.cycles.max_bounces = 6; S.cycles.diffuse_bounces = 3; S.cycles.glossy_bounces = 3
S.cycles.transmission_bounces = 4; S.cycles.volume_bounces = 1; S.cycles.transparent_max_bounces = 16
S.cycles.sample_clamp_indirect = 6.0; S.cycles.volume_step_rate = 1.5; S.cycles.volume_max_steps = 256
S.cycles.use_light_tree = True; S.cycles.caustics_reflective = False; S.cycles.caustics_refractive = False
S.render.film_transparent = False
S.view_settings.view_transform = 'AgX'; S.view_settings.look = 'AgX - Medium High Contrast'
S.view_settings.exposure = 0.0
S.render.image_settings.file_format = 'PNG'; S.render.image_settings.color_depth = '16'

def compositor():
    S.use_nodes = True
    nt = S.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    rl = nt.nodes.new("CompositorNodeRLayers")
    out = nt.nodes.new("CompositorNodeComposite")
    # anamorphic horizontal streak flare (blue-ish), plus soft bloom
    st = nt.nodes.new("CompositorNodeGlare"); st.glare_type = 'STREAKS'
    gl = nt.nodes.new("CompositorNodeGlare"); gl.glare_type = 'FOG_GLOW'
    def gset(n, **kw):
        for k, v in kw.items():
            if hasattr(n, k):
                try: setattr(n, k, v); continue
                except Exception: pass
            nm = {"threshold": "Threshold", "mix": "Strength", "streaks": "Streaks", "angle_offset": "Streaks Angle",
                  "fade": "Fade", "size": "Size", "quality": "Quality"}.get(k)
            if nm and nm in n.inputs:
                try: n.inputs[nm].default_value = v
                except Exception: pass
    gset(st, quality='HIGH', streaks=2, angle_offset=0.0, fade=0.965, threshold=1.6, mix=0.0)
    gset(gl, quality='HIGH', threshold=1.2, size=8, mix=0.0)
    link(nt, rl.outputs["Image"], st.inputs[0]); link(nt, rl.outputs["Image"], gl.inputs[0])
    # isolate the glare contributions, tint streaks blue, then add back at controlled strength
    sub1 = nt.nodes.new("CompositorNodeMixRGB"); sub1.blend_type = 'SUBTRACT'
    link(nt, st.outputs[0], sub1.inputs[1]); link(nt, rl.outputs["Image"], sub1.inputs[2])
    tint = nt.nodes.new("CompositorNodeMixRGB"); tint.blend_type = 'MULTIPLY'; tint.inputs[0].default_value = 1.0
    tint.inputs[2].default_value = (0.45, 0.7, 1.0, 1)
    link(nt, sub1.outputs[0], tint.inputs[1])
    sub2 = nt.nodes.new("CompositorNodeMixRGB"); sub2.blend_type = 'SUBTRACT'
    link(nt, gl.outputs[0], sub2.inputs[1]); link(nt, rl.outputs["Image"], sub2.inputs[2])
    a1 = nt.nodes.new("CompositorNodeMixRGB"); a1.blend_type = 'ADD'; a1.inputs[0].default_value = 0.55
    link(nt, rl.outputs["Image"], a1.inputs[1]); link(nt, tint.outputs[0], a1.inputs[2])
    a2 = nt.nodes.new("CompositorNodeMixRGB"); a2.blend_type = 'ADD'; a2.inputs[0].default_value = 0.35
    link(nt, a1.outputs[0], a2.inputs[1]); link(nt, sub2.outputs[0], a2.inputs[2])
    # subtle lens: barrel + chromatic dispersion
    ld = nt.nodes.new("CompositorNodeLensdist")
    if "Distort" in ld.inputs: ld.inputs["Distort"].default_value = -0.012
    if "Dispersion" in ld.inputs: ld.inputs["Dispersion"].default_value = 0.008
    link(nt, a2.outputs[0], ld.inputs[0])
    link(nt, ld.outputs[0], out.inputs[0])
compositor()

if MODE == "render":
    wd, ht, smp = int(argv[1]), int(argv[2]), int(argv[3]); outp = argv[4]
    S.render.resolution_x, S.render.resolution_y = wd, ht; S.render.resolution_percentage = 100
    S.cycles.samples = smp
    if len(argv) > 5 and argv[5] == 'border':
        x0, x1, y0, y1 = map(float, argv[6:10])
        S.render.use_border = True; S.render.use_crop_to_border = False
        S.render.border_min_x, S.render.border_max_x, S.render.border_min_y, S.render.border_max_y = x0, x1, y0, y1
    if len(argv) > 5 and argv[5] == 'nocomp':
        S.use_nodes = False
    S.render.filepath = outp
    bpy.ops.render.render(write_still=True)
elif MODE == "save":
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(argv[1]), compress=True)
