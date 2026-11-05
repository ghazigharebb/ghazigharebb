import React from 'react';
// Vector re-drawing of the Agha Galali monogram (triangle "A" interlaced with a ring "G").
// Approximation traced from an LED photo — replace with the original file when available.
export const LogoAG: React.FC<{size: number; sheen: number}> = ({size, sheen}) => {
  const sx = -60 + sheen * 320; // sheen band position in viewBox units
  const tri = 'M100 4 L197 188 L3 188 Z M100 80 L58 156 L142 156 Z';
  // ring as thick arc, open on the right like a G, plus crossbar
  const R = 64, sw = 22, cx = 100, cy = 120;
  const a0 = (-28 * Math.PI) / 180, a1 = (8 * Math.PI) / 180;
  const p = (a: number) => `${(cx + R * Math.cos(a)).toFixed(2)} ${(cy + R * Math.sin(a)).toFixed(2)}`;
  const ring = `M${p(a0)} A${R} ${R} 0 1 0 ${p(a1)}`;
  return (
    <svg width={size} height={size} viewBox="0 0 200 200">
      <defs>
        <linearGradient id="steel" x1="0" y1="0" x2="0.3" y2="1">
          <stop offset="0" stopColor="#f4f7fa" /><stop offset="0.35" stopColor="#aeb8c3" /><stop offset="0.55" stopColor="#4b545e" />
          <stop offset="0.75" stopColor="#8994a0" /><stop offset="1" stopColor="#2b3138" />
        </linearGradient>
        <linearGradient id="chrome" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ffffff" /><stop offset="0.3" stopColor="#d5dce3" /><stop offset="0.48" stopColor="#6f7a86" />
          <stop offset="0.52" stopColor="#3d454e" /><stop offset="0.7" stopColor="#c6ced6" /><stop offset="1" stopColor="#eef2f5" />
        </linearGradient>
        <linearGradient id="sh" gradientUnits="userSpaceOnUse" x1={sx - 30} y1="0" x2={sx + 30} y2="40">
          <stop offset="0" stopColor="#fff" stopOpacity="0" /><stop offset="0.5" stopColor="#fff" stopOpacity="0.85" /><stop offset="1" stopColor="#fff" stopOpacity="0" />
        </linearGradient>
        <clipPath id="top"><rect x="0" y="0" width="200" height="74" /></clipPath>
      </defs>
      {/* triangle */}
      <path d={tri} fill="url(#steel)" fillRule="evenodd" stroke="#0d0f12" strokeWidth="1.5" />
      <path d={tri} fill="url(#sh)" fillRule="evenodd" />
      {/* ring (G) */}
      <path d={ring} fill="none" stroke="#0d0f12" strokeWidth={sw + 3} />
      <path d={ring} fill="none" stroke="url(#chrome)" strokeWidth={sw} />
      <path d={ring} fill="none" stroke="url(#sh)" strokeWidth={sw} />
      {/* crossbar */}
      <rect x={118} y={116} width={57} height={20} fill="url(#chrome)" stroke="#0d0f12" strokeWidth="1.5" />
      <rect x={118} y={116} width={57} height={20} fill="url(#sh)" />
      {/* apex passes over the ring (interlace) */}
      <g clipPath="url(#top)">
        <path d={tri} fill="url(#steel)" fillRule="evenodd" stroke="#0d0f12" strokeWidth="1.5" />
        <path d={tri} fill="url(#sh)" fillRule="evenodd" />
      </g>
    </svg>
  );
};
