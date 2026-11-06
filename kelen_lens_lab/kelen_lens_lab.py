# Kelen Lens Lab — cinematic lens looks for Blender 5.x (Cycles)
# Optical lenses are real camera models (OSL custom camera): swirl bokeh, cat's-eye,
# anamorphic ovals, field curvature, barrel/fisheye distortion.
# Finishing is a compositor stack: bloom, halation, anamorphic streaks, chromatic
# aberration, prism halo/kaleido, dream spot, vignette and animated film grain.

bl_info = {
    "name": "Kelen Lens Lab",
    "author": "Kelen Studio",
    "version": (1, 0, 0),
    "blender": (5, 0, 0),
    "location": "3D View > Sidebar (N) > Lens",
    "description": "Cinematic lens looks: swirl, anamorphic, Petzval, prism, dream spot + film finishing",
    "category": "Camera",
}

import bpy
from bpy.props import (EnumProperty, FloatProperty, PointerProperty, BoolProperty)

LENSES = [
    ('CLEAN', "Clean", "Modern sharp lens with round bokeh"),
    ('ANAMORPHIC', "Anamorphic", "Oval bokeh, horizontal blue streaks, slight barrel"),
    ('SWIRL', "Swirl", "Vintage swirly bokeh (cat's-eye + tangential stretch)"),
    ('PETZVAL', "Petzval Vortex", "Strong swirl with soft, curved focus field"),
    ('DREAM', "Dream Field", "Sharp centre, edges melt out of focus (field curvature)"),
    ('FISHEYE', "Fisheye", "Strong barrel distortion"),
    ('PRISM_HALO', "Prism Halo", "Mirrored glowing copies around the frame edge"),
    ('PRISM_KALEIDO', "Prism Kaleido", "Kaleidoscopic prism reflections"),
    ('DREAM_SPOT', "Dream Spot", "Glowing centre spot, everything else drifts away"),
]

# ------------------------------------------------------------------ optics (OSL camera)
OSL_TEMPLATE = r'''
shader camera(output point position = 0.0, output vector direction = 0.0, output color throughput = 1.0)
{
  float focal_length = %(fl)f;
  float ap_radius = %(apr)f;   // metres
  float apn = %(apn)f;         // aperture radius in focal-length units = 1 / (2 N)
  float squeeze = %(squeeze)f; // <1: oval (anamorphic) bokeh
  float swirl = %(swirl)f;     // cat's-eye + tangential stretch
  float curvature = %(curv)f;  // field curvature (edges defocus)
  float barrel = %(barrel)f;   // <0 barrel, >0 pincushion
  int use_dof = %(dof)d;

  point Pr = camera_shader_raster_position() - vector(0.5);
  vector sensor; getattribute("cam:sensor_size", sensor);
  vector q = vector(Pr[0] * sensor[0], Pr[1] * sensor[1], 0.0);
  float rn = length(q) / (0.5 * length(vector(sensor[0], sensor[1], 0.0)));   // 0 centre .. 1 corner
  vector ru = rn > 1e-5 ? normalize(q) : vector(1, 0, 0);
  vector tu = vector(-ru[1], ru[0], 0.0);

  point Pc = q / focal_length;
  Pc *= (1.0 + barrel * rn * rn);
  direction = normalize(vector(Pc[0], Pc[1], 1.0));
  if (!use_dof) return;

  vector ap; getattribute("cam:aperture_position", ap);
  vector s = ap / max(apn, 1e-6);                        // unit-disk sample (ap is in focal-length units)
  if (swirl > 0.0) {
    // cat's-eye: second (exit pupil) disk slides outward with field position
    vector off = ru * rn * swirl * 0.85;
    if (length(s + off) > 1.0) { throughput = color(0.0); return; }
    float sr = dot(s, ru), st = dot(s, tu);
    s = ru * sr * (1.0 - 0.35 * swirl * rn) + tu * st * (1.0 + 0.45 * swirl * rn);
  }
  s[0] *= squeeze;
  position = s * ap_radius;

  float fd; getattribute("cam:focal_distance", fd);
  fd = fd / (1.0 + curvature * rn * rn);
  point Pf = direction * fd / direction[2];
  direction = normalize(Pf - position);
}
'''

OPTICS = {   # squeeze, swirl, curvature, barrel
    'CLEAN': (1.0, 0.0, 0.0, 0.0),
    'ANAMORPHIC': (0.5, 0.0, 0.05, -0.05),
    'SWIRL': (1.0, 0.75, 0.15, 0.0),
    'PETZVAL': (1.0, 1.0, 0.6, 0.02),
    'DREAM': (1.0, 0.2, 1.4, 0.0),
    'FISHEYE': (1.0, 0.1, 0.1, -0.45),
    'PRISM_HALO': (1.0, 0.25, 0.1, 0.0),
    'PRISM_KALEIDO': (1.0, 0.25, 0.1, 0.0),
    'DREAM_SPOT': (1.0, 0.4, 0.8, 0.0),
}


