import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {useFonts} from './fonts';
import {LogoAG} from './LogoAG';

// 936x260 LED, 30 fps, 450 frames = 15 s seamless loop.
// Every periodic motion uses a period that divides 450 so frame 449 -> frame 0 is continuous.
export const W = 936, H = 260, LOOP = 450;
const NAME_FONT = 'NKufi';
const PANEL_X = 664; // left edge of the black logo panel (angled)
const CX = PANEL_X / 2 + 6; // centre of the content zone
const TAU = Math.PI * 2;
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const ease = Easing.bezier(0.22, 1, 0.36, 1);
const io = Easing.bezier(0.65, 0, 0.35, 1);
const lerp = (f: number, a: number, b: number, from: number, to: number, e = ease) => interpolate(f, [a, b], [from, to], {...clamp, easing: e});

// scene boundaries (blade transitions at these frames)
const T1 = 120, T2 = 285, T3 = 375;

const DARK = '#1c1104';
const GOLD_TEXT = 'linear-gradient(180deg,#fff6cf 0%,#f3c94f 38%,#b8860b 62%,#ffe9a0 100%)';

// ---------- background ----------
const Rosette: React.FC<{r: number; k: number; amp: number; n: number; rot: number; op: number; cx: number; cy: number}> = ({r, k, amp, n, rot, op, cx, cy}) => {
  const paths: string[] = [];
  for (let j = 0; j < n; j++) {
    const ph = (j / n) * (TAU / k);
    let d = '';
    for (let i = 0; i <= 720; i++) {
      const t = (i / 720) * TAU;
      const rr = r + amp * Math.sin(k * t + ph);
      d += `${i ? 'L' : 'M'}${(cx + rr * Math.cos(t)).toFixed(1)} ${(cy + rr * Math.sin(t)).toFixed(1)}`;
    }
    paths.push(d);
  }
  return (
    <g transform={`rotate(${rot} ${cx} ${cy})`} opacity={op}>
      {paths.map((d, i) => <path key={i} d={d} fill="none" stroke="#5a3a05" strokeWidth={1} />)}
    </g>
  );
};

const SPARKS = Array.from({length: 16}, (_, i) => {
  const s = Math.sin(i * 91.7) * 43758.5453;
  const r = s - Math.floor(s);
  const s2 = Math.sin(i * 12.9) * 9631.1;
  const r2 = s2 - Math.floor(s2);
  return {x: 20 + r * (PANEL_X - 50), y: 18 + r2 * (H - 36), ph: (i * 0.137) % 1, size: 10 + (i % 3) * 5};
});

const Spark: React.FC<{x: number; y: number; s: number; a: number}> = ({x, y, s, a}) => (
  <svg style={{position: 'absolute', left: x - s, top: y - s, opacity: a}} width={s * 2} height={s * 2} viewBox="-10 -10 20 20">
    <path d="M0 -10 Q1 -1 10 0 Q1 1 0 10 Q-1 1 -10 0 Q-1 -1 0 -10Z" fill="#fffbe6" />
    <circle r={2} fill="#fff" />
  </svg>
);

const GoldBG: React.FC<{f: number}> = ({f}) => {
  const sheen = ((f % 150) / 150) * (W + 900) - 450;
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(112deg,#7d4f08 0%,#b9861a 16%,#e9c25a 34%,#fff0b3 47%,#f1cd68 55%,#c38f1c 72%,#8f5f0c 88%,#6a4306 100%)'}} />
      {/* brushed metal grain */}
      <AbsoluteFill style={{background: 'repeating-linear-gradient(0deg,rgba(255,255,255,0.05) 0 1px,rgba(90,50,0,0.05) 1px 3px)'}} />
      <svg width={W} height={H} style={{position: 'absolute'}}>
        <Rosette cx={CX} cy={H / 2} r={250} k={24} amp={26} n={6} rot={(f / LOOP) * 15} op={0.13} />
        <Rosette cx={CX} cy={H / 2} r={150} k={18} amp={18} n={5} rot={-(f / LOOP) * 20} op={0.11} />
        <Rosette cx={CX} cy={H / 2} r={360} k={36} amp={22} n={4} rot={(f / LOOP) * 10} op={0.09} />
      </svg>
      {/* travelling sheen, 3 passes per loop */}
      <div style={{position: 'absolute', top: -60, bottom: -60, left: sheen, width: 260, transform: 'skewX(-24deg)',
        background: 'linear-gradient(90deg,rgba(255,250,220,0) 0%,rgba(255,250,220,0.55) 50%,rgba(255,250,220,0) 100%)', mixBlendMode: 'soft-light'}} />
      {SPARKS.map((p, i) => {
        const v = Math.max(0, Math.sin(TAU * (f / 90 + p.ph)));
        const a = Math.pow(v, 10);
        return <Spark key={i} x={p.x} y={p.y} s={p.size * (0.4 + 0.6 * a)} a={a} />;
      })}
      <AbsoluteFill style={{background: 'radial-gradient(120% 140% at 40% 50%,rgba(0,0,0,0) 55%,rgba(60,30,0,0.45) 100%)'}} />
      {/* thin bronze frame */}
      <div style={{position: 'absolute', inset: 5, border: '2px solid rgba(70,40,0,0.55)', borderRadius: 4, boxShadow: 'inset 0 0 0 1px rgba(255,240,190,0.35)'}} />
    </AbsoluteFill>
  );
};

