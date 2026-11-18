import React from 'react';
import {AbsoluteFill, Img, staticFile, useCurrentFrame} from 'remotion';
import {CameraMotionBlur} from '@remotion/motion-blur';
import {W, H, YELLOW, INK, TAU, rng, eIn, eIO, lerp, useShxFonts} from './shx';

// ============================================================================
// SHEXANI — LED 936x260, 20 s seamless loop (8 items x 2.5 s).
// One thing at a time, big. Left: a Shexani-Yellow panel whose edge is the arrow of the logo, carrying a
// deck of real banknotes and service cards; the front one glides away and the next comes forward.
// Right: the official logo, fixed, in every frame. Once per loop the yellow sweeps the whole sign.
// All content stays inside x = 140..796.
// ============================================================================
const ITEM = 75, MOVE = 30;
type Item = {img: string; ar: number; name: string; sym?: string; card?: boolean};
const ITEMS: Item[] = [
  {img: 'notes/iqd.jpg', ar: 2.218, name: 'دیناری عێراقی', sym: 'د.ع'},
  {img: 'notes/usd.jpg', ar: 2.375, name: 'دۆلاری ئەمریکی', sym: '$'},
  {img: 'notes/eur.jpg', ar: 1.927, name: 'یۆرۆ', sym: '€'},
  {img: 'notes/gbp.jpg', ar: 1.87, name: 'پاوەندی بەریتانی', sym: '£'},
  {img: 'notes/irr.jpg', ar: 2.219, name: 'تومەنی ئێرانی', sym: '﷼'},
  {img: 'shexani/pay/fib_new.png', ar: 2.472, name: 'FIB', card: true},
  {img: 'shexani/pay/qi.png', ar: 2.094, name: 'کی کارد', card: true},
  {img: 'shexani/pay/nass.png', ar: 3.491, name: 'ناس واڵێت', card: true},
];
const NI = ITEMS.length;
export const LOOP2 = ITEM * NI; // 600

// ---- layout ----
const TIP = 462, SLOPE = 79;                 // panel edge = the logo's arrow: tip at mid-height
const DCX = 294, DCY = 96;                   // deck centre
const LOGO_AR = 1925.1 / 819.4, LW = 324, LH = LW / LOGO_AR;
const LOGO_L = 798 - LW, LOGO_T = 130 - 0.3905 * LH; // the panel's tip points at the X of the logo

// yellow covers everything left of this arrow-shaped edge; once per loop it sweeps the whole sign
const tipAt = (f: number) => {
  const e = f > LOOP2 / 2 ? eIO(rng(f, LOOP2 - 44, LOOP2 - 8)) : 1 - eIO(rng(f, 10, 50));
  return lerp(TIP, W + SLOPE + 40, e);
};
const arrowClip = (tip: number, inset = 0) => `polygon(-10px -10px, ${tip - SLOPE - inset}px -10px, ${tip - inset}px 50%, ${tip - SLOPE - inset}px calc(100% + 10px), -10px calc(100% + 10px))`;

const Rosette: React.FC<{cx: number; cy: number; r: number; rot: number}> = ({cx, cy, r, rot}) => (
  <g transform={`rotate(${rot} ${cx} ${cy})`} stroke="#8A5A00" fill="none" strokeWidth={1.2} opacity={0.13}>
    {[0, 1, 2, 3, 4, 5].map((n) => {
      let d = '';
      for (let i = 0; i <= 240; i++) { const t = (i / 240) * TAU; const rr = r + r * 0.16 * Math.sin(16 * t + (n * TAU) / 96); d += `${i ? 'L' : 'M'}${(cx + rr * Math.cos(t)).toFixed(1)} ${(cy + rr * Math.sin(t)).toFixed(1)}`; }
      return <path key={n} d={d} />;
    })}
  </g>
);

