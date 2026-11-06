# Kelen Icon Turntable — one-click looping 3D icon renders with a transparent background (Blender 5.x)
# Select any model -> Setup -> Preview Stills -> Render Loop (PNG sequence, ProRes 4444 or WebM with alpha).

bl_info = {
    "name": "Kelen Icon Turntable",
    "author": "Kelen Studio",
    "version": (1, 0, 0),
    "blender": (5, 0, 0),
    "location": "3D View > Sidebar (N) > Turntable",
    "description": "Centre, light and spin any model into a seamless transparent-background loop",
    "category": "Render",
}

import math, os
import bpy
from mathutils import Vector, Matrix
from bpy.props import EnumProperty, FloatProperty, IntProperty, BoolProperty, StringProperty

PRESETS = [
    ('GOLDEN_RUST', "Golden Rust", "Warm tungsten key, cool teal rim: metal, wood, tools"),
    ('NEON_VIOLET', "Neon Violet", "Violet and cyan rims on deep purple: product / gadget look"),
    ('CRIMSON', "Crimson", "Soft white key with hot magenta-red rims: sci-fi hard-surface"),
    ('STUDIO', "Studio White", "Clean big-softbox catalogue light"),
]
# light rigs in camera space: (name, x, y, z, power W, size m, color, look-at height)
#   x: right, y: away from camera (+ = behind the object), z: up — relative to an object fitted to 1 m
RIGS = {
    'GOLDEN_RUST': [("Key", -1.6, -1.3, 1.6, 340, 1.0, (1.0, 0.76, 0.5)),
                    ("Rim", 1.4, 1.4, 1.0, 1300, 0.35, (0.45, 0.8, 1.0)),
                    ("Kick", -1.5, 1.5, -0.1, 700, 0.3, (1.0, 0.55, 0.25)),
                    ("Top", 0.2, 0.4, 2.0, 220, 0.6, (1.0, 0.9, 0.8)),
                    ("Fill", 1.8, -1.6, -0.3, 35, 2.0, (0.75, 0.85, 1.0))],
    'NEON_VIOLET': [("Key", -1.3, -1.6, 1.4, 260, 1.4, (0.85, 0.8, 1.0)),
                    ("RimL", -1.6, 1.4, 0.6, 700, 0.5, (0.55, 0.3, 1.0)),
                    ("RimR", 1.6, 1.3, 0.3, 600, 0.5, (0.2, 0.9, 1.0)),
                    ("Top", 0.0, 0.3, 2.0, 200, 1.0, (0.7, 0.55, 1.0))],
    'CRIMSON': [("Key", -1.2, -1.7, 1.2, 300, 1.6, (1.0, 0.97, 0.94)),
                ("RimR", 1.6, 1.2, 0.2, 800, 0.4, (1.0, 0.1, 0.35)),
                ("RimL", -1.7, 1.2, -0.3, 450, 0.4, (1.0, 0.15, 0.25)),
                ("Under", 0.4, -0.6, -1.6, 90, 1.0, (1.0, 0.2, 0.4))],
    'STUDIO': [("Key", -1.4, -1.6, 1.6, 380, 2.2, (1.0, 0.98, 0.95)),
               ("Fill", 1.8, -1.4, 0.6, 150, 2.5, (1.0, 1.0, 1.0)),
               ("Rim", 0.6, 1.8, 1.4, 420, 1.0, (1.0, 1.0, 1.0))],
}
WORLD = {'GOLDEN_RUST': ((0.05, 0.045, 0.04), 0.6), 'NEON_VIOLET': ((0.05, 0.03, 0.09), 0.7),
         'CRIMSON': ((0.05, 0.05, 0.055), 0.5), 'STUDIO': ((0.5, 0.5, 0.5), 0.6)}
RIG_TAG = "kelen_tt"


def _tag(o):
    o[RIG_TAG] = True
    return o