// ---------- logo panel (right, every frame) ----------
const PULSES = [0, T1, T2, T3];
const LogoPanel: React.FC<{f: number}> = ({f}) => {
  const float = Math.sin((TAU * f) / 150) * 2.5;
  const sheenPos = ((f + 60) % 150) / 150; // chrome glint, 3 per loop
  const clip = `polygon(44px 0, 100% 0, 100% 100%, 0 100%)`;
  return (
    <>
      {/* shadow cast on gold */}
      <div style={{position: 'absolute', left: PANEL_X - 18, top: 0, width: W - PANEL_X + 18, height: H, clipPath: clip, background: 'rgba(40,20,0,0.35)', filter: 'blur(8px)'}} />
      {/* gold trim */}
      <div style={{position: 'absolute', left: PANEL_X - 7, top: 0, width: W - PANEL_X + 7, height: H, clipPath: clip,
        background: 'linear-gradient(180deg,#fff2b8,#c8961f 30%,#7a4c06 55%,#f2cf6a 80%,#9b6b0f)'}} />
      <div style={{position: 'absolute', left: PANEL_X, top: 0, width: W - PANEL_X, height: H, clipPath: clip, overflow: 'hidden',
        background: 'radial-gradient(90% 80% at 60% 45%,#2c2c2e 0%,#111113 55%,#000 100%)'}}>
        {/* lacquer reflection */}
        <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(160deg,rgba(255,255,255,0.10) 0%,rgba(255,255,255,0) 40%)'}} />
        {PULSES.map((p) => {
          const d = ((f - p + LOOP) % LOOP);
          if (d > 40) return null;
          const t = d / 40;
          return <div key={p} style={{position: 'absolute', left: 148 - 40 - t * 120, top: 130 - 40 - t * 120, width: 80 + t * 240, height: 80 + t * 240,
            borderRadius: '50%', border: `${3 - 2 * t}px solid rgba(243,201,79,${0.7 * (1 - t)})`}} />;
        })}
        <div style={{position: 'absolute', left: 148 - 104, top: 130 - 104 + float, width: 208, height: 208, filter: 'drop-shadow(0 6px 10px rgba(0,0,0,0.8))'}}>
          <LogoAG size={208} sheen={sheenPos} />
        </div>
      </div>
    </>
  );
};

// ---------- transitions ----------
const Blade: React.FC<{f: number; at: number}> = ({f, at}) => {
  const d = f - at;
  const dd = d < -LOOP / 2 ? d + LOOP : d > LOOP / 2 ? d - LOOP : d;
  if (dd < -12 || dd > 12) return null;
  const x = interpolate(dd, [-12, 12], [PANEL_X + 120, -360], {easing: io});
  return (
    <div style={{position: 'absolute', top: -40, bottom: -40, left: x, width: 240, transform: 'skewX(-22deg)', mixBlendMode: 'screen',
      background: 'linear-gradient(90deg,rgba(255,220,120,0) 0%,rgba(255,236,170,0.9) 40%,#fffdf2 50%,rgba(255,236,170,0.9) 60%,rgba(255,220,120,0) 100%)'}} />
  );
};

