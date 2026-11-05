import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {useFonts} from './fonts';
import {LogoAG} from './LogoAG';
import {SceneBills, SceneRain} from './Money';

// 936x260 LED, 30 fps, 450 frames = 15 s seamless loop.
// Every periodic motion uses a period that divides 450 so frame 449 -> frame 0 is continuous.
export const W = 936, H = 260, LOOP = 450;
const NAME_FONT = 'NKufi';
const PANEL_X = 680; // left edge of the black logo panel (angled)
// The left ~110 px of the physical sign are not visible (measured from a photo of the installed screen),
// so all text and banknotes live in SAFE_L..PANEL_X. The gold background still fills the full 936 px.
export const SAFE_L = 122;
const ZW = PANEL_X - SAFE_L; // content zone width
const CX = SAFE_L + ZW / 2; // centre of the content zone (absolute)
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
  return {x: SAFE_L + 10 + r * (ZW - 30), y: 18 + r2 * (H - 36), ph: (i * 0.137) % 1, size: 10 + (i % 3) * 5};
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
      <div style={{position: 'absolute', top: 5, bottom: 5, right: 5, left: -20, border: '2px solid rgba(70,40,0,0.55)', borderRadius: 4, boxShadow: 'inset 0 0 0 1px rgba(255,240,190,0.35)'}} />
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
          return <div key={p} style={{position: 'absolute', left: (W - PANEL_X) / 2 + 12 - 40 - t * 120, top: 130 - 40 - t * 120, width: 80 + t * 240, height: 80 + t * 240,
            borderRadius: '50%', border: `${3 - 2 * t}px solid rgba(243,201,79,${0.7 * (1 - t)})`}} />;
        })}
        <div style={{position: 'absolute', left: (W - PANEL_X) / 2 + 12 - 100, top: 130 - 100 + float, width: 200, height: 200, filter: 'drop-shadow(0 6px 10px rgba(0,0,0,0.8))'}}>
          <LogoAG size={200} sheen={sheenPos} />
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
    <div style={{position: 'absolute', left: 0, top: 0, width: ZW, height: H, opacity: 1 - out, filter: `blur(${out * 6}px)`, transform: `translateX(${-out * 40}px)`}}>
      <div dir="rtl" style={{position: 'absolute', left: 0, right: 0, top: 28, textAlign: 'center', fontFamily: NAME_FONT, fontWeight: 900, fontSize: 92, lineHeight: 1.45,
        transform: `scale(${scale})`, clipPath: `inset(-20px -20px -20px ${reveal}%)`, filter: engrave}}>
        <span style={{backgroundImage: `linear-gradient(100deg,${DARK} 0%,${DARK} ${glintX - 8}%,#9b6a12 ${glintX - 2}%,#fff1b0 ${glintX}%,#9b6a12 ${glintX + 2}%,${DARK} ${glintX + 8}%,${DARK} 100%)`,
          WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent', padding: '0 12px'}}>{'آغا گەڵاڵی'}</span>
      </div>
      {/* reveal edge glint */}
      {reveal > 0 && reveal < 100 && (
        <div style={{position: 'absolute', top: 40, height: 130, left: (reveal / 100) * ZW - 2, width: 4, background: '#fffbe8', boxShadow: '0 0 18px 6px rgba(255,240,180,0.9)'}} />
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
    <div style={{position: 'absolute', left: 0, top: 0, width: ZW, height: H, opacity: 1 - out, filter: `blur(${out * 5}px)`, perspective: 800}}>
      {/* card (left) */}
      <div style={{position: 'absolute', left: 2, top: 66, width: 214, height: 128, borderRadius: 18, overflow: 'hidden',
        transform: `translateX(${(1 - card) * -360}px) rotateY(${(1 - card) * -70 + tilt}deg) rotateX(${tilt * 0.4}deg)`,
        background: 'linear-gradient(160deg,#ffffff,#f1f4f4)', boxShadow: '0 14px 26px rgba(60,30,0,0.45), 0 0 0 3px #e9c25a, 0 0 0 5px #6b4305'}}>
        <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 10, background: 'linear-gradient(90deg,#0fa596,#14c2b0)'}} />
        <Img src={staticFile('fib.png')} style={{position: 'absolute', left: 14, top: 34, width: 186}} />
        <div style={{position: 'absolute', top: -40, bottom: -40, left: `${shine}%`, width: 70, transform: 'skewX(-20deg)',
          background: 'linear-gradient(90deg,rgba(20,194,176,0),rgba(20,194,176,0.28),rgba(255,255,255,0.9),rgba(20,194,176,0.28),rgba(20,194,176,0))'}} />
      </div>
      {/* travelling dots from card to text */}
      <svg width={ZW} height={H} style={{position: 'absolute'}}>
        {[0, 1, 2, 3].map((k) => {
          const t = ((lf * 1.4 + k * 18) % 72) / 72;
          const a = card * (1 - out) * Math.sin(Math.PI * t);
          const x = 222 + t * 26, y = 130 + Math.sin(t * Math.PI * 2) * 10;
          return <circle key={k} cx={x} cy={y} r={5} fill={DARK} opacity={a} />;
        })}
      </svg>
      {/* text (right, near logo) */}
      <div dir="rtl" style={{position: 'absolute', left: 250, right: 8, top: 62, textAlign: 'center', fontFamily: 'NKufi', fontWeight: 900, color: DARK, filter: engrave}}>
        <div style={{fontSize: 32, lineHeight: 1.65, overflow: 'hidden', whiteSpace: 'nowrap'}}>
          <div style={{transform: `translateY(${(1 - w1) * 70}px)`, opacity: w1}}>{'ناردن و وەرگرتنی'}</div>
        </div>
        <div style={{fontSize: 32, lineHeight: 1.65, overflow: 'hidden', whiteSpace: 'nowrap'}}>
          <div style={{transform: `translateY(${(1 - w2) * 70}px)`, opacity: w2}}>
            {'پارە بە '}<span dir="ltr" style={{fontFamily: 'NSans', color: '#0b7f74'}}>FIB</span>
          </div>
        </div>
      </div>
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
      <div style={{position: 'absolute', left: SAFE_L, top: 0, width: ZW, height: H}}>
      {f < T1 && <SceneName f={f} />}
      {f >= T1 - 2 && f < T2 && <SceneBills lf={f - T1} fps={fps} zoneW={ZW} H={H} dark={DARK} engrave={engrave} />}
      {f >= T2 && f < T3 && <SceneFIB f={f} fps={fps} />}
      {f >= T3 && <SceneRain lf={f - T3} fps={fps} zoneW={ZW} H={H} cx={ZW / 2} />}
      </div>
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
