"""«سوار» — cloaked figure with an ember-hot spear, standing in darkness. Blender 4.5 / Cycles.
python standing.py -- sim                          (cloth sim -> work/cloak.blend cache mesh)
python standing.py -- render <w> <h> <samples> <out.png>
python standing.py -- save <out.blend>
"""
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['none']
MODE = argv[0]
HERE = os.path.dirname(os.path.abspath(__file__)) if '__file__' in globals() else os.getcwd()
R = random.Random(5)

bpy.ops.wm.read_factory_settings(use_empty=True)
S = bpy.context.scene; C = S.collection
def link(nt, a, b): nt.links.new(a, b)
def node(nt, t, **kw):
    n = nt.nodes.new(t)
    for k, v in kw.items():
        if k in n.inputs: n.inputs[k].default_value = v
        else: setattr(n, k, v)
    return n
def mnode(nt, op, a, b=None):
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

# ============================================================ BODY PROXY (skin modifier mannequin)
def skin_body():
    pts = {
        'pelvis': ((0, 0, 0.98), (0.17, 0.12)), 'spine': ((0, 0.0, 1.20), (0.15, 0.11)),
        'chest': ((0, 0.01, 1.38), (0.21, 0.13)), 'neck': ((0, 0.02, 1.58), (0.06, 0.06)),
        'head': ((0, 0.03, 1.66), (0.05, 0.05)), 'headtop': ((0, 0.03, 1.70), (0.04, 0.04)),
        'lsh': ((-0.235, 0, 1.46), (0.075, 0.07)), 'lel': ((-0.25, 0.02, 1.18), (0.05, 0.05)), 'lha': ((-0.24, 0.06, 0.92), (0.045, 0.04)),
        'rsh': ((0.235, 0, 1.46), (0.075, 0.07)), 'rel': ((0.29, 0.14, 1.22), (0.05, 0.05)), 'rwr': ((0.32, 0.36, 1.31), (0.04, 0.035)),
        'rha': ((0.33, 0.43, 1.32), (0.045, 0.045)),
        'lhip': ((-0.1, 0, 0.95), (0.085, 0.085)), 'lkn': ((-0.12, 0.03, 0.52), (0.06, 0.06)), 'lft': ((-0.13, 0.0, 0.07), (0.05, 0.05)),
        'lto': ((-0.14, 0.17, 0.04), (0.045, 0.035)),
        'rhip': ((0.1, 0, 0.95), (0.085, 0.085)), 'rkn': ((0.12, 0.05, 0.52), (0.06, 0.06)), 'rft': ((0.14, 0.02, 0.07), (0.05, 0.05)),
        'rto': ((0.16, 0.19, 0.04), (0.045, 0.035)),
    }
    edges = [('pelvis', 'spine'), ('spine', 'chest'), ('chest', 'neck'), ('neck', 'head'), ('head', 'headtop'),
             ('chest', 'lsh'), ('lsh', 'lel'), ('lel', 'lha'), ('chest', 'rsh'), ('rsh', 'rel'), ('rel', 'rwr'), ('rwr', 'rha'),
             ('pelvis', 'lhip'), ('lhip', 'lkn'), ('lkn', 'lft'), ('lft', 'lto'),
             ('pelvis', 'rhip'), ('rhip', 'rkn'), ('rkn', 'rft'), ('rft', 'rto')]
    names = list(pts)
    me = bpy.data.meshes.new("Body"); me.from_pydata([pts[n][0] for n in names], [(names.index(a), names.index(b)) for a, b in edges], [])
    o = bpy.data.objects.new("Body", me); C.objects.link(o)
    sk = o.modifiers.new("skin", 'SKIN')
    for i, n in enumerate(names):
        me.skin_vertices[0].data[i].radius = pts[n][1]
    me.skin_vertices[0].data[0].use_root = True
    s = o.modifiers.new("sub", 'SUBSURF'); s.levels = 3; s.render_levels = 3
    return o
body = skin_body()
bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1.0, location=(0, 0.035, 1.725))
HEAD = bpy.context.object; HEAD.name = 'Head'; HEAD.scale = (0.092, 0.108, 0.118); bpy.ops.object.shade_smooth()

