import React, {useEffect, useState} from 'react';
import {AbsoluteFill, Img, continueRender, delayRender, staticFile} from 'remotion';

// Shexani — still frame for the 936x260 LED above the door.
// Follows the brand's own storefront board: Ink fascia, white wordmark, yellow X, yellow band below.
// The left ~110 px of the physical sign are hidden, so everything sits in x = 122..936.
const W = 936, H = 260, SAFE_L = 122;
const YELLOW = '#F5B700', INK = '#16130D', BUTTER = '#FFF1C2';
const LOGO_AR = 1925.1 / 819.4; // official SVG viewBox

const AR = 'U+0600-06FF,U+0750-077F,U+FB50-FDFF,U+FE70-FEFF,U+200C-200F';
const useBrandFonts = () => {
  const [h] = useState(() => delayRender('brand fonts'));
  useEffect(() => {
    const faces = [
      new FontFace('ShxKufi', `url(${staticFile('fonts/nkufi-800.woff2')})`, {weight: '800', unicodeRange: AR}),
      new FontFace('ShxSans', `url(${staticFile('fonts/nsans-700.woff2')})`, {weight: '700', unicodeRange: AR}),
    ];
    Promise.all(faces.map((f) => f.load())).then((l) => { l.forEach((f) => document.fonts.add(f)); continueRender(h); }).catch(() => continueRender(h));
  }, [h]);
};

export const ShexaniStill: React.FC<{variant: 'dark-info' | 'dark-center' | 'yellow-center'}> = ({variant}) => {
  useBrandFonts();
  const yellowBg = variant === 'yellow-center';
  const logo = staticFile(yellowBg ? 'shexani/logo_tag_yellow.svg' : 'shexani/logo_tag_dark.svg');
  const centered = variant !== 'dark-info';
  const LH = centered ? 196 : 182;
  const LW = LH * LOGO_AR;
  const zoneC = (SAFE_L + W) / 2;
  const logoLeft = centered ? zoneC - LW / 2 : W - 34 - LW;
  const logoTop = (H - 14 - LH) / 2;
  return (
    <AbsoluteFill style={{background: yellowBg ? YELLOW : INK, overflow: 'hidden'}}>
      {/* soft light falloff so the fascia does not read as a flat fill on the LED */}
      <AbsoluteFill style={{background: yellowBg
        ? `radial-gradient(70% 120% at ${logoLeft + LW / 2}px 45%,rgba(255,236,170,0.55) 0%,rgba(255,236,170,0) 60%),linear-gradient(180deg,rgba(0,0,0,0) 60%,rgba(120,80,0,0.18) 100%)`
        : `radial-gradient(60% 110% at ${logoLeft + LW / 2}px 46%,rgba(255,241,194,0.075) 0%,rgba(255,241,194,0) 65%),linear-gradient(180deg,#1d1912 0%,${INK} 55%,#100d08 100%)`}} />
      <Img src={logo} style={{position: 'absolute', left: logoLeft, top: logoTop, width: LW, height: LH}} />
      {variant === 'dark-info' && (
        <>
          <div style={{position: 'absolute', left: logoLeft - 30, top: 62, width: 3, height: 112, borderRadius: 2, background: YELLOW}} />
          <div dir="rtl" style={{position: 'absolute', left: SAFE_L + 20, width: logoLeft - 30 - (SAFE_L + 20) - 22, top: 54, textAlign: 'center'}}>
            <div style={{fontFamily: 'ShxSans', fontWeight: 700, fontSize: 21, lineHeight: 1.7, color: BUTTER, whiteSpace: 'nowrap'}}>{'دۆلار · یۆرۆ · پاوەند · لیرە'}</div>
            {/* phone groups laid out left-to-right explicitly: Arabic-Indic digits separated by spaces get reordered by the bidi algorithm */}
            <div dir="ltr" style={{display: 'flex', justifyContent: 'center', gap: 10, fontFamily: 'ShxKufi', fontWeight: 800, fontSize: 33, lineHeight: 1.6, color: YELLOW, whiteSpace: 'nowrap'}}>
              {['٠٧٥١', '٩٩٩', '٢٠٠٠'].map((g) => <span key={g}>{g}</span>)}
            </div>
          </div>
        </>
      )}
      {/* yellow band under the fascia (ink band on the yellow version) */}
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 4, height: 10, background: yellowBg ? INK : YELLOW}} />
    </AbsoluteFill>
  );
};
