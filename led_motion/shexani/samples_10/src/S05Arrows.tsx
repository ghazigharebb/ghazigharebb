import React from 'react';
import {AbsoluteFill, Img, staticFile, useCurrentFrame} from 'remotion';
import {CameraMotionBlur} from '@remotion/motion-blur';
import {W, H, SL, SR, CX, YELLOW, INK, BUTTER, TAU, rng, eExpo, eIn, eIO, eBack, rnd, lerp, Chevron, Logo, LOGO, useShxFonts} from './shx';

// 05 — "two arrows, one X": the logo's own story. One arrow carries dinar from the right, one carries
// dollar from the left; they meet in the middle, the money changes sides, and the arrows become the X.
const CY = 118, HIT = 46;
const LH = 176, LW = LH * LOGO.tagDark.ar, LL = CX - LW / 2, LT = (H - 12 - LH) / 2;
const XH0 = 124, XH1 = LH * LOGO.tagDark.xh;
const XX1 = LL + LW * LOGO.tagDark.xcx, XY1 = LT + LH * LOGO.tagDark.xcy;

const Inner: React.FC = () => {
  const f = useCurrentFrame();
  const inn = eIn(rng(f, 8, HIT));                  // approach
  const lock = eIO(rng(f, 92, 122));                // X travels to its place in the logo
  const out = rng(f, 166, 180);
  const xh = lerp(XH0, XH1, lock);
  const tipX = lerp(CX, XX1, lock), tipY = lerp(CY, XY1, lock);
  const gap = (1 - inn) * 520;                      // distance of each arrow tip from the meeting point
  const squash = f >= HIT ? 1 + 0.16 * Math.exp(-(f - HIT) / 5) * Math.cos((f - HIT) * 0.9) : 1;
  const shake = f >= HIT && f < HIT + 8 ? Math.sin(f * 3.1) * 5 * (1 - (f - HIT) / 8) : 0;
  // notes: follow their arrow in, then swap sides on arcs, then leave
  const sw = eIO(rng(f, HIT, HIT + 34));
  const leave = eIn(rng(f, 92, 112));
  const note = (src: string, ar: number, side: -1 | 1) => {
    // side -1: starts on the left (dollar), ends on the right
    const h = 74, w = h * ar;
    const startX = CX + side * (gap + 150);
    const endX = CX - side * 205;
    const x = f < HIT ? startX : lerp(CX + side * 150, endX, sw) - side * leave * 420;
    const y = CY + (f < HIT ? 0 : -side * Math.sin(Math.PI * sw) * 46);
    const rot = f < HIT ? side * -4 : side * (-4 + 8 * sw) + Math.sin(Math.PI * sw) * side * 14;
    return <Img src={staticFile(src)} style={{position: 'absolute', left: x - w / 2, top: y - h / 2, width: w, height: h, borderRadius: 4, transform: `rotate(${rot}deg)`,
      boxShadow: '0 8px 18px rgba(0,0,0,0.6)', opacity: (1 - leave) * rng(f, 6, 14)}} />;
  };
  const reveal = eExpo(rng(f, 112, 140));
  const flash = f >= HIT ? Math.max(0, 1 - (f - HIT) / 14) : 0;
  return (
    <AbsoluteFill style={{opacity: 1 - out, transform: `translateX(${shake}px)`}}>
      {/* speed streaks */}
      {f < HIT + 4 && Array.from({length: 16}, (_, i) => {
        const side = i % 2 ? 1 : -1, y = 34 + rnd(i, 1) * 170, len = 60 + rnd(i, 2) * 150;
        const x = CX + side * (gap + 120 + rnd(i, 3) * 260);
        return <div key={i} style={{position: 'absolute', left: side > 0 ? x : x - len, top: y, width: len, height: 2 + (i % 3), borderRadius: 2, opacity: 0.55 * inn * (1 - flash),
          background: `linear-gradient(${side > 0 ? 90 : 270}deg,${i % 4 < 2 ? YELLOW : '#ffffff'},rgba(255,255,255,0))`}} />;
      })}
      {note('notes/usd.jpg', 2.375, -1)}
      {note('notes/iqd.jpg', 2.218, 1)}
      {/* impact */}
      {flash > 0 && (
        <>
          <div style={{position: 'absolute', left: CX - 170, top: CY - 170, width: 340, height: 340, borderRadius: '50%', opacity: flash,
            background: 'radial-gradient(circle,rgba(255,246,208,0.95) 0%,rgba(245,183,0,0.45) 30%,rgba(245,183,0,0) 65%)'}} />
          <div style={{position: 'absolute', left: CX - 40 - (1 - flash) * 190, top: CY - 40 - (1 - flash) * 190, width: 80 + (1 - flash) * 380, height: 80 + (1 - flash) * 380, borderRadius: '50%',
            border: `${1 + 3 * flash}px solid rgba(245,183,0,${flash})`}} />
          {Array.from({length: 18}, (_, i) => {
            const a = rnd(i, 5) * TAU, d = (1 - flash) * (60 + rnd(i, 6) * 150), s = 3 + rnd(i, 7) * 4;
            return <div key={i} style={{position: 'absolute', left: CX + Math.cos(a) * d - s / 2, top: CY + Math.sin(a) * d * 0.55 - s / 2, width: s, height: s, borderRadius: s, background: i % 3 ? YELLOW : '#fff', opacity: flash}} />;
          })}
        </>
      )}
      {/* the two arrows */}
      <div style={{position: 'absolute', left: tipX - gap, top: tipY, transform: `translate(-100%,-50%) scale(${1 / squash},${squash})`, transformOrigin: '100% 50%'}}><Chevron side="l" h={xh} color="#ffffff" /></div>
      <div style={{position: 'absolute', left: tipX + gap, top: tipY, transform: `translate(0,-50%) scale(${1 / squash},${squash})`, transformOrigin: '0% 50%'}}><Chevron side="r" h={xh} color={YELLOW} /></div>
      {/* official logo opens out from the X */}
      <div style={{position: 'absolute', left: LL, top: LT, clipPath: `inset(-10px ${(1 - reveal) * 100}% -10px ${LOGO.tagDark.xcx * 2 * 100}%)`, opacity: Math.min(1, reveal * 3)}}><Logo kind="tagDark" h={LH} /></div>
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 4, height: 10, background: YELLOW, transform: `scaleX(${eBack(rng(f, 120, 146), 0.6)})`, transformOrigin: `${XX1}px 50%`}} />
    </AbsoluteFill>
  );
};

export const S05Arrows: React.FC = () => {
  useShxFonts();
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg,#1d1912 0%,${INK} 55%,#100d08 100%)`}}>
      <CameraMotionBlur shutterAngle={200} samples={5}><Inner /></CameraMotionBlur>
    </AbsoluteFill>
  );
};
export const _s05 = [W, SL, SR, BUTTER];
