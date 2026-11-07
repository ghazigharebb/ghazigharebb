"""Paste re-rendered border regions into the full raw render with a feathered mask."""
import sys, numpy as np, cv2
raw = cv2.imread(sys.argv[1], cv2.IMREAD_UNCHANGED).astype(np.float32)
H, W = raw.shape[:2]
for spec in sys.argv[3:]:
    path, x0, x1, y0, y1 = spec.split(":"); x0, x1, y0, y1 = map(float, (x0, x1, y0, y1))
    p = cv2.imread(path, cv2.IMREAD_UNCHANGED).astype(np.float32)
    m = np.zeros((H, W), np.float32)
    px0, px1 = int(x0 * W), int(x1 * W); py0, py1 = int((1 - y1) * H), int((1 - y0) * H)   # blender border y from bottom
    pad = 40
    m[py0 + pad if py0 > 0 else 0: py1 - pad if py1 < H else H, px0 + pad if px0 > 0 else 0: px1 - pad if px1 < W else W] = 1
    m = cv2.GaussianBlur(m, (0, 0), 14)[..., None]
    raw = raw * (1 - m) + p * m
cv2.imwrite(sys.argv[2], np.clip(raw, 0, 65535).astype(np.uint16))
print("merged")