// gold glare around the loop point: hides the seam (peaks at frame 0 == 450)
const Glare: React.FC<{f: number}> = ({f}) => {
  const d = f > LOOP / 2 ? f - LOOP : f; // -225..225
  const a = interpolate(d, [-10, -1, 0, 12], [0, 0.85, 0.85, 0], clamp);
  if (a <= 0) return null;
  return <AbsoluteFill style={{background: `radial-gradient(70% 120% at ${CX}px 50%,rgba(255,250,225,${a}) 0%,rgba(255,225,140,${a * 0.6}) 50%,rgba(255,210,100,0) 100%)`}} />;
};

// ---------- text helpers ----------
const engrave = 'drop-shadow(0 1px 0 rgba(255,246,205,0.85)) drop-shadow(0 3px 5px rgba(70,35,0,0.35))';

// ---------- scene 1: name ----------
const SceneName: React.FC<{f: number}> = ({f}) => {
  const reveal = lerp(f, 6, 40, 100, 0, io);
  const sub = lerp(f, 30, 50, 0, 1);
  const out = lerp(f, 104, 120, 0, 1, io);
  const glintX = lerp(f, 44, 84, -30, 130, io);
  const lineW = lerp(f, 34, 60, 0, 90);
  const scale = lerp(f, 6, 50, 1.08, 1);
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: PANEL_X, height: H, opacity: 1 - out, filter: `blur(${out * 6}px)`, transform: `translateX(${-out * 40}px)`}}>
      <div dir="rtl" style={{position: 'absolute', left: 0, right: 0, top: 22, textAlign: 'center', fontFamily: NAME_FONT, fontWeight: 900, fontSize: 104, lineHeight: 1.45,
        transform: `scale(${scale})`, clipPath: `inset(-20px -20px -20px ${reveal}%)`, filter: engrave}}>
        <span style={{backgroundImage: `linear-gradient(100deg,${DARK} 0%,${DARK} ${glintX - 8}%,#9b6a12 ${glintX - 2}%,#fff1b0 ${glintX}%,#9b6a12 ${glintX + 2}%,${DARK} ${glintX + 8}%,${DARK} 100%)`,
          WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent', padding: '0 12px'}}>{'آغا گەڵاڵی'}</span>
      </div>
      {/* reveal edge glint */}
      {reveal > 0 && reveal < 100 && (
        <div style={{position: 'absolute', top: 40, height: 130, left: (reveal / 100) * PANEL_X - 2, width: 4, background: '#fffbe8', boxShadow: '0 0 18px 6px rgba(255,240,180,0.9)'}} />
      )}
      <div dir="rtl" style={{position: 'absolute', left: 0, right: 0, top: 186, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 16, opacity: sub, transform: `translateY(${(1 - sub) * 10}px)`}}>
        <Rule w={lineW} />
        <span style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 30, color: DARK, filter: engrave, letterSpacing: 0}}>{'بۆ ئاڵوگۆڕی دراو'}</span>
        <Rule w={lineW} flip />
      </div>
    </div>
  );
};
const Rule: React.FC<{w: number; flip?: boolean}> = ({w, flip}) => (
  <div style={{display: 'flex', alignItems: 'center', flexDirection: flip ? 'row-reverse' : 'row', width: w, filter: engrave}}>
    <div style={{width: 9, height: 9, background: DARK, transform: 'rotate(45deg)', flexShrink: 0}} />
    <div style={{flex: 1, height: 3, background: DARK, borderRadius: 2}} />
  </div>
);

// ---------- coins ----------
type Cur = {sym: string; name: string; accent: string; small?: boolean};
const CURS: Cur[] = [
  {sym: 'ع.د', name: 'دینار', accent: '#e0453a', small: true},
  {sym: '$', name: 'دۆلار', accent: '#2fbf71'},
  {sym: '€', name: 'یۆرۆ', accent: '#3f7bff'},
  {sym: '£', name: 'پاوەند', accent: '#b05cff'},
];