# ============================================================ SPEAR
SPEAR_BASE = Vector((0.36, 0.47, 0.0)); SPEAR_TOP = Vector((0.33, 0.50, 2.55))
def spear():
    d = SPEAR_TOP - SPEAR_BASE
    # shaft: slightly irregular wooden pole
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.019, radius2=0.016, depth=d.length)
    for v in bm.verts:
        t = (v.co.z / d.length) + 0.5
        v.co.x += 0.004 * math.sin(t * 7.0) ; v.co.y += 0.003 * math.cos(t * 5.0)
    shaft = obj_from_bm("Shaft", bm)
    shaft.location = (SPEAR_BASE + SPEAR_TOP) / 2; shaft.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    sm = bpy.data.materials.new("Wood"); sm.use_nodes = True; nt = sm.node_tree; p = nt.nodes["Principled BSDF"]
    tc = node(nt, "ShaderNodeTexCoord"); mp = node(nt, "ShaderNodeMapping"); mp.inputs["Scale"].default_value = (40, 40, 1.2)
    link(nt, tc.outputs["Object"], mp.inputs["Vector"])
    w = node(nt, "ShaderNodeTexWave", wave_type='RINGS'); w.inputs["Scale"].default_value = 2.0; w.inputs["Distortion"].default_value = 8.0; w.inputs["Detail"].default_value = 6.0
    link(nt, mp.outputs[0], w.inputs["Vector"])
    cr = node(nt, "ShaderNodeValToRGB"); cr.color_ramp.elements[0].color = (0.06, 0.035, 0.018, 1); cr.color_ramp.elements[1].color = (0.16, 0.10, 0.055, 1)
    link(nt, w.outputs["Fac"], cr.inputs["Fac"]); link(nt, cr.outputs["Color"], p.inputs["Base Color"])
    p.inputs["Roughness"].default_value = 0.55
    b = node(nt, "ShaderNodeBump", **{"Strength": 0.4, "Distance": 0.002}); link(nt, w.outputs["Fac"], b.inputs["Height"]); link(nt, b.outputs["Normal"], p.inputs["Normal"])
    shaft.data.materials.append(sm)
    # leather wrap at the grip and below the head
    lm = bpy.data.materials.new("Leather"); lm.use_nodes = True; lp = lm.node_tree.nodes["Principled BSDF"]
    lp.inputs["Base Color"].default_value = (0.05, 0.03, 0.02, 1); lp.inputs["Roughness"].default_value = 0.6
    for z0, z1 in ((1.22, 1.42), (2.17, 2.25)):
        for k in range(int((z1 - z0) / 0.012)):
            z = z0 + k * 0.012
            bpy.ops.mesh.primitive_torus_add(major_radius=0.021, minor_radius=0.0045, major_segments=20, minor_segments=6,
                                             location=SPEAR_BASE.lerp(SPEAR_TOP, z / d.length))
            t = bpy.context.object; t.rotation_euler = (math.radians(R.uniform(-8, 8)), math.radians(R.uniform(-8, 8)), 0)
            t.data.materials.append(lm)
    # iron socket + leaf blade, heated: emission ramps from tip
    socket_z = 2.25
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=0.022, radius2=0.014, depth=0.1)
    sock = obj_from_bm("Socket", bm); sock.location = SPEAR_BASE.lerp(SPEAR_TOP, (socket_z + 0.05) / d.length)
    sock.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    # blade: lens-shaped leaf profile, extruded with a central ridge
    bm = bmesh.new(); prof = []
    L = 0.30; N = 24
    for i in range(N + 1):
        t = i / N; z = t * L
        wdt = 0.058 * math.sin(math.pi * t ** 0.62) * (1 - t ** 2.2)
        prof.append((z, wdt))
    ring = []
    for z, wdt in prof:
        ring.append([bm.verts.new((-wdt, 0, z)), bm.verts.new((0, 0.0045 * (1 - z / L) + 0.0008, z)),
                     bm.verts.new((wdt, 0, z)), bm.verts.new((0, -0.0045 * (1 - z / L) - 0.0008, z))])
    for a, b2 in zip(ring[:-1], ring[1:]):
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b2[(k + 1) % 4], b2[k]))
    blade = obj_from_bm("Blade", bm)
    blade.location = SPEAR_BASE.lerp(SPEAR_TOP, (socket_z + 0.1) / d.length) + Vector((0, 0, 0))
    q = d.to_track_quat('Z', 'Y')
    camp = Vector((2.75, -4.6, 1.15)); dn = d.normalized()
    to_cam = (camp - blade.location); to_cam = (to_cam - dn * to_cam.dot(dn)).normalized()
    nrm = q @ Vector((0, 1, 0))
    ang = math.atan2(dn.dot(nrm.cross(to_cam)), nrm.dot(to_cam)) - math.radians(38)
    blade.rotation_euler = (Matrix.Rotation(ang, 4, dn) @ q.to_matrix().to_4x4()).to_euler()
    blade.visible_shadow = False
    # hot iron material: blackbody emission strongest at the tip, cooling toward the socket
    hm = bpy.data.materials.new("HotIron"); hm.use_nodes = True; nt = hm.node_tree; p = nt.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (0.03, 0.028, 0.026, 1); p.inputs["Metallic"].default_value = 0.85; p.inputs["Roughness"].default_value = 0.45
    tc = node(nt, "ShaderNodeTexCoord"); sep = node(nt, "ShaderNodeSeparateXYZ"); link(nt, tc.outputs["Object"], sep.inputs[0])
    t = mnode(nt, 'DIVIDE', sep.outputs[2], L)                     # 0 at socket, 1 at tip
    nz = node(nt, "ShaderNodeTexNoise", **{"Scale": 60.0, "Detail": 10.0}); link(nt, tc.outputs["Object"], nz.inputs["Vector"])
    heat = mnode(nt, 'POWER', mnode(nt, 'MAXIMUM', mnode(nt, 'ADD', t, mnode(nt, 'MULTIPLY', mnode(nt, 'SUBTRACT', nz.outputs["Fac"], 0.5), 0.35)), 0.0), 1.6)
    bb = node(nt, "ShaderNodeBlackbody")
    link(nt, mnode(nt, 'ADD', 820.0, mnode(nt, 'MULTIPLY', heat, 460.0)), bb.inputs[0])
    link(nt, bb.outputs[0], p.inputs["Emission Color"])
    scale_n = node(nt, "ShaderNodeTexVoronoi", feature='F1'); scale_n.inputs["Scale"].default_value = 140.0
    link(nt, tc.outputs["Object"], scale_n.inputs["Vector"])
    oxide = node(nt, "ShaderNodeMapRange"); oxide.inputs[1].default_value = 0.25; oxide.inputs[2].default_value = 0.55; oxide.inputs[3].default_value = 0.25; oxide.inputs[4].default_value = 1.0
    link(nt, scale_n.outputs["Distance"], oxide.inputs[0])
    link(nt, mnode(nt, 'MULTIPLY', mnode(nt, 'MULTIPLY', mnode(nt, 'POWER', heat, 1.5), 1.5), oxide.outputs[0]), p.inputs["Emission Strength"])
    # scale/oxide flakes
    b = node(nt, "ShaderNodeBump", **{"Strength": 0.5, "Distance": 0.001}); link(nt, nz.outputs["Fac"], b.inputs["Height"]); link(nt, b.outputs["Normal"], p.inputs["Normal"])
    blade.data.materials.append(hm)
    im = bpy.data.materials.new("Iron"); im.use_nodes = True; ip = im.node_tree.nodes["Principled BSDF"]
    ip.inputs["Base Color"].default_value = (0.03, 0.028, 0.026, 1); ip.inputs["Metallic"].default_value = 0.9; ip.inputs["Roughness"].default_value = 0.5
    sock.data.materials.append(im)
    tip = SPEAR_BASE.lerp(SPEAR_TOP, (socket_z + 0.1 + L * 0.65) / d.length)
    return shaft, blade, tip
