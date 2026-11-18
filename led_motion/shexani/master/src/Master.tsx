import React, {useEffect, useLayoutEffect, useMemo, useRef, useState} from 'react';
import {AbsoluteFill, Img, continueRender, delayRender, staticFile, useCurrentFrame} from 'remotion';
import {CameraMotionBlur} from '@remotion/motion-blur';
import {W, H, SL, SR, YELLOW, INK, BUTTER, TAU, rng, eOut, eIn, eIO, eBack, eExpo, rnd, lerp, Chevron, loadShxFonts, useShxFonts} from './shx';

// ============================================================================
// SHEXANI — LED 936x260, 15 s seamless loop.
// Flip-disc coin wall (idea 4) + the two meeting arrows (idea 5).
// The official logo with its name is on screen in every frame: large in the centre at the loop point,
// docked on the right while the currencies and payment services play.
// All content stays inside x = 140..796 (either edge of the installed screen may be hidden).
// ============================================================================
export const LOOP = 450;
const CELL = 6.5, COLS = Math.floor(W / CELL), ROWS = Math.floor(H / CELL), N = COLS * ROWS;
const X0 = (W - COLS * CELL) / 2 + CELL / 2, Y0 = (H - ROWS * CELL) / 2 + CELL / 2;
const FLIP = 7;

// ---- timeline ----
const DOCK_A = 26, DOCK_B = 46;
const BEAT0 = 46, BEAT = 40, HIT = 7;           // arrows meet HIT frames into every beat
const PAY = BEAT0 + 5 * BEAT;                    // 246
const ALL = PAY + 80;                            // 326
const FIN = ALL + 40;                            // 366: yellow wave
const BACK = 416;                                // dark wave back to the loop point
const UNDOCK_A = 370, UNDOCK_B = 400;

// ---- layout ----
const LOGO_AR = 1925.1 / 819.4;
const BIG = {h: 166, cx: (SL + SR) / 2, cy: 127};
const DOCK = {h: 100, cx: SR - 6 - (100 * LOGO_AR) / 2, cy: 130};
const DIV_X = 548;                               // divider between the stage and the docked logo
const SC = 342, SCY = 116;                       // where the arrows meet (stage centre)
const SYM_CX = 212, NOTE_CX = 426, NOTE_CY = 98;

const CURR = [
  {img: 'notes/iqd.jpg', ar: 2.218, name: 'دیناری عێراقی', sym: 'د.ع'},
  {img: 'notes/usd.jpg', ar: 2.375, name: 'دۆلاری ئەمریکی', sym: '$'},
  {img: 'notes/eur.jpg', ar: 1.927, name: 'یۆرۆ', sym: '€'},
  {img: 'notes/gbp.jpg', ar: 1.87, name: 'پاوەندی بەریتانی', sym: '£'},
  {img: 'notes/irr.jpg', ar: 2.219, name: 'تومەنی ئێرانی', sym: '\uFDFC'},
];
const PAYS = [
  {img: 'shexani/pay/fib_new.png', ar: 2.472},
  {img: 'shexani/pay/qi.png', ar: 2.094},
  {img: 'shexani/pay/nass.png', ar: 3.491},
];
const EVENTS = [...CURR.map((_, k) => BEAT0 + k * BEAT), PAY, ALL]; // every time the arrows cross

const dockAmt = (f: number) => eIO(rng(f, DOCK_A, DOCK_B)) * (1 - eIO(rng(f, UNDOCK_A, UNDOCK_B)));
// x of the yellow/dark boundary during the finale (yellow is to the right of it)
const boundary = (f: number) => {
  const bY = f < FIN ? 1e6 : X0 + (COLS - 1 - (f - FIN - FLIP / 2) / 0.17) * CELL;
  const bD = f < BACK ? -1e6 : X0 + ((f - BACK - FLIP / 2) / 0.16) * CELL;
  return Math.max(bY, bD);
};

