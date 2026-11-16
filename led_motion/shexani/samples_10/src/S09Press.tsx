import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {H, SL, SR, CX, YELLOW, INK, BUTTER, PAPER, BRONZE, TAU, rng, eOut, eIn, eIO, eBack, rnd, lerp, Logo, LOGO, XMark, useShxFonts} from './shx';

// 09 — the money press: the strip is a printing line. A blank sheet runs under the roller and comes out as a
// Shexani note (a brand piece, not a currency design); the X is struck onto it like a seal.
const NW = 470, NH = 176, NY = (H - NH) / 2 - 4, ROLL = 722;
const LH = 106, LW = LH * LOGO.tagColour.ar;

const Rosette: React.FC<{cx: number; cy: number; r: number}> = ({cx, cy, r}) => (
  <g stroke={BRONZE} fill="none" strokeWidth={0.9} opacity={0.55}>
    {[0, 1, 2, 3, 4].map((n) => {
      let d = '';
      for (let i = 0; i <= 180; i++) { const t = (i / 180) * TAU; const rr = r + r * 0.22 * Math.sin(12 * t + (n * TAU) / 60); d += `${i ? 'L' : 'M'}${(cx + rr * Math.cos(t)).toFixed(1)} ${(cy + rr * Math.sin(t)).toFixed(1)}`; }
      return <path key={n} d={d} />;
    })}
    <circle cx={cx} cy={cy} r={r * 0.45} /><circle cx={cx} cy={cy} r={r * 0.3} />
  </g>
);

const Printed: React.FC = () => (
  <div style={{position: 'absolute', inset: 0, background: `linear-gradient(135deg,${PAPER},${BUTTER})`}}>
    <svg width={NW} height={NH} style={{position: 'absolute'}}>
      {Array.from({length: 9}, (_, w) => {
        let d = ''; for (let x = 0; x <= NW; x += 6) d += `${x ? 'L' : 'M'}${x} ${(16 + w * 18 + Math.sin(x / 26 + w) * 5).toFixed(1)}`;
        return <path key={w} d={d} stroke={BRONZE} strokeWidth={0.7} fill="none" opacity={0.22} />;
      })}
      <Rosette cx={50} cy={NH / 2} r={27} /><Rosette cx={NW - 50} cy={NH / 2} r={27} />
      <rect x={7} y={7} width={NW - 14} height={NH - 14} fill="none" stroke={INK} strokeWidth={3} rx={3} />
      <rect x={13} y={13} width={NW - 26} height={NH - 26} fill="none" stroke={YELLOW} strokeWidth={2} rx={2} />
    </svg>
    {/* official logo; its X is clipped away and struck on separately as the seal (same polygons, same colours) */}
    <div style={{position: 'absolute', left: NW / 2 - LW / 2, top: NH / 2 - LH / 2 + 2, clipPath: 'inset(0 0 0 14.2%)'}}><Logo kind="tagColour" h={LH} /></div>
    <div dir="ltr" style={{position: 'absolute', left: 24, bottom: 16, fontFamily: 'ShxMont', fontWeight: 800, fontSize: 11, color: BRONZE, letterSpacing: 1.5}}>SX 000 001</div>
    <div dir="ltr" style={{position: 'absolute', right: 24, top: 16, fontFamily: 'ShxMont', fontWeight: 800, fontSize: 11, color: BRONZE, letterSpacing: 1.5}}>ERBIL · 60M</div>
  </div>
);

