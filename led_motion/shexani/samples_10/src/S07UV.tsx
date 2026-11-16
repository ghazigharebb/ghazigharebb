import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {W, H, SL, SR, CX, ZW, INK, TAU, rng, eBack, rnd, lerp, Logo, LOGO, useShxFonts} from './shx';

// 07 — the UV test: the gesture every exchange office makes to check a note. The sign goes dark-violet like
// a counterfeit lamp; a beam sweeps and the hidden marks fluoresce: fibres, rosettes, the logo, "genuine".
const NEON = ['#39ff88', '#ff3d6e', '#3fd0ff', '#ffe23a'];
const FIB = Array.from({length: 70}, (_, i) => ({x: SL + 10 + rnd(i, 1) * (ZW - 20), y: 16 + rnd(i, 2) * 226, a: rnd(i, 3) * 180, l: 9 + rnd(i, 4) * 12, c: NEON[i % 4], k: (rnd(i, 5) - 0.5) * 10}));
const LH = 150, LW = LH * LOGO.tagDark.ar;

export const S07UV: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  // lamp: flickers on at 18, off at 142
  const flick = (t: number) => (t < 0 ? 0 : t < 2 ? 1 : t < 4 ? 0.15 : t < 6 ? 0.9 : t < 7 ? 0.3 : 1);
  const uv = f < 142 ? flick(f - 18) : 1 - flick(f - 142) * 1;
  const uvOn = Math.max(0, Math.min(1, uv));
  const beam = lerp(SL - 90, SR + 90, rng(f, 30, 96));
  const after = f >= 142 ? Math.max(0, 1 - (f - 148) / 22) : 1; // phosphor afterglow once the lamp is off
  const glowA = (f >= 26 ? 1 : 0) * after;
  const mask = f < 96 ? `linear-gradient(90deg,#000 0px,#000 ${beam - 30}px,rgba(0,0,0,0) ${beam + 40}px)` : undefined;
  const stamp = eBack(rng(f, 100, 114));
  return (
    <AbsoluteFill style={{background: INK, overflow: 'hidden'}}>
      {/* ordinary light: the logo is barely there */}
      <div style={{position: 'absolute', left: CX - LW / 2 + 60, top: (H - LH) / 2, opacity: 0.1 * (1 - uvOn)}}><Logo kind="tagDark" h={LH} /></div>
      {/* UV wash */}
      <AbsoluteFill style={{opacity: uvOn, background: 'radial-gradient(80% 140% at 50% 0%,#5b1fd6 0%,#2a0a78 45%,#0e0230 100%)'}} />
      <AbsoluteFill style={{opacity: uvOn * 0.5, background: 'repeating-linear-gradient(0deg,rgba(255,255,255,0.03) 0 1px,rgba(0,0,0,0) 1px 4px)'}} />
      {/* fluorescent layer, revealed by the beam */}
      <div style={{position: 'absolute', inset: 0, opacity: glowA, WebkitMaskImage: mask, maskImage: mask}}>
        <svg width={W} height={H} style={{position: 'absolute', filter: 'drop-shadow(0 0 3px rgba(255,255,255,0.7))'}}>
          {FIB.map((b, i) => {
            const r = (b.a * Math.PI) / 180, dx = Math.cos(r) * b.l, dy = Math.sin(r) * b.l;
            return <path key={i} d={`M${b.x} ${b.y} q${dx / 2 + b.k} ${dy / 2 - b.k} ${dx} ${dy}`} stroke={b.c} strokeWidth={2} fill="none" strokeLinecap="round" opacity={0.85} />;
          })}
          {[SL + 74].map((cx, j) => (
            <g key={j} transform={`rotate(${(f / 180) * 30 * (j ? -1 : 1)} ${cx} 80)`} stroke="#3fd0ff" fill="none" strokeWidth={1.6} opacity={0.9}>
              {[0, 1, 2, 3].map((n) => {
                let d = '';
                for (let i = 0; i <= 120; i++) { const t = (i / 120) * TAU; const rr = 40 + 8 * Math.sin(10 * t + (n * TAU) / 40); d += `${i ? 'L' : 'M'}${(cx + rr * Math.cos(t)).toFixed(1)} ${(80 + rr * Math.sin(t)).toFixed(1)}`; }
                return <path key={n} d={d} />;
              })}
            </g>
          ))}
        </svg>
        {/* the logo fluoresces yellow-green */}
        <div style={{position: 'absolute', left: CX - LW / 2 + 60, top: (H - LH) / 2 - 2, filter: 'sepia(1) saturate(9) hue-rotate(18deg) brightness(1.25) drop-shadow(0 0 10px rgba(226,255,58,0.9)) drop-shadow(0 0 22px rgba(226,255,58,0.5))'}}>
          <Logo kind="nameWhite" h={LH * (680 / 819.4)} />
        </div>
      </div>
      {/* "genuine" mark */}
      {f >= 100 && (
        <div dir="rtl" style={{position: 'absolute', left: SL + 12, top: 162, transform: `rotate(-7deg) scale(${stamp})`, opacity: after, padding: '2px 14px 6px', borderRadius: 10,
          border: '3px solid #39ff88', color: '#39ff88', fontFamily: 'ShxKufi', fontWeight: 800, fontSize: 24, lineHeight: 1.4, whiteSpace: 'nowrap',
          boxShadow: '0 0 14px rgba(57,255,136,0.8), inset 0 0 10px rgba(57,255,136,0.35)', textShadow: '0 0 10px rgba(57,255,136,0.9)'}}>{'پارەی ڕەسەن ✓'}</div>
      )}
      {/* the lamp beam */}
      {f >= 28 && f < 98 && (
        <div style={{position: 'absolute', left: beam - 70, top: -30, width: 140, height: H + 60, mixBlendMode: 'screen',
          background: 'linear-gradient(90deg,rgba(140,80,255,0) 0%,rgba(170,120,255,0.55) 38%,rgba(240,225,255,0.95) 50%,rgba(170,120,255,0.55) 62%,rgba(140,80,255,0) 100%)'}} />
      )}
      {/* lamp tube along the top edge */}
      <div style={{position: 'absolute', left: SL, width: ZW, top: 0, height: 5, opacity: uvOn, background: '#c9a8ff', boxShadow: '0 0 18px 8px rgba(140,80,255,0.9)'}} />
    </AbsoluteFill>
  );
};
