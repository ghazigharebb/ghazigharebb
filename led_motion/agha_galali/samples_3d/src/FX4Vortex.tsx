import React, {useMemo} from 'react';
import * as THREE from 'three';
import {useThree} from '@react-three/fiber';
import {useCurrentFrame} from 'remotion';
import {Env, Stage, useBillTextures, BILL_SRC, bendPlane, range, easeInOut, rand, TAU, PANEL_X, SAFE_L} from './common';
import {DARK, engrave} from '../agha/AghaGalali';

// Real banknotes swirl in a 3D tornado, then four hero notes break out and lock into a fan.
const N = 60;
const CX = 0.3; // vortex axis x (world), centred in the visible zone
const NAMES = ['دینار', 'دۆلار', 'یۆرۆ', 'پاوەند'];

const Cam: React.FC<{f: number}> = ({f}) => {
  const {camera} = useThree();
  const t = easeInOut(range(f, 0, 150));
  const a = -0.5 + t * 0.6;
  camera.position.set(CX + Math.sin(a) * 8.4, 1.3 - t * 1.2, Math.cos(a) * 8.4);
  camera.lookAt(CX, 0.05, 0);
  return null;
};

const Swarm: React.FC<{f: number}> = ({f}) => {
  const tex = useBillTextures();
  const items = useMemo(() => Array.from({length: N}, (_, i) => {
    const b = i % 4; const w = 1.0 + rand(i, 1) * 0.38;
    const geom = new THREE.PlaneGeometry(w, w / BILL_SRC[b].ar, 10, 1);
    return {b, w, geom, base: Float32Array.from(geom.attributes.position.array as Float32Array), a0: rand(i, 2) * TAU, h0: rand(i, 3), r: 0.85 + rand(i, 4) * 1.1, sp: 0.06 + rand(i, 5) * 0.035, tilt: (rand(i, 6) - 0.5) * 0.8};
  }), []);
  // the 4 hero notes: indices 0..3 (one per currency)
  const heroGeoms = useMemo(() => BILL_SRC.map((b) => { const w = 2.5; const g = new THREE.PlaneGeometry(w, w / b.ar, 14, 1); return {g, w, base: Float32Array.from(g.attributes.position.array as Float32Array)}; }), []);
  if (tex.some((t) => !t)) return null;
  const gather = easeInOut(range(f, 92, 124));
  const scatter = range(f, 92, 120);
  return (
    <group>
      {items.map((it, i) => {
        if (i < 4) return null;
        const ang = it.a0 + f * it.sp * (1 + (1 - it.r / 2.7));
        const h = ((it.h0 + f * 0.006) % 1) * 3.2 - 1.6;
        const r = it.r * (0.55 + 0.45 * ((h + 1.6) / 3.2)) * (1 + scatter * 3);
        const x = CX + Math.cos(ang) * r, z = Math.sin(ang) * r;
        bendPlane(it.geom, it.base, it.w, 0.5 * Math.sin(f / 7 + i), 0.03, f * 0.3 + i);
        const op = 1 - scatter;
        if (op <= 0.01) return null;
        return (
          <mesh key={i} geometry={it.geom} position={[x, h, z]} rotation={[it.tilt + Math.sin(f / 13 + i) * 0.4, -ang + Math.PI / 2, Math.sin(f / 9 + i) * 0.5]}>
            <meshStandardMaterial map={tex[it.b]!} side={THREE.DoubleSide} roughness={0.55} transparent opacity={op} />
          </mesh>
        );
      })}
      {/* hero notes: ride the vortex, then lock into a fan facing camera */}
      {heroGeoms.map((hg, b) => {
        const ang = b * (TAU / 4) + f * 0.055;
        const vx = CX + Math.cos(ang) * 1.4, vz = Math.sin(ang) * 1.4, vy = Math.sin(f / 20 + b) * 0.6;
        const fanA = (1.5 - b) * 0.27; // fan spread (dinar on the right, read first)
        const fx = CX + Math.sin(fanA) * 1.9, fy = -2.0 + Math.cos(fanA) * 1.9, fz = 1.3 + (3 - b) * 0.03;
        const x = vx + (fx - vx) * gather, y = vy + (fy - vy) * gather, z = vz + (fz - vz) * gather;
        const ry = (-ang + Math.PI / 2) * (1 - gather);
        const rz = fanA * -1 * gather + Math.sin(f / 9 + b) * 0.4 * (1 - gather);
        bendPlane(hg.g, hg.base, hg.w, 0.45 * (1 - gather) * Math.sin(f / 7 + b), 0.03 * (1 - gather), f * 0.3);
        return (
          <mesh key={'h' + b} geometry={hg.g} position={[x, y, z]} rotation={[0, ry, rz]} scale={0.6 + 0.4 * gather} castShadow>
            <meshStandardMaterial map={tex[b]!} side={THREE.DoubleSide} roughness={0.45} />
          </mesh>
        );
      })}
    </group>
  );
};

export const FX4Vortex: React.FC = () => {
  const f = useCurrentFrame();
  const lab = range(f, 122, 136);
  return (
    <Stage camera={{fov: 24, position: [0, 1.4, 9.5]}}
      overlay={
        <div dir="rtl" style={{position: 'absolute', left: SAFE_L, width: PANEL_X - SAFE_L, top: 214, display: 'flex', justifyContent: 'center', gap: 22, opacity: lab}}>
          {NAMES.map((n) => <span key={n} style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 26, color: DARK, filter: engrave}}>{n}</span>)}
        </div>
      }>
      <Env intensity={1} />
      <Cam f={f} />
      <fog attach="fog" args={['#d9ae4a', 8.5, 17]} />
      <ambientLight intensity={0.6} />
      <directionalLight position={[2, 5, 6]} intensity={2} castShadow shadow-mapSize-width={1024} shadow-mapSize-height={1024}
        shadow-camera-left={-5} shadow-camera-right={5} shadow-camera-top={3} shadow-camera-bottom={-3} />
      <mesh position={[0, 0, -2.4]} receiveShadow><planeGeometry args={[40, 14]} /><shadowMaterial opacity={0.18} color="#3a2200" /></mesh>
      <Swarm f={f} />
    </Stage>
  );
};