shaft, blade, TIP = spear()

# ============================================================ CLOAK (cloth simulated)
def cloak_mesh():
    NA, NR = 96, 120
    z_top, z_bot = 1.905, 0.02
    def radius(z):
        pts = [(1.905, 0.03), (1.895, 0.075), (1.865, 0.115), (1.81, 0.142), (1.75, 0.150), (1.68, 0.155), (1.60, 0.15), (1.54, 0.20), (1.47, 0.29), (1.38, 0.31), (1.2, 0.33), (0.9, 0.37), (0.5, 0.43), (0.02, 0.53)]
        for (za, ra), (zb, rb) in zip(pts[:-1], pts[1:]):
            if zb <= z <= za:
                t = (za - z) / (za - zb); return ra + (rb - ra) * t
        return pts[-1][1]
    bm = bmesh.new(); rows = []
    for j in range(NR + 1):
        z = z_top + (z_bot - z_top) * j / NR
        r = radius(z); row = []
        for i in range(NA):
            th = 2 * math.pi * i / NA
            row.append(bm.verts.new((r * math.cos(th), r * math.sin(th) + 0.02, z)))
        rows.append(row)
    def is_hole(zc, thc):
        deg = math.degrees(thc) % 360
        if 1.57 < zc < 1.79 and 66 < deg < 114: return True          # face opening of the hood
        if 1.10 < zc < 1.36 and 40 < deg < 60: return True           # opening the right arm reaches through
        if zc < 1.0 and 84 < deg < 92: return True                   # front split of the cloak
        return False
    for j in range(NR):
        for i in range(NA):
            zc = (rows[j][i].co.z + rows[j + 1][i].co.z) / 2; thc = 2 * math.pi * (i + 0.5) / NA
            if is_hole(zc, thc): continue
            bm.faces.new((rows[j][i], rows[j][(i + 1) % NA], rows[j + 1][(i + 1) % NA], rows[j + 1][i]))
    # cap the crown
    c = bm.verts.new((0, 0.02, z_top + 0.005))
    for i in range(NA): bm.faces.new((c, rows[0][(i + 1) % NA], rows[0][i]))
    for v in [v for v in bm.verts if not v.link_faces]: bm.verts.remove(v)
    o = obj_from_bm("Cloak", bm)
    pin = o.vertex_groups.new(name="pin")
    pin.add([v.index for v in o.data.vertices if 1.715 < v.co.z < 1.775 and v.co.y - 0.02 < 0.06], 1.0, 'REPLACE')
    return o