// ---------------------------------------------------------------- the wall
type Step = {at: number; target: Uint8Array; start: Float32Array};
type WallData = {steps: Step[]; stage: Uint8Array};
const useWall = () => {
  const [steps, setSteps] = useState<WallData | null>(null);
  const [h] = useState(() => delayRender('wall maps'));
  useEffect(() => {
    loadShxFonts().then(() => {
      const c = document.createElement('canvas'); c.width = COLS; c.height = ROWS;
      const x = c.getContext('2d', {willReadFrequently: true})!;
      const grab = () => { const d = x.getImageData(0, 0, COLS, ROWS).data; const o = new Uint8Array(N); for (let i = 0; i < N; i++) o[i] = d[i * 4 + 3] > 100 ? 1 : 0; return o; };
      x.fillStyle = '#fff'; x.textAlign = 'center'; x.textBaseline = 'middle';
      const symMaps = CURR.map((cu) => {
        x.clearRect(0, 0, COLS, ROWS);
        const arabic = cu.sym.charCodeAt(0) > 0x500;
        if (arabic) {
          x.direction = 'rtl'; x.font = '800 20px ShxKufi';
          const size = Math.min(30, (20 * 19) / x.measureText(cu.sym).width);
          x.font = `800 ${size}px ShxKufi`; x.fillText(cu.sym, SYM_CX / CELL, ROWS / 2 - 1.5);
        } else { x.direction = 'ltr'; x.font = '800 33px ShxMont'; x.fillText(cu.sym, SYM_CX / CELL, ROWS / 2 + 1.5); }
        return grab();
      });
      x.clearRect(0, 0, COLS, ROWS); x.direction = 'ltr'; x.font = '800 17px ShxMont';
      ['$', '€', '£', '₺'].forEach((s, k) => x.fillText(s, 50.5 + (k - 1.5) * 14.2, ROWS / 2 - 4));
      const allMap = grab();
      const zero = new Uint8Array(N), one = new Uint8Array(N).fill(1);
      const stage = new Uint8Array(N); // everything left of the docked logo
      for (let i = 0; i < N; i++) stage[i] = X0 + (i % COLS) * CELL < DIV_X - 8 ? 1 : 0;
      const mk = (at: number, target: Uint8Array, delay: (col: number, row: number, i: number) => number): Step => {
        const start = new Float32Array(N);
        for (let i = 0; i < N; i++) start[i] = at + delay(i % COLS, Math.floor(i / COLS), i);
        return {at, target, start};
      };
      const radial = (col: number, row: number, i: number) => Math.hypot(col - SC / CELL, (row - SCY / CELL) * 1.3) * 0.17 + rnd(i, 1) * 1.2;
      const S: Step[] = [];
      // each currency: the new symbol forms outward from the arrows' meeting point, right behind the shock ring
      CURR.forEach((_, k) => S.push(mk(BEAT0 + k * BEAT + HIT, symMaps[k], radial)));
      S.push(mk(PAY + HIT, zero, radial));
      S.push(mk(ALL + HIT, allMap, radial));
      // finale: the whole wall turns Shexani Yellow from the logo side, then back to Ink for the loop
      S.push(mk(FIN, one, (col, _r, i) => (COLS - 1 - col) * 0.17 + rnd(i, 3) * 1.2));
      S.push(mk(BACK, zero, (col, _r, i) => col * 0.16 + rnd(i, 4) * 1.2));
      setSteps({steps: S, stage}); continueRender(h);
    });
  }, [h]);
  return steps;
};