export const S09Press: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  const travel = rng(f, 0, 104);
  const left = lerp(SR + 40, CX - NW / 2, eIO(travel)) - eIn(rng(f, 160, 180)) * 760;
  const printedW = Math.max(0, Math.min(NW, ROLL - left));
  const rollUp = eOut(rng(f, 104, 122));           // roller lifts away once the sheet is through
  const seal = rng(f, 118, 128);
  const sealS = seal < 1 ? lerp(3.2, 1, eIn(seal)) : 1 + 0.12 * Math.exp(-(f - 128) / 4) * Math.cos((f - 128) * 1.1);
  const ring = rng(f, 128, 146);
  const lift = eBack(rng(f, 132, 150), 1.2);
  const sheen = lerp(-30, 130, rng(f, 136, 158));
  const xx = NW / 2 - LW / 2 + LW * LOGO.tagColour.xcx, xy = NH / 2 - LH / 2 + 2 + LH * LOGO.tagColour.xcy, xh = LH * LOGO.tagColour.xh;
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg,#1d1912 0%,${INK} 60%,#100d08 100%)`, overflow: 'hidden'}}>
      {/* conveyor rails */}
      {[NY - 10, NY + NH + 6].map((y) => (
        <div key={y} style={{position: 'absolute', left: 0, right: 0, top: y, height: 4, background: `repeating-linear-gradient(90deg,${YELLOW} 0 14px,rgba(245,183,0,0.15) 14px 28px)`, backgroundPositionX: -f * 5, opacity: 0.5}} />
      ))}
      {/* the sheet */}
      <div style={{position: 'absolute', left, top: NY - lift * 5, width: NW, height: NH, borderRadius: 5, overflow: 'hidden', transform: `scale(${1 + 0.035 * lift})`,
        boxShadow: `0 ${8 + 12 * lift}px ${16 + 18 * lift}px rgba(0,0,0,0.6)`}}>
        <div style={{position: 'absolute', inset: 0, background: `linear-gradient(135deg,#f3ecd6,#e9dfc0)`}} />
        <div style={{position: 'absolute', left: 0, top: 0, width: printedW, height: NH, overflow: 'hidden'}}><div style={{position: 'absolute', left: 0, top: 0, width: NW, height: NH}}><Printed /></div></div>
        {/* wet-ink edge right behind the roller */}
        {printedW > 0 && printedW < NW && <div style={{position: 'absolute', left: printedW - 10, top: 0, width: 10, height: NH, background: 'linear-gradient(90deg,rgba(245,183,0,0),rgba(245,183,0,0.75))'}} />}
        {/* the seal: X struck onto the note */}
        {f >= 118 && <div style={{position: 'absolute', left: xx, top: xy, transform: `translate(-50%,-50%) scale(${sealS})`, opacity: Math.min(1, seal * 3)}}><XMark h={xh} left={INK} right={YELLOW} /></div>}
        {ring > 0 && ring < 1 && <div style={{position: 'absolute', left: xx - 12 - ring * 70, top: xy - 12 - ring * 70, width: 24 + ring * 140, height: 24 + ring * 140, borderRadius: '50%', border: `${3 - 2 * ring}px solid rgba(245,183,0,${1 - ring})`}} />}
        <div style={{position: 'absolute', top: -30, bottom: -30, left: `${sheen}%`, width: 60, transform: 'skewX(-20deg)', background: 'linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,0.8),rgba(255,255,255,0))'}} />
      </div>
      {/* ink droplets thrown off at the nip */}
      {travel > 0.1 && travel < 0.98 && Array.from({length: 12}, (_, i) => {
        const t = ((f * 1.7 + i * 7) % 20) / 20, a = -0.5 + rnd(i, 1) * 1.0;
        return <div key={i} style={{position: 'absolute', left: ROLL - 4 - Math.cos(a) * t * 46, top: NY + rnd(i, 2) * NH + Math.sin(a) * t * 30, width: 4, height: 4, borderRadius: 2, background: YELLOW, opacity: 1 - t}} />;
      })}
      {/* the roller */}
      <div style={{position: 'absolute', left: ROLL - 6, top: 8 - rollUp * 250, width: 46, height: H - 16, borderRadius: 10, overflow: 'hidden',
        background: 'linear-gradient(90deg,#3a3428 0%,#c9c2b0 22%,#fffaf0 34%,#8d8676 52%,#2b261c 78%,#16130d 100%)', boxShadow: '0 0 0 2px #0b0906, -10px 0 22px rgba(0,0,0,0.55)'}}>
        <div style={{position: 'absolute', inset: 0, background: 'repeating-linear-gradient(0deg,rgba(0,0,0,0.0) 0 10px,rgba(0,0,0,0.22) 10px 12px)', backgroundPositionY: f * 6}} />
        <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 12, background: YELLOW}} /><div style={{position: 'absolute', left: 0, right: 0, bottom: 0, height: 12, background: YELLOW}} />
        <div style={{position: 'absolute', left: 0, top: 12, bottom: 12, width: 9, background: 'rgba(245,183,0,0.85)'}} />
      </div>
    </AbsoluteFill>
  );
};
export const _s09 = SL;
