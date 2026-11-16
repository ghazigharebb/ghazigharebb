import React, {useMemo} from 'react';
import * as THREE from 'three';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {Env} from '../fx3d/common';
import {ShxCanvas, YELLOW, INK, TAU, eIO, rng, rnd, useTex, chevronShape, useShxFonts} from './shx';

// 02 — "the door above the door": the Ink fascia splits at the X like the sliding glass door below it,
// opening onto a deep gold vault, then closes again (natural loop).
const EYE: [number, number, number] = [0, -0.7, 6.5];
const OPEN = 0.96, DEPTH = 1.9;

const gold = new THREE.MeshStandardMaterial({color: '#d9961a', metalness: 1, roughness: 0.3, envMapIntensity: 0.75});
const BARS = (() => {
  const out: {x: number; y: number; z: number; r: number}[] = [];
  const bw = 0.3, bh = 0.088;
  for (let layer = 0; layer < 2; layer++) {
    const z = -0.7 - layer * 0.5;
    for (let j = 0; j < 6 + layer * 2; j++) {
      for (let k = -3; k <= 3; k++) {
        const x = k * (bw + 0.012) + (j % 2) * 0.155;
        if (Math.abs(x) > OPEN - 0.12) continue;
        // a low wall across the vault, rising into stacks at both sides; the centre stays open for the logo
        const maxRow = (layer === 0 ? 2 : 3) + Math.max(0, Math.round((Math.abs(x) - 0.38) * 7));
        if (j > maxRow) continue;
        out.push({x, y: -0.5 + bh / 2 + j * (bh + 0.006), z, r: (rnd(out.length, 1) - 0.5) * 0.05});
      }
    }
  }
  return out;
})();

const Vault: React.FC<{f: number; open: number}> = ({f, open}) => {
  const logo = useTex('shexani/logo_tag_dark.svg');
  const sweep = -1.6 + 3.2 * rng(f, 62, 128);
  return (
    <group>
      <mesh position={[0, 0, -DEPTH]}><planeGeometry args={[OPEN * 2 + 0.2, 1.1]} /><meshStandardMaterial color="#0e0b06" roughness={0.9} /></mesh>
      <mesh position={[0, 0.5, -DEPTH / 2]} rotation={[Math.PI / 2, 0, 0]}><planeGeometry args={[OPEN * 2 + 0.2, DEPTH]} /><meshStandardMaterial color="#2a1d07" roughness={0.6} metalness={0.4} /></mesh>
      <mesh position={[0, -0.5, -DEPTH / 2]} rotation={[-Math.PI / 2, 0, 0]}><planeGeometry args={[OPEN * 2 + 0.2, DEPTH]} /><meshStandardMaterial color="#1c1305" roughness={0.5} metalness={0.5} /></mesh>
      <mesh position={[-OPEN - 0.05, 0, -DEPTH / 2]} rotation={[0, Math.PI / 2, 0]}><planeGeometry args={[DEPTH, 1.1]} /><meshStandardMaterial color="#231807" roughness={0.6} metalness={0.4} /></mesh>
      <mesh position={[OPEN + 0.05, 0, -DEPTH / 2]} rotation={[0, -Math.PI / 2, 0]}><planeGeometry args={[DEPTH, 1.1]} /><meshStandardMaterial color="#231807" roughness={0.6} metalness={0.4} /></mesh>
      {/* ceiling light strips */}
      {[-0.5, -1.0, -1.5].map((z) => <mesh key={z} position={[0, 0.495, z]} rotation={[Math.PI / 2, 0, 0]}><planeGeometry args={[OPEN * 1.7, 0.035]} /><meshBasicMaterial color="#ffe9a8" toneMapped={false} transparent opacity={0.25 + 0.75 * open} /></mesh>)}
      {BARS.map((b, i) => <mesh key={i} material={gold} position={[b.x, b.y, b.z]} rotation={[0, b.r, 0]}><boxGeometry args={[0.3, 0.088, 0.17]} /></mesh>)}
      {logo && <mesh position={[0, 0.14, -DEPTH + 0.02]}><planeGeometry args={[1.0, 1.0 / (1925.1 / 819.4)]} /><meshBasicMaterial map={logo} transparent toneMapped={false} opacity={open} /></mesh>}
      <pointLight position={[0, 0.25, -0.5]} intensity={2.2 * open} distance={4} color="#ffd98a" />
      <pointLight position={[sweep, 0.1, -0.2]} intensity={open > 0.9 ? 1.6 : 0} distance={1.6} color="#ffffff" />
    </group>
  );
};

const Doors: React.FC<{f: number; open: number}> = ({f, open}) => {
  const chL = useMemo(() => new THREE.ShapeGeometry(chevronShape('l')), []);
  const chR = useMemo(() => new THREE.ShapeGeometry(chevronShape('r')), []);
  const shift = open * OPEN;
  const pulse = 1 + 0.06 * Math.sin((TAU * f) / 30) * (1 - open);
  const door = (side: -1 | 1) => (
    <group position={[side * (1.5 + shift), 0, 0]}>
      <mesh><planeGeometry args={[3, 1.4]} /><meshBasicMaterial color={INK} /></mesh>
      {/* brand band continues across both doors */}
      <mesh position={[0, -0.455, 0.003]}><planeGeometry args={[3, 0.04]} /><meshBasicMaterial color={YELLOW} toneMapped={false} /></mesh>
      {/* lit edge at the seam */}
      <mesh position={[-side * 1.494, 0, 0.004]}><planeGeometry args={[0.012, 1.4]} /><meshBasicMaterial color="#ffe9a8" toneMapped={false} transparent opacity={0.25 + 0.75 * Math.min(1, open * 3)} /></mesh>
      <mesh geometry={side === -1 ? chL : chR} position={[-side * 1.5, 0.03, 0.006]} scale={0.46 * pulse}><meshBasicMaterial color={side === -1 ? '#ffffff' : YELLOW} toneMapped={false} /></mesh>
    </group>
  );
  return <>{door(-1)}{door(1)}</>;
};

export const S02Doors: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  const open = eIO(rng(f, 22, 62)) * (1 - eIO(rng(f, 132, 170)));
  return (
    <AbsoluteFill style={{background: '#000'}}>
      <ShxCanvas eye={EYE}>
        <Env intensity={0.55} />
        <ambientLight intensity={0.25} />
        <Vault f={f} open={open} />
        <Doors f={f} open={open} />
      </ShxCanvas>
    </AbsoluteFill>
  );
};