const Wall: React.FC<{f: number}> = ({f}) => {
  const data = useWall();
  const ref = useRef<HTMLCanvasElement>(null);
  useLayoutEffect(() => {
    const cv = ref.current; if (!cv || !data) return;
    const {steps, stage} = data;
    // light glints that travel over the discs without waiting for a full flip: a shock ring from every
    // meeting of the arrows, and one diagonal sweep at the loop point
    const rings = EVENTS.map((T) => f - (T + HIT)).filter((t) => t >= 0 && t < 13);
    const sweep = f >= 2 && f < 34 ? (f - 2) * 7.5 : -1;
    const x = cv.getContext('2d')!;
    x.fillStyle = '#0b0906'; x.fillRect(0, 0, W, H);
    const r = CELL * 0.44;
    for (let i = 0; i < N; i++) {
      let best = -1e9, second = -1e9, bi = -1, si = -1;
      for (let s = 0; s < steps.length; s++) {
        const st = steps[s].start[i];
        if (st > f) continue;
        if (st > best) { second = best; si = bi; best = st; bi = s; } else if (st > second) { second = st; si = s; }
      }
      const cur = bi >= 0 ? steps[bi].target[i] : 0, prev = si >= 0 ? steps[si].target[i] : 0;
      const p = bi >= 0 ? (f - best) / FLIP : 1;
      let show = cur, sy = 1;
      if (p < 1 && prev !== cur) { sy = Math.abs(Math.cos(Math.PI * p)); show = p < 0.5 ? prev : cur; }
      const col = i % COLS, row = (i - col) / COLS, cx = X0 + col * CELL, cy = Y0 + row * CELL;
      let g = 0;
      if (stage[i]) for (const t of rings) { const dd = Math.hypot(col - SC / CELL, row - SCY / CELL) - t * 5.2; g = Math.max(g, Math.exp(-(dd * dd) / 7) * (1 - t / 13)); }
      if (sweep >= 0) { const q = col + row * 1.3 - sweep; g = Math.max(g, Math.exp(-(q * q) / 26) * 0.9); }
      // idle life: a few discs wink on their own (period divides the loop)
      if (!show && sy === 1 && rnd(i, 9) < 0.014 && (f + Math.floor(rnd(i, 8) * 90)) % 90 < 5) g = Math.max(g, 0.7);
      const sh = show ? 0.9 + 0.1 * Math.sin((TAU * f) / 45 + col * 0.35 + row * 0.6) : 1;
      x.fillStyle = g > 0.3 ? `rgb(255,${Math.round(190 + 55 * g)},${Math.round(150 * g * g)})` : show ? `rgb(${Math.round(245 * sh)},${Math.round(183 * sh)},0)` : '#262118';
      x.beginPath(); x.ellipse(cx, cy, r, Math.max(0.35, r * sy), 0, 0, TAU); x.fill();
      if (sy < 0.95 && sy > 0.05) { x.fillStyle = 'rgba(255,241,194,0.6)'; x.fillRect(cx - r, cy - 0.5, r * 2, 1); }
    }
  }, [f, data]);
  return <canvas ref={ref} width={W} height={H} style={{position: 'absolute', left: 0, top: 0, width: W, height: H}} />;
};

