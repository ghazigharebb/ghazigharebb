"""Hand-painted Kurdish sign textures (RGBA) with brush roughness, drips and weathering."""
import numpy as np, cv2, os, sys
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__)); T = os.path.join(HERE, "tex")
FONT = os.path.join(T, "Vazirmatn-Black.ttf")
rng = np.random.default_rng(3)

def painted(lines, size, color, out, fsize, wobble=2.0, drips=40, weather=0.35, spacing=1.15):
    W, H = size
    img = Image.new("L", (W, H), 0); d = ImageDraw.Draw(img)
    y = H * 0.1
    for txt, scale in lines:
        f = ImageFont.truetype(FONT, int(fsize * scale), layout_engine=ImageFont.Layout.RAQM)
        bb = d.textbbox((0, 0), txt, font=f, direction="rtl", language="ckb")
        tw = bb[2] - bb[0]
        d.text(((W - tw) / 2 - bb[0], y), txt, font=f, fill=255, direction="rtl", language="ckb")
        y += (bb[3] - bb[1]) * spacing + fsize * 0.25
    a = np.array(img).astype(np.float32) / 255
    # hand-painted wobble: displace with smooth noise
    h, w = a.shape
    nx = cv2.GaussianBlur(rng.normal(0, 1, (h, w)).astype(np.float32), (0, 0), 18) * wobble * 40
    ny = cv2.GaussianBlur(rng.normal(0, 1, (h, w)).astype(np.float32), (0, 0), 18) * wobble * 40
    gx, gy = np.meshgrid(np.arange(w, dtype=np.float32), np.arange(h, dtype=np.float32))
    a = cv2.remap(a, gx + nx, gy + ny, cv2.INTER_LINEAR)
    # brush edge roughness
    edge = cv2.GaussianBlur(rng.random((h, w)).astype(np.float32), (0, 0), 1.2)
    a = np.clip((cv2.GaussianBlur(a, (0, 0), 1.5) - 0.5 + (edge - 0.5) * 0.5) * 6 + 0.5, 0, 1)
    # drips from paint-heavy lower edges
    ys, xs = np.where((a[:-6] > 0.9) & (a[6:] < 0.1))
    if len(xs):
        for i in rng.choice(len(xs), min(drips, len(xs)), replace=False):
            x0, y0 = xs[i], ys[i]; L = int(rng.uniform(10, 70)); wd = int(rng.uniform(2, 5))
            cv2.line(a, (x0, y0), (x0, min(h - 1, y0 + L)), 1.0, wd)
            cv2.circle(a, (x0, min(h - 1, y0 + L)), wd, 1.0, -1)
    # weathering: flaking paint
    wn = cv2.GaussianBlur(rng.random((h, w)).astype(np.float32), (0, 0), 6)
    wn = (wn - wn.min()) / (wn.max() - wn.min())
    a *= np.clip((wn - weather * 0.55) * 4, 0, 1) * 0.85 + 0.15 * (wn > 0.2)
    a *= rng.uniform(0.85, 1.0, (h, w)).astype(np.float32)
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., 0], rgba[..., 1], rgba[..., 2] = color
    rgba[..., 3] = (np.clip(a, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(os.path.join(T, out))
    print("wrote", out)

# generator side: "neighbourhood generator / 1 amp = 10,000 dinar"
painted([("مۆلیدەی گەڕەک", 1.0), ("١ ئەمپێر = ١٠،٠٠٠ دینار", 0.62)], (2048, 900), (150, 18, 12), "sign_gen.png", 300)
# rolling shutter graffiti: "for rent"
painted([("بۆ کرێ", 1.0)], (1400, 600), (235, 235, 228), "sign_rent.png", 330, wobble=3.0, drips=60, weather=0.25)
# board warning: "danger — do not touch"
painted([("مەترسی", 1.0), ("دەستی لێ مەدە", 0.6)], (1200, 700), (200, 25, 15), "sign_danger.png", 260, wobble=1.2, drips=15, weather=0.2)