const CoinFace: React.FC<{c: Cur; d: number}> = ({c, d}) => (
  <div style={{position: 'absolute', inset: 0, borderRadius: '50%', backfaceVisibility: 'hidden',
    background: 'conic-gradient(from 200deg,#fff3c0,#b8860b,#6b4305,#e9c25a,#fff7d6,#a87410,#5c3a03,#f0cd6a,#fff3c0)'}}>
    <div style={{position: 'absolute', inset: d * 0.065, borderRadius: '50%', background: 'radial-gradient(circle at 38% 30%,#3a3a3c 0%,#141416 55%,#000 100%)',
      boxShadow: 'inset 0 3px 6px rgba(0,0,0,0.9), inset 0 -2px 3px rgba(255,255,255,0.12)'}}>
      <div style={{position: 'absolute', inset: d * 0.05, borderRadius: '50%', border: `2px solid ${c.accent}`, boxShadow: `0 0 8px ${c.accent}`}} />
      <div style={{position: 'absolute', inset: d * 0.1, borderRadius: '50%', border: '1.5px dashed rgba(233,194,90,0.55)'}} />
      <div style={{position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <span dir={c.small ? 'rtl' : 'ltr'} style={{fontFamily: c.small ? 'NKufi' : 'NSans', fontWeight: 900, fontSize: c.small ? d * 0.3 : d * 0.5, lineHeight: 1,
          backgroundImage: GOLD_TEXT, WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent', transform: c.small ? 'translateY(-4%)' : 'translateY(-3%)',
          filter: 'drop-shadow(0 2px 2px rgba(0,0,0,0.8))'}}>{c.sym}</span>
      </div>
    </div>
    {/* specular */}
    <div style={{position: 'absolute', inset: 0, borderRadius: '50%', background: 'linear-gradient(135deg,rgba(255,255,255,0.35) 0%,rgba(255,255,255,0) 35%)'}} />
  </div>
);

export const Coin: React.FC<{c: Cur; d: number; rotY: number}> = ({c, d, rotY}) => {
  const layers = 7;
  return (
    <div style={{width: d, height: d, position: 'relative', transformStyle: 'preserve-3d', transform: `rotateY(${rotY}deg)`}}>
      {Array.from({length: layers}, (_, i) => (
        <div key={i} style={{position: 'absolute', inset: 0, borderRadius: '50%', transform: `translateZ(${-1 - i}px)`,
          background: i % 2 ? '#7a4c06' : '#a8761a'}} />
      ))}
      <div style={{position: 'absolute', inset: 0, transform: 'translateZ(0.5px)', transformStyle: 'preserve-3d'}}><CoinFace c={c} d={d} /></div>
      <div style={{position: 'absolute', inset: 0, transform: `translateZ(${-layers - 1.5}px) rotateY(180deg)`, transformStyle: 'preserve-3d'}}><CoinFace c={c} d={d} /></div>
    </div>
  );
};

const SLOT_X = [568, 410, 252, 94]; // right-to-left reading order
const SceneCoins: React.FC<{f: number; fps: number}> = ({f, fps}) => {
  const lf = f - T1; // 0..165
  const D = 116;
  // swap A (slots 0<->1, 2<->3) 70..98 ; swap B (slots 1<->2) 112..138
  const sA = lerp(lf, 70, 98, 0, 1, io);
  const sB = lerp(lf, 112, 138, 0, 1, io);
  const slotOf = (c: number): {x: number; y: number; spin: number} => {
    // after A: coin0->1, coin1->0, coin2->3, coin3->2 ; after B: slot1<->slot2
    const afterA = [1, 0, 3, 2][c];
    const afterB = afterA === 1 ? 2 : afterA === 2 ? 1 : afterA;
    let x = SLOT_X[c];
    let y = 0, spin = 0;
    if (sA > 0) {
      x = interpolate(sA, [0, 1], [SLOT_X[c], SLOT_X[afterA]]);
      y = Math.sin(Math.PI * sA) * (c % 2 === 0 ? -34 : 34);
      spin += 360 * sA;
    }
    if (sB > 0 && afterB !== afterA) {
      x = interpolate(sB, [0, 1], [SLOT_X[afterA], SLOT_X[afterB]]);
      y = Math.sin(Math.PI * sB) * (afterA === 1 ? -34 : 34);
      spin += 360 * sB;
    } else if (sB > 0) {
      spin += 0;
    }
    return {x, y, spin};
  };
  const arrowsA = interpolate(lf, [64, 72, 96, 104], [0, 1, 1, 0], clamp);
  const arrowsB = interpolate(lf, [106, 114, 136, 144], [0, 1, 1, 0], clamp);
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: PANEL_X, height: H, perspective: 700}}>
      {/* exchange arcs */}
      <svg width={PANEL_X} height={H} style={{position: 'absolute'}}>
        <defs>
          <marker id="ah" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="4" markerHeight="4" orient="auto"><path d="M0 0L10 5L0 10z" fill={DARK} /></marker>
        </defs>
        <g opacity={arrowsA} stroke={DARK} strokeWidth={3.5} fill="none" strokeLinecap="round" markerEnd="url(#ah)" strokeDasharray="10 8" strokeDashoffset={-lf * 2}>
          <path d={`M${SLOT_X[0] - 24} 26 Q${(SLOT_X[0] + SLOT_X[1]) / 2} -6 ${SLOT_X[1] + 24} 26`} />
          <path d={`M${SLOT_X[1] + 24} 196 Q${(SLOT_X[0] + SLOT_X[1]) / 2} 228 ${SLOT_X[0] - 24} 196`} />
          <path d={`M${SLOT_X[2] - 24} 26 Q${(SLOT_X[2] + SLOT_X[3]) / 2} -6 ${SLOT_X[3] + 24} 26`} />
          <path d={`M${SLOT_X[3] + 24} 196 Q${(SLOT_X[2] + SLOT_X[3]) / 2} 228 ${SLOT_X[2] - 24} 196`} />
        </g>
        <g opacity={arrowsB} stroke={DARK} strokeWidth={3.5} fill="none" strokeLinecap="round" markerEnd="url(#ah)" strokeDasharray="10 8" strokeDashoffset={-lf * 2}>
          <path d={`M${SLOT_X[1] - 24} 26 Q${(SLOT_X[1] + SLOT_X[2]) / 2} -6 ${SLOT_X[2] + 24} 26`} />
          <path d={`M${SLOT_X[2] + 24} 196 Q${(SLOT_X[1] + SLOT_X[2]) / 2} 228 ${SLOT_X[1] - 24} 196`} />
        </g>
      </svg>
      {CURS.map((c, i) => {
        const st = 4 + i * 7;
        const drop = spring({frame: lf - st, fps, config: {damping: 13, stiffness: 120}});
        const spinIn = interpolate(drop, [0, 1], [-540, 0]);
        const exitT = lerp(lf, 146 + i * 3, 158 + i * 3, 0, 1, io);
        const {x, y, spin} = slotOf(i);
        const bob = Math.sin(TAU * (lf / 60 + i * 0.25)) * 3;
        const labelOp = Math.min(interpolate(drop, [0.75, 1], [0, 1], clamp), 1 - Math.max(interpolate(lf, [66, 72, 96, 102], [0, 1, 1, 0], clamp), interpolate(lf, [108, 114, 138, 144], [0, 1, 1, 0], clamp))) * (1 - exitT);
        const cy = 102;
        // trails during swaps
        const moving = (sA > 0 && sA < 1) || (sB > 0 && sB < 1);
        return (
          <React.Fragment key={c.name}>
            {moving && [3, 6, 9].map((k) => {
              const g = slotOfAt(i, lf - k);
              return <div key={k} style={{position: 'absolute', left: g.x - D / 2, top: cy - D / 2 + g.y, width: D, height: D, borderRadius: '50%',
                background: 'radial-gradient(circle,rgba(255,240,180,0.55),rgba(255,220,120,0) 70%)', opacity: 0.6 - k * 0.05}} />;
            })}
            <div style={{position: 'absolute', left: x - D / 2, top: cy - D / 2 + y + bob + (1 - drop) * -200, width: D, height: D,
              transformStyle: 'preserve-3d', transform: `scale(${1 - exitT * 0.4})`, opacity: 1 - exitT,
              filter: 'drop-shadow(0 8px 6px rgba(60,30,0,0.45))'}}>
              <Coin c={c} d={D} rotY={spinIn + spin + exitT * 90 + Math.sin(TAU * (lf / 90 + i * 0.2)) * 12} />
            </div>
            <div dir="rtl" style={{position: 'absolute', left: x - 80, width: 160, top: 172, textAlign: 'center', fontFamily: 'NKufi', fontWeight: 900, fontSize: 30, lineHeight: 1.6,
              color: DARK, opacity: labelOp, filter: engrave, transform: `translateY(${(1 - drop) * 12}px)`}}>{c.name}</div>
          </React.Fragment>
        );
      })}
    </div>
  );

  function slotOfAt(c: number, lfx: number) {
    const a = lerp(lfx, 70, 98, 0, 1, io), b = lerp(lfx, 112, 138, 0, 1, io);
    const afterA = [1, 0, 3, 2][c];
    const afterB = afterA === 1 ? 2 : afterA === 2 ? 1 : afterA;
    if (b > 0 && afterB !== afterA) return {x: interpolate(b, [0, 1], [SLOT_X[afterA], SLOT_X[afterB]]), y: Math.sin(Math.PI * b) * (afterA === 1 ? -34 : 34)};
    if (a > 0) return {x: interpolate(a, [0, 1], [SLOT_X[c], SLOT_X[afterA]]), y: Math.sin(Math.PI * a) * (c % 2 === 0 ? -34 : 34)};
    return {x: SLOT_X[c], y: 0};
  }
};