// ---------------------------------------------------------------- the logo (always on screen)
const BrandLogo: React.FC<{f: number}> = ({f}) => {
  const d = dockAmt(f);
  const h = lerp(BIG.h, DOCK.h, d), w = h * LOGO_AR;
  const left = lerp(BIG.cx, DOCK.cx, d) - w / 2, top = lerp(BIG.cy, DOCK.cy, d) - h / 2;
  const B = boundary(f);
  const darkRight = Math.max(0, Math.min(w + 60, left + w + 30 - B));   // px hidden on the right of the dark version
  const yelLeft = Math.max(0, Math.min(w, B - left));                   // px hidden on the left of the yellow version
  const breathe = 1 + 0.012 * Math.sin((TAU * f) / 90);
  return (
    <>
      {/* quiet Ink plate so the wall never fights the wordmark */}
      <div style={{position: 'absolute', left: left - 30, top: top - 14, width: w + 60, height: h + 28, clipPath: `inset(-40px ${darkRight}px -40px -40px)`}}>
        <div style={{position: 'absolute', inset: 0, borderRadius: 26, background: 'rgba(14,12,8,0.9)', filter: 'blur(9px)'}} />
      </div>
      {/* in the yellow moment the wordmark sits on solid Shexani Yellow, exactly like the brand's primary logo */}
      <div style={{position: 'absolute', left: left - 30, top: top - 14, width: w + 60, height: h + 28, clipPath: `inset(-40px -40px -40px ${Math.max(0, B - (left - 30))}px)`}}>
        <div style={{position: 'absolute', inset: 0, borderRadius: 26, background: YELLOW, filter: 'blur(7px)'}} />
      </div>
      <div style={{position: 'absolute', left, top, width: w, height: h, transform: `scale(${breathe})`}}>
        <Img src={staticFile('shexani/logo_tag_dark.svg')} style={{position: 'absolute', left: 0, top: 0, width: w, height: h, clipPath: `inset(0 ${Math.max(0, darkRight - 30)}px 0 0)`}} />
        <Img src={staticFile('shexani/logo_tag_yellow.svg')} style={{position: 'absolute', left: 0, top: 0, width: w, height: h, clipPath: `inset(0 0 0 ${yelLeft}px)`}} />
      </div>
      {/* divider between the stage and the brand */}
      <div style={{position: 'absolute', left: DIV_X, top: 130 - 62 * rng(d, 0.86, 1), width: 3, height: 124 * rng(d, 0.86, 1), borderRadius: 2, background: YELLOW, opacity: rng(d, 0.86, 1)}} />
    </>
  );
};

// ---------------------------------------------------------------- the two arrows
const Arrows: React.FC<{f: number}> = ({f}) => (
  <>
    {EVENTS.map((T) => {
      const t = f - T;
      if (t < 0 || t > 18) return null;
      const p = t / 16;
      const u = p < 0.44 ? -(1 - eIn(p / 0.44)) : p < 0.56 ? 0 : eIn(Math.min(1, (p - 0.56) / 0.44));
      const a = Math.abs(u), h = lerp(124, 64, a), op = 1 - a * a * a;
      const sq = t >= HIT ? 1 + 0.14 * Math.exp(-(t - HIT) / 3) : 1;
      const fl = t >= HIT ? Math.max(0, 1 - (t - HIT) / 11) : 0;
      return (
        <React.Fragment key={T}>
          {fl > 0 && (
            <>
              <div style={{position: 'absolute', left: SC - 150, top: SCY - 150, width: 300, height: 300, borderRadius: '50%', opacity: fl,
                background: 'radial-gradient(circle,rgba(255,246,208,0.95) 0%,rgba(245,183,0,0.4) 32%,rgba(245,183,0,0) 66%)'}} />
              {Array.from({length: 14}, (_, i) => {
                const an = rnd(i + T, 5) * TAU, dd = (1 - fl) * (50 + rnd(i + T, 6) * 130), s = 3 + rnd(i, 7) * 4;
                return <div key={i} style={{position: 'absolute', left: SC + Math.cos(an) * dd - s / 2, top: SCY + Math.sin(an) * dd * 0.6 - s / 2, width: s, height: s, borderRadius: s, background: i % 3 ? YELLOW : '#fff', opacity: fl}} />;
              })}
            </>
          )}
          <div style={{position: 'absolute', left: SC + u * 250, top: SCY, opacity: op, transform: `translate(-100%,-50%) scale(${1 / sq},${sq})`, transformOrigin: '100% 50%', filter: 'drop-shadow(0 6px 10px rgba(0,0,0,0.6))'}}><Chevron side="l" h={h} color="#ffffff" /></div>
          <div style={{position: 'absolute', left: SC - u * 250, top: SCY, opacity: op, transform: `translate(0,-50%) scale(${1 / sq},${sq})`, transformOrigin: '0% 50%', filter: 'drop-shadow(0 6px 10px rgba(0,0,0,0.6))'}}><Chevron side="r" h={h} color={YELLOW} /></div>
        </React.Fragment>
      );
    })}
  </>
);

