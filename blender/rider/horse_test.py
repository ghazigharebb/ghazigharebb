import bpy, os, sys, math, random
from mathutils import Vector
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
OUT = argv[0] if argv else "work/horse_test.png"
bpy.ops.wm.read_factory_settings(use_empty=True)
S = bpy.context.scene
bpy.ops.import_scene.gltf(filepath=os.path.abspath("dl_horse/Horse.glb"))
H = [o for o in bpy.data.objects if o.type == 'MESH'][0]; H.name = "Horse"
for o in list(bpy.data.objects):
    if o.type != 'MESH': bpy.data.objects.remove(o)
H.parent = None
H.scale = (0.0088, 0.0088, 0.0088)       # ~1.6 m at withers
bpy.context.view_layer.objects.active = H; H.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.object.shade_smooth()
if H.data.shape_keys: H.shape_key_clear()
me = H.data
zs = [v.co.z for v in me.vertices]; zmin = min(zs)
for v in me.vertices: v.co.z -= zmin
ys = [v.co.y for v in me.vertices]; ylen = max(ys) - min(ys); y0 = min(ys)

sub = H.modifiers.new("sub", 'SUBSURF'); sub.levels = 2; sub.render_levels = 3

# vertex groups: mane (top of neck), tail (rear), body (everything)
def vg(name, fn):
    g = H.vertex_groups.new(name=name)
    for v in me.vertices:
        w = fn(v.co)
        if w > 0: g.add([v.index], min(1.0, w), 'REPLACE')
    return g
ymax = max(ys); zmax = max(zs) - zmin
vg("mane", lambda c: 1.0 if (c.y > y0 + 0.66 * ylen and c.y < y0 + 0.93 * ylen and c.z > 1.15 and abs(c.x) < 0.06
                             and c.z > 1.15 + (c.y - (y0 + 0.66 * ylen)) * 0.9 - 0.05) else 0)
vg("tail", lambda c: 1.0 if c.y < y0 + 0.12 * ylen and c.z > 0.9 else 0)
vg("coat", lambda c: 1.0)

# material: black horse coat
m = bpy.data.materials.new("Coat"); m.use_nodes = True; nt = m.node_tree; p = nt.nodes["Principled BSDF"]
p.inputs["Base Color"].default_value = (0.012, 0.010, 0.009, 1); p.inputs["Roughness"].default_value = 0.38
p.inputs["Coat Weight"].default_value = 0.15; p.inputs["Sheen Weight"].default_value = 0.6
p.inputs["Sheen Roughness"].default_value = 0.35; p.inputs["Sheen Tint"].default_value = (0.6, 0.55, 0.5, 1)
tc = nt.nodes.new("ShaderNodeTexCoord"); nz = nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = 9; nz.inputs["Detail"].default_value = 12
nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
b = nt.nodes.new("ShaderNodeBump"); b.inputs["Strength"].default_value = 0.35; b.inputs["Distance"].default_value = 0.02
nt.links.new(nz.outputs["Fac"], b.inputs["Height"]); nt.links.new(b.outputs["Normal"], p.inputs["Normal"])
H.data.materials.append(m)
hm = bpy.data.materials.new("Hair"); hm.use_nodes = True; hnt = hm.node_tree
hnt.nodes.remove(hnt.nodes["Principled BSDF"])
ph = hnt.nodes.new("ShaderNodeBsdfHairPrincipled"); ph.parametrization = 'MELANIN'
ph.inputs["Melanin"].default_value = 0.95; ph.inputs["Roughness"].default_value = 0.28; ph.inputs["Radial Roughness"].default_value = 0.4
hnt.links.new(ph.outputs[0], hnt.nodes["Material Output"].inputs["Surface"])
H.data.materials.append(hm)