// ---------------------------------------------------------------- the stage: one item at a time
// Motion rules: horizontal only, no bounce, no overshoot, nothing moves while an item is held.
// The outgoing item accelerates away to the left and fades; the incoming one arrives from the logo side and
// settles on a long quintic ease-out (velocity reaches zero exactly at rest). Sizes and rest positions are
// whole pixels so nothing shimmers on the LED while it is still.
const OUT_END = 24, IN_A = 6, IN_B = 44, TRAVEL = 150;
const quintOut = (t: number) => 1 - Math.pow(1 - Math.min(1, Math.max(0, t)), 5);
const itemSize = (it: Item) => { if (it.card) return {w: 292, h: 142}; const w = Math.round(Math.min(304, 142 * it.ar)); return {w, h: Math.round(w / it.ar)}; };

const Card: React.FC<{it: Item; dx: number; op: number; sc: number; ry: number; sheen: number}> = ({it, dx, op, sc, ry, sheen}) => {
  const {w, h} = itemSize(it);
  if (op <= 0.001) return null;
  return (
    <div style={{position: 'absolute', left: Math.round(DCX - w / 2), top: Math.round(DCY - h / 2), width: w, height: h, opacity: op, perspective: 900, transform: `translateX(${dx}px)`}}>
      <div style={{position: 'absolute', inset: 0, borderRadius: it.card ? 16 : 6, overflow: 'hidden', background: it.card ? '#ffffff' : undefined,
        transform: `scale(${sc}) rotateY(${ry}deg)`, boxShadow: `0 16px 28px rgba(70,45,0,0.48)${it.card ? ', 0 0 0 2px rgba(22,19,13,0.9)' : ''}`}}>
        {it.card
          ? (() => { const lw = Math.round(Math.min(w - 56, (h - 54) * it.ar)), lh = Math.round(lw / it.ar); return <Img src={staticFile(it.img)} style={{position: 'absolute', left: Math.round((w - lw) / 2), top: Math.round((h - lh) / 2), width: lw, height: lh}} />; })()
          : <Img src={staticFile(it.img)} style={{position: 'absolute', inset: 0, width: w, height: h}} />}
        {sheen > -44 && sheen < 149 && <div style={{position: 'absolute', top: -30, bottom: -30, left: `${sheen}%`, width: 54, transform: 'skewX(-20deg)', background: 'linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,0.6),rgba(255,255,255,0))'}} />}
      </div>
    </div>
  );
};

const Caption: React.FC<{it: Item; dx: number; op: number}> = ({it, dx, op}) => {
  if (op <= 0.001) return null;
  const size = it.name.length > 14 ? 23 : it.name.length > 11 ? 26 : 36;
  const arabicSym = !!it.sym && it.sym.charCodeAt(0) > 0x500;
  return (
    <div dir="rtl" style={{position: 'absolute', left: 140, width: 266, top: 183, height: 62, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, opacity: op, transform: `translateX(${dx}px)`}}>
      {it.sym && (
        <span style={{flexShrink: 0, width: 42, height: 42, borderRadius: 21, background: INK, display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: arabicSym ? 'ShxKufi' : 'ShxMont', fontWeight: 800, fontSize: arabicSym ? (it.sym.length > 2 ? 16 : 20) : 26, color: YELLOW, lineHeight: 1, paddingBottom: arabicSym ? 5 : 0, direction: arabicSym ? 'rtl' : 'ltr'}}>{it.sym}</span>
      )}
      <span style={{fontFamily: 'ShxKufi, ShxMont', fontWeight: 800, fontSize: size, lineHeight: 1.5, color: INK, whiteSpace: 'nowrap', paddingBottom: 6}}>{it.name}</span>
    </div>
  );
};

