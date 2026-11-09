"""Film finish for «سوار»: halation, gentle grade, vignette, fine grain, dithered 8-bit export.
python post.py raw.png out_basename
"""
import sys, numpy as np, cv2
src, dst = sys.argv[1], sys.argv[2]
im = cv2.imread(src, cv2.IMREAD_UNCHANGED)
img = (im[..., :3].astype(np.float32) / (65535.0 if im.dtype == np.uint16 else 255.0))[..., ::-1].copy()
H, W = img.shape[:2]; s = W / 2160.0
rng = np.random.default_rng(11)
lum = img @ np.array([0.2126, 0.7152, 0.0722], np.float32)

# halation: warm red bleed around the hot iron and embers
hot = np.clip((lum - 0.55) / 0.45, 0, 1)
hal = cv2.GaussianBlur(hot, (0, 0), 10 * s) * 0.55 + cv2.GaussianBlur(hot, (0, 0), 34 * s) * 0.45
img += hal[..., None] * np.array([1.0, 0.32, 0.10], np.float32) * 0.30

# grade: keep blacks deep but not crushed to zero; cool the shadows a touch
sh = np.clip(1 - lum / 0.25, 0, 1)[..., None]
img = img + sh * np.array([-0.002, 0.0, 0.004], np.float32)
img = np.clip(img, 0, 1)
img = img * 0.99 + 0.006                                   # film base

# vignette (soft, for 4:5)
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H * 0.47) / (H / 2)) ** 2)
img *= (1 - 0.30 * np.clip(r - 0.5, 0, 1) ** 1.5)[..., None]

# fine film grain, luma-weighted
g = rng.normal(0, 1, (H, W)).astype(np.float32); g = cv2.GaussianBlur(g, (0, 0), 0.7 * s); g /= g.std()
gc = rng.normal(0, 1, (H, W, 3)).astype(np.float32); gc = cv2.GaussianBlur(gc, (0, 0), 0.8 * s); gc /= gc.std()
amt = (0.0045 + 0.006 * np.clip(1 - np.abs(lum - 0.3) / 0.45, 0, 1))[..., None]
img = np.clip(img + amt * (0.85 * g[..., None] + 0.2 * gc), 0, 1)

out = img[..., ::-1]
cv2.imwrite(dst + ".png", np.clip(out * 255 + rng.random(out.shape), 0, 255).astype(np.uint8), [cv2.IMWRITE_PNG_COMPRESSION, 9])
cv2.imwrite(dst + ".jpg", np.clip(out * 255 + rng.random(out.shape), 0, 255).astype(np.uint8), [cv2.IMWRITE_JPEG_QUALITY, 96])
print("saved", dst, W, H)
