import React from 'react';
import {Easing, interpolate, spring, staticFile} from 'remotion';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const TAU = Math.PI * 2;
const io = Easing.bezier(0.65, 0, 0.35, 1);
const outE = Easing.bezier(0.16, 1, 0.3, 1);
const inE = Easing.bezier(0.7, 0, 0.84, 0);

export type Bill = {img: string; ar: number; name: string; code: string; accent: string};
// aspect ratios are measured from the trimmed images (see prep script)
const ALL_BILLS: Bill[] = [
  {img: 'notes/iqd.jpg', ar: 2.27, name: 'دیناری عێراقی', code: 'IQD', accent: '#c0392b'},
  {img: 'notes/usd.jpg', ar: 2.36, name: 'دۆلاری ئەمریکی', code: 'USD', accent: '#1e7a46'},
  {img: 'notes/eur.jpg', ar: 1.91, name: 'یۆرۆ', code: 'EUR', accent: '#2a56c6'},
  {img: 'notes/gbp.jpg', ar: 1.87, name: 'پاوەندی بەریتانی', code: 'GBP', accent: '#8e2a5a'},
];
// which real banknote images are present in public/notes (edit when a new scan arrives)
export const AVAILABLE = ['USD', 'EUR', 'GBP'];
export const BILLS = ALL_BILLS.filter((b) => AVAILABLE.includes(b.code));

// A banknote that can bend like paper: sliced into vertical strips on a sine wave.
export const Note: React.FC<{b: Bill; w: number; wave: number; phase: number; gloss?: number; radius?: number}> = ({b, w, wave, phase, gloss = -1, radius = 5}) => {
  const h = w / b.ar;
  const N = wave > 0.2 ? 18 : 1;
  const sw = w / N;
  const k = (TAU * 1.1) / w;
  const strips = [];
  for (let i = 0; i < N; i++) {
    const x0 = i * sw, xc = x0 + sw / 2;
    const z = N === 1 ? 0 : wave * Math.sin(k * xc + phase);
    const ang = N === 1 ? 0 : (-Math.atan(wave * k * Math.cos(k * xc + phase)) * 180) / Math.PI;
    const shade = 1 + 0.35 * Math.sin((ang * Math.PI) / 180);
    strips.push(
      <div key={i} style={{position: 'absolute', left: x0, top: 0, width: sw + (N === 1 ? 0 : 0.8), height: h,
        backgroundImage: `url(${staticFile(b.img)})`, backgroundSize: `${w}px ${h}px`, backgroundPosition: `${-x0}px 0`,
        transform: `translateZ(${z}px) rotateY(${ang}deg)`, filter: `brightness(${shade})`,
        borderTopLeftRadius: i === 0 ? radius : 0, borderBottomLeftRadius: i === 0 ? radius : 0,
        borderTopRightRadius: i === N - 1 ? radius : 0, borderBottomRightRadius: i === N - 1 ? radius : 0}} />,
    );
  }
  return (
    <div style={{position: 'relative', width: w, height: h, transformStyle: 'preserve-3d'}}>
      {strips}
      {gloss > -1 && gloss < 2 && (
        <div style={{position: 'absolute', inset: 0, overflow: 'hidden', borderRadius: radius, transform: 'translateZ(2px)', mixBlendMode: 'screen'}}>
          <div style={{position: 'absolute', top: -40, bottom: -40, left: `${gloss * 100 - 20}%`, width: '22%', transform: 'skewX(-22deg)',
            background: 'linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,0.75),rgba(255,255,255,0))'}} />
        </div>
      )}
    </div>
  );
};