// ---------- scene 3: FIB ----------
const SceneFIB: React.FC<{f: number; fps: number}> = ({f, fps}) => {
  const lf = f - T2; // 0..90
  const card = spring({frame: lf - 4, fps, config: {damping: 14, stiffness: 110}});
  const out = lerp(lf, 78, 90, 0, 1, io);
  const shine = lerp(lf, 28, 52, -40, 140, io);
  const w1 = spring({frame: lf - 14, fps, config: {damping: 16}});
  const w2 = spring({frame: lf - 22, fps, config: {damping: 16}});
  const tilt = Math.sin(TAU * lf / 90) * 4;
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: PANEL_X, height: H, opacity: 1 - out, filter: `blur(${out * 5}px)`, perspective: 800}}>
      {/* card (left) */}
      <div style={{position: 'absolute', left: 18, top: 60, width: 238, height: 140, borderRadius: 18, overflow: 'hidden',
        transform: `translateX(${(1 - card) * -360}px) rotateY(${(1 - card) * -70 + tilt}deg) rotateX(${tilt * 0.4}deg)`,
        background: 'linear-gradient(160deg,#ffffff,#f1f4f4)', boxShadow: '0 14px 26px rgba(60,30,0,0.45), 0 0 0 3px #e9c25a, 0 0 0 5px #6b4305'}}>
        <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 10, background: 'linear-gradient(90deg,#0fa596,#14c2b0)'}} />
        <Img src={staticFile('fib.png')} style={{position: 'absolute', left: 18, top: 36, width: 202}} />
        <div style={{position: 'absolute', top: -40, bottom: -40, left: `${shine}%`, width: 70, transform: 'skewX(-20deg)',
          background: 'linear-gradient(90deg,rgba(20,194,176,0),rgba(20,194,176,0.28),rgba(255,255,255,0.9),rgba(20,194,176,0.28),rgba(20,194,176,0))'}} />
      </div>
      {/* travelling dots from card to text */}
      <svg width={PANEL_X} height={H} style={{position: 'absolute'}}>
        {[0, 1, 2, 3].map((k) => {
          const t = ((lf * 1.4 + k * 18) % 72) / 72;
          const a = card * (1 - out) * Math.sin(Math.PI * t);
          const x = 262 + t * 30, y = 130 + Math.sin(t * Math.PI * 2) * 10;
          return <circle key={k} cx={x} cy={y} r={5} fill={DARK} opacity={a} />;
        })}
      </svg>
      {/* text (right, near logo) */}
      <div dir="rtl" style={{position: 'absolute', left: 292, right: 4, top: 52, textAlign: 'center', fontFamily: 'NKufi', fontWeight: 900, color: DARK, filter: engrave}}>
        <div style={{fontSize: 37, lineHeight: 1.65, overflow: 'hidden', whiteSpace: 'nowrap'}}>
          <div style={{transform: `translateY(${(1 - w1) * 70}px)`, opacity: w1}}>{'ناردن و وەرگرتنی'}</div>
        </div>
        <div style={{fontSize: 37, lineHeight: 1.65, overflow: 'hidden', whiteSpace: 'nowrap'}}>
          <div style={{transform: `translateY(${(1 - w2) * 70}px)`, opacity: w2}}>
            {'پارە بە '}<span dir="ltr" style={{fontFamily: 'NSans', color: '#0b7f74'}}>FIB</span>
          </div>
        </div>
      </div>
    </div>
  );
};