// something that comes out of the arrows' meeting point and is drawn back into the next one
const useInOut = (f: number, born: number, gone: number) => {
  const inn = rng(f, born, born + 15), out = eIn(rng(f, gone, gone + 7));
  return {inn, out, visible: f >= born && f < gone + 7, k: eOut(inn) * (1 - out), s: eBack(inn, 1.5) * (1 - out * 0.85)};
};

const Note: React.FC<{f: number; k: number}> = ({f, k}) => {
  const c = CURR[k];
  const T = BEAT0 + k * BEAT;
  const {inn, out, visible, k: pos, s} = useInOut(f, T + HIT + 1, T + BEAT + HIT - 6);
  if (!visible) return null;
  const w = Math.min(226, 112 * c.ar), h = w / c.ar;
  const x = lerp(SC, NOTE_CX, pos), y = lerp(SCY, NOTE_CY, pos) + Math.sin((f - T) / 9) * 2 * pos;
  const t = f - T;
  const rotY = (1 - eOut(inn)) * -110 + Math.sin(t / 11) * 9 - out * 60;
  const rotZ = lerp(-16, -3, eOut(inn)) + out * 14;
  const sheen = lerp(-40, 140, rng(t, HIT + 12, HIT + 26));
  const lab = eExpo(rng(t, HIT + 9, HIT + 21)) * (1 - rng(t, BEAT + HIT - 9, BEAT + HIT - 4));
  return (
    <>
      <div style={{position: 'absolute', left: x - w / 2, top: y - h / 2, width: w, height: h, perspective: 520, opacity: Math.min(1, inn * 4) * (1 - out * out)}}>
        <div style={{position: 'absolute', inset: 0, borderRadius: 5, overflow: 'hidden', transform: `scale(${s}) rotateY(${rotY}deg) rotateX(${Math.sin(t / 13) * 5}deg) rotateZ(${rotZ}deg)`,
          boxShadow: '0 12px 22px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,241,194,0.25)'}}>
          <Img src={staticFile(c.img)} style={{position: 'absolute', inset: 0, width: w, height: h}} />
          <div style={{position: 'absolute', top: -30, bottom: -30, left: `${sheen}%`, width: 46, transform: 'skewX(-20deg)', background: 'linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,0.75),rgba(255,255,255,0))'}} />
        </div>
      </div>
      <div dir="rtl" style={{position: 'absolute', left: NOTE_CX - 130, width: 260, top: 170, textAlign: 'center', overflow: 'hidden', paddingBottom: 14}}>
        <div style={{display: 'inline-block', transform: `translateY(${(1 - lab) * 120}%)`, fontFamily: 'ShxKufi', fontWeight: 800, fontSize: c.name.length > 12 ? 24 : 27, lineHeight: 1.5, color: '#ffffff',
          textShadow: '0 2px 0 #0b0906, 0 0 12px #0b0906, 0 0 4px #0b0906', whiteSpace: 'nowrap', borderBottom: `3px solid ${YELLOW}`}}>{c.name}</div>
      </div>
    </>
  );
};

