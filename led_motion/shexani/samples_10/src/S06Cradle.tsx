import React, {useMemo} from 'react';
import * as THREE from 'three';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {Env} from '../fx3d/common';
import {ShxCanvas, YELLOW, BUTTER, INK, TAU, rnd, useDrawTex, drawCoinFace, useShxFonts, CX} from './shx';

// 06 — Newton's cradle of coins: the dinar strikes, the dollar flies. Exchange told by physics, no words.
// The pendulum is periodic, so the loop has no seam.
const SYMS = ['$', '€', 'X', '£', 'د.ع']; // left -> right (the dinar is on the right, where Kurdish reading starts)
const R = 0.15, L = 0.5, TOP = 0.39, TH0 = 0.78, PERIOD = 60;
const rim = new THREE.MeshStandardMaterial({color: '#d9961a', metalness: 1, roughness: 0.3, envMapIntensity: 0.8});

const Coin: React.FC<{i: number; ang: number; jit: number}> = ({i, ang, jit}) => {
  const tex = useDrawTex(256, 256, drawCoinFace(SYMS[i]), 'c' + SYMS[i]);
  const x0 = (i - 2) * R * 2;
  const str = useMemo(() => new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(0, 0, 0.09), new THREE.Vector3(0, -L + R * 0.9, 0), new THREE.Vector3(0, 0, -0.09), new THREE.Vector3(0, -L + R * 0.9, 0)]), []);
  if (!tex) return null;
  return (
    <group position={[x0 + jit, TOP, 0]} rotation={[0, 0, ang]}>
      <lineSegments geometry={str}><lineBasicMaterial color={BUTTER} transparent opacity={0.75} /></lineSegments>
      <group position={[0, -L, 0]} rotation={[0, 0, -ang * 0.15]}>
        <mesh rotation={[Math.PI / 2, 0, 0]} material={rim}><cylinderGeometry args={[R, R, 0.04, 56, 1, true]} /></mesh>
        <mesh position={[0, 0, 0.0201]}><circleGeometry args={[R, 56]} /><meshBasicMaterial map={tex} toneMapped={false} /></mesh>
      </group>
    </group>
  );
};

export const S06Cradle: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  const c = Math.cos((TAU * f) / PERIOD);
  const right = TH0 * Math.max(0, c);    // dinar swings out to the right first
  const left = -TH0 * Math.max(0, -c);
  // frames since the last impact (impacts at 15, 45, 75 ...)
  const since = ((f - 15) % 30 + 30) % 30;
  const hitSide = Math.floor((f - 15) / 30) % 2 === 0 ? 1 : -1; // which end was just struck
  const flash = f >= 15 ? Math.max(0, 1 - since / 9) : 0;
  const jit = (i: number) => (i > 0 && i < 4 ? Math.sin(since * 2.2 + i) * 0.006 * Math.max(0, 1 - since / 8) : 0);
  const impactX = hitSide * R * 3; // contact point between the end coin and its neighbour
  return (
    <AbsoluteFill style={{background: `radial-gradient(60% 120% at ${CX}px 55%,#211c13 0%,${INK} 55%,#0d0b07 100%)`}}>
      <ShxCanvas eye={[0, -0.15, 6.5]}>
        <Env intensity={1.1} />
        <ambientLight intensity={0.55} />
        <directionalLight position={[-2, 3, 5]} intensity={2.2} />
        {/* frame bar */}
        <mesh position={[0, TOP, 0]}><boxGeometry args={[1.86, 0.03, 0.2]} /><meshBasicMaterial color={YELLOW} /></mesh>
        {[-0.93, 0.93].map((x) => <mesh key={x} position={[x, TOP - 0.03, 0]}><boxGeometry args={[0.03, 0.09, 0.2]} /><meshBasicMaterial color="#9c7400" /></mesh>)}
        {SYMS.map((_, i) => <Coin key={i} i={i} ang={i === 0 ? left : i === 4 ? right : 0} jit={jit(i)} />)}
        {/* impact flash + sparks */}
        {flash > 0 && (
          <group position={[impactX, TOP - L, 0.08]}>
            <mesh><circleGeometry args={[0.1 + 0.25 * (1 - flash), 24]} /><meshBasicMaterial color="#fff6d0" transparent opacity={0.8 * flash} blending={THREE.AdditiveBlending} depthWrite={false} toneMapped={false} /></mesh>
            {Array.from({length: 10}, (_, k) => {
              const a = rnd(k + Math.floor(f / 30) * 13, 1) * TAU, d = (1 - flash) * (0.12 + rnd(k, 2) * 0.22);
              return <mesh key={k} position={[Math.cos(a) * d, Math.sin(a) * d - 0.1 * (1 - flash) * (1 - flash), 0]}><sphereGeometry args={[0.012 * flash, 6, 6]} /><meshBasicMaterial color={YELLOW} toneMapped={false} /></mesh>;
            })}
          </group>
        )}
      </ShxCanvas>
      <div dir="rtl" style={{position: 'absolute', left: 0, width: '100%', top: 214, textAlign: 'center', fontFamily: 'ShxSans', fontWeight: 700, fontSize: 21, color: BUTTER, opacity: 0.9}}>
        <span style={{position: 'relative', left: CX - 468}}>{'شێخانی · ئاڵوگۆڕی دراو'}</span>
      </div>
    </AbsoluteFill>
  );
};
