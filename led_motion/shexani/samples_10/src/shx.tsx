import React, {useEffect, useMemo, useState} from 'react';
import * as THREE from 'three';
import {useThree} from '@react-three/fiber';
import {ThreeCanvas} from '@remotion/three';
import {Img, continueRender, delayRender, staticFile} from 'remotion';

// ---------------------------------------------------------------------------
// Shexani LED (936x260) shared kit. Everything important stays in SL..SR:
// up to 140 px may be hidden on either side of the installed screen.
// ---------------------------------------------------------------------------
export const W = 936, H = 260, SL = 140, SR = 796, ZW = SR - SL, CX = (SL + SR) / 2;
export const YELLOW = '#F5B700', INK = '#16130D', BUTTER = '#FFF1C2', STONE = '#6B6457', PAPER = '#FBF8F0', BRONZE = '#8A5A00';
export const TAU = Math.PI * 2;
export const c01 = (x: number) => Math.min(1, Math.max(0, x));
export const rng = (f: number, a: number, b: number) => c01((f - a) / (b - a));
export const eOut = (t: number) => 1 - Math.pow(1 - c01(t), 3);
export const eExpo = (t: number) => { t = c01(t); return t === 1 ? 1 : 1 - Math.pow(2, -10 * t); };
export const eIn = (t: number) => Math.pow(c01(t), 3);
export const eIO = (t: number) => { t = c01(t); return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; };
export const eBack = (t: number, s = 1.7) => { t = c01(t) - 1; return t * t * ((s + 1) * t + s) + 1; };
export const rnd = (i: number, n = 0) => { const s = Math.sin(i * 127.1 + n * 311.7) * 43758.5453; return s - Math.floor(s); };
export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

// ---- fonts (brand: Noto Kufi Arabic / Noto Sans Arabic / Montserrat) ----
const AR = 'U+0600-06FF,U+0750-077F,U+FB50-FDFF,U+FE70-FEFF,U+200C-200F';
let fontsPromise: Promise<void> | null = null;
export const loadShxFonts = () => {
  fontsPromise ??= Promise.all([
    new FontFace('ShxKufi', `url(${staticFile('fonts/nkufi-800.woff2')})`, {weight: '800', unicodeRange: AR}),
    new FontFace('ShxSans', `url(${staticFile('fonts/nsans-700.woff2')})`, {weight: '700', unicodeRange: AR}),
    new FontFace('ShxMont', `url(${staticFile('fonts/mont-800.woff2')})`, {weight: '800'}),
    new FontFace('ShxMont', `url(${staticFile('fonts/mont-800-ext.woff2')})`, {weight: '800', unicodeRange: 'U+20A0-20BF'}),
  ].map((f) => f.load())).then((l) => { l.forEach((f) => document.fonts.add(f)); });
  return fontsPromise;
};
export const useShxFonts = () => {
  const [h] = useState(() => delayRender('shx fonts'));
  useEffect(() => { loadShxFonts().then(() => continueRender(h)).catch((e) => { console.error(e); continueRender(h); }); }, [h]);
};

// ---- the X: two meeting arrows, exactly the polygons of the official logo (tip at origin, height 184) ----
export const CHEV_L: [number, number][] = [[-107.33, -92], [-56.22, -92], [0, 0], [-56.22, 92], [-107.33, 92], [-51.11, 0]];
export const CHEV_R: [number, number][] = CHEV_L.map(([x, y]) => [-x, y]);
const pts = (p: [number, number][]) => p.map(([x, y]) => `${x},${y}`).join(' ');
export const Chevron: React.FC<{side: 'l' | 'r'; h: number; color: string; style?: React.CSSProperties}> = ({side, h, color, style}) => {
  const s = h / 184, w = 107.33 * s;
  return (
    <svg width={w} height={h} viewBox={side === 'l' ? '-107.33 -92 107.33 184' : '0 -92 107.33 184'} style={{display: 'block', overflow: 'visible', ...style}}>
      <polygon points={pts(side === 'l' ? CHEV_L : CHEV_R)} fill={color} />
    </svg>
  );
};
export const XMark: React.FC<{h: number; left?: string; right?: string; style?: React.CSSProperties}> = ({h, left = '#fff', right = YELLOW, style}) => (
  <svg width={(214.66 * h) / 184} height={h} viewBox="-107.33 -92 214.66 184" style={{display: 'block', overflow: 'visible', ...style}}>
    <polygon points={pts(CHEV_L)} fill={left} /><polygon points={pts(CHEV_R)} fill={right} />
  </svg>
);

// ---- official logo images (SVG from the brand package) ----
export const LOGO = {
  nameDark: {src: 'shexani/logo_name_dark.svg', ar: 1925.1 / 680, xcx: 139.33 / 1925.1, xcy: 320 / 680, xh: 184 / 680},
  tagDark: {src: 'shexani/logo_tag_dark.svg', ar: 1925.1 / 819.4, xcx: 139.33 / 1925.1, xcy: 320 / 819.4, xh: 184 / 819.4},
  tagColour: {src: 'shexani/logo_tag_colour.svg', ar: 1925.1 / 819.4, xcx: 139.33 / 1925.1, xcy: 320 / 819.4, xh: 184 / 819.4},
  nameWhite: {src: 'shexani/logo_name_white.svg', ar: 1925.1 / 680, xcx: 139.33 / 1925.1, xcy: 320 / 680, xh: 184 / 680},
} as const;
export const Logo: React.FC<{kind: keyof typeof LOGO; h: number; style?: React.CSSProperties}> = ({kind, h, style}) => (
  <Img src={staticFile(LOGO[kind].src)} style={{height: h, width: h * LOGO[kind].ar, display: 'block', ...style}} />
);