const Pays: React.FC<{f: number}> = ({f}) => {
  const t = f - PAY;
  if (t < HIT || f > ALL + HIT + 2) return null;
  const CW = 124, CH = 78;
  const slots = [478, 345, 212]; // right-to-left: FIB first
  const line = eExpo(rng(t, HIT + 20, HIT + 34)) * (1 - rng(f, ALL - 4, ALL + 2));
  return (
    <>
      {PAYS.map((p, i) => {
        const {inn, out, visible, k: pos, s} = useInOut(f, PAY + HIT + 1 + i * 5, ALL + HIT - 6);
        if (!visible) return null;
        const x = lerp(SC, slots[i], pos), y = lerp(SCY, 98, pos) + Math.sin((t + i * 9) / 10) * 2 * pos;
        const lw = Math.min(CW - 22, (CH - 24) * p.ar), lh = lw / p.ar;
        const sheen = lerp(-50, 150, rng(t, HIT + 16 + i * 6, HIT + 32 + i * 6));
        return (
          <div key={i} style={{position: 'absolute', left: x - CW / 2, top: y - CH / 2, width: CW, height: CH, perspective: 500, opacity: Math.min(1, inn * 4) * (1 - out * out)}}>
            <div style={{position: 'absolute', inset: 0, borderRadius: 12, overflow: 'hidden', background: '#ffffff', transform: `scale(${s}) rotateY(${(1 - eOut(inn)) * -120 + Math.sin((t + i * 7) / 12) * 7}deg) rotateZ(${(1 - eOut(inn)) * -12}deg)`,
              boxShadow: `0 12px 22px rgba(0,0,0,0.7), 0 0 0 3px ${YELLOW}`}}>
              <Img src={staticFile(p.img)} style={{position: 'absolute', left: (CW - lw) / 2, top: (CH - lh) / 2, width: lw, height: lh}} />
              <div style={{position: 'absolute', top: -30, bottom: -30, left: `${sheen}%`, width: 40, transform: 'skewX(-20deg)', background: 'linear-gradient(90deg,rgba(245,183,0,0),rgba(245,183,0,0.35),rgba(255,255,255,0.9),rgba(245,183,0,0.35),rgba(245,183,0,0))'}} />
            </div>
          </div>
        );
      })}
      <div dir="rtl" style={{position: 'absolute', left: SL, width: DIV_X - SL - 6, top: 160, textAlign: 'center', overflow: 'hidden', paddingBottom: 14}}>
        <div style={{display: 'inline-block', transform: `translateY(${(1 - line) * 120}%)`, fontFamily: 'ShxKufi', fontWeight: 800, fontSize: 27, lineHeight: 1.5, color: '#ffffff',
          textShadow: '0 2px 0 #0b0906, 0 0 12px #0b0906, 0 0 4px #0b0906', whiteSpace: 'nowrap', borderBottom: `3px solid ${YELLOW}`}}>{'ناردن و وەرگرتنی پارە'}</div>
      </div>
    </>
  );
};

const AllLabel: React.FC<{f: number}> = ({f}) => {
  const a = eBack(rng(f, ALL + HIT + 12, ALL + HIT + 24), 1.2) * (1 - rng(f, FIN - 2, FIN + 5));
  if (a <= 0) return null;
  return (
    <div dir="rtl" style={{position: 'absolute', left: SL, width: 520 - SL, top: 196, textAlign: 'center'}}>
      <span style={{display: 'inline-block', transform: `scale(${a})`, padding: '0 18px 4px', borderRadius: 22, background: 'rgba(11,9,6,0.92)', boxShadow: `0 0 0 2px ${YELLOW}`, fontFamily: 'ShxKufi', fontWeight: 800, fontSize: 23, lineHeight: 1.6,
        color: BUTTER, whiteSpace: 'nowrap'}}>{'و هەموو دراوەکانی تر'}</span>
    </div>
  );
};

const Stage: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: DIV_X - 3, height: H, overflow: 'hidden'}}>
      {CURR.map((_, k) => <Note key={k} f={f} k={k} />)}
      <Pays f={f} />
      <AllLabel f={f} />
      <Arrows f={f} />
    </div>
  );
};

export const ShexaniMaster: React.FC<{samples?: number}> = ({samples = 5}) => {
  useShxFonts();
  const f = useCurrentFrame();
  const stage = useMemo(() => <Stage />, []);
  return (
    <AbsoluteFill style={{background: '#0b0906', overflow: 'hidden'}}>
      <Wall f={f} />
      <AbsoluteFill style={{background: 'radial-gradient(95% 170% at 50% 50%,rgba(0,0,0,0) 62%,rgba(0,0,0,0.42) 100%)'}} />
      <BrandLogo f={f} />
      {samples > 1 ? <CameraMotionBlur shutterAngle={190} samples={samples}>{stage}</CameraMotionBlur> : stage}
    </AbsoluteFill>
  );
};
export const _m = [INK];