def apply_optics(cam_obj, s):
    cam = cam_obj.data
    sq, sw, cv, br = OPTICS[s.lens]
    k = s.strength
    sq = 1.0 - (1.0 - sq) * min(k, 1.5)
    if s.focus_object:
        cam.dof.focus_object = s.focus_object
    cam.dof.use_dof = True
    cam.dof.aperture_fstop = s.fstop
    src = OSL_TEMPLATE % dict(fl=cam.lens, apr=cam.lens * 1e-3 / (2.0 * s.fstop), apn=0.5 / s.fstop, squeeze=sq,
                              swirl=sw * k, curv=cv * k, barrel=br * k, dof=1)
    name = "KelenLens.osl"
    txt = bpy.data.texts.get(name) or bpy.data.texts.new(name)
    txt.clear(); txt.write(src)
    import cycles.osl as cosl
    msgs = []
    ok, _oso, bytecode, h = cosl.update_internal_script(lambda t, m: msgs.append(m), txt)
    if not ok or not bytecode:
        raise RuntimeError("OSL compile failed: " + " ".join(msgs))
    cam.type = 'CUSTOM'
    cam.custom_mode = 'INTERNAL'
    cam.custom_shader = txt
    cam.custom_bytecode = bytecode
    cam.custom_bytecode_hash = h
    cam.update_tag()


def remove_optics(cam_obj):
    cam_obj.data.type = 'PERSP'


# ------------------------------------------------------------------ finishing (compositor)
def _n(tree, t, x, y, **inputs):
    n = tree.nodes.new(t); n.location = (x, y)
    for k, v in inputs.items():
        n.inputs[k].default_value = v
    return n


def _mix(tree, x, y, blend, fac, a, b, a_out='Image', b_out='Image'):
    m = tree.nodes.new('ShaderNodeMix'); m.location = (x, y)
    m.data_type = 'RGBA'; m.blend_type = blend; m.clamp_result = False
    m.inputs['Factor'].default_value = fac
    tree.links.new(a.outputs[a_out], m.inputs['A'])
    tree.links.new(b.outputs[b_out], m.inputs['B'])
    return m


