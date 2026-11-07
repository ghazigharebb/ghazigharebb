import React, {useEffect, useMemo, useState} from 'react';
import * as THREE from 'three';
import {useThree} from '@react-three/fiber';
import {ThreeCanvas} from '@remotion/three';
import {RoomEnvironment} from 'three/examples/jsm/environments/RoomEnvironment.js';
import {SVGLoader} from 'three/examples/jsm/loaders/SVGLoader.js';
import {AbsoluteFill, continueRender, delayRender, staticFile, useCurrentFrame} from 'remotion';
import {GoldBG, LogoPanel, PANEL_X, SAFE_L, W, H} from '../agha/AghaGalali';
import {useFonts} from '../agha/fonts';

export {PANEL_X, SAFE_L, W, H};
export const TAU = Math.PI * 2;
export const clamp01 = (x: number) => Math.min(1, Math.max(0, x));
export const easeOut = (t: number) => 1 - Math.pow(1 - clamp01(t), 3);
export const easeInOut = (t: number) => { t = clamp01(t); return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; };
export const easeOutBack = (t: number, s = 1.6) => { t = clamp01(t) - 1; return t * t * ((s + 1) * t + s) + 1; };
export const range = (f: number, a: number, b: number) => clamp01((f - a) / (b - a));
export const rand = (i: number, n = 0) => { const s = Math.sin(i * 127.1 + n * 311.7) * 43758.5453; return s - Math.floor(s); };

// Studio reflections without downloads.
export const Env: React.FC<{intensity?: number}> = ({intensity = 1}) => {
  const {gl, scene} = useThree();
  useEffect(() => {
    const pm = new THREE.PMREMGenerator(gl);
    const env = pm.fromScene(new RoomEnvironment(), 0.04).texture;
    scene.environment = env;
    scene.environmentIntensity = intensity;
    return () => { env.dispose(); pm.dispose(); };
  }, [gl, scene, intensity]);
  return null;
};

// Canvas over the visible content zone; the gold field and the logo panel stay as the brand frame.
export const CANVAS_L = SAFE_L - 40, CANVAS_W = PANEL_X - SAFE_L + 90;
export const Stage: React.FC<{children: React.ReactNode; overlay?: React.ReactNode; bg?: React.ReactNode; camera?: {fov: number; position: [number, number, number]}}> = ({children, overlay, bg, camera = {fov: 22, position: [0, 0, 10]}}) => {
  useFonts();
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{background: '#000', overflow: 'hidden'}}>
      {bg ?? <GoldBG f={f} />}
      <div style={{position: 'absolute', left: CANVAS_L, top: 0, width: CANVAS_W, height: H}}>
        <ThreeCanvas width={CANVAS_W} height={H} shadows gl={{alpha: true, antialias: true, preserveDrawingBuffer: true}} camera={camera} style={{background: 'transparent'}}>
          {children}
        </ThreeCanvas>
      </div>
      {overlay}
      <LogoPanel f={f} />
    </AbsoluteFill>
  );
};

// ---------- shaped Kurdish glyphs -> extruded 3D geometry ----------
export type GlyphJSON = {upm: number; width: number; glyphs: {d: string; x: number; y: number; cluster: number}[]};
const parsePath = (d: string, sp: THREE.ShapePath) => {
  const tok = d.match(/[MLQCZ]|-?\d*\.?\d+(?:e-?\d+)?/gi) ?? [];
  let i = 0; const n = () => parseFloat(tok[i++]);
  while (i < tok.length) {
    const c = tok[i++];
    if (c === 'M') sp.moveTo(n(), n());
    else if (c === 'L') sp.lineTo(n(), n());
    else if (c === 'Q') { const a = n(), b = n(), x = n(), y = n(); sp.quadraticCurveTo(a, b, x, y); }
    else if (c === 'C') { const a = n(), b = n(), cc = n(), dd = n(), x = n(), y = n(); sp.bezierCurveTo(a, b, cc, dd, x, y); }
    else if (c === 'Z' || c === 'z') { /* closed by toShapes */ }
  }
};
export type Glyph3D = {geom: THREE.ExtrudeGeometry; cx: number; cy: number; order: number};
// Returns one geometry per shaped glyph, centred on its own pivot, in world units where 1 = `size` em.
export const useGlyphs = (json: GlyphJSON, size: number, depth: number, bevel: number): Glyph3D[] => useMemo(() => {
  const s = size / json.upm;
  const out: Glyph3D[] = [];
  json.glyphs.forEach((g, idx) => {
    const sp = new THREE.ShapePath();
    parsePath(g.d, sp);
    (sp as unknown as {userData: object}).userData = {style: {fillRule: 'nonzero'}};
    const shapes = SVGLoader.createShapes(sp);
    const geom = new THREE.ExtrudeGeometry(shapes, {depth: depth / s, bevelEnabled: true, bevelThickness: bevel / s, bevelSize: (bevel * 0.8) / s, bevelSegments: 3, curveSegments: 10});
    geom.scale(s, s, s);
    geom.computeBoundingBox();
    const bb = geom.boundingBox!;
    const cx = (bb.min.x + bb.max.x) / 2, cy = (bb.min.y + bb.max.y) / 2;
    geom.translate(-cx, -cy, -depth / 2);
    out.push({geom, cx: cx + g.x * s - (json.width * s) / 2, cy: cy + g.y * s, order: idx});
  });
  return out;
}, [json, size, depth, bevel]);