// ---------------------------------------------------------------------------
// 3D kit. World units: screen height = 1, so the screen is 3.6 x 1 at z = 0.
// ---------------------------------------------------------------------------
export const HWU = W / H / 2, SAFE_HW = ZW / H / 2; // 1.8 and ~1.26
// Off-axis ("window") projection: the picture is correct for an eye at `eye`, measured from the screen centre.
export const OffAxis: React.FC<{eye: [number, number, number]}> = ({eye}) => {
  const {camera} = useThree();
  const [ex, ey, ez] = eye; const n = 0.1, far = 80;
  camera.position.set(ex, ey, ez); camera.rotation.set(0, 0, 0); camera.updateMatrixWorld();
  camera.projectionMatrix.makePerspective(((-HWU - ex) * n) / ez, ((HWU - ex) * n) / ez, ((0.5 - ey) * n) / ez, ((-0.5 - ey) * n) / ez, n, far);
  camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();
  return null;
};
export const ShxCanvas: React.FC<{children: React.ReactNode; eye?: [number, number, number]}> = ({children, eye = [0, 0, 6.5]}) => (
  <ThreeCanvas width={W} height={H} shadows flat gl={{alpha: true, antialias: true, preserveDrawingBuffer: true}} camera={{fov: 10, position: [0, 0, 6.5], near: 0.1, far: 80}}
    style={{position: 'absolute', left: 0, top: 0}}>
    <OffAxis eye={eye} />
    {children}
  </ThreeCanvas>
);

// ThreeCanvas only redraws on frame change while rendering, so advance once when an async texture arrives.
const useRelease = (ready: boolean, handle: number) => {
  const {advance} = useThree();
  useEffect(() => { if (!ready) return; advance(performance.now()); requestAnimationFrame(() => continueRender(handle)); }, [ready, advance, handle]);
};
export const useTex = (src: string) => {
  const [h] = useState(() => delayRender('tex ' + src));
  const [tex, setTex] = useState<THREE.Texture | null>(null);
  useEffect(() => {
    new THREE.TextureLoader().load(staticFile(src), (t) => { t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 8; setTex(t); }, undefined, (e) => { console.error('tex failed', src, e); continueRender(h); });
  }, [src, h]);
  useRelease(!!tex, h);
  return tex;
};
// Canvas textures drawn after the brand fonts are really registered (canvas text uses browser shaping, so Kurdish joins correctly).
export const useDrawTex = (w: number, h: number, draw: (ctx: CanvasRenderingContext2D) => void, key = '') => {
  const [hd] = useState(() => delayRender('draw tex ' + key));
  const [tex, setTex] = useState<THREE.CanvasTexture | null>(null);
  useEffect(() => {
    loadShxFonts().then(() => {
      const c = document.createElement('canvas'); c.width = w; c.height = h;
      draw(c.getContext('2d')!);
      const t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 8; setTex(t);
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useRelease(!!tex, hd);
  return tex;
};

// chevrons as THREE shapes, height 1, tip at origin, y up
export const chevronShape = (side: 'l' | 'r') => {
  const p = (side === 'l' ? CHEV_L : CHEV_R).map(([x, y]) => new THREE.Vector2(x / 184, -y / 184));
  return new THREE.Shape(side === 'l' ? p : p.slice().reverse());
};
// flat brand-colour materials for the X: [faces, sides]
export const X_WHITE = [new THREE.MeshBasicMaterial({color: '#ffffff'}), new THREE.MeshBasicMaterial({color: '#a9a394'})];
export const X_YELLOW = [new THREE.MeshBasicMaterial({color: '#F5B700'}), new THREE.MeshBasicMaterial({color: '#9c7400'})];
export const useX3D = (depth: number, bevel = 0.012) => useMemo(() => {
  const mk = (s: 'l' | 'r') => { const g = new THREE.ExtrudeGeometry(chevronShape(s), {depth, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 3}); g.translate(0, 0, -depth / 2); return g; };
  return {l: mk('l'), r: mk('r')};
}, [depth, bevel]);

// coin face: ink enamel, gold rim, yellow symbol (or the X)
export const drawCoinFace = (sym: string) => (ctx: CanvasRenderingContext2D) => {
  const S = 256, c = S / 2;
  const g = ctx.createRadialGradient(c - 30, c - 40, 10, c, c, c);
  g.addColorStop(0, '#fff3b0'); g.addColorStop(0.5, '#f5b700'); g.addColorStop(1, '#8a5a00');
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(c, c, c, 0, TAU); ctx.fill();
  ctx.fillStyle = '#16130D'; ctx.beginPath(); ctx.arc(c, c, c - 20, 0, TAU); ctx.fill();
  ctx.strokeStyle = 'rgba(245,183,0,0.55)'; ctx.lineWidth = 3; ctx.setLineDash([6, 8]); ctx.beginPath(); ctx.arc(c, c, c - 34, 0, TAU); ctx.stroke(); ctx.setLineDash([]);
  if (sym === 'X') {
    const s = 0.62; ctx.save(); ctx.translate(c, c); ctx.scale(s, s);
    const poly = (p: [number, number][], col: string) => { ctx.fillStyle = col; ctx.beginPath(); p.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath(); ctx.fill(); };
    poly(CHEV_L, '#ffffff'); poly(CHEV_R, '#F5B700'); ctx.restore();
  } else {
    const ar = /[؀-ۿ]/.test(sym);
    ctx.fillStyle = '#F5B700'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.font = ar ? '800 96px ShxKufi' : '800 150px ShxMont';
    if (ar) ctx.direction = 'rtl';
    ctx.fillText(sym, c, c + (ar ? -4 : 8));
  }
};