const Deck: React.FC = () => {
  const f = useCurrentFrame();
  const i0 = Math.floor(f / ITEM) % NI, local = f % ITEM;
  const prev = (i0 - 1 + NI) % NI;
  const q = eIn(rng(local, 0, OUT_END));                 // outgoing: 0 at rest -> 1 gone
  const tin = rng(local, IN_A, IN_B), pin = quintOut(tin); // incoming: 0 away -> 1 at rest
  const inOp = eIO(rng(tin, 0, 0.3));
  const sheen = lerp(-45, 150, eIO(rng(local, IN_B + 2, IN_B + 26)));
  const capOut = eIn(rng(local, 0, 14)), capT = rng(local, 14, 44), capIn = quintOut(capT);
  const dot = eIO(rng(local, 4, 28));
  return (
    <AbsoluteFill>
      <Card it={ITEMS[prev]} dx={-TRAVEL * q} op={1 - q} sc={1 - 0.07 * q} ry={24 * q} sheen={-100} />
      <Card it={ITEMS[i0]} dx={TRAVEL * (1 - pin)} op={inOp} sc={0.93 + 0.07 * pin} ry={-24 * (1 - pin)} sheen={sheen} />
      <Caption it={ITEMS[prev]} dx={-18 * capOut} op={1 - capOut} />
      <Caption it={ITEMS[i0]} dx={18 * (1 - capIn)} op={eIO(rng(capT, 0, 0.4))} />
      {/* progress: one dot per item, the active one stretches smoothly */}
      <div style={{position: 'absolute', left: 148, top: 248, display: 'flex', gap: 5}}>
        {ITEMS.map((_, j) => { const a = j === i0 ? dot : j === prev ? 1 - dot : 0; return <div key={j} style={{width: 5 + 11 * a, height: 5, borderRadius: 3, background: INK, opacity: 0.3 + 0.6 * a}} />; })}
      </div>
    </AbsoluteFill>
  );
};

export const ShexaniMaster2: React.FC<{samples?: number}> = ({samples = 6}) => {
  useShxFonts();
  const f = useCurrentFrame();
  const tip = tipAt(f);
  const logo = (src: string) => <Img src={staticFile(src)} style={{position: 'absolute', left: LOGO_L, top: LOGO_T, width: LW, height: LH}} />;
  return (
    <AbsoluteFill style={{background: INK, overflow: 'hidden'}}>
      {/* Ink side: the logo, fixed */}
      <AbsoluteFill style={{background: `radial-gradient(70% 120% at 70% 45%,#262016 0%,${INK} 55%,#0d0b07 100%)`}} />
      {logo('shexani/logo_tag_dark.svg')}
      {/* soft shadow the yellow panel casts on the Ink side */}
      <div style={{position: 'absolute', inset: 0, clipPath: arrowClip(tip + 14), background: 'rgba(0,0,0,0.45)', filter: 'blur(7px)'}} />
      {/* Yellow panel */}
      <div style={{position: 'absolute', inset: 0, clipPath: arrowClip(tip), background: `radial-gradient(60% 110% at ${DCX}px 40%,#FFD23F 0%,${YELLOW} 55%,#E0A600 100%)`}}>
        <svg width={W} height={H} style={{position: 'absolute'}}>
          <Rosette cx={DCX} cy={110} r={150} rot={(f / LOOP2) * 22.5} />
          <Rosette cx={DCX} cy={110} r={230} rot={-(f / LOOP2) * 22.5} />
        </svg>
        {logo('shexani/logo_tag_yellow.svg')}
      </div>
      {/* a darker band just inside the edge gives the arrow thickness */}
      <div style={{position: 'absolute', inset: 0, clipPath: arrowClip(tip), pointerEvents: 'none'}}>
        <div style={{position: 'absolute', inset: 0, clipPath: `polygon(${tip - SLOPE - 22}px -10px, ${tip - SLOPE}px -10px, ${tip}px 50%, ${tip - SLOPE}px calc(100% + 10px), ${tip - SLOPE - 22}px calc(100% + 10px), ${tip - 22}px 50%)`, background: 'rgba(138,90,0,0.38)'}} />
      </div>
      {samples > 1 ? <CameraMotionBlur shutterAngle={180} samples={samples}><Deck /></CameraMotionBlur> : <Deck />}
    </AbsoluteFill>
  );
};