def _clear_rig(scene):
    for o in [o for o in scene.objects if o.get(RIG_TAG)]:
        if o.type == 'EMPTY':
            for c in o.children:
                if not c.get(RIG_TAG):
                    mw = c.matrix_world.copy(); c.parent = None; c.matrix_world = mw
        bpy.data.objects.remove(o, do_unlink=True)


def _roots(objs):
    sel = set(objs)
    return [o for o in objs if not (o.parent and o.parent in sel)]


def _world_bbox(objs):
    pts = []
    for o in objs:
        if o.type == 'MESH':
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def setup_turntable(context, objs=None):
    scene = context.scene; s = scene.kelen_turntable
    objs = objs or [o for o in context.selected_objects] or [o for o in scene.objects if o.type == 'MESH' and not o.get(RIG_TAG)]
    meshes = [o for o in objs if o.type == 'MESH']
    for o in objs:   # include children so whole imported hierarchies move together
        meshes += [c for c in o.children_recursive if c.type == 'MESH' and c not in meshes]
    if not meshes:
        raise RuntimeError("Select the model (mesh objects) first")
    _clear_rig(scene)
    context.view_layer.update()
    lo, hi = _world_bbox(meshes)
    centre = (lo + hi) / 2; size = max(hi - lo)
    k = 1.0 / max(size, 1e-6)

    col = scene.collection
    def empty(name, parent=None):
        e = _tag(bpy.data.objects.new(name, None)); col.objects.link(e); e.parent = parent; e.empty_display_size = 0.3; return e
    base = empty("TT_Base"); spin = empty("TT_Spin", base); fit = empty("TT_Fit", spin)
    fit.location = -centre * k; fit.scale = (k, k, k)
    roots = _roots(list({*objs, *meshes}))
    for o in roots:
        mw = o.matrix_world.copy(); o.parent = fit; o.matrix_parent_inverse = Matrix.Identity(4); o.matrix_basis = mw
    base.rotation_euler = (math.radians(s.tilt), math.radians(s.lean), 0.0)

    # seamless loop: frame 1 -> 0 deg, frame N+1 -> 360 deg, linear
    fps = scene.render.fps; n = max(2, round(s.seconds * fps))
    scene.frame_start, scene.frame_end = 1, n
    spin.rotation_euler = (0, 0, 0); spin.keyframe_insert("rotation_euler", index=2, frame=1)
    spin.rotation_euler = (0, 0, math.tau * (1 if s.direction == 'CCW' else -1)); spin.keyframe_insert("rotation_euler", index=2, frame=n + 1)
    try:
        for fc in spin.animation_data.action.fcurves:
            for kp in fc.keyframe_points: kp.interpolation = 'LINEAR'
    except Exception:
        for layer in spin.animation_data.action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    for fc in bag.fcurves:
                        for kp in fc.keyframe_points: kp.interpolation = 'LINEAR'
    if s.bob > 0:
        d = base.driver_add("location", 2).driver; d.type = 'SCRIPTED'
        d.expression = "%f*sin(2*pi*(frame-1)/%d)" % (s.bob, n)

    # camera framed on the bounding sphere of the fitted model (covers every angle of the spin)
    r = 0.5 * (hi - lo).length * k
    cam = _tag(bpy.data.objects.new("TT_Camera", bpy.data.cameras.new("TT_Camera"))); col.objects.link(cam)
    cam.data.lens = s.lens; cam.data.sensor_fit = 'AUTO'; cam.data.clip_start = 0.01
    half = math.atan(18.0 / s.lens)
    dist = r * s.margin / math.sin(half)
    el = math.radians(s.elevation)
    cam.location = (0, -dist * math.cos(el), dist * math.sin(el))
    cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scene.camera = cam

    # lights live in camera space so they never spin with the object
    for name, x, y, z, w, sz, colr in RIGS[s.preset]:
        l = bpy.data.lights.new("TT_" + name, 'AREA'); l.energy = w * s.light_power; l.size = sz; l.color = colr
        lo_ = _tag(bpy.data.objects.new("TT_" + name, l)); col.objects.link(lo_)
        lo_.location = (x, y, z); lo_.rotation_euler = (Vector((0, 0, 0)) - lo_.location).to_track_quat('-Z', 'Y').to_euler()
    w_col, w_str = WORLD[s.preset]
    world = scene.world or bpy.data.worlds.new("TT_World"); scene.world = world; world.use_nodes = True
    bg = world.node_tree.nodes.get('Background')
    if bg:
        bg.inputs['Color'].default_value = (*w_col, 1); bg.inputs['Strength'].default_value = w_str

    if s.shadow:
        bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, -r * 1.05))
        pl = _tag(context.active_object); pl.name = "TT_ShadowCatcher"; pl.is_shadow_catcher = True

    r_ = scene.render; r_.engine = 'CYCLES'; r_.film_transparent = True
    r_.resolution_x = r_.resolution_y = s.resolution; r_.resolution_percentage = 100
    cy = scene.cycles; cy.samples = s.samples; cy.use_adaptive_sampling = True; cy.adaptive_threshold = 0.015; cy.use_denoising = True
    vs = scene.view_settings
    try: vs.view_transform = 'AgX'; vs.look = 'AgX - Medium High Contrast'
    except Exception: pass
    return base, spin, cam


