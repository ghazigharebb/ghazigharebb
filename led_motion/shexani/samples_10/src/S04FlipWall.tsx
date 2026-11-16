import React, {useEffect, useLayoutEffect, useRef, useState} from 'react';
import {AbsoluteFill, continueRender, delayRender, staticFile, useCurrentFrame} from 'remotion';
import {W, H, CX, TAU, rnd, loadShxFonts} from './shx';

// 04 — flip-disc coin wall: thousands of two-sided coins (Shexani Yellow / Ink) flip in waves, like a
// mechanical flip-dot board or a stadium card stunt. Only pure yellow and black: reads from far, in daylight.
const CELL = 6.5, COLS = Math.floor(W / CELL), ROWS = Math.floor(H / CELL);
const X0 = (W - COLS * CELL) / 2 + CELL / 2, Y0 = (H - ROWS * CELL) / 2 + CELL / 2;
const N = COLS * ROWS;
const FLIP = 8;

type Maps = {sym: Uint8Array; logo: Uint8Array};
const sample = (c: HTMLCanvasElement) => {
  const d = c.getContext('2d')!.getImageData(0, 0, COLS, ROWS).data; const o = new Uint8Array(N);
  for (let i = 0; i < N; i++) o[i] = d[i * 4 + 3] > 105 ? 1 : 0;
  return o;
};

// each step: when it starts, what every disc shows after it, and how the wave travels
const STEPS: {at: number; target: (m: Maps, i: number) => number; delay: (col: number, row: number, i: number) => number}[] = [
  {at: 6, target: (m, i) => m.sym[i], delay: (c, r, i) => Math.hypot(c - COLS / 2, (r - ROWS / 2) * 1.6) * 0.27 + rnd(i, 1) * 2},
  {at: 50, target: (m, i) => 1 - m.sym[i], delay: (c, r, i) => (c + r * 1.4) * 0.14 + rnd(i, 2) * 2},
  {at: 90, target: (m, i) => 1 - m.logo[i], delay: (c, r, i) => (COLS - c) * 0.17 + rnd(i, 3) * 2.5},
  {at: 126, target: (m, i) => m.logo[i], delay: (c, r, i) => Math.abs(r - ROWS / 2) * 0.8 + rnd(i, 4) * 2},
  {at: 163, target: () => 0, delay: (c, r, i) => rnd(i, 5) * 8},
];

export const S04FlipWall: React.FC = () => {
  const f = useCurrentFrame();
  const ref = useRef<HTMLCanvasElement>(null);
  const [maps, setMaps] = useState<Maps | null>(null);
  const [h] = useState(() => delayRender('flip maps'));
  useEffect(() => {
    const img = new Image();
    const go = () => {
      const c = document.createElement('canvas'); c.width = COLS; c.height = ROWS; const x = c.getContext('2d', {willReadFrequently: true})!;
      // currency symbols
      x.fillStyle = '#fff'; x.textAlign = 'center'; x.textBaseline = 'middle'; x.font = '800 33px ShxMont';
      const cc = CX / CELL; ['$', '€', '£', '₺'].forEach((s, k) => x.fillText(s, cc + (k - 1.5) * 24, ROWS / 2 + 1.5));
      const sym = sample(c);
      // official wordmark (one-colour) with the X
      x.clearRect(0, 0, COLS, ROWS);
      const lw = 96, lh = lw / (1925.1 / 680);
      x.drawImage(img, cc - lw / 2, ROWS / 2 - lh / 2 + 0.5, lw, lh);
      const logo = sample(c);
      setMaps({sym, logo}); continueRender(h);
    };
    img.onload = () => loadShxFonts().then(go);
    img.onerror = () => continueRender(h);
    img.src = staticFile('shexani/logo_name_white.svg');
  }, [h]);

  useLayoutEffect(() => {
    const cv = ref.current; if (!cv || !maps) return;
    const x = cv.getContext('2d')!;
    x.fillStyle = '#0b0906'; x.fillRect(0, 0, W, H);
    const r = CELL * 0.44;
    for (let row = 0; row < ROWS; row++) for (let col = 0; col < COLS; col++) {
      const i = row * COLS + col;
      let prev = 0, cur = 0, p = 1;
      for (const s of STEPS) {
        const st = s.at + s.delay(col, row, i);
        if (f < st) break;
        prev = cur; cur = s.target(maps, i); p = (f - st) / FLIP;
      }
      let show = cur, sy = 1;
      if (p < 1 && prev !== cur) { sy = Math.abs(Math.cos(Math.PI * p)); show = p < 0.5 ? prev : cur; }
      // idle shimmer on yellow faces
      const sh = show ? 0.9 + 0.1 * Math.sin((TAU * f) / 45 + col * 0.35 + row * 0.6) : 1;
      x.fillStyle = show ? `rgb(${Math.round(245 * sh)},${Math.round(183 * sh)},0)` : '#262118';
      x.beginPath(); x.ellipse(X0 + col * CELL, Y0 + row * CELL, r, Math.max(0.35, r * sy), 0, 0, TAU); x.fill();
      if (sy < 0.95 && sy > 0.05) { x.fillStyle = 'rgba(255,241,194,0.55)'; x.fillRect(X0 + col * CELL - r, Y0 + row * CELL - 0.5, r * 2, 1); }
    }
  }, [f, maps]);

  return (
    <AbsoluteFill style={{background: '#0b0906'}}>
      <canvas ref={ref} width={W} height={H} style={{width: W, height: H}} />
      <AbsoluteFill style={{background: 'radial-gradient(90% 160% at 50% 50%,rgba(0,0,0,0) 60%,rgba(0,0,0,0.45) 100%)'}} />
    </AbsoluteFill>
  );
};
