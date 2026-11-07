"""Film finish for the Generator Web still.
python post.py in.png out_basename   -> out_basename.png (16-bit), out_basename.jpg (q95)
All sizes scale with image width so tests and the 4K final match.
"""
import sys, numpy as np, cv2

src, dst = sys.argv[1], sys.argv[2]
img = cv2.imread(src, cv2.IMREAD_UNCHANGED)
img = img[..., :3].astype(np.float32) / (65535.0 if img.dtype == np.uint16 else 255.0)
img = img[..., ::-1].copy()  # RGB
H, W = img.shape[:2]; s = W / 3840.0
rng = np.random.default_rng(7)
lum = img @ np.array([0.2126, 0.7152, 0.0722], np.float32)

# ---------------- rain: streaks only show where something bright is behind them
def streak_layer(n, len_rng, thick, alpha_rng, blur, angle_deg):
    lay = np.zeros((H, W), np.float32)
    a = np.deg2rad(angle_deg)
    for _ in range(n):
        x, y = rng.uniform(-0.05 * W, 1.05 * W), rng.uniform(-0.05 * H, 1.0 * H)
        L = rng.uniform(*len_rng) * s
        da = a + rng.normal(0, np.deg2rad(1.2))
        x2, y2 = x + np.sin(da) * L, y + np.cos(da) * L
        cv2.line(lay, (int(x), int(y)), (int(x2), int(y2)), float(rng.uniform(*alpha_rng)), max(1, int(round(thick * s))), cv2.LINE_AA)
    if blur > 0: lay = cv2.GaussianBlur(lay, (0, 0), blur * s)
    return lay
rain = (streak_layer(int(1600), (45, 110), 1.0, (0.05, 0.15), 0.8, -7)      # far
        + streak_layer(int(1300), (70, 160), 1.6, (0.08, 0.22), 1.2, -8)     # mid
        + streak_layer(int(260), (220, 520), 4.0, (0.06, 0.14), 6.0, -9))    # near, defocused
light_behind = cv2.GaussianBlur(lum, (0, 0), 45 * s)
light_behind = np.clip(light_behind / max(np.percentile(light_behind, 99.5), 1e-3), 0, 1) ** 1.4
rain_vis = rain * (0.015 + 0.9 * light_behind)
rain_col = np.array([0.80, 0.88, 1.0], np.float32)
img = 1 - (1 - img) * (1 - np.clip(rain_vis[..., None] * rain_col * 0.42, 0, 1))   # screen

# ---------------- halation (red-orange bleed around hot highlights, like film)
hot = np.clip((lum - 0.72) / 0.28, 0, 1)
hal = cv2.GaussianBlur(hot, (0, 0), 14 * s) * 0.6 + cv2.GaussianBlur(hot, (0, 0), 40 * s) * 0.4
img += hal[..., None] * np.array([0.95, 0.30, 0.10], np.float32) * 0.22

# ---------------- grade: teal shadows, warm highlights, gentle S-curve
sh = np.clip(1 - lum / 0.35, 0, 1)[..., None]
hi = np.clip((lum - 0.45) / 0.55, 0, 1)[..., None]
img = img + sh * np.array([-0.006, 0.004, 0.010], np.float32) + hi * np.array([0.020, 0.006, -0.018], np.float32)
img = np.clip(img, 0, 1)
img = img + 0.06 * (img - 0.5) * (1 - np.abs(2 * img - 1))           # soft contrast
img = np.clip(img * 0.992 + 0.004, 0, 1)                               # film black lift

# ---------------- vignette (elliptical for scope)
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2 * 0.55)
img *= (1 - 0.32 * np.clip(r - 0.55, 0, 1) ** 1.6)[..., None]

# ---------------- film grain (luma-weighted, ~35mm at 4K)
g = rng.normal(0, 1, (H, W)).astype(np.float32)
g = cv2.GaussianBlur(g, (0, 0), 0.75 * s); g /= g.std()
gc = rng.normal(0, 1, (H, W, 3)).astype(np.float32)
gc = cv2.GaussianBlur(gc, (0, 0), 0.9 * s); gc /= gc.std()
amt = (0.0045 + 0.0050 * np.clip(1 - np.abs(lum - 0.35) / 0.5, 0, 1))[..., None]
img = np.clip(img + amt * (0.85 * g[..., None] + 0.2 * gc), 0, 1)

out = img[..., ::-1]
cv2.imwrite(dst + ".png", (out * 65535 + 0.5).astype(np.uint16))
cv2.imwrite(dst + ".jpg", (out * 255 + 0.5).astype(np.uint8), [cv2.IMWRITE_JPEG_QUALITY, 95])
print("saved", dst, W, H)
