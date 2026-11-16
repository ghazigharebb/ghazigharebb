import React, {useMemo} from 'react';
import * as THREE from 'three';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {Env, useGlyphs, GlyphJSON} from '../fx3d/common';
import {ShxCanvas, YELLOW, BUTTER, INK, TAU, rng, lerp, eIO, useX3D, useShxFonts, CX} from './shx';
import nameJson from './name_glyphs.json';

// 10 — "the sign that knows the time": real raised letters on the fascia; the light comes from where the sun
// really is (morning left, noon above, evening right), and at night the letters light themselves.
// Shown here as a 6 s time-lapse; on site it would be four clips on the controller's schedule.
const PARTS = [
  {t: 'بەیانیت باش', clock: '08:00', sun: true},
  {t: 'نیوەڕۆت باش', clock: '13:00', sun: true},
  {t: 'ئێوارەت باش', clock: '18:00', sun: true},
  {t: 'شەوت باش', clock: '22:00', sun: false},
];
const mix = (a: string, b: string, t: number) => new THREE.Color(a).lerp(new THREE.Color(b), t);

const Sign: React.FC<{f: number}> = ({f}) => {
  const glyphs = useGlyphs(nameJson as GlyphJSON, 0.4, 0.07, 0.012);
  const x3 = useX3D(0.38, 0.03);
  const day = rng(f, 0, 132);                 // 0 morning -> 1 evening
  const night = eIO(rng(f, 128, 142)) * (1 - eIO(rng(f, 170, 180)));
  const phi = lerp(2.62, 0.52, day);          // sun angle: left-low -> top -> right-low
  const sunCol = day < 0.5 ? mix('#ffcf8f', '#ffffff', day * 2) : mix('#ffffff', '#ff8f3d', (day - 0.5) * 2);
  const white = useMemo(() => new THREE.MeshStandardMaterial({color: '#ffffff', roughness: 0.6, metalness: 0}), []);
  const yel = useMemo(() => new THREE.MeshStandardMaterial({color: '#F5B700', roughness: 0.6, metalness: 0}), []);
  white.emissive = new THREE.Color('#fff6dc'); white.emissiveIntensity = 0.75 * night;
  yel.emissive = new THREE.Color(YELLOW); yel.emissiveIntensity = 0.15 + 0.85 * night;
  const halo = useMemo(() => {
    const c = document.createElement('canvas'); c.width = 512; c.height = 256; const x = c.getContext('2d')!;
    const g = x.createRadialGradient(256, 128, 0, 256, 128, 256); g.addColorStop(0, 'rgba(255,214,110,0.9)'); g.addColorStop(0.5, 'rgba(245,183,0,0.25)'); g.addColorStop(1, 'rgba(245,183,0,0)');
    x.fillStyle = g; x.fillRect(0, 0, 512, 256); return new THREE.CanvasTexture(c);
  }, []);
  return (
    <>
      <ambientLight intensity={0.5 + 0.25 * (1 - night)} />
      <directionalLight position={[Math.cos(phi) * 4, Math.sin(phi) * 2.6 + 0.4, 2.2]} intensity={2.4 * (1 - night)} color={sunCol} castShadow
        shadow-mapSize-width={2048} shadow-mapSize-height={1024} shadow-camera-left={-2} shadow-camera-right={2} shadow-camera-top={1} shadow-camera-bottom={-1} shadow-bias={-0.0006} />
      <mesh position={[0, 0, -0.04]} receiveShadow><planeGeometry args={[6, 2]} /><meshStandardMaterial color="#2e281c" roughness={1} /></mesh>
      {/* night: back-lit halo */}
      <mesh position={[0.12, 0.03, -0.03]}><planeGeometry args={[2.6, 0.95]} /><meshBasicMaterial map={halo} transparent opacity={0.55 * night} blending={THREE.AdditiveBlending} depthWrite={false} toneMapped={false} /></mesh>
      <group position={[0.2, -0.1, 0]}>
        {glyphs.map((g, i) => <mesh key={i} geometry={g.geom} material={white} position={[g.cx, g.cy, 0.04]} castShadow />)}
      </group>
      <group position={[-0.83, 0.03, 0.04]} scale={0.21}>
        <mesh geometry={x3.l} material={white} castShadow /><mesh geometry={x3.r} material={yel} castShadow />
      </group>
    </>
  );
};

export const S10Time: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  const idx = Math.min(3, Math.floor(f / 45));
  const local = f - idx * 45;
  const a = Math.min(1, local / 8) * (1 - rng(local, 38, 45));
  const p = PARTS[idx];
  const day = rng(f, 0, 132);
  // sun / moon marker travelling along the top edge
  const sx = CX + lerp(-250, 250, day);
  return (
    <AbsoluteFill style={{background: INK}}>
      <ShxCanvas eye={[0, -0.2, 6.5]}>
        <Env intensity={0.1} />
        <Sign f={f} />
      </ShxCanvas>
      <div dir="rtl" style={{position: 'absolute', left: CX - 200, width: 400, top: 206, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 12, opacity: a, transform: `translateY(${(1 - a) * 8}px)`}}>
        <span style={{fontFamily: 'ShxSans', fontWeight: 700, fontSize: 22, color: BUTTER}}>{p.t}</span>
        <span style={{width: 5, height: 5, borderRadius: 3, background: YELLOW}} />
        <span dir="ltr" style={{fontFamily: 'ShxMont', fontWeight: 800, fontSize: 21, color: YELLOW, letterSpacing: 1}}>{p.clock}</span>
      </div>
      {p.sun
        ? <div style={{position: 'absolute', left: sx - 9, top: 14 + 14 * Math.abs(day - 0.5) * 2, width: 18, height: 18, borderRadius: 9, background: YELLOW, boxShadow: '0 0 14px 4px rgba(245,183,0,0.7)', opacity: a}} />
        : <div style={{position: 'absolute', left: CX + 232, top: 16, width: 18, height: 18, borderRadius: 9, boxShadow: `inset -6px -2px 0 0 ${BUTTER}`, opacity: a}} />}
    </AbsoluteFill>
  );
};
export const _t = TAU;