def set_output(scene, path):
    s = scene.kelen_turntable; ims = scene.render.image_settings
    os.makedirs(bpy.path.abspath(path), exist_ok=True)
    if s.output == 'PNG':
        ims.media_type = 'IMAGE'; ims.file_format = 'PNG'; ims.color_mode = 'RGBA'; ims.color_depth = '8'
        scene.render.filepath = os.path.join(path, "frame_")
    else:
        ims.media_type = 'VIDEO'; ims.file_format = 'FFMPEG'; f = scene.render.ffmpeg
        if s.output == 'PRORES':
            f.format = 'QUICKTIME'; f.codec = 'PRORES'; f.ffmpeg_prores_profile = '4444'
            scene.render.filepath = os.path.join(path, "loop.mov")
        else:
            f.format = 'WEBM'; f.codec = 'WEBM'; f.constant_rate_factor = 'HIGH'
            scene.render.filepath = os.path.join(path, "loop.webm")
        f.audio_codec = 'NONE'; ims.color_mode = 'RGBA'


def render_previews(scene, folder, scale=50, samples=48):
    """Four still angles of the loop (0/90/180/270 deg) for a quick look before the full render."""
    os.makedirs(bpy.path.abspath(folder), exist_ok=True)
    r = scene.render; keep = (r.resolution_percentage, scene.cycles.samples, r.filepath, r.image_settings.media_type, r.image_settings.file_format, scene.frame_current)
    r.resolution_percentage = scale; scene.cycles.samples = samples
    r.image_settings.media_type = 'IMAGE'; r.image_settings.file_format = 'PNG'; r.image_settings.color_mode = 'RGBA'
    n = scene.frame_end; out = []
    for q in range(4):
        f = 1 + round(q * n / 4); scene.frame_set(f)
        r.filepath = os.path.join(folder, "preview_%d.png" % (q * 90)); bpy.ops.render.render(write_still=True); out.append(r.filepath)
    r.resolution_percentage, scene.cycles.samples, r.filepath, r.image_settings.media_type, r.image_settings.file_format, f0 = keep
    scene.frame_set(f0)
    return out


