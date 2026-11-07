import React, {useMemo} from 'react';
import * as THREE from 'three';
import {useThree} from '@react-three/fiber';
import {interpolate, useCurrentFrame} from 'remotion';
import {Env, Stage, useGlyphs, easeOutBack, easeInOut, range, rand, GlyphJSON, CANVAS_L, CANVAS_W, SAFE_L, PANEL_X} from './common';
import nameJson from './name_glyphs.json';
import {DARK, engrave} from '../agha/AghaGalali';

// 1 world unit = 66.9 px at fov 22 / z 10 (260 px tall canvas)
const ZONE_SHIFT = ((SAFE_L + PANEL_X) / 2 - (CANVAS_L + CANVAS_W / 2)) / 66.9;
const SPARKS_PER = 9;

const Cam: React.FC<{f: number}> = ({f}) => {
  const {camera} = useThree();
  const t = easeInOut(range(f, 0, 100));
  const x = interpolate(t, [0, 1], [2.6, 1.1]) + Math.sin(f / 40) * 0.12;
  const y = interpolate(t, [0, 1], [-1.4, -0.55]);
  const z = interpolate(t, [0, 1], [7.6, 9.7]);
  camera.position.set(x + ZONE_SHIFT, y, z);
  camera.lookAt(ZONE_SHIFT, 0.32, 0);
  return null;
};

const Name3D: React.FC<{f: number}> = ({f}) => {
  const glyphs = useGlyphs(nameJson as GlyphJSON, 1.33, 0.22, 0.055);
  // right-to-left reveal: highest x first
  const order = useMemo(() => [...glyphs].sort((a, b) => b.cx - a.cx).map((g) => glyphs.indexOf(g)), [glyphs]);
  const mats = useMemo(() => [
    new THREE.MeshPhysicalMaterial({color: '#173a73', metalness: 0.35, roughness: 0.22, clearcoat: 1, clearcoatRoughness: 0.08}),
    new THREE.MeshStandardMaterial({color: '#ffcf66', metalness: 1, roughness: 0.14}),
  ], []);
  const sparkGeo = useMemo(() => new THREE.SphereGeometry(0.028, 6, 6), []);
  const sparkMat = useMemo(() => new THREE.MeshBasicMaterial({color: '#fff3c4', toneMapped: false}), []);
  return (
    <group position={[ZONE_SHIFT, 0.42, 0]}>
      {glyphs.map((g, i) => {
        const k = order.indexOf(i);
        const st = 6 + k * 4.2;
        const t = range(f, st, st + 24);
        const e = easeOutBack(t, 1.4);
        const ry = (rand(i, 1) - 0.5) * 1.6;
        return (
          <mesh key={i} geometry={g.geom} material={mats} castShadow
            position={[g.cx, g.cy + (1 - e) * -1.6, (1 - e) * 2.2]}
            rotation={[(1 - e) * -1.9, (1 - e) * ry, (1 - e) * (rand(i, 2) - 0.5) * 0.8]}
            scale={0.4 + 0.6 * Math.min(1, t * 1.6)} />
        );
      })}
      {/* landing sparks */}
      {glyphs.map((g, i) => {
        const k = order.indexOf(i);
        const land = 6 + k * 4.2 + 14;
        const d = f - land;
        if (d < 0 || d > 22) return null;
        return Array.from({length: SPARKS_PER}, (_, j) => {
          const a = rand(i * 13 + j, 3) * Math.PI * 2;
          const sp = 0.05 + rand(i * 13 + j, 4) * 0.07;
          const x = g.cx + Math.cos(a) * sp * d;
          const y = g.cy + Math.sin(a) * sp * d * 0.7 - 0.004 * d * d;
          const s = Math.max(0, 1 - d / 22);
          return <mesh key={`${i}-${j}`} geometry={sparkGeo} material={sparkMat} position={[x, y, 0.25 + rand(j, 5) * 0.3]} scale={s} />;
        });
      })}
    </group>
  );
};

const Lights: React.FC<{f: number}> = ({f}) => {
  // a warm light that sweeps right -> left and makes the gold bevels flash
  const sweep = interpolate(f, [70, 125], [6, -6], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <>
      <ambientLight intensity={0.25} />
      <directionalLight position={[0, 4, -3]} intensity={1.6} color="#fff2d0" />
      <directionalLight position={[-3, 5, 6]} intensity={2.2} castShadow shadow-mapSize-width={1024} shadow-mapSize-height={1024}
        shadow-camera-left={-6} shadow-camera-right={6} shadow-camera-top={3} shadow-camera-bottom={-3} />
      <pointLight position={[sweep + ZONE_SHIFT, 1.2, 2.2]} intensity={f > 68 && f < 128 ? 18 : 0} distance={6} color="#fff0c8" />
      {/* shadow catcher: shadows fall on the (HTML) gold wall */}
      <mesh position={[0, 0, -0.35]} receiveShadow>
        <planeGeometry args={[30, 10]} />
        <shadowMaterial opacity={0.22} color="#3a2200" />
      </mesh>
    </>
  );
};

export const FX1Forge: React.FC = () => {
  const f = useCurrentFrame();
  const sub = range(f, 78, 96);
  return (
    <Stage camera={{fov: 22, position: [0, 0, 10]}}
      overlay={
        <div dir="rtl" style={{position: 'absolute', left: SAFE_L, width: PANEL_X - SAFE_L, top: 192, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 14,
          opacity: sub, transform: `translateY(${(1 - sub) * 12}px)`}}>
          <div style={{width: 70 * sub, height: 3, background: DARK, filter: engrave}} />
          <span style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 28, color: DARK, filter: engrave}}>{'بۆ ئاڵوگۆڕی دراو'}</span>
          <div style={{width: 70 * sub, height: 3, background: DARK, filter: engrave}} />
        </div>
      }>
      <Env intensity={1.45} />
      <Cam f={f} />
      <Lights f={f} />
      <Name3D f={f} />
    </Stage>
  );
};
