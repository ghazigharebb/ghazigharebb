"""Demo: Poly Haven 'Rusted Spade 01' (CC0) through Kelen Icon Turntable.
blender -b -P spade_demo.py -- OUT_DIR [preview|png|prores|webm] [SIZE] [SAMPLES]"""
import sys, os, importlib.util
import bpy

ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.abspath('spade_turntable')
MODE = ARGS[1] if len(ARGS) > 1 else 'preview'
SIZE = int(ARGS[2]) if len(ARGS) > 2 else 1080
SPP = int(ARGS[3]) if len(ARGS) > 3 else 128
HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.environ.get('KELEN_ASSETS', os.path.join(HERE, 'polyhaven'))

bpy.ops.wm.read_factory_settings(use_empty=True)
spec = importlib.util.spec_from_file_location("kelen_icon_turntable", os.path.join(HERE, "kelen_icon_turntable.py"))
tt = importlib.util.module_from_spec(spec); spec.loader.exec_module(tt); tt.register()

before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=os.path.join(ASSETS, 'models', 'rusted_spade_01', 'rusted_spade_01.gltf'))
model = [o for o in bpy.data.objects if o not in before]
for o in bpy.context.view_layer.objects: o.select_set(o in model)

sc = bpy.context.scene; s = sc.kelen_turntable
s.preset = 'GOLDEN_RUST'; s.seconds = 5.0; s.direction = 'CCW'
s.tilt = 16.0; s.lean = 38.0; s.bob = 0.015; s.elevation = 5.0; s.lens = 50.0; s.margin = 1.0
s.resolution = SIZE; s.samples = SPP; sc.render.fps = 24
tt.setup_turntable(bpy.context, model)
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'spade_turntable.blend'))
if MODE == 'preview':
    print('previews', tt.render_previews(sc, os.path.join(OUT, 'preview'), scale=100, samples=SPP))
else:
    s.output = {'png': 'PNG', 'prores': 'PRORES', 'webm': 'WEBM'}[MODE]
    tt.set_output(sc, os.path.join(OUT, MODE))
    bpy.ops.render.render(animation=True)
print('done')
