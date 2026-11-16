import React, {useLayoutEffect, useRef} from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {W, H, SL, CX, ZW, YELLOW, INK, BUTTER, rng, eIO, eBack, lerp, Logo, LOGO, XMark, useShxFonts} from './shx';

// 08 — one line around the world: a single unbroken yellow line draws New York, London, Paris and Istanbul
// and comes home to the Erbil Citadel. The wide strip is used as what it is: a panorama.
const B = 196; // ground line
const battlements = (x0: number, x1: number, y: number, step = 13) => { let s = ''; for (let x = x0; x < x1 - 1; x += step) s += ` V${y - 9} H${Math.min(x1, x + step / 2)} V${y} H${Math.min(x1, x + step)}`; return s; };
const PATH = [
  `M-40 ${B} H80`,
  // New York
  `V150 H108 V118 H134 V158 H150 V110 H162 V84 H170 V62 H176 V30 L179 8 L182 30 V62 H188 V84 H196 V110 H208 V158 H226 V98 L234 88 H258 V138 H274 V92 H282 V72 L289 46 L296 72 V92 H304 V148 H330 V124 H358 V${B} H470`,
  // London: Big Ben, Parliament, Tower Bridge, the Eye
  `V76 H465 V66 H470 V50 L486 20 L502 50 V66 H507 V76 H502 V140 H520 V126 H527 V140 H548 V126 H555 V140 H576 V126 H583 V140 H600 V${B} H636 V92 L646 74 L656 92 V124 Q700 166 744 124 V92 L754 74 L764 92 V${B} H812 V182 A40 40 0 1 1 812.1 182 V${B} H900`,
  // Paris
  `Q960 150 968 62 H971 V42 L975 12 L979 42 V62 H982 Q990 150 1050 ${B} H1128`,
  // Istanbul
  `V72 H1123 V64 H1128 V42 L1133 18 L1138 42 V64 H1143 V72 H1138 V150 H1158 Q1183 108 1208 150 V120 A62 62 0 0 1 1270 58 V40 V58 A62 62 0 0 1 1332 120 V150 Q1357 108 1382 150 H1402 V72 H1397 V64 H1402 V42 L1407 18 L1412 42 V64 H1417 V72 H1412 V${B} H1540`,
  // Erbil Citadel: the mound, the wall, the gate
  `L1592 132 V106${battlements(1592, 1696, 106)} V74${battlements(1696, 1748, 74, 13)} V106${battlements(1748, 1852, 106)} V132 L1904 ${B} H2000`,
].join(' ');
const WORLD = 1960;
const CITIES: {x: number; name: string; sym: string; bx: number; by: number}[] = [
  {x: 220, name: 'نیویۆرک', sym: '$', bx: 318, by: 62},
  {x: 640, name: 'لەندەن', sym: '£', bx: 586, by: 74},
  {x: 975, name: 'پاریس', sym: '€', bx: 1040, by: 70},
  {x: 1270, name: 'ئەستەنبوڵ', sym: '₺', bx: 1196, by: 60},
  {x: 1722, name: 'هەولێر', sym: 'X', bx: 1722, by: 36},
];

export const S08OneLine: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  const pathRef = useRef<SVGPathElement>(null);
  const worldRef = useRef<HTMLDivElement>(null);
  const tipRef = useRef<HTMLDivElement>(null);
  const p = rng(f, 4, 128);
  const zoom = eIO(rng(f, 130, 152));
  const out = rng(f, 172, 180);
  const S1 = (ZW - 20) / WORLD; // scale that fits the whole journey in the visible zone
  useLayoutEffect(() => {
    const path = pathRef.current, world = worldRef.current, tip = tipRef.current; if (!path || !world || !tip) return;
    const total = path.getTotalLength();
    path.style.strokeDasharray = `${total}`; path.style.strokeDashoffset = `${total * (1 - p)}`;
    const at = (q: number) => path.getPointAtLength(total * Math.max(0, Math.min(1, q)));
    const t = at(p);
    // camera follows a smoothed pen position so the small ups and downs of the line don't shake the frame
    let sx = 0; const K = 12; for (let k = 0; k < K; k++) sx += at(p - k * 0.006).x; sx /= K;
    const follow = SL + ZW * 0.66 - sx;
    const sc = lerp(1, S1, zoom);
    const tx = lerp(follow, SL + 10, zoom), ty = lerp(0, 26, zoom);
    world.style.transform = `translate(${tx}px,${ty}px) scale(${sc})`;
    tip.style.left = `${t.x - 5}px`; tip.style.top = `${t.y - 5}px`;
    world.dataset.tipx = String(t.x);
  }, [p, zoom, S1]);
  // which badges are already passed (approximate by pen progress along x, monotone enough)
  const LH = 96, LW = LH * LOGO.tagDark.ar;
  return (
    <AbsoluteFill style={{background: `linear-gradient(180deg,#1d1912 0%,${INK} 60%,#100d08 100%)`, overflow: 'hidden', opacity: 1 - out}}>
      <div ref={worldRef} style={{position: 'absolute', left: 0, top: 0, width: 2000, height: H, transformOrigin: '0 0'}}>
        <svg width={2040} height={H} style={{position: 'absolute', left: 0, top: 0, overflow: 'visible'}}>
          <path d={PATH} fill="none" stroke="rgba(245,183,0,0.10)" strokeWidth={2} />
          <path ref={pathRef} d={PATH} fill="none" stroke={YELLOW} strokeWidth={lerp(3.2, 6, zoom)} strokeLinejoin="round" strokeLinecap="round" />
        </svg>
        {CITIES.map((c, i) => {
          const show = eBack(rng(p, (c.x - 60) / 1990, (c.x - 60) / 1990 + 0.035));
          return (
            <React.Fragment key={c.name}>
              <div style={{position: 'absolute', left: c.bx - 19, top: c.by - 19, width: 38, height: 38, borderRadius: 19, background: YELLOW, transform: `scale(${show * lerp(1, 1.9, zoom)})`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 0 12px rgba(245,183,0,0.6)'}}>
                {c.sym === 'X' ? <XMark h={17} left={INK} right="#ffffff" /> : <span style={{fontFamily: 'ShxMont', fontWeight: 800, fontSize: 24, color: INK, lineHeight: 1}}>{c.sym}</span>}
              </div>
              <div dir="rtl" style={{position: 'absolute', left: c.x - 80, width: 160, top: 205, textAlign: 'center', fontFamily: 'ShxSans', fontWeight: 700, fontSize: 19, color: i === 4 ? YELLOW : BUTTER,
                opacity: show * (1 - zoom), whiteSpace: 'nowrap'}}>{c.name}</div>
            </React.Fragment>
          );
        })}
        <div ref={tipRef} style={{position: 'absolute', width: 10, height: 10, borderRadius: 5, background: '#fffbe6', boxShadow: '0 0 12px 5px rgba(245,183,0,0.9)', opacity: p < 1 ? 1 : 0}} />
      </div>
      {/* home: the logo under the finished panorama */}
      <div style={{position: 'absolute', left: CX - LW / 2, top: 122, opacity: zoom, transform: `translateY(${(1 - zoom) * 16}px)`}}><Logo kind="tagDark" h={LH} /></div>
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 4, height: 8, background: YELLOW, opacity: zoom}} />
    </AbsoluteFill>
  );
};
export const _s08 = W;