// ---------- scene 4: exchange-board reels ----------
const SYMS = ['$', '€', '£', 'ع.د'];
const SceneReels: React.FC<{f: number; fps: number}> = ({f, fps}) => {
  const lf = f - T3; // 0..75
  const TW = 118, TH = 150, GAP = 34;
  const total = 4 * TW + 3 * GAP;
  const x0 = CX - total / 2;
  const appear = spring({frame: lf - 2, fps, config: {damping: 15}});
  const out = lerp(lf, 62, 73, 0, 1, io);
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: PANEL_X, height: H, opacity: 1 - out, transform: `scale(${1 + out * 0.08})`}}>
      {CURS.map((c, i) => {
        const tileI = 3 - i; // right-to-left: dinar at rightmost
        const land = 22 + i * 7;
        const target = SYMS.indexOf(c.sym);
        // reel position in "symbol units": spins fast then settles on target
        const settle = spring({frame: lf - land, fps, config: {damping: 11, stiffness: 140}});
        const off = i * 1.37;
        const P0 = land * 0.55 + off;
        let Pt = Math.floor(P0) + 2; while (((Pt % 4) + 4) % 4 !== target) Pt++;
        const base = lf < land ? lf * 0.55 + off : P0 + (Pt - P0) * settle;
        const blur = lf < land ? 3 : Math.min(3, Math.abs(1 - settle) * 3);
        const flash = interpolate(lf - land, [0, 3, 14], [0, 1, 0], clamp);
        const left = x0 + tileI * (TW + GAP);
        return (
          <div key={c.name} style={{position: 'absolute', left, top: 22 + (1 - appear) * 30, width: TW, height: TH + 46, opacity: appear}}>
            <div style={{position: 'absolute', left: 0, top: 0, width: TW, height: TH, borderRadius: 14, overflow: 'hidden',
              background: 'linear-gradient(180deg,#1a1a1c,#050505 50%,#1a1a1c)', boxShadow: '0 10px 18px rgba(60,30,0,0.45), 0 0 0 3px #e9c25a, 0 0 0 5px #6b4305'}}>
              <div style={{position: 'absolute', left: 0, right: 0, top: 0, transform: `translateY(${-((base % 4) + 4) * TH + 0}px)`, filter: `blur(${blur}px)`}}>
                {Array.from({length: 12}, (_, k) => {
                  const s = SYMS[k % 4];
                  return <div key={k} style={{height: TH, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                    <span style={{fontFamily: s === 'ع.د' ? 'NKufi' : 'NSans', fontWeight: 900, fontSize: s === 'ع.د' ? 46 : 84, lineHeight: 1, direction: s === 'ع.د' ? 'rtl' : 'ltr',
                      backgroundImage: GOLD_TEXT, WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent'}}>{s}</span>
                  </div>;
                })}
              </div>
              {/* split line + gloss */}
              <div style={{position: 'absolute', left: 0, right: 0, top: TH / 2 - 1, height: 2, background: 'rgba(0,0,0,0.9)'}} />
              <div style={{position: 'absolute', inset: 0, background: 'linear-gradient(180deg,rgba(255,255,255,0.14) 0%,rgba(255,255,255,0) 45%,rgba(0,0,0,0.35) 100%)'}} />
              <div style={{position: 'absolute', inset: 0, boxShadow: `inset 0 0 0 2px ${c.accent}`, borderRadius: 14, opacity: 0.8}} />
              <div style={{position: 'absolute', inset: 0, background: `radial-gradient(circle,rgba(255,240,180,${flash * 0.6}),rgba(255,240,180,0) 70%)`}} />
            </div>
            <div dir="rtl" style={{position: 'absolute', left: -20, right: -20, top: TH + 2, textAlign: 'center', fontFamily: 'NKufi', fontWeight: 900, fontSize: 28, lineHeight: 1.5, color: DARK, filter: engrave,
              opacity: interpolate(lf - land, [2, 10], [0, 1], clamp)}}>{c.name}</div>
          </div>
        );
      })}
    </div>
  );
};

export const AghaGalali: React.FC = () => {
  useFonts();
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <AbsoluteFill style={{background: '#000', overflow: 'hidden'}}>
      <GoldBG f={f} />
      {f < T1 && <SceneName f={f} />}
      {f >= T1 && f < T2 && <SceneCoins f={f} fps={fps} />}
      {f >= T2 && f < T3 && <SceneFIB f={f} fps={fps} />}
      {f >= T3 && <SceneReels f={f} fps={fps} />}
      <div style={{position: 'absolute', left: 0, top: 0, width: PANEL_X + 10, height: H, overflow: 'hidden'}}>
        <Blade f={f} at={T1} />
        <Blade f={f} at={T2} />
        <Blade f={f} at={T3} />
      </div>
      <Glare f={f} />
      <LogoPanel f={f} />
    </AbsoluteFill>
  );
};