def build_finishing(scene, s):
    name = "Kelen Lens Finishing"
    tree = bpy.data.node_groups.get(name)
    if tree:
        bpy.data.node_groups.remove(tree)
    tree = bpy.data.node_groups.new(name, 'CompositorNodeTree')
    tree.interface.new_socket('Image', in_out='OUTPUT', socket_type='NodeSocketColor')
    scene.compositing_node_group = tree
    L = tree.links.new
    x = 0
    cur = _n(tree, 'CompositorNodeRLayers', x, 0); out = 'Image'
    base = cur

    def step(node, inp='Image', o='Image'):
        nonlocal cur, out, x
        L(cur.outputs[out], node.inputs[inp]); cur, out = node, o

    # prism effects: mirrored, blurred copies screened onto the frame edges
    if s.lens in ('PRISM_HALO', 'PRISM_KALEIDO'):
        x += 220
        kal = s.lens == 'PRISM_KALEIDO'
        fl = _n(tree, 'CompositorNodeFlip', x, -300, **{'Flip X': True, 'Flip Y': kal})
        L(base.outputs['Image'], fl.inputs['Image'])
        tr = _n(tree, 'CompositorNodeTransform', x + 200, -300, Scale=1.35 if kal else 1.18, Angle=0.6 if kal else 0.0)
        L(fl.outputs['Image'], tr.inputs['Image'])
        bl = _n(tree, 'CompositorNodeBlur', x + 400, -300, Size=(40.0, 40.0))
        L(tr.outputs['Image'], bl.inputs['Image'])
        em = _n(tree, 'CompositorNodeEllipseMask', x + 400, -550, Position=(0.5, 0.5), Size=(0.62, 0.62))
        eb = _n(tree, 'CompositorNodeBlur', x + 600, -550, Size=(140.0, 140.0))
        L(em.outputs['Mask'], eb.inputs['Image'])
        edge = tree.nodes.new('ShaderNodeMath'); edge.operation = 'MULTIPLY_ADD'; edge.location = (x + 800, -550)
        edge.inputs[1].default_value = -s.prism * (1.4 if kal else 1.0)     # (1 - mask) * prism
        edge.inputs[2].default_value = s.prism * (1.4 if kal else 1.0)
        L(eb.outputs['Image'], edge.inputs[0])
        scr = _mix(tree, x + 800, -200, 'SCREEN', 1.0, cur, bl, out)
        m2 = edge
        L(m2.outputs[0], scr.inputs['Factor'])
        if kal:
            fl2 = _n(tree, 'CompositorNodeFlip', x, -800, **{'Flip X': False, 'Flip Y': True})
            L(base.outputs['Image'], fl2.inputs['Image'])
            bl2 = _n(tree, 'CompositorNodeBlur', x + 200, -800, Size=(25.0, 25.0))
            L(fl2.outputs['Image'], bl2.inputs['Image'])
            scr2 = _mix(tree, x + 1000, -200, 'SCREEN', 1.0, scr, bl2, 'Result')
            L(m2.outputs[0], scr2.inputs['Factor'])
            cur, out = scr2, 'Result'
        else:
            cur, out = scr, 'Result'
        x += 1200

    if s.lens == 'DREAM_SPOT':
        x += 220
        bl = _n(tree, 'CompositorNodeBlur', x, -300, Size=(60.0, 60.0))
        L(cur.outputs[out], bl.inputs['Image'])
        em = _n(tree, 'CompositorNodeEllipseMask', x, -550, Position=(0.5, 0.48), Size=(0.42, 0.5))
        eb = _n(tree, 'CompositorNodeBlur', x + 200, -550, Size=(180.0, 180.0))
        L(em.outputs['Mask'], eb.inputs['Image'])
        m = _mix(tree, x + 400, -100, 'MIX', 1.0, bl, cur, 'Image', out)
        L(eb.outputs['Image'], m.inputs['Factor'])
        cur, out = m, 'Result'; x += 600

    # chromatic aberration (+ optional extra distortion)
    if s.aberration > 0:
        x += 220
        ld = _n(tree, 'CompositorNodeLensdist', x, 0, Dispersion=s.aberration * 0.06, Distortion=0.0, Jitter=True)
        step(ld)

    # bloom
    if s.bloom > 0:
        x += 220
        g = _n(tree, 'CompositorNodeGlare', x, 0, Type='Bloom', Threshold=0.8, Strength=s.bloom, Size=0.85, Smoothness=0.4)
        step(g)

    # halation: red-orange glow bleeding from highlights (film emulsion look)
    if s.halation > 0:
        x += 220
        g = _n(tree, 'CompositorNodeGlare', x, -250, Type='Bloom', Threshold=1.0, Strength=1.0, Size=0.6, Smoothness=0.7,
               Tint=(1.0, 0.25, 0.08, 1.0), Saturation=1.0)
        L(cur.outputs[out], g.inputs['Image'])
        m = _mix(tree, x + 200, 0, 'ADD', s.halation, cur, g, out, 'Glare')
        cur, out = m, 'Result'; x += 200

    # anamorphic streaks
    streak = s.streaks if s.lens != 'ANAMORPHIC' else max(s.streaks, 0.6)
    if streak > 0:
        x += 220
        g = _n(tree, 'CompositorNodeGlare', x, -250, Type='Streaks', Threshold=4.0, Strength=1.0, Streaks=2,
               **{'Streaks Angle': 0.0}, Fade=0.96, Tint=(0.35, 0.6, 1.0, 1.0))
        L(cur.outputs[out], g.inputs['Image'])
        m = _mix(tree, x + 200, 0, 'ADD', streak * 0.6, cur, g, out, 'Glare')
        cur, out = m, 'Result'; x += 200

    # vignette
    if s.vignette > 0:
        x += 220
        em = _n(tree, 'CompositorNodeEllipseMask', x, -300, Position=(0.5, 0.5), Size=(1.05, 1.05))
        eb = _n(tree, 'CompositorNodeBlur', x + 200, -300, Size=(320.0, 320.0))
        L(em.outputs['Mask'], eb.inputs['Image'])
        mul = _mix(tree, x + 400, 0, 'MULTIPLY', s.vignette, cur, eb, out, 'Image')
        cur, out = mul, 'Result'; x += 400

    # animated film grain
    if s.grain > 0:
        x += 220
        ic = _n(tree, 'CompositorNodeImageCoordinates', x, -300)
        L(base.outputs['Image'], ic.inputs['Image'])
        st = tree.nodes.new('CompositorNodeSceneTime'); st.location = (x, -500)
        nz = tree.nodes.new('ShaderNodeTexNoise'); nz.location = (x + 200, -300); nz.noise_dimensions = '4D'
        nz.inputs['Scale'].default_value = 0.9; nz.inputs['Detail'].default_value = 0.0
        L(ic.outputs['Pixel'], nz.inputs['Vector']); L(st.outputs['Frame'], nz.inputs['W'])
        m = _mix(tree, x + 400, 0, 'OVERLAY', s.grain * 0.45, cur, nz, out, 'Fac')
        cur, out = m, 'Result'; x += 400

    go = tree.nodes.new('NodeGroupOutput'); go.location = (x + 250, 0)
    L(cur.outputs[out], go.inputs[0])
    return tree