def wool_material():
    m = bpy.data.materials.new("Wool"); m.use_nodes = True; nt = m.node_tree; p = nt.nodes["Principled BSDF"]
    tc = node(nt, "ShaderNodeTexCoord")
    # large-scale tonal variation and wear
    n1 = node(nt, "ShaderNodeTexNoise", **{"Scale": 4.0, "Detail": 8.0, "Roughness": 0.6}); link(nt, tc.outputs["Object"], n1.inputs["Vector"])
    cr = node(nt, "ShaderNodeValToRGB"); cr.color_ramp.elements[0].color = (0.012, 0.011, 0.010, 1); cr.color_ramp.elements[1].color = (0.032, 0.027, 0.022, 1)
    link(nt, n1.outputs["Fac"], cr.inputs["Fac"])
    sepw = node(nt, "ShaderNodeSeparateXYZ"); link(nt, tc.outputs["Object"], sepw.inputs[0])
    hn = node(nt, "ShaderNodeTexNoise", **{"Scale": 14.0, "Detail": 8.0}); link(nt, tc.outputs["Object"], hn.inputs["Vector"])
    hem = node(nt, "ShaderNodeMapRange"); hem.inputs[1].default_value = 0.32; hem.inputs[2].default_value = 0.02
    link(nt, mnode(nt, 'ADD', sepw.outputs[2], mnode(nt, 'MULTIPLY', hn.outputs["Fac"], 0.12)), hem.inputs[0])
    dusty = node(nt, "ShaderNodeMix", data_type='RGBA'); dusty.inputs[7].default_value = (0.075, 0.042, 0.03, 1)
    link(nt, mnode(nt, 'MULTIPLY', hem.outputs[0], 0.85), dusty.inputs[0]); link(nt, cr.outputs["Color"], dusty.inputs[6])
    link(nt, dusty.outputs[2], p.inputs["Base Color"])
    p.inputs["Roughness"].default_value = 0.92
    p.inputs["Sheen Weight"].default_value = 0.7; p.inputs["Sheen Roughness"].default_value = 0.5; p.inputs["Sheen Tint"].default_value = (0.22, 0.2, 0.18, 1)
    # coarse weave + fibre fuzz
    mp = node(nt, "ShaderNodeMapping"); mp.inputs["Scale"].default_value = (260, 260, 260); link(nt, tc.outputs["Object"], mp.inputs["Vector"])
    w1 = node(nt, "ShaderNodeTexWave", wave_type='BANDS', bands_direction='X'); w1.inputs["Scale"].default_value = 1.0; w1.inputs["Distortion"].default_value = 0.6
    w2 = node(nt, "ShaderNodeTexWave", wave_type='BANDS', bands_direction='Z'); w2.inputs["Scale"].default_value = 1.0; w2.inputs["Distortion"].default_value = 0.6
    link(nt, mp.outputs[0], w1.inputs["Vector"]); link(nt, mp.outputs[0], w2.inputs["Vector"])
    weave = mnode(nt, 'MULTIPLY', w1.outputs["Fac"], w2.outputs["Fac"])
    fz = node(nt, "ShaderNodeTexNoise", **{"Scale": 900.0, "Detail": 4.0}); link(nt, tc.outputs["Object"], fz.inputs["Vector"])
    b1 = node(nt, "ShaderNodeBump", **{"Strength": 0.35, "Distance": 0.0008}); link(nt, weave, b1.inputs["Height"])
    b2 = node(nt, "ShaderNodeBump", **{"Strength": 0.4, "Distance": 0.0006}); link(nt, fz.outputs["Fac"], b2.inputs["Height"])
    link(nt, b1.outputs["Normal"], b2.inputs["Normal"]); link(nt, b2.outputs["Normal"], p.inputs["Normal"])
    return m

M_WOOL = wool_material()
M_SKIN = bpy.data.materials.new("Dark"); M_SKIN.use_nodes = True
M_SKIN.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.01, 0.008, 0.007, 1)
M_SKIN.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.7
body.data.materials.append(M_SKIN); HEAD.data.materials.append(M_SKIN)

CLOAK_CACHE = os.path.join(HERE, "work", "cloak_sim.obj")


