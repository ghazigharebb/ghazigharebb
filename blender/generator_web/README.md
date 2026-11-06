# تۆڕی مۆلیدە — Generator Web

Cinematic anamorphic still (2.39:1), built entirely from code with Blender 4.5 / Cycles.

- `scene.py` — builds the whole scene (street, buildings, ~400 wires, generator, signs, fog) and renders.
- `make_signs.py` — hand-painted Kurdish sign textures (Vazirmatn font, OFL licence).
- `post.py` — film finish: comp rain, halation, grain, grade, vignette.
- `tex/` — generated textures + font.

```
python make_signs.py
python scene.py -- render 3840 1608 256 out/raw.png
python post.py out/raw.png out/final.png
python scene.py -- save generator_web.blend   # packed .blend, open on any PC
```