def apply_all(scene, s, cam_obj=None):
    cam_obj = cam_obj or scene.camera
    if scene.render.engine != 'CYCLES':
        scene.render.engine = 'CYCLES'
    if s.use_optics:
        apply_optics(cam_obj, s)
    else:
        remove_optics(cam_obj)
    build_finishing(scene, s)


# ------------------------------------------------------------------ UI
class KelenLensSettings(bpy.types.PropertyGroup):
    lens: EnumProperty(name="Lens", items=LENSES, default='SWIRL')
    strength: FloatProperty(name="Character", default=1.0, min=0.0, max=2.0, description="How strong the lens character is")
    use_optics: BoolProperty(name="Optical Lens (Cycles)", default=True, description="Real lens model on the camera (needs Cycles)")
    fstop: FloatProperty(name="F-Stop", default=1.4, min=0.7, max=22.0)
    focus_object: PointerProperty(name="Focus", type=bpy.types.Object)
    bloom: FloatProperty(name="Bloom", default=0.5, min=0.0, max=3.0)
    halation: FloatProperty(name="Halation", default=0.35, min=0.0, max=2.0)
    streaks: FloatProperty(name="Streaks", default=0.0, min=0.0, max=2.0)
    aberration: FloatProperty(name="Chromatic Aberration", default=0.25, min=0.0, max=2.0)
    prism: FloatProperty(name="Prism Amount", default=0.6, min=0.0, max=2.0)
    vignette: FloatProperty(name="Vignette", default=0.35, min=0.0, max=1.0)
    grain: FloatProperty(name="Film Grain", default=0.35, min=0.0, max=1.5)


class KELEN_OT_apply_lens(bpy.types.Operator):
    bl_idname = "kelen.apply_lens"
    bl_label = "Apply Lens"
    bl_description = "Put the chosen lens on the active camera and build the finishing stack"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        if not context.scene.camera:
            self.report({'ERROR'}, "The scene has no camera")
            return {'CANCELLED'}
        try:
            apply_all(context.scene, context.scene.kelen_lens)
        except Exception as e:
            self.report({'ERROR'}, str(e))
            return {'CANCELLED'}
        self.report({'INFO'}, "Lens applied: " + context.scene.kelen_lens.lens)
        return {'FINISHED'}


class KELEN_OT_remove_lens(bpy.types.Operator):
    bl_idname = "kelen.remove_lens"
    bl_label = "Remove Lens"
    bl_options = {'REGISTER', 'UNDO'}

    def execute(self, context):
        if context.scene.camera:
            remove_optics(context.scene.camera)
        context.scene.compositing_node_group = None
        return {'FINISHED'}


class KELEN_PT_lens(bpy.types.Panel):
    bl_label = "Kelen Lens Lab"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = "Lens"

    def draw(self, context):
        s = context.scene.kelen_lens
        col = self.layout.column(align=True)
        col.prop(s, "lens", text="")
        col.prop(s, "strength", slider=True)
        box = self.layout.box(); box.label(text="Focus", icon='CAMERA_DATA')
        box.prop(s, "use_optics"); box.prop(s, "focus_object"); box.prop(s, "fstop")
        box = self.layout.box(); box.label(text="Finishing", icon='SHADING_RENDERED')
        for p in ("bloom", "halation", "streaks", "aberration", "prism", "vignette", "grain"):
            box.prop(s, p, slider=True)
        row = self.layout.row(align=True)
        row.scale_y = 1.4
        row.operator("kelen.apply_lens", icon='CHECKMARK')
        row.operator("kelen.remove_lens", text="", icon='X')


classes = (KelenLensSettings, KELEN_OT_apply_lens, KELEN_OT_remove_lens, KELEN_PT_lens)


def register():
    for c in classes:
        bpy.utils.register_class(c)
    bpy.types.Scene.kelen_lens = PointerProperty(type=KelenLensSettings)


def unregister():
    del bpy.types.Scene.kelen_lens
    for c in reversed(classes):
        bpy.utils.unregister_class(c)


if __name__ == "__main__":
    register()
