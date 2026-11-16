import React, {useMemo} from 'react';
import * as THREE from 'three';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {Env} from '../fx3d/common';
import {ShxCanvas, YELLOW, TAU, rnd, useTex, useDrawTex, drawCoinFace, useShxFonts} from './shx';

// 03 — "the invisible screen" (night version): pure black = LEDs off, nothing touches the edges,
// so at night the rectangle disappears and the logo and coins seem to hang in the air above the door.
const SYMS = ['$', '€', '£', '₺', 'د.ع', 'X'];
const RX = 1.1, RZ = 0.6;
const rim = new THREE.MeshStandardMaterial({color: '#d9961a', metalness: 1, roughness: 0.3, envMapIntensity: 0.8});

const Coin: React.FC<{f: number; i: number}> = ({f, i}) => {
  const tex = useDrawTex(256, 256, drawCoinFace(SYMS[i]), SYMS[i]);
  const a = (TAU * f) / 180 + (i * TAU) / SYMS.length;
  const x = RX * Math.cos(a), z = RZ * Math.sin(a), y = 0.17 * Math.sin(a + 0.7) - 0.02;
  if (!tex) return null;
  return (
    <group position={[x, y, z]} rotation={[0, a * 2 + i, 0.15 * Math.sin(a)]}>
      <mesh rotation={[Math.PI / 2, 0, 0]} material={rim}><cylinderGeometry args={[0.1, 0.1, 0.022, 40, 1, true]} /></mesh>
      <mesh position={[0, 0, 0.0112]}><circleGeometry args={[0.1, 40]} /><meshBasicMaterial map={tex} toneMapped={false} /></mesh>
      <mesh position={[0, 0, -0.0112]} rotation={[0, Math.PI, 0]}><circleGeometry args={[0.1, 40]} /><meshBasicMaterial map={tex} toneMapped={false} /></mesh>
    </group>
  );
};

const Scene: React.FC<{f: number}> = ({f}) => {
  const logo = useTex('shexani/logo_name_dark.svg');
  const glow = useMemo(() => {
    const c = document.createElement('canvas'); c.width = c.height = 256;
    const x = c.getContext('2d')!; const g = x.createRadialGradient(128, 128, 0, 128, 128, 128);
    g.addColorStop(0, 'rgba(245,183,0,0.55)'); g.addColorStop(0.4, 'rgba(245,183,0,0.16)'); g.addColorStop(1, 'rgba(245,183,0,0)');
    x.fillStyle = g; x.fillRect(0, 0, 256, 256);
    return new THREE.CanvasTexture(c);
  }, []);
  const breathe = 0.75 + 0.25 * Math.sin((TAU * f) / 90);
  return (
    <>
      <mesh position={[0, 0, -0.5]}><planeGeometry args={[2.6, 1.0]} /><meshBasicMaterial map={glow} transparent opacity={0.5 * breathe} blending={THREE.AdditiveBlending} depthWrite={false} toneMapped={false} /></mesh>
      {logo && <mesh position={[0.02, 0.0, 0]}><planeGeometry args={[1.62, 1.62 / (1925.1 / 680)]} /><meshBasicMaterial map={logo} transparent alphaTest={0.5} toneMapped={false} side={THREE.DoubleSide} /></mesh>}
      {SYMS.map((_, i) => <Coin key={i} f={f} i={i} />)}
      {/* comet dust behind each coin */}
      {SYMS.map((_, i) => Array.from({length: 7}, (__, k) => {
        const a = (TAU * f) / 180 + (i * TAU) / SYMS.length - (k + 1) * 0.07;
        return <mesh key={`${i}-${k}`} position={[RX * Math.cos(a), 0.17 * Math.sin(a + 0.7) - 0.02, RZ * Math.sin(a)]}>
          <sphereGeometry args={[0.014 * (1 - k / 8), 6, 6]} /><meshBasicMaterial color={YELLOW} transparent opacity={0.7 * (1 - k / 7)} toneMapped={false} /></mesh>;
      }))}
      {/* twinkles */}
      {Array.from({length: 26}, (_, i) => {
        const tw = Math.pow(Math.max(0, Math.sin((TAU * f) / 60 + rnd(i, 1) * TAU)), 6);
        return <mesh key={i} position={[(rnd(i, 2) - 0.5) * 2.3, (rnd(i, 3) - 0.5) * 0.72, (rnd(i, 4) - 0.5) * 1.0]}>
          <sphereGeometry args={[0.008, 5, 5]} /><meshBasicMaterial color="#fff3c4" transparent opacity={tw} toneMapped={false} /></mesh>;
      })}
    </>
  );
};

export const S03Float: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{background: '#000'}}>
      <ShxCanvas eye={[0, -0.25, 6.5]}>
        <Env intensity={0.9} />
        <ambientLight intensity={0.8} />
        <directionalLight position={[-2, 2, 5]} intensity={2} />
        <Scene f={f} />
      </ShxCanvas>
    </AbsoluteFill>
  );
};