# ============================================================ SLEEVE + GLOVED FIST ON THE SHAFT
def sleeve_and_hand():
    a = Vector((0.27, 0.15, 1.22)); b = Vector((0.33, 0.43, 1.315))      # elbow -> over the hand
    d = b - a; n = 28; m = 24
    bm = bmesh.new(); rows = []
    q = d.to_track_quat('Z', 'Y')
    for j in range(n + 1):
        t = j / n; c = a.lerp(b, t)
        r = 0.08 + 0.022 * t ** 2
        row = []
        for i in range(m):
            th = 2 * math.pi * i / m
            fold = 0.012 * math.sin(th * 3 + t * 9) + 0.008 * math.sin(th * 5 - t * 4)
            sag = -0.02 * (1 - abs(math.cos(th))) * t if math.sin(th) < 0 else 0
            v = Vector(((r + fold) * math.cos(th), (r + fold) * math.sin(th) + sag, 0))
            row.append(bm.verts.new(c + q @ v))
        rows.append(row)
    for j in range(n):
        for i in range(m):
            bm.faces.new((rows[j][i], rows[j][(i + 1) % m], rows[j + 1][(i + 1) % m], rows[j + 1][i]))
    sl = obj_from_bm("Sleeve", bm, M_WOOL)
    so = sl.modifiers.new("t", 'SOLIDIFY'); so.thickness = 0.008
    sd = sl.modifiers.new("s", 'SUBSURF'); sd.levels = 1; sd.render_levels = 2
    bpy.context.view_layer.objects.active = sl; bpy.ops.object.shade_smooth()
    gm = bpy.data.materials.new("Glove"); gm.use_nodes = True; gp = gm.node_tree.nodes["Principled BSDF"]
    gp.inputs["Base Color"].default_value = (0.008, 0.006, 0.005, 1); gp.inputs["Roughness"].default_value = 0.7
    gp.inputs["Coat Weight"].default_value = 0.2
    shaft_dir = (SPEAR_TOP - SPEAR_BASE).normalized()
    grip_z = 1.33
    c = SPEAR_BASE.lerp(SPEAR_TOP, grip_z / (SPEAR_TOP - SPEAR_BASE).length)
    side = Vector((-0.8, -0.6, 0)).normalized()     # palm sits on the body side of the shaft
    # palm
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.045, segments=20, ring_count=12, location=c + side * 0.035 + Vector((0, 0, 0.005)))
    palm = bpy.context.object; palm.scale = (0.75, 0.9, 1.15); palm.data.materials.append(gm); bpy.ops.object.shade_smooth()
    # four fingers wrapped around the shaft (stacked), knuckles toward the camera side
    for k in range(4):
        z = 0.03 - k * 0.021
        bpy.ops.mesh.primitive_torus_add(major_radius=0.027, minor_radius=0.0105 - k * 0.0007, major_segments=24, minor_segments=10,
                                         location=c + Vector((0, 0, z)))
        f = bpy.context.object; f.data.materials.append(gm)
        # keep ~70% of the ring (open toward the palm)
        bm = bmesh.new(); bm.from_mesh(f.data)
        ang0 = math.atan2(side.y, side.x)
        kill = [v for v in bm.verts if abs((math.atan2(v.co.y, v.co.x) - ang0 + math.pi) % (2 * math.pi) - math.pi) < 0.9]
        bmesh.ops.delete(bm, geom=kill, context='VERTS'); bm.to_mesh(f.data); bm.free()
        bpy.ops.object.shade_smooth()
    # thumb over the fingers
    cyl_a = c + side * 0.03 + Vector((0, 0, 0.055)); cyl_b = c + Vector((0.01, 0.02, 0.045)) - side * 0.025
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=0.012, radius2=0.010, depth=(cyl_b - cyl_a).length)
    th = obj_from_bm("Thumb", bm, gm); th.location = (cyl_a + cyl_b) / 2; th.rotation_euler = (cyl_b - cyl_a).to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.objects.active = th; bpy.ops.object.shade_smooth()
sleeve_and_hand()