// ---------- textures that need a loaded font or an image ----------
// While rendering, ThreeCanvas only redraws on frame change (frameloop "never"), so after a texture
// arrives we must advance R3F once ourselves before releasing the frame capture.
const useReleaseWhenReady = (ready: boolean, handle: number) => {
  const {advance} = useThree();
  useEffect(() => {
    if (!ready) return;
    advance(performance.now());
    requestAnimationFrame(() => continueRender(handle));
  }, [ready, advance, handle]);
};

export const useImageTexture = (src: string) => {
  const [h] = useState(() => delayRender('tex ' + src));
  const [tex, setTex] = useState<THREE.Texture | null>(null);
  useEffect(() => {
    new THREE.TextureLoader().load(staticFile(src), (t) => { t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 8; setTex(t); }, undefined, (e) => { console.error('texture failed', src, e); continueRender(h); });
  }, [src, h]);
  useReleaseWhenReady(!!tex, h);
  return tex;
};

// Draws on a 2D canvas after the Kurdish fonts are ready (canvas text uses the browser's shaping).
export const useCanvasTexture = (w: number, h: number, draw: (ctx: CanvasRenderingContext2D, img: Record<string, HTMLImageElement>) => void, images: string[] = []) => {
  const [hd] = useState(() => delayRender('canvas tex'));
  const [tex, setTex] = useState<THREE.CanvasTexture | null>(null);
  useEffect(() => {
    const load = (src: string) => new Promise<[string, HTMLImageElement]>((res) => { const im = new Image(); im.onload = () => res([src, im]); im.onerror = () => res([src, im]); im.src = staticFile(src); });
    Promise.all([document.fonts.ready, ...images.map(load)]).then(async (r) => {
      await Promise.all([document.fonts.load('900 40px NKufi'), document.fonts.load('900 40px NSans')]);
      const imgs: Record<string, HTMLImageElement> = {};
      (r.slice(1) as [string, HTMLImageElement][]).forEach(([k, v]) => { imgs[k] = v; });
      const c = document.createElement('canvas'); c.width = w; c.height = h;
      const ctx = c.getContext('2d')!;
      draw(ctx, imgs);
      const t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 8;
      setTex(t);
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useReleaseWhenReady(!!tex, hd);
  return tex;
};

export const BILL_SRC = [
  {src: 'notes/iqd.jpg', ar: 2.218}, {src: 'notes/usd.jpg', ar: 2.375}, {src: 'notes/eur.jpg', ar: 1.927}, {src: 'notes/gbp.jpg', ar: 1.87},
];
export const useBillTextures = () => {
  const a = useImageTexture(BILL_SRC[0].src), b = useImageTexture(BILL_SRC[1].src), c = useImageTexture(BILL_SRC[2].src), d = useImageTexture(BILL_SRC[3].src);
  return [a, b, c, d];
};

// a banknote mesh that bends along its length (bend in radians across the whole note)
export const bendPlane = (geom: THREE.PlaneGeometry, base: Float32Array, w: number, bend: number, wave = 0, phase = 0) => {
  const pos = geom.attributes.position as THREE.BufferAttribute;
  for (let i = 0; i < pos.count; i++) {
    const x = base[i * 3], y = base[i * 3 + 1];
    let px = x, pz = 0;
    if (Math.abs(bend) > 1e-4) { const r = w / bend; const a = x / r; px = r * Math.sin(a); pz = r * (1 - Math.cos(a)); }
    pz += wave * Math.sin((x / w) * TAU * 1.2 + phase);
    pos.setXYZ(i, px, y, pz);
  }
  pos.needsUpdate = true; geom.computeVertexNormals();
};
