"""Download the CC0 Poly Haven assets used by dapir_real_scene.py into ./polyhaven next to this script.
Run: python fetch_polyhaven.py"""
import json, os, sys, urllib.request
DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'polyhaven')
os.makedirs(DEST, exist_ok=True); os.chdir(DEST)
UA = {'User-Agent': 'kelen-blender/1.0'}
def get(u): return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=60))
def fetch(url, path):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    if os.path.exists(path): return
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=300) as r, open(path, 'wb') as f:
        f.write(r.read())
def hdri(aid, res='4k'):
    f = get(f'https://api.polyhaven.com/files/{aid}')['hdri'][res]['hdr']
    fetch(f['url'], f'hdri/{aid}_{res}.hdr'); print('hdri', aid)
def texture(aid, res='2k'):
    f = get(f'https://api.polyhaven.com/files/{aid}')
    for key in ('Diffuse', 'nor_gl', 'Rough', 'Displacement', 'AO'):
        if key in f and res in f[key]:
            e = f[key][res].get('jpg') or f[key][res].get('png')
            fetch(e['url'], f'tex/{aid}/{key}.{e["url"].rsplit(".", 1)[1]}')
    print('tex', aid)
def model(aid, res='2k'):
    f = get(f'https://api.polyhaven.com/files/{aid}')
    g = f['gltf'][res]['gltf']
    fetch(g['url'], f'models/{aid}/{aid}.gltf')
    for rel, inc in g.get('include', {}).items():
        fetch(inc['url'], f'models/{aid}/{rel}')
    print('model', aid)
hdri('misty_pines', '4k')
for t in ('dark_wooden_planks', 'brown_planks_05', 'castle_wall_slates', 'brown_mud_leaves_01', 'forest_ground_04', 'bark_brown_02'):
    texture(t)
for m in ('Lantern_01', 'tree_stump_01', 'rock_moss_set_01', 'boulder_01', 'fern_02', 'grass_medium_01', 'nettle_plant'):
    try: model(m)
    except Exception as e: print('model fail', m, e)