# ============================================================ GROUND
def ground():
    bm = bmesh.new(); bmesh.ops.create_grid(bm, x_segments=260, y_segments=260, size=7.0)
    o = obj_from_bm("Ground", bm)
    sd = o.modifiers.new("sub", 'SUBSURF'); sd.subdivision_type = 'SIMPLE'; sd.levels = 1; sd.render_levels = 2
    d = o.modifiers.new("disp", 'DISPLACE'); t = bpy.data.textures.new("gt", 'CLOUDS'); t.noise_scale = 0.35; t.noise_depth = 4
    d.texture = t; d.strength = 0.05; d.texture_coords = 'GLOBAL'
    m = bpy.data.materials.new("Earth"); m.use_nodes = True; nt = m.node_tree; p = nt.nodes["Principled BSDF"]
    tc = node(nt, "ShaderNodeTexCoord")
    n1 = node(nt, "ShaderNodeTexNoise", **{"Scale": 1.2, "Detail": 10.0, "Roughness": 0.6}); link(nt, tc.outputs["Object"], n1.inputs["Vector"])
    cr = node(nt, "ShaderNodeValToRGB"); cr.color_ramp.elements[0].color = (0.030, 0.012, 0.007, 1); cr.color_ramp.elements[1].color = (0.085, 0.040, 0.024, 1)
    link(nt, n1.outputs["Fac"], cr.inputs["Fac"])
    # dry cracks
    vor = node(nt, "ShaderNodeTexVoronoi", feature='DISTANCE_TO_EDGE'); vor.inputs["Scale"].default_value = 2.2; vor.inputs["Randomness"].default_value = 1.0
    dn = node(nt, "ShaderNodeTexNoise", **{"Scale": 3.0, "Detail": 6.0}); link(nt, tc.outputs["Object"], dn.inputs["Vector"])
    dmx = node(nt, "ShaderNodeMix", data_type='VECTOR'); dmx.inputs[0].default_value = 0.35
    link(nt, tc.outputs["Object"], dmx.inputs[4]); link(nt, dn.outputs["Color"], dmx.inputs[5]); link(nt, dmx.outputs[1], vor.inputs["Vector"])
    crack = node(nt, "ShaderNodeMapRange"); crack.inputs[1].default_value = 0.0; crack.inputs[2].default_value = 0.008; crack.inputs[3].default_value = 0.45
    link(nt, vor.outputs["Distance"], crack.inputs[0])
    mix = node(nt, "ShaderNodeMix", data_type='RGBA', blend_type='MULTIPLY'); mix.inputs[0].default_value = 1.0
    link(nt, cr.outputs["Color"], mix.inputs[6]); link(nt, crack.outputs[0], mix.inputs[7])
    link(nt, mix.outputs[2], p.inputs["Base Color"])
    p.inputs["Roughness"].default_value = 0.96
    pebble = node(nt, "ShaderNodeTexVoronoi", feature='F1'); pebble.inputs["Scale"].default_value = 70.0; link(nt, tc.outputs["Object"], pebble.inputs["Vector"])
    fine = node(nt, "ShaderNodeTexNoise", **{"Scale": 300.0, "Detail": 6.0}); link(nt, tc.outputs["Object"], fine.inputs["Vector"])
    b1 = node(nt, "ShaderNodeBump", **{"Strength": 0.9, "Distance": 0.01}); link(nt, crack.outputs[0], b1.inputs["Height"])
    b2 = node(nt, "ShaderNodeBump", **{"Strength": 0.5, "Distance": 0.002}); link(nt, mnode(nt, 'SUBTRACT', 1.0, pebble.outputs["Distance"]), b2.inputs["Height"])
    b3 = node(nt, "ShaderNodeBump", **{"Strength": 0.4, "Distance": 0.001}); link(nt, fine.outputs["Fac"], b3.inputs["Height"])
    link(nt, b1.outputs["Normal"], b2.inputs["Normal"]); link(nt, b2.outputs["Normal"], b3.inputs["Normal"]); link(nt, b3.outputs["Normal"], p.inputs["Normal"])
    o.data.materials.append(m)
    return o, m
G, M_EARTH = ground()
# stones
for k in range(160):
    rr = R.uniform(0.01, 0.06) * (1 if R.random() < 0.9 else 2.2)
    a = R.uniform(0, 6.28); dist = R.uniform(0.4, 6.0)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=rr, location=(math.cos(a) * dist, math.sin(a) * dist + 1.0, rr * 0.25))
    st = bpy.context.object; st.scale = (1, R.uniform(0.6, 1.2), R.uniform(0.4, 0.8)); st.rotation_euler.z = R.uniform(0, 6.28)
    dd = st.modifiers.new("d", 'DISPLACE'); tt = bpy.data.textures.new("st", 'VORONOI'); tt.noise_scale = rr * 0.8; dd.texture = tt; dd.strength = rr * 0.3
    st.data.materials.append(M_EARTH)
# dry grass tufts (hair on small patches)
gm = bpy.data.materials.new("DryGrass"); gm.use_nodes = True; gnt = gm.node_tree; gnt.nodes.remove(gnt.nodes["Principled BSDF"])
ph = gnt.nodes.new("ShaderNodeBsdfHairPrincipled"); ph.parametrization = 'MELANIN'; ph.inputs["Melanin"].default_value = 0.45
ph.inputs["Melanin Redness"].default_value = 0.6; ph.inputs["Roughness"].default_value = 0.5
link(gnt, ph.outputs[0], gnt.nodes["Material Output"].inputs["Surface"])
for k in range(22):
    a = R.uniform(0, 6.28); dist = R.uniform(1.0, 5.5)
    bpy.ops.mesh.primitive_circle_add(vertices=10, radius=R.uniform(0.06, 0.18), fill_type='NGON', location=(math.cos(a) * dist, math.sin(a) * dist + 1.0, 0.0))
    tf = bpy.context.object; tf.data.materials.append(gm)
    pm = tf.modifiers.new("g", 'PARTICLE_SYSTEM'); st = pm.particle_system.settings
    st.type = 'HAIR'; st.count = R.randint(60, 160); st.use_advanced_hair = True
    st.normal_factor = R.uniform(0.03, 0.07); st.factor_random = 0.02; st.brownian_factor = 0.0
    st.root_radius = 1.0; st.radius_scale = 0.0012; st.roughness_endpoint = 0.04; st.roughness_end_shape = 0.6
    st.child_type = 'NONE'; st.render_step = 4
    tf.show_instancer_for_render = False

