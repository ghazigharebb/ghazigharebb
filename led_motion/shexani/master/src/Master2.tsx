import React from 'react';
import {AbsoluteFill, Img, staticFile, useCurrentFrame} from 'remotion';
import {CameraMotionBlur} from '@remotion/motion-blur';
import {W, H, YELLOW, INK, TAU, rng, eIn, eIO, eExpo, lerp, useShxFonts} from './shx';

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
const TIP = 492, SLOPE = 79;                 // panel edge = the logo's arrow: tip at mid-height
const DCX = 297, DCY = 96;                   // deck centre
const LOGO_AR = 1925.1 / 819.4, LW = 268, LH = LW / LOGO_AR;
const LOGO_L = 653 - LW / 2, LOGO_T = 130 - 0.3905 * LH; // the panel's tip points at the X of the logo

// yellow covers everything left of this arrow-shaped edge; once per loop it sweeps the whole sign
const tipAt = (f: number) => {
  const e = f > LOOP2 / 2 ? eIO(rng(f, LOOP2 - 30, LOOP2 - 10)) : 1 - eIO(rng(f, 8, 30));
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

// ---------------------------------------------------------------- the deck
const itemSize = (it: Item) => (it.card ? {w: 296, h: 146} : {w: Math.min(316, 146 * it.ar), h: Math.min(316, 146 * it.ar) / it.ar});

const DeckItem: React.FC<{it: Item; s: number; f: number}> = ({it, s, f}) => {
  if (s > 3 || s < -1) return null;
  const {w, h} = itemSize(it);
  let x: number, y: number, sc: number, rot: number, op: number, dim: number, blur: number;
  if (s >= 0) {
    x = DCX + 24 * s; y = DCY - 13 * s; sc = 1 - 0.085 * s; rot = -2 + 4.5 * s; op = s <= 2 ? 1 : 3 - s; dim = Math.min(1, s) * 0.2 + Math.max(0, s - 1) * 0.16; blur = s * 1.1;
  } else {
    const u = -s; // leaving: glides off to the left like a dealt card
    x = DCX - 430 * eIn(u) - 30 * u; y = DCY + 20 * u; sc = 1 - 0.05 * u; rot = -2 - 13 * u; op = 1 - Math.pow(u, 4); dim = 0; blur = 0;
  }
  const front = Math.max(0, 1 - Math.abs(s));
  const float = Math.sin((TAU * f) / 150) * 2.2 * front;
  const sheen = lerp(-45, 150, rng(f % ITEM, MOVE + 8, MOVE + 30));
  return (
    <div style={{position: 'absolute', left: x - w / 2, top: y - h / 2 + float, width: w, height: h, opacity: op, zIndex: Math.round(100 - s * 10), perspective: 700}}>
      <div style={{position: 'absolute', inset: 0, borderRadius: it.card ? 16 : 6, overflow: 'hidden', background: it.card ? '#ffffff' : undefined,
        transform: `scale(${sc}) rotate(${rot}deg) rotateY(${Math.sin((TAU * f) / 200) * 5 * front}deg)`,
        boxShadow: `0 ${10 + 12 * front}px ${18 + 16 * front}px rgba(70,45,0,${0.32 + 0.22 * front})${it.card ? `, 0 0 0 2px rgba(22,19,13,0.9)` : ''}`,
        filter: blur > 0.15 || dim > 0.02 ? `blur(${blur}px) brightness(${1 - dim})` : undefined}}>
        {it.card
          ? (() => { const lw = Math.min(w - 56, (h - 54) * it.ar), lh = lw / it.ar; return <Img src={staticFile(it.img)} style={{position: 'absolute', left: (w - lw) / 2, top: (h - lh) / 2, width: lw, height: lh}} />; })()
          : <Img src={staticFile(it.img)} style={{position: 'absolute', inset: 0, width: w, height: h}} />}
        {front > 0.9 && <div style={{position: 'absolute', top: -30, bottom: -30, left: `${sheen}%`, width: 54, transform: 'skewX(-20deg)', background: 'linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,0.7),rgba(255,255,255,0))'}} />}
      </div>
    </div>
  );
};

const Caption: React.FC<{it: Item; a: number; dir: number}> = ({it, a, dir}) => {
  // a: 0 hidden .. 1 shown; dir: +1 enters from below, -1 leaves upward
  const ty = dir > 0 ? (1 - a) * 115 : -(1 - a) * 115;
  const size = it.name.length > 14 ? 25 : it.name.length > 11 ? 28 : 36;
  const arabicSym = !!it.sym && it.sym.charCodeAt(0) > 0x500;
  return (
    <div dir="rtl" style={{position: 'absolute', left: 142, width: 284, top: 183, height: 62, overflow: 'hidden'}}>
      <div style={{position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, transform: `translateY(${ty}%)`}}>
        {it.sym && (
          <span style={{flexShrink: 0, width: 42, height: 42, borderRadius: 21, background: INK, display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: arabicSym ? 'ShxKufi' : 'ShxMont', fontWeight: 800, fontSize: arabicSym ? (it.sym.length > 2 ? 16 : 20) : 26, color: YELLOW, lineHeight: 1, paddingBottom: arabicSym ? 5 : 0, direction: arabicSym ? 'rtl' : 'ltr'}}>{it.sym}</span>
        )}
        <span style={{fontFamily: 'ShxKufi, ShxMont', fontWeight: 800, fontSize: size, lineHeight: 1.5, color: INK, whiteSpace: 'nowrap', paddingBottom: 6}}>{it.name}</span>
      </div>
    </div>
  );
};

const Deck: React.FC = () => {
  const f = useCurrentFrame();
  const i0 = Math.floor(f / ITEM) % NI, local = f % ITEM;
  const t = eIO(rng(local, 0, MOVE));
  const prev = (i0 - 1 + NI) % NI;
  const capOut = eExpo(rng(local, 0, 12)), capIn = eExpo(rng(local, 12, 28));
  return (
    <AbsoluteFill>
      {ITEMS.map((it, j) => { const k = (j - prev + NI) % NI; return <DeckItem key={j} it={it} s={k - t} f={f} />; })}
      {local < 12 ? <Caption it={ITEMS[prev]} a={1 - capOut} dir={-1} /> : <Caption it={ITEMS[i0]} a={capIn} dir={1} />}
      {/* progress: one dot per item */}
      <div style={{position: 'absolute', left: 148, top: 248, display: 'flex', gap: 5}}>
        {ITEMS.map((_, j) => <div key={j} style={{width: j === i0 ? 16 : 5, height: 5, borderRadius: 3, background: INK, opacity: j === i0 ? 0.9 : 0.3}} />)}
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