class KelenTurntableSettings(bpy.types.PropertyGroup):
    preset: EnumProperty(name="Light", items=PRESETS, default='GOLDEN_RUST')
    seconds: FloatProperty(name="Loop Seconds", default=5.0, min=0.5, max=60)
    direction: EnumProperty(name="Spin", items=[('CCW', "Left", ""), ('CW', "Right", "")], default='CCW')
    tilt: FloatProperty(name="Tilt to Camera", default=12.0, min=-60, max=60, description="Degrees the spin axis leans toward the camera")
    lean: FloatProperty(name="Side Lean", default=0.0, min=-75, max=75, description="Degrees the spin axis leans sideways (diagonal hero look)")
    bob: FloatProperty(name="Float", default=0.02, min=0.0, max=0.2, description="Gentle up/down float, in metres of a 1 m fitted model")
    elevation: FloatProperty(name="Camera Height", default=6.0, min=-45, max=60)
    lens: FloatProperty(name="Lens mm", default=85.0, min=18, max=200)
    margin: FloatProperty(name="Margin", default=1.12, min=1.0, max=2.0)
    light_power: FloatProperty(name="Light Power", default=1.0, min=0.0, max=10.0)
    shadow: BoolProperty(name="Soft Floor Shadow", default=False)
    resolution: IntProperty(name="Size px", default=1080, min=128, max=4096)
    samples: IntProperty(name="Samples", default=128, min=8, max=4096)
    output: EnumProperty(name="Output", items=[('PNG', "PNG Sequence (alpha)", ""), ('PRORES', "ProRes 4444 .mov (alpha)", ""), ('WEBM', "WebM VP9 (alpha)", "")], default='PNG')
    folder: StringProperty(name="Folder", default="//turntable/", subtype='DIR_PATH')


class KELEN_OT_tt_setup(bpy.types.Operator):
    bl_idname = "kelen.tt_setup"; bl_label = "Setup Turntable"; bl_options = {'REGISTER', 'UNDO'}
    bl_description = "Centre and fit the selected model, add camera, lights and a seamless spin"
    def execute(self, context):
        try: setup_turntable(context)
        except Exception as e:
            self.report({'ERROR'}, str(e)); return {'CANCELLED'}
        return {'FINISHED'}


class KELEN_OT_tt_preview(bpy.types.Operator):
    bl_idname = "kelen.tt_preview"; bl_label = "Preview Stills"
    bl_description = "Render four quick stills (0/90/180/270 deg) into the output folder"
    def execute(self, context):
        out = render_previews(context.scene, os.path.join(context.scene.kelen_turntable.folder, "preview"))
        self.report({'INFO'}, "Previews: " + os.path.dirname(bpy.path.abspath(out[0]))); return {'FINISHED'}


class KELEN_OT_tt_render(bpy.types.Operator):
    bl_idname = "kelen.tt_render"; bl_label = "Render Loop"
    bl_description = "Render the full transparent loop in the chosen format"
    def execute(self, context):
        set_output(context.scene, context.scene.kelen_turntable.folder)
        bpy.ops.render.render('INVOKE_DEFAULT', animation=True); return {'FINISHED'}


class KELEN_PT_turntable(bpy.types.Panel):
    bl_label = "Kelen Icon Turntable"; bl_space_type = 'VIEW_3D'; bl_region_type = 'UI'; bl_category = "Turntable"
    def draw(self, context):
        s = context.scene.kelen_turntable; L = self.layout
        L.prop(s, "preset")
        b = L.box(); b.label(text="Motion", icon='LOOP_FORWARDS')
        for p in ("seconds", "direction", "tilt", "lean", "bob"): b.prop(s, p)
        b = L.box(); b.label(text="Camera & Light", icon='CAMERA_DATA')
        for p in ("elevation", "lens", "margin", "light_power", "shadow"): b.prop(s, p)
        b = L.box(); b.label(text="Output", icon='RENDER_ANIMATION')
        for p in ("resolution", "samples", "output", "folder"): b.prop(s, p)
        c = L.column(align=True); c.scale_y = 1.3
        c.operator("kelen.tt_setup", icon='OBJECT_ORIGIN'); c.operator("kelen.tt_preview", icon='IMAGE_DATA'); c.operator("kelen.tt_render", icon='RENDER_ANIMATION')


classes = (KelenTurntableSettings, KELEN_OT_tt_setup, KELEN_OT_tt_preview, KELEN_OT_tt_render, KELEN_PT_turntable)


def register():
    for c in classes: bpy.utils.register_class(c)
    bpy.types.Scene.kelen_turntable = bpy.props.PointerProperty(type=KelenTurntableSettings)


def unregister():
    del bpy.types.Scene.kelen_turntable
    for c in reversed(classes): bpy.utils.unregister_class(c)


if __name__ == "__main__":
    register()