# ============================================================ EMBERS + DUST
em_mat = bpy.data.materials.new("Ember"); em_mat.use_nodes = True; ent = em_mat.node_tree; ent.nodes.remove(ent.nodes["Principled BSDF"])
ee = ent.nodes.new("ShaderNodeEmission"); bb = ent.nodes.new("ShaderNodeBlackbody"); bb.inputs[0].default_value = 1500
link(ent, bb.outputs[0], ee.inputs["Color"]); ee.inputs["Strength"].default_value = 28
link(ent, ee.outputs[0], ent.nodes["Material Output"].inputs["Surface"])
RE = random.Random(9)
for k in range(34):
    # embers rise from the tip and drift with a light breeze to the left, cooling as they go
    h = RE.random() ** 1.5
    pos = TIP + Vector((-0.9 * h + RE.gauss(0, 0.12 + 0.3 * h), RE.gauss(0, 0.12 + 0.25 * h), 1.6 * h + RE.uniform(-0.05, 0.1)))
    L = RE.uniform(0.006, 0.03)
    dirv = Vector((-0.5 + RE.gauss(0, 0.3), RE.gauss(0, 0.3), 1.0)).normalized()
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.0012, radius2=0.0004, depth=L)
    e = obj_from_bm("Ember", bm, em_mat); e.location = pos; e.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    e.visible_shadow = False
dust_m = bpy.data.materials.new("Dust"); dust_m.use_nodes = True
dp = dust_m.node_tree.nodes["Principled BSDF"]; dp.inputs["Base Color"].default_value = (0.6, 0.55, 0.5, 1); dp.inputs["Roughness"].default_value = 1.0
bm = bmesh.new()
for k in range(900):
    p = Vector((RE.uniform(-1.6, 1.8), RE.uniform(-1.8, 2.2), RE.uniform(0.2, 3.2)))
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=RE.uniform(0.0006, 0.0015), matrix=Matrix.Translation(p))
dust = obj_from_bm("DustMotes", bm, dust_m); dust.visible_shadow = False

# ============================================================ LIGHT, ATMOSPHERE, WORLD
bpy.ops.object.light_add(type='POINT', location=TIP); kl = bpy.context.object; kl.name = "TipLight"
kl.data.energy = 70; kl.data.color = (1.0, 0.45, 0.14); kl.data.shadow_soft_size = 0.08
bpy.ops.object.light_add(type='SPOT', location=(-1.6, 3.4, 5.6)); rim = bpy.context.object; rim.name = "MoonRim"
rim.data.spot_size = math.radians(50); rim.data.spot_blend = 1.0; rim.data.shadow_soft_size = 0.6; rim.data.energy = 1500; rim.data.color = (0.55, 0.68, 1.0)
rim.rotation_euler = (Vector((0, 0, 1.3)) - rim.location).to_track_quat('-Z', 'Y').to_euler()
w = bpy.data.worlds.new("W"); S.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.0006, 0.0007, 0.001, 1)
fm = bpy.data.materials.new("Haze"); fm.use_nodes = True; fnt = fm.node_tree; fnt.nodes.remove(fnt.nodes["Principled BSDF"])
vp = fnt.nodes.new("ShaderNodeVolumePrincipled"); vp.inputs["Density"].default_value = 0.012; vp.inputs["Anisotropy"].default_value = 0.6
link(fnt, vp.outputs[0], fnt.nodes["Material Output"].inputs["Volume"])
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 1.0, 3.0)); haze = bpy.context.object; haze.name = "Haze"
haze.scale = (14, 14, 6); haze.data.materials.append(fm); haze.visible_shadow = False