def hair(name, group, count, length, children, rough, clump, kink=0.0, along=(0, 0, 0), normal=1.0):
    mod = H.modifiers.new(name, 'PARTICLE_SYSTEM'); ps = mod.particle_system; st = ps.settings
    st.type = 'HAIR'; st.count = count; st.hair_length = length; st.use_advanced_hair = True
    st.normal_factor = normal; st.object_align_factor = along
    st.material_slot = "Hair"; st.display_step = 3; st.render_step = 5
    st.child_type = 'INTERPOLATED' if children else 'NONE'; st.rendered_child_count = children; st.child_percent = children
    st.roughness_1 = rough; st.roughness_2 = rough * 0.6; st.clump_factor = clump
    st.root_radius = 1.0; st.radius_scale = 0.0025 if length < 0.05 else 0.004
    if kink: st.kink = 'WAVE'; st.kink_amplitude = kink; st.kink_frequency = 3
    ps.vertex_group_density = group
    return st
hair("coatfur", "coat", 60000, 0.012, 6, 0.0006, 0.0, along=(0, -0.0026, -0.0008), normal=0.0009)
hair("mane", "mane", 1200, 0.32, 40, 0.012, 0.4, kink=0.008, along=(0, -0.05, 0.022), normal=0.045)
hair("tail", "tail", 900, 0.75, 60, 0.03, 0.5, kink=0.02, along=(0, -0.2, 0.044), normal=0.029)
# put the modifiers before subsurf? particles must come after subsurf for density on smooth surface
bpy.context.view_layer.objects.active = H
for mname in ("coatfur", "mane", "tail"):
    while H.modifiers.find(mname) < H.modifiers.find("sub"):
        bpy.ops.object.modifier_move_down(modifier=mname)

# ground + lights
bpy.ops.mesh.primitive_plane_add(size=60); g = bpy.context.object
gm = bpy.data.materials.new("Ground"); gm.use_nodes = True; gp = gm.node_tree.nodes["Principled BSDF"]
gp.inputs["Base Color"].default_value = (0.05, 0.022, 0.015, 1); gp.inputs["Roughness"].default_value = 0.95
g.data.materials.append(gm)
w = bpy.data.worlds.new("W"); S.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
# rim moon from behind, warm ember key from spearhead position
bpy.ops.object.light_add(type='AREA', location=(-2.5, -3.5, 4.0)); rim = bpy.context.object
rim.data.size = 2.0; rim.data.energy = 900; rim.data.color = (0.6, 0.72, 1.0)
rim.rotation_euler = (Vector((0, 0.5, 1.2)) - rim.location).to_track_quat('-Z', 'Y').to_euler()
bpy.ops.object.light_add(type='POINT', location=(0.55, 1.4, 2.9)); key = bpy.context.object
key.data.energy = 120; key.data.color = (1.0, 0.42, 0.12); key.data.shadow_soft_size = 0.05

bpy.ops.object.camera_add(location=(3.6, -2.2, 1.25)); cam = bpy.context.object; S.camera = cam
cam.rotation_euler = (Vector((0, 0.4, 1.1)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam.data.lens = 45
S.render.engine = 'CYCLES'; S.cycles.device = 'CPU'; S.cycles.samples = 48; S.cycles.use_denoising = True
S.render.resolution_x, S.render.resolution_y = 540, 675
S.view_settings.view_transform = 'AgX'; S.view_settings.look = 'AgX - Medium High Contrast'
S.render.filepath = os.path.abspath(OUT)
if not os.environ.get('DBG'): bpy.ops.render.render(write_still=True)
if os.environ.get("DBG"):
    print("DIMS", tuple(round(d,2) for d in H.dimensions))
    dg = bpy.context.evaluated_depsgraph_get(); he = H.evaluated_get(dg)
    for ps in he.particle_systems:
        if len(ps.particles):
            hk = ps.particles[0].hair_keys
            print("PS", ps.name, len(ps.particles), "len", round((hk[-1].co - hk[0].co).length, 3) if len(hk) else None)
