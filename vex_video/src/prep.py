import numpy as np
from PIL import Image, ImageDraw, ImageFilter
U='/root/.claude/uploads/9380ad24-ca4a-55ce-bb1f-255b979b9299/'
# 1) orange band cutout
im=Image.open(U+'9d56099f-image.jpg').convert('RGB'); print(im.size)
a=np.array(im).astype(int)
cand=(a.min(axis=2)>218)
m=Image.fromarray((cand*255).astype('uint8'),'L')
for pt in [(2,2),(im.width-3,2),(2,im.height-3),(im.width-3,im.height-3),(im.width//2,im.height-4)]:
    if m.getpixel(pt)==255: ImageDraw.floodfill(m,pt,128)
bg=(np.array(m)==128)
alpha=np.where(bg,0,255).astype('uint8')
al=Image.fromarray(alpha,'L').filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(1.4))
rgba=im.copy(); rgba.putalpha(al)
rgba=rgba.resize((1400,1400),Image.LANCZOS); rgba.save('assets/orange.png')
bgc=Image.new('RGBA',rgba.size,(6,40,52,255)); bgc.alpha_composite(rgba); bgc.convert('RGB').save('chk_orange.jpg')
# 2) logo cutout (cyan)
lg=Image.open(U+'3dca9e49-image.jpg').convert('RGB'); print(lg.size)
g=np.array(lg).astype(float)[:,:,1]
al=np.clip((g-60)/(190),0,1)
out=np.zeros(g.shape+(4,),dtype='uint8'); out[...,0]=0; out[...,1]=236; out[...,2]=255; out[...,3]=(al*255).astype('uint8')
Image.fromarray(out,'RGBA').resize((1400,1400),Image.LANCZOS).save('assets/logo.png')
print('bg logo px',np.array(lg)[5,5], 'bg3')
# 3) black band scene
b=Image.open(U+'c305664c-image.png').convert('RGB'); print(b.size)
bb=np.array(b)
for p in [(5,5),(5,1000),(1000,5),(1900,1900),(1000,1900),(960,40),(960,1930),(40,960),(1900,960)]:
    print(p,bb[p[1]%bb.shape[0],p[0]%bb.shape[1]])
b.resize((1400,1400),Image.LANCZOS).save('assets/black.jpg',quality=93)
