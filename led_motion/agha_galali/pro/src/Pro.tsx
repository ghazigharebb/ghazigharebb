import React, {useMemo} from 'react';
import * as THREE from 'three';
import {AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {ThreeCanvas} from '@remotion/three';
import {CameraMotionBlur} from '@remotion/motion-blur';
import {GoldBG, LogoPanel, PANEL_X, SAFE_L, W, H, DARK} from '../agha/AghaGalali';
import {useFonts} from '../agha/fonts';
import {Env, useImageTexture, bendPlane, rand, TAU} from '../fx3d/common';

// ============================================================================
// Agha Galali — LED 936x260, 15 s seamless loop, "After Effects grade" finish:
// real camera motion blur, anamorphic flare + light-leak transitions, parallax gold
// bokeh (Lovart plates), 3D banknotes with paper bend, extruded engraved type.
// ============================================================================
export const LOOP = 450;
const ZW = PANEL_X - SAFE_L; // visible content zone (the left ~110 px of the sign are hidden)
const ZC = ZW / 2;
const C = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const expoOut = Easing.bezier(0.16, 1, 0.3, 1);
const expoIn = Easing.bezier(0.7, 0, 0.84, 0);
const expoIO = Easing.bezier(0.87, 0, 0.13, 1);
const r01 = (f: number, a: number, b: number) => Math.min(1, Math.max(0, (f - a) / (b - a)));
const ease = (f: number, a: number, b: number, e: (t: number) => number = expoOut) => e(r01(f, a, b));
const backOut = (t: number, s = 1.7) => { const x = Math.min(1, Math.max(0, t)) - 1; return x * x * ((s + 1) * x + s) + 1; };

// timeline
const S2 = 104, BILL_LEN = 44, S3 = 280, S4 = 366;
const CUTS = [0, S2, S2 + BILL_LEN, S2 + BILL_LEN * 2, S2 + BILL_LEN * 3, S3, S4];

const ESPRESSO = '#1a0f03';
const GOLD_GRAD = 'linear-gradient(180deg,#fff6cf 0%,#f3c94f 42%,#b8860b 68%,#ffe9a0 100%)';
const engrave = 'drop-shadow(0 1px 0 rgba(255,246,205,0.9)) drop-shadow(0 4px 6px rgba(60,30,0,0.45))';

// ---------------------------------------------------------------- background
const bgPlate = (() => { try { return staticFile('pro/gold_bg.jpg'); } catch { return null; } })();
const Background: React.FC<{f: number; plate: boolean}> = ({f, plate}) => {
  const p = (TAU * f) / LOOP;
  return (
    <AbsoluteFill style={{overflow: 'hidden'}}>
      {plate && bgPlate ? (
        <>
          <Img src={bgPlate} style={{position: 'absolute', width: W * 1.12, height: H * 1.12, left: -W * 0.06 + Math.sin(p) * 14, top: -H * 0.06 + Math.cos(p) * 4, objectFit: 'cover'}} />
          {/* moving sheen like a light rig passing over metal */}
          <div style={{position: 'absolute', top: -60, bottom: -60, left: ((f % 150) / 150) * (W + 900) - 450, width: 300, transform: 'skewX(-24deg)', mixBlendMode: 'soft-light',
            background: 'linear-gradient(90deg,rgba(255,250,220,0),rgba(255,250,220,0.6),rgba(255,250,220,0))'}} />
          <AbsoluteFill style={{background: 'radial-gradient(120% 140% at 40% 50%,rgba(0,0,0,0) 55%,rgba(50,25,0,0.5) 100%)'}} />
          <div style={{position: 'absolute', top: 5, bottom: 5, right: 5, left: -20, border: '2px solid rgba(70,40,0,0.55)', borderRadius: 4, boxShadow: 'inset 0 0 0 1px rgba(255,240,190,0.35)'}} />
        </>
      ) : <GoldBG f={f} />}
    </AbsoluteFill>
  );
};

// parallax bokeh from the Lovart dust plate (screen blend), seamless over the loop
const Bokeh: React.FC<{f: number; front?: boolean}> = ({f, front}) => {
  const tileW = front ? W * 1.6 : W;
  const tileH = (tileW * 768) / 1376;
  const speed = front ? 2 : 1; // tiles per loop
  const off = ((f * speed) / LOOP) * tileW;
  const y = Math.sin((TAU * f) / LOOP) * 10 - (tileH - H) / 2;
  return (
    <div style={{position: 'absolute', inset: 0, overflow: 'hidden', mixBlendMode: 'screen', opacity: front ? 0.28 : 0.5, filter: front ? 'blur(2.5px)' : undefined}}>
      {[0, 1, 2].map((k) => (
        <Img key={k} src={staticFile('pro/dust.jpg')} style={{position: 'absolute', top: y, left: k * tileW - off, width: tileW, height: tileH}} />
      ))}
    </div>
  );
};

// anamorphic flare plate (Lovart) + warm light leak, used on every cut
const Flare: React.FC<{f: number; at: number; big?: boolean}> = ({f, at, big}) => {
  let d = f - at;
  if (d < -LOOP / 2) d += LOOP; if (d > LOOP / 2) d -= LOOP;
  const span = big ? 16 : 11;
  if (d < -span || d > span) return null;
  const t = (d + span) / (2 * span);
  const x = interpolate(t, [0, 1], [PANEL_X + 60, SAFE_L - 160], {easing: expoIO});
  const a = Math.sin(Math.PI * t);
  const fw = big ? 1500 : 1100;
  return (
    <>
      <Img src={staticFile('pro/flare.jpg')} style={{position: 'absolute', left: x - fw / 2, top: H / 2 - (big ? 170 : 120), width: fw, height: big ? 340 : 240, mixBlendMode: 'screen', opacity: a * (big ? 1 : 0.85)}} />
      <div style={{position: 'absolute', left: x - 260, top: -120, width: 520, height: 500, mixBlendMode: 'screen', opacity: a * (big ? 0.7 : 0.45),
        background: 'radial-gradient(closest-side,rgba(255,170,60,0.85),rgba(255,120,30,0.35) 45%,rgba(255,90,0,0) 100%)'}} />
    </>
  );
};

// ---------------------------------------------------------------- extruded engraved type
const Extruded: React.FC<{text: string; size: number; glint?: number; depth?: number}> = ({text, size, glint = -50, depth = 6}) => {
  const layers = [];
  for (let k = depth; k >= 1; k--) {
    const c = Math.round(26 + (depth - k) * 6);
    layers.push(<span key={k} aria-hidden style={{position: 'absolute', inset: 0, color: `rgb(${c + 30},${c + 12},${Math.max(0, c - 18)})`, transform: `translate(${k * 0.55}px,${k * 0.85}px)`}}>{text}</span>);
  }
  return (
    <span style={{position: 'relative', display: 'inline-block', fontFamily: 'NKufi', fontWeight: 900, fontSize: size, lineHeight: 1.45, whiteSpace: 'nowrap'}}>
      {layers}
      <span style={{position: 'relative', backgroundImage: `linear-gradient(100deg,${ESPRESSO} 0%,${ESPRESSO} ${glint - 9}%,#8a5a0c ${glint - 3}%,#fff3bf ${glint}%,#8a5a0c ${glint + 3}%,${ESPRESSO} ${glint + 9}%,${ESPRESSO} 100%)`,
        WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent', filter: 'drop-shadow(0 -1px 0 rgba(255,236,180,0.55))'}}>{text}</span>
    </span>
  );
};

const Burst: React.FC<{f: number; at: number; x: number; y: number; n?: number; spread?: number}> = ({f, at, x, y, n = 14, spread = 70}) => {
  const d = f - at;
  if (d < 0 || d > 26) return null;
  return (
    <>
      {Array.from({length: n}, (_, i) => {
        const a = rand(i + at, 1) * TAU, sp = (0.35 + rand(i + at, 2) * 0.65) * spread;
        const t = d / 26, e = 1 - Math.pow(1 - t, 3);
        const s = 2 + rand(i + at, 3) * 3.5;
        return <div key={i} style={{position: 'absolute', left: x + Math.cos(a) * sp * e - s, top: y + Math.sin(a) * sp * e * 0.6 + 18 * t * t - s, width: s * 2, height: s * 2, borderRadius: '50%',
          background: 'radial-gradient(circle,#fffbe6,#f3c94f 55%,rgba(243,201,79,0))', opacity: 1 - t}} />;
      })}
      <div style={{position: 'absolute', left: x - 90, top: y - 90, width: 180, height: 180, borderRadius: '50%', mixBlendMode: 'screen', opacity: Math.max(0, 1 - d / 12),
        background: 'radial-gradient(circle,rgba(255,244,200,0.9),rgba(255,210,110,0.35) 40%,rgba(255,200,90,0) 70%)'}} />
    </>
  );
};

// ---------------------------------------------------------------- S1: name
const SceneName: React.FC<{f: number}> = ({f}) => {
  const words = ['آغا', 'گەڵاڵی']; // RTL order: first word sits on the right
  const push = 1 + 0.05 * r01(f, 0, 110);
  const out = ease(f, 94, 108, expoIn);
  const glint = interpolate(f, [44, 82], [-20, 125], {...C, easing: expoIO});
  const sub = ease(f, 32, 52);
  const lines = ease(f, 40, 62);
  return (
    <div style={{position: 'absolute', inset: 0, transform: `translateX(${-out * ZW * 1.25}px) scale(${push})`, transformOrigin: '50% 45%'}}>
      <div dir="rtl" style={{position: 'absolute', left: 0, right: 0, top: 24, display: 'flex', justifyContent: 'center', gap: 22, perspective: 600, filter: engrave}}>
        {words.map((w, i) => {
          const s = 6 + i * 8;
          const t = r01(f, s, s + 24);
          const e = expoOut(t);
          return (
            <div key={w} style={{opacity: Math.min(1, t * 4), transform: `translateX(${(1 - e) * -140}px) translateZ(${(1 - e) * -320}px) rotateY(${(1 - e) * 62}deg)`, transformOrigin: '50% 50%'}}>
              <Extruded text={w} size={90} glint={glint} />
            </div>
          );
        })}
      </div>
      <Burst f={f} at={22} x={ZC + 140} y={92} />
      <Burst f={f} at={30} x={ZC - 70} y={92} n={18} spread={95} />
      {/* subtitle: rules draw outward from the centre, text opens from the centre */}
      <div dir="rtl" style={{position: 'absolute', left: 0, right: 0, top: 186, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 14}}>
        <Rule w={100 * lines} />
        <span style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 30, color: DARK, filter: engrave, clipPath: `inset(0 ${(1 - sub) * 50}% 0 ${(1 - sub) * 50}%)`, whiteSpace: 'nowrap'}}>{'بۆ ئاڵوگۆڕی دراو'}</span>
        <Rule w={100 * lines} flip />
      </div>
    </div>
  );
};
const Rule: React.FC<{w: number; flip?: boolean}> = ({w, flip}) => (
  <div style={{display: 'flex', alignItems: 'center', flexDirection: flip ? 'row-reverse' : 'row', width: 100, justifyContent: 'flex-start', filter: engrave}}>
    <div style={{width: 9, height: 9, background: DARK, transform: `rotate(45deg) scale(${w > 90 ? 1 : w / 90})`, flexShrink: 0}} />
    <div style={{width: Math.max(0, w - 12), height: 3, background: DARK, borderRadius: 2, marginLeft: flip ? 0 : 3, marginRight: flip ? 3 : 0}} />
  </div>
);

// ---------------------------------------------------------------- S2: 3D banknotes
const BILLS = [
  {src: 'notes/iqd.jpg', ar: 2.218, name: 'دیناری عێراقی', code: 'IQD', denom: '25,000', accent: '#c0392b'},
  {src: 'notes/usd.jpg', ar: 2.375, name: 'دۆلاری ئەمریکی', code: 'USD', denom: '100', accent: '#1e7a46'},
  {src: 'notes/eur.jpg', ar: 1.927, name: 'یۆرۆ', code: 'EUR', denom: '100', accent: '#2a56c6'},
  {src: 'notes/gbp.jpg', ar: 1.87, name: 'پاوەندی بەریتانی', code: 'GBP', denom: '50', accent: '#8e2a5a'},
];
const U = 66.9; // px per world unit at fov 22, z 10, 260 px tall
const NOTE_X = (186 - ZC) / U;

const Bill3D: React.FC<{f: number; i: number}> = ({f, i}) => {
  const b = BILLS[i];
  const tex = useImageTexture(b.src);
  const w = Math.min(4.5, 2.25 * b.ar), h = w / b.ar;
  const geom = useMemo(() => new THREE.PlaneGeometry(w, h, 24, 2), [w, h]);
  const base = useMemo(() => Float32Array.from(geom.attributes.position.array as Float32Array), [geom]);
  const t = f - (S2 + i * BILL_LEN);
  const inn = ease(t, 0, 18);
  const out = ease(t, BILL_LEN - 4, BILL_LEN + 8, expoIn);
  const x = NOTE_X + (1 - inn) * 8.5 - out * 10;
  const ry = (1 - inn) * -1.15 + out * 0.9 + 0.1 * Math.cos(t / 9);
  const rz = (1 - inn) * 0.22 - out * 0.15;
  const y = 0.08 + Math.sin(t / 11) * 0.05;
  const wave = 0.32 * (1 - inn) + 0.4 * out + 0.025;
  bendPlane(geom, base, w, (1 - inn) * -0.5 + out * 0.6, wave, t * 0.35);
  if (!tex || t < -2 || t > BILL_LEN + 10) return null;
  return (
    <mesh geometry={geom} position={[x, y, (1 - inn) * -1.2]} rotation={[0.04 * Math.sin(t / 13), ry, rz]} castShadow>
      <meshPhysicalMaterial map={tex} roughness={0.42} clearcoat={0.4} clearcoatRoughness={0.25} side={THREE.DoubleSide} envMapIntensity={0.55} />
    </mesh>
  );
};

const BillLights: React.FC<{f: number}> = ({f}) => {
  // a glint light travels across each note while it is held
  const t = (f - S2) % BILL_LEN;
  const lx = interpolate(t, [14, 40], [3.5, -5.5], C);
  return (
    <>
      <ambientLight intensity={0.55} />
      <directionalLight position={[-2.5, 4, 6]} intensity={2.1} castShadow shadow-mapSize-width={1024} shadow-mapSize-height={1024}
        shadow-camera-left={-6} shadow-camera-right={6} shadow-camera-top={3} shadow-camera-bottom={-3} />
      <pointLight position={[lx, 1.2, 2.2]} intensity={t > 12 && t < 42 ? 16 : 0} distance={5.5} color="#fff4d6" />
      <mesh position={[0, 0, -0.55]} receiveShadow><planeGeometry args={[30, 10]} /><shadowMaterial opacity={0.3} color="#3a2200" /></mesh>
    </>
  );
};

const BillLabels: React.FC<{f: number}> = ({f}) => (
  <>
    {BILLS.map((b, i) => {
      const t = f - (S2 + i * BILL_LEN);
      if (t < -2 || t > BILL_LEN + 10) return null;
      const nameIn = ease(t, 6, 20);
      const chip = backOut(r01(t, 11, 22));
      const ring = r01(t, 14, 30);
      const under = ease(t, 9, 24);
      const out = ease(t, BILL_LEN - 6, BILL_LEN + 4, expoIn);
      const giant = interpolate(t, [0, BILL_LEN + 8], [40, -40]);
      return (
        <React.Fragment key={b.code}>
          {/* giant outlined denomination drifting behind the note (kinetic depth) */}
          <div dir="ltr" style={{position: 'absolute', left: 10 + giant, top: 6, fontFamily: 'NSans', fontWeight: 900, fontSize: b.denom.length > 3 ? 150 : 210, lineHeight: 1,
            color: 'transparent', WebkitTextStroke: '2px rgba(70,38,0,0.22)', opacity: ease(t, 0, 12) * (1 - out), whiteSpace: 'nowrap'}}>{b.denom}</div>
          <div dir="rtl" style={{position: 'absolute', left: 334, right: 10, top: 52, textAlign: 'center', transform: `translateY(${-out * 30}px)`, opacity: 1 - out}}>
            <div style={{overflow: 'hidden', paddingTop: 6, paddingBottom: 12, marginBottom: -12}}>
              <div style={{transform: `translateY(${(1 - nameIn) * 110}%)`, fontFamily: 'NKufi', fontWeight: 900, fontSize: b.name.length > 12 ? 23 : b.name.length > 8 ? 27 : 46,
                lineHeight: 1.55, color: DARK, filter: engrave, whiteSpace: 'nowrap'}}>{b.name}</div>
            </div>
            <div style={{height: 3, width: 150 * under, margin: '2px auto 10px', background: `linear-gradient(90deg,rgba(26,15,3,0),${DARK},rgba(26,15,3,0))`}} />
            <div style={{position: 'relative', display: 'inline-block', transform: `scale(${chip})`}}>
              <div style={{position: 'absolute', inset: -4, borderRadius: 40, border: `2px solid ${b.accent}`, transform: `scale(${1 + ring * 0.8})`, opacity: (1 - ring) * 0.9}} />
              <div style={{padding: '2px 18px 4px', borderRadius: 30, background: 'linear-gradient(180deg,#2a2a2c,#050505)',
                boxShadow: `0 0 0 2px #e9c25a, 0 0 0 4px ${b.accent}, 0 6px 12px rgba(60,30,0,0.45), 0 0 ${18 * (1 - ring)}px ${b.accent}`}}>
                <span style={{fontFamily: 'NSans', fontWeight: 900, fontSize: 28, letterSpacing: 3, backgroundImage: GOLD_GRAD, WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent'}}>{b.code}</span>
              </div>
            </div>
          </div>
        </React.Fragment>
      );
    })}
  </>
);

const ZoneCanvas: React.FC<{children: React.ReactNode}> = ({children}) => (
  <ThreeCanvas width={ZW} height={H} shadows gl={{alpha: true, antialias: true, preserveDrawingBuffer: true}} camera={{fov: 22, position: [0, 0, 10]}} style={{position: 'absolute', left: 0, top: 0}}>
    {children}
  </ThreeCanvas>
);

const SceneBills: React.FC<{f: number}> = ({f}) => (
  <>
    <BillLabels f={f} />
    <ZoneCanvas>
      <Env intensity={1} />
      <BillLights f={f} />
      {BILLS.map((_, i) => <Bill3D key={i} f={f} i={i} />)}
    </ZoneCanvas>
  </>
);

// ---------------------------------------------------------------- S3: FIB
const SceneFIB: React.FC<{f: number}> = ({f}) => {
  const t = f - S3;
  const card = ease(t, 2, 26);
  const out = ease(t, 80, 92, expoIn);
  const sheen = interpolate(t, [24, 46], [-40, 140], {...C, easing: expoIO});
  const w1 = ease(t, 14, 30), w2 = ease(t, 22, 38);
  const tilt = Math.sin((TAU * t) / 90) * 5;
  const cardStyle: React.CSSProperties = {position: 'absolute', inset: 0, borderRadius: 18, overflow: 'hidden', background: 'linear-gradient(160deg,#ffffff,#eef2f2)'};
  return (
    <div style={{position: 'absolute', inset: 0, transform: `translateX(${-out * ZW * 1.25}px)`}}>
      <div style={{position: 'absolute', left: 6, top: 52, width: 212, height: 124, perspective: 700}}>
        <div style={{position: 'absolute', inset: 0, transformStyle: 'preserve-3d',
          transform: `translateX(${(1 - card) * -220}px) rotateY(${(1 - card) * -105 + tilt}deg) rotateX(${tilt * 0.5}deg) scale(${0.8 + 0.2 * card})`}}>
          <div style={{...cardStyle, boxShadow: `0 14px 26px rgba(60,30,0,0.45), 0 0 0 3px #e9c25a, 0 0 0 5px #6b4305, 0 0 ${10 + 8 * Math.sin(t / 6)}px rgba(255,220,120,0.8)`}}>
            <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 9, background: 'linear-gradient(90deg,#0fa596,#14c2b0)'}} />
            <Img src={staticFile('fib.png')} style={{position: 'absolute', left: 14, top: 34, width: 184}} />
            <div style={{position: 'absolute', top: -40, bottom: -40, left: `${sheen}%`, width: 60, transform: 'skewX(-20deg)',
              background: 'linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,0.95),rgba(255,255,255,0))'}} />
          </div>
        </div>
      </div>
      {/* gold particle stream: card -> text */}
      {Array.from({length: 12}, (_, k) => {
        const p = ((t * 1.3 + k * 9) % 54) / 54;
        const x0 = 222, x1 = 300, cx = (x0 + x1) / 2;
        const x = (1 - p) * (1 - p) * x0 + 2 * (1 - p) * p * cx + p * p * x1;
        const y = 116 + Math.sin(p * Math.PI) * -26 + Math.sin(k) * 6;
        const a = Math.sin(Math.PI * p) * card * (1 - out);
        return <div key={k} style={{position: 'absolute', left: x - 3, top: y - 3, width: 6, height: 6, borderRadius: '50%', opacity: a,
          background: 'radial-gradient(circle,#fffbe6,#f3c94f 60%,rgba(243,201,79,0))', boxShadow: '0 0 6px rgba(255,220,120,0.9)'}} />;
      })}
      <div dir="rtl" style={{position: 'absolute', left: 252, right: 8, top: 56, textAlign: 'center', fontFamily: 'NKufi', fontWeight: 900, color: DARK, filter: engrave}}>
        <div style={{fontSize: 32, lineHeight: 1.65, overflow: 'hidden', whiteSpace: 'nowrap', paddingBottom: 8, marginBottom: -8}}>
          <div style={{transform: `translateY(${(1 - w1) * 120}%)`}}>{'ناردن و وەرگرتنی'}</div>
        </div>
        <div style={{fontSize: 32, lineHeight: 1.65, overflow: 'hidden', whiteSpace: 'nowrap', paddingBottom: 8, marginBottom: -8}}>
          <div style={{transform: `translateY(${(1 - w2) * 120}%)`}}>
            {'پارە بە '}<span dir="ltr" style={{fontFamily: 'NSans', color: '#0b7f74', textShadow: `0 0 ${8 * w2}px rgba(20,194,176,0.8)`}}>FIB</span>
          </div>
        </div>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- S4: 3D money rain + ribbon
const RAIN = Array.from({length: 26}, (_, i) => ({
  b: i % 4, x: -3.9 + rand(i, 1) * 7.8, z: -2.6 + rand(i, 2) * 4.2, delay: rand(i, 3) * 26, sp: 0.07 + rand(i, 4) * 0.05,
  w: 1.05 + rand(i, 5) * 0.5, tum: 0.05 + rand(i, 6) * 0.08, ph: rand(i, 7) * TAU,
}));
const RainNote: React.FC<{f: number; i: number; tex: THREE.Texture | null}> = ({f, i, tex}) => {
  const p = RAIN[i];
  const b = BILLS[p.b];
  const geom = useMemo(() => new THREE.PlaneGeometry(p.w, p.w / b.ar, 10, 1), [p.w, b.ar]);
  const base = useMemo(() => Float32Array.from(geom.attributes.position.array as Float32Array), [geom]);
  const t = f - S4 - p.delay;
  if (!tex || t < 0) return null;
  const y = 2.8 - t * p.sp * (1 + t / 70) * 1.2;
  if (y < -3.2) return null;
  bendPlane(geom, base, p.w, 0.5 * Math.sin(t / 8 + p.ph), 0.05, t * 0.4 + p.ph);
  return (
    <mesh geometry={geom} position={[p.x + Math.sin(t / 10 + p.ph) * 0.35, y, p.z]} rotation={[t * p.tum + p.ph, Math.sin(t / 9 + p.ph) * 0.8, Math.sin(t / 12 + p.ph) * 0.6]} castShadow>
      <meshStandardMaterial map={tex} side={THREE.DoubleSide} roughness={0.5} envMapIntensity={0.6} />
    </mesh>
  );
};
const RainNotes: React.FC<{f: number}> = ({f}) => {
  const tex = [useImageTexture(BILLS[0].src), useImageTexture(BILLS[1].src), useImageTexture(BILLS[2].src), useImageTexture(BILLS[3].src)];
  return <>{RAIN.map((p, i) => <RainNote key={i} f={f} i={i} tex={tex[p.b]} />)}</>;
};
const SceneRain: React.FC<{f: number}> = ({f}) => {
  const t = f - S4;
  const rib = ease(t, 8, 26);
  const txt = ease(t, 16, 32);
  const sweep = interpolate(t, [30, 54], [-30, 130], {...C, easing: expoIO});
  const out = ease(t, 60, 74, expoIn);
  return (
    <div style={{position: 'absolute', inset: 0}}>
      <ZoneCanvas>
        <Env intensity={1} />
        <ambientLight intensity={0.7} />
        <directionalLight position={[2, 5, 6]} intensity={2} castShadow shadow-mapSize-width={1024} shadow-mapSize-height={1024}
          shadow-camera-left={-6} shadow-camera-right={6} shadow-camera-top={4} shadow-camera-bottom={-4} />
        <mesh position={[0, 0, -3]} receiveShadow><planeGeometry args={[40, 14]} /><shadowMaterial opacity={0.18} color="#3a2200" /></mesh>
        <RainNotes f={f} />
      </ZoneCanvas>
      <div dir="rtl" style={{position: 'absolute', left: ZC - 268, width: 536, top: 94, height: 72, borderRadius: 14, transform: `scaleX(${rib}) scale(${1 + out * 0.06})`, opacity: 1 - out,
        background: 'linear-gradient(180deg,#2c2c2e,#0b0b0c 55%,#1b1b1d)', boxShadow: `0 0 0 3px #e9c25a, 0 0 0 5px #6b4305, 0 14px 26px rgba(40,20,0,0.6), 0 0 ${16 + 10 * Math.sin(t / 5)}px rgba(255,210,110,0.7)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden'}}>
        <span style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 32, lineHeight: 1, paddingTop: 6, whiteSpace: 'nowrap', clipPath: `inset(0 ${(1 - txt) * 50}% 0 ${(1 - txt) * 50}%)`,
          backgroundImage: `linear-gradient(100deg,#b8860b 0%,#f3c94f ${sweep - 12}%,#fffbe6 ${sweep}%,#f3c94f ${sweep + 12}%,#b8860b 100%)`, WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent'}}>{'ئاڵوگۆڕی هەموو دراوەکان'}</span>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- content (motion-blurred)
const Content: React.FC = () => {
  useFonts();
  const f = useCurrentFrame();
  return (
    <AbsoluteFill>
      <div style={{position: 'absolute', left: SAFE_L, top: 0, width: ZW, height: H, overflow: 'hidden'}}>
        {f < S2 + 8 && <SceneName f={f} />}
        {f >= S2 - 2 && f < S3 + 2 && <SceneBills f={f} />}
        {f >= S3 - 2 && f < S4 + 2 && <SceneFIB f={f} />}
        {f >= S4 - 2 && <SceneRain f={f} />}
      </div>
    </AbsoluteFill>
  );
};

export const AghaGalaliPro: React.FC<{plate?: boolean; samples?: number}> = ({plate = true, samples = 6}) => {
  useFonts();
  const f = useCurrentFrame();
  const glare = (() => { const d = f > LOOP / 2 ? f - LOOP : f; return interpolate(d, [-8, 0, 10], [0, 0.6, 0], C); })();
  return (
    <AbsoluteFill style={{background: '#000', overflow: 'hidden'}}>
      <Background f={f} plate={plate} />
      <Bokeh f={f} />
      {samples > 1 ? <CameraMotionBlur shutterAngle={200} samples={samples}><Content /></CameraMotionBlur> : <Content />}
      <Bokeh f={f} front />
      <div style={{position: 'absolute', left: 0, top: 0, width: PANEL_X + 30, height: H, overflow: 'hidden'}}>
        {CUTS.map((c, i) => <Flare key={i} f={f} at={c} big={i === 0 || c === S3 || c === S4} />)}
      </div>
      {glare > 0 && <AbsoluteFill style={{background: `radial-gradient(70% 120% at ${SAFE_L + ZC}px 50%,rgba(255,250,225,${glare}) 0%,rgba(255,225,140,${glare * 0.5}) 50%,rgba(255,210,100,0) 100%)`}} />}
      <LogoPanel f={f} />
    </AbsoluteFill>
  );
};