// ---------- hero parade: each real banknote gets its own close-up ----------
export const SceneBills: React.FC<{lf: number; fps: number; zoneW: number; H: number; dark: string; engrave: string}> = ({lf, fps, zoneW, H, dark, engrave}) => {
  const SLOT = Math.floor(165 / BILLS.length);
  const NW = 318; // note width in hero pose
  const noteCX = 164, noteCY = 122;
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: zoneW, height: H, overflow: 'hidden', perspective: 650}}>
      {BILLS.map((b, i) => {
        const t = lf - i * SLOT; // local time of this bill
        if (t < -2 || t > SLOT + 16) return null;
        const last = i === BILLS.length - 1;
        const enter = spring({frame: t, fps, config: {damping: 15, stiffness: 95, mass: 0.9}});
        const exit = last ? interpolate(t, [SLOT + 2, SLOT + 14], [0, 1], {...clamp, easing: inE}) : interpolate(t, [SLOT - 4, SLOT + 10], [0, 1], {...clamp, easing: inE});
        const w = Math.min(NW, 158 * b.ar);
        const h = w / b.ar;
        const x = noteCX + (1 - enter) * 520 - exit * 640;
        const y = noteCY + (1 - enter) * -40 + Math.sin((TAU * t) / 60) * 2.5 + exit * 16;
        const rotY = (1 - enter) * -65 + exit * 55 + Math.sin((TAU * t) / 80) * 3;
        const rotZ = (1 - enter) * 14 - exit * 10;
        const rotX = Math.sin((TAU * t) / 70) * 3;
        const wave = 14 * (1 - enter) + 18 * exit + 1.2;
        const phase = t * 0.35;
        const gloss = interpolate(t, [14, 34], [-0.1, 1.3], clamp);
        const blur = exit * 3 + Math.max(0, (1 - enter) - 0.4) * 4;
        // label
        const lab = interpolate(t, [8, 18], [0, 1], {...clamp, easing: outE}) * (1 - interpolate(t, [SLOT - 6, SLOT + 2], [0, 1], clamp));
        return (
          <React.Fragment key={b.code}>
            {/* soft cast shadow */}
            <div style={{position: 'absolute', left: x - w / 2 + 10, top: y - h / 2 + 18, width: w, height: h, borderRadius: 8, background: 'rgba(60,30,0,0.45)',
              filter: 'blur(12px)', opacity: enter * (1 - exit)}} />
            <div style={{position: 'absolute', left: x - w / 2, top: y - h / 2, width: w, height: h, transformStyle: 'preserve-3d', filter: blur > 0.3 ? `blur(${blur}px)` : undefined,
              transform: `rotateY(${rotY}deg) rotateZ(${rotZ}deg) rotateX(${rotX}deg)`}}>
              <Note b={b} w={w} wave={wave} phase={phase} gloss={gloss} />
            </div>
            {/* label: name + code, right side (towards the logo, RTL reading start) */}
            <div dir="rtl" style={{position: 'absolute', left: 326, right: 10, top: 60, textAlign: 'center', opacity: lab, transform: `translateY(${(1 - lab) * 26}px)`}}>
              <div style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: b.name.length > 12 ? 25 : b.name.length > 8 ? 28 : 46, lineHeight: 1.55, color: dark, filter: engrave, whiteSpace: 'nowrap'}}>{b.name}</div>
              <div style={{display: 'inline-block', marginTop: 6, padding: '2px 16px 4px', borderRadius: 30, background: 'linear-gradient(180deg,#2a2a2c,#050505)',
                boxShadow: `0 0 0 2px #e9c25a, 0 0 0 4px ${b.accent}, 0 6px 10px rgba(60,30,0,0.4)`}}>
                <span style={{fontFamily: 'NSans', fontWeight: 900, fontSize: 28, letterSpacing: 3,
                  backgroundImage: 'linear-gradient(180deg,#fff6cf,#f3c94f 45%,#b8860b 70%,#ffe9a0)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent'}}>{b.code}</span>
              </div>
            </div>
          </React.Fragment>
        );
      })}
    </div>
  );
};

// ---------- finale: banknote rain behind a black ribbon ----------
const RAIN = Array.from({length: 18}, (_, i) => {
  const r = (n: number) => { const s = Math.sin(i * 127.1 + n * 311.7) * 43758.5453; return s - Math.floor(s); };
  return {bill: i % BILLS.length, x: 20 + r(1) * 520, delay: r(2) * 34, speed: 3.2 + r(3) * 2.2, w: 96 + r(4) * 54, spin: (r(5) - 0.5) * 6, flip: 2 + r(6) * 4, ph: r(7) * TAU, z: r(8)};
}).sort((a, b) => a.z - b.z);

export const SceneRain: React.FC<{lf: number; fps: number; zoneW: number; H: number; cx: number}> = ({lf, fps, zoneW, H, cx}) => {
  const ribbon = spring({frame: lf - 10, fps, config: {damping: 14, stiffness: 120}});
  const out = interpolate(lf, [62, 74], [0, 1], {...clamp, easing: io});
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: zoneW, height: H, overflow: 'hidden', perspective: 600}}>
      {RAIN.map((p, i) => {
        const t = lf - p.delay;
        if (t < 0) return null;
        const b = BILLS[p.bill];
        const h = p.w / b.ar;
        const y = -h - 20 + t * p.speed * (1 + t / 90);
        const x = p.x + Math.sin(t / 9 + p.ph) * 26;
        if (y > H + 40) return null;
        return (
          <div key={i} style={{position: 'absolute', left: x - p.w / 2, top: y, width: p.w, height: h, transformStyle: 'preserve-3d', opacity: 1 - out * 0.6,
            transform: `rotateZ(${Math.sin(t / 11 + p.ph) * 28 + p.spin * t}deg) rotateX(${t * p.flip + p.ph * 30}deg) rotateY(${Math.sin(t / 7 + p.ph) * 30}deg)`,
            filter: p.z < 0.35 ? 'blur(1.6px) brightness(0.92)' : undefined}}>
            <Note b={b} w={p.w} wave={4} phase={t * 0.4 + p.ph} radius={3} />
          </div>
        );
      })}
      {/* ribbon */}
      <div dir="rtl" style={{position: 'absolute', left: cx - 270, width: 540, top: 94, height: 72, borderRadius: 14,
        transform: `scaleX(${ribbon}) scale(${1 + out * 0.05})`, opacity: 1 - out,
        background: 'linear-gradient(180deg,#2c2c2e,#0b0b0c 55%,#1b1b1d)', boxShadow: '0 0 0 3px #e9c25a, 0 0 0 5px #6b4305, 0 14px 24px rgba(40,20,0,0.55)',
        display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <span style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 32, lineHeight: 1, opacity: interpolate(lf, [16, 24], [0, 1], clamp),
          backgroundImage: 'linear-gradient(180deg,#fff6cf,#f3c94f 45%,#b8860b 70%,#ffe9a0)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
          paddingTop: 6, whiteSpace: 'nowrap'}}>{'ئاڵوگۆڕی هەموو دراوەکان'}</span>
      </div>
    </div>
  );
};