# ============================================================ CAMERA (4:5)
bpy.ops.object.camera_add(); cam = bpy.context.object; S.camera = cam
cam.location = (2.75, -4.6, 1.15)
look = Vector((0.3, 0.25, 1.36))
cam.rotation_euler = (look - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam.data.lens = 50; cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 36
cam.data.dof.use_dof = True; cam.data.dof.focus_distance = (Vector((0, 0.1, 1.4)) - cam.location).length; cam.data.dof.aperture_fstop = 2.0
cam.data.clip_start = 0.05

S.render.engine = 'CYCLES'; S.cycles.device = 'CPU'
S.cycles.use_adaptive_sampling = True; S.cycles.adaptive_threshold = 0.015
S.cycles.use_denoising = True; S.cycles.denoiser = 'OPENIMAGEDENOISE'
S.cycles.denoising_input_passes = 'RGB_ALBEDO_NORMAL'; S.cycles.denoising_prefilter = 'ACCURATE'
S.cycles.max_bounces = 8; S.cycles.volume_bounces = 1; S.cycles.sample_clamp_indirect = 8
S.cycles.volume_step_rate = 1.0; S.cycles.use_light_tree = True
S.view_settings.view_transform = 'AgX'; S.view_settings.look = 'AgX - Medium High Contrast'
S.render.image_settings.file_format = 'PNG'; S.render.image_settings.color_depth = '16'

def build_cloak():
    if os.path.exists(CLOAK_CACHE):
        bpy.ops.wm.obj_import(filepath=CLOAK_CACHE, forward_axis='Y', up_axis='Z')
        o = bpy.context.selected_objects[0]; o.name = "Cloak"
        o.data.materials.clear()
    else:
        o = cloak_mesh()
    o.data.materials.append(M_WOOL)
    bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.shade_smooth()
    # heavy-wool vertical folds, growing toward the hem
    fg = o.vertex_groups.new(name="folds")
    for v in o.data.vertices:
        w = max(0.0, min(1.0, (1.45 - v.co.z) / 1.4)) ** 0.8
        if w > 0: fg.add([v.index], w, 'REPLACE')
    ft = bpy.data.textures.new("folds", 'CLOUDS'); ft.noise_scale = 0.16; ft.noise_depth = 3
    em = bpy.data.objects.new("FoldSpace", None); C.objects.link(em); em.scale = (1.0, 1.0, 4.0)
    dm = o.modifiers.new("folds", 'DISPLACE'); dm.texture = ft; dm.texture_coords = 'OBJECT'; dm.texture_coords_object = em
    dm.strength = 0.085; dm.mid_level = 0.5; dm.vertex_group = "folds"
    so = o.modifiers.new("thick", 'SOLIDIFY'); so.thickness = 0.008; so.offset = 0
    sd = o.modifiers.new("sub", 'SUBSURF'); sd.levels = 1; sd.render_levels = 2
    return o

if MODE == "sim":
    o = cloak_mesh()
    for ob in (body, G, shaft, HEAD):
        ob.modifiers.new("col", 'COLLISION'); ob.collision.thickness_outer = 0.012; ob.collision.cloth_friction = 8.0
    cm = o.modifiers.new("Cloth", 'CLOTH'); cs = cm.settings
    cs.quality = 12; cs.mass = 0.55; cs.air_damping = 1.0; cs.shrink_min = -0.11
    cs.tension_stiffness = 10; cs.compression_stiffness = 10; cs.shear_stiffness = 3; cs.bending_stiffness = 0.12
    cs.vertex_group_mass = "pin"; cs.pin_stiffness = 1.0
    cc = cm.collision_settings; cc.distance_min = 0.006; cc.use_self_collision = True; cc.self_distance_min = 0.005; cc.collision_quality = 3
    cm.point_cache.frame_start = 1; cm.point_cache.frame_end = 130
    bpy.ops.object.effector_add(type='WIND', location=(-3, 2, 1)); wd_ = bpy.context.object
    wd_.rotation_euler = (0, math.radians(90), math.radians(-25)); wd_.field.strength = 18; wd_.field.noise = 1.5
    import time; t0 = time.time()
    for f in range(1, 131):
        S.frame_set(f)
        if f % 10 == 0: print("SIM", f, round(time.time() - t0, 1), flush=True)
    dg = bpy.context.evaluated_depsgraph_get(); oe = o.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(oe)
    tmp = bpy.data.objects.new("CloakSim", me); C.objects.link(tmp)
    for ob in bpy.context.selected_objects: ob.select_set(False)
    tmp.select_set(True); bpy.context.view_layer.objects.active = tmp
    os.makedirs(os.path.dirname(CLOAK_CACHE), exist_ok=True)
    bpy.ops.wm.obj_export(filepath=CLOAK_CACHE, export_selected_objects=True, export_materials=False, forward_axis='Y', up_axis='Z')
    print("cloak cached", CLOAK_CACHE)
elif MODE in ("render", "save"):
    build_cloak()
    if MODE == "render":
        wd, ht, smp = int(argv[1]), int(argv[2]), int(argv[3])
        S.render.resolution_x, S.render.resolution_y = wd, ht; S.cycles.samples = smp
        S.render.filepath = os.path.abspath(argv[4])
        if len(argv) > 5 and argv[5] == 'border':
            x0, x1, y0, y1 = map(float, argv[6:10]); S.render.use_border = True; S.render.use_crop_to_border = False
            S.render.border_min_x, S.render.border_max_x, S.render.border_min_y, S.render.border_max_y = x0, x1, y0, y1
        bpy.ops.render.render(write_still=True)
    else:
        bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(argv[1]), compress=True)
if MODE == "pindbg":
    o = cloak_mesh(); g = o.vertex_groups["pin"]
    idx = [v.index for v in o.data.vertices if any(gr.group == g.index for gr in v.groups)]
    print("PIN", len(idx), "of", len(o.data.vertices), "zmax", round(max(v.co.z for v in o.data.vertices), 3))
    cm = o.modifiers.new("Cloth", 'CLOTH'); print("ATTRS", [a for a in dir(cm.settings) if 'pin' in a or 'group' in a])
if MODE == "bladedbg":
    bpy.context.view_layer.update()
    mw = blade.matrix_world; nrm = (mw.to_3x3() @ Vector((0, 1, 0))).normalized(); wid = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
    tc_ = (cam.location - blade.matrix_world.translation).normalized()
    print("BLADE normal.dot(tocam)", round(nrm.dot(tc_), 3), "width.dot(tocam)", round(wid.dot(tc_), 3))
