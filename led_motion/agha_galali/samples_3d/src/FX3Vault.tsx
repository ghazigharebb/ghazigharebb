import React, {useMemo} from 'react';
import * as THREE from 'three';
import {useThree} from '@react-three/fiber';
import {useCurrentFrame} from 'remotion';
import {Env, Stage, useBillTextures, BILL_SRC, bendPlane, range, easeInOut, easeOut, rand, TAU, PANEL_X} from './common';
import {DARK, engrave} from '../agha/AghaGalali';

const R = 1.42; // door radius (world units, ~95 px)
const DX = -1.55; // door centre x

const gold = new THREE.MeshStandardMaterial({color: '#f0c25a', metalness: 1, roughness: 0.22});
const goldDark = new THREE.MeshStandardMaterial({color: '#b8862a', metalness: 1, roughness: 0.35});
const navy = new THREE.MeshPhysicalMaterial({color: '#1a3d78', metalness: 0.6, roughness: 0.32, clearcoat: 0.6});
const steel = new THREE.MeshStandardMaterial({color: '#c9d1d9', metalness: 1, roughness: 0.18});

const Cam: React.FC<{f: number}> = ({f}) => {
  const {camera} = useThree();
  const push = easeInOut(range(f, 0, 150));
  camera.position.set(DX + 1.9 - 0.9 * push, 0.5 - 0.35 * push, 8.6 - 1.6 * push);
  camera.lookAt(DX + 1.25, 0, 0);
  return null;
};

const Door: React.FC<{f: number}> = ({f}) => {
  const wheel = easeInOut(range(f, 8, 58)) * Math.PI * 3; // 1.5 turns, heavy
  const bolts = easeInOut(range(f, 54, 70));
  const open = easeInOut(range(f, 68, 104));
  const boltN = 10;
  return (
    <group position={[DX, 0, 0]}>
      {/* frame ring in the wall */}
      <mesh material={goldDark} rotation={[Math.PI / 2, 0, 0]} position={[0, 0, -0.05]} castShadow receiveShadow>
        <cylinderGeometry args={[R + 0.22, R + 0.22, 0.3, 72, 1, true]} />
      </mesh>
      <mesh material={gold} position={[0, 0, 0.1]}>
        <torusGeometry args={[R + 0.2, 0.06, 16, 96]} />
      </mesh>
      {/* bolt sockets on the frame */}
      {/* hinge group: pivot on the left edge, swings toward camera */}
      <group position={[-R - 0.05, 0, 0]} rotation={[0, -open * 1.95, 0]}>
        <group position={[R + 0.05, 0, 0]}>
          <mesh material={navy} rotation={[Math.PI / 2, 0, 0]} castShadow>
            <cylinderGeometry args={[R, R, 0.32, 96]} />
          </mesh>
          {/* concentric gold rings on the face */}
          {[0.92, 0.7, 0.5].map((k, i) => (
            <mesh key={i} material={i === 1 ? steel : gold} position={[0, 0, 0.165]}>
              <torusGeometry args={[R * k, 0.022 + i * 0.004, 12, 96]} />
            </mesh>
          ))}
          {/* rivets */}
          {Array.from({length: 24}, (_, i) => {
            const a = (i / 24) * TAU;
            return <mesh key={i} material={gold} position={[Math.cos(a) * R * 0.83, Math.sin(a) * R * 0.83, 0.17]}><sphereGeometry args={[0.035, 10, 10]} /></mesh>;
          })}
          {/* locking bolts (retract inward) */}
          {Array.from({length: boltN}, (_, i) => {
            const a = (i / boltN) * TAU;
            const r = R - 0.05 + (1 - bolts) * 0.2;
            return (
              <mesh key={i} material={steel} position={[Math.cos(a) * r, Math.sin(a) * r, 0]} rotation={[0, 0, a + Math.PI / 2]} castShadow>
                <cylinderGeometry args={[0.055, 0.055, 0.34, 16]} />
              </mesh>
            );
          })}
          {/* spinning wheel */}
          <group position={[0, 0, 0.3]} rotation={[0, 0, -wheel]}>
            <mesh material={gold}><torusGeometry args={[0.52, 0.05, 16, 64]} /></mesh>
            {[0, 1, 2].map((i) => (
              <group key={i} rotation={[0, 0, (i / 3) * TAU]}>
                <mesh material={gold} position={[0.26, 0, 0]} rotation={[0, 0, Math.PI / 2]}><cylinderGeometry args={[0.035, 0.035, 0.52, 12]} /></mesh>
                <mesh material={gold} position={[0.56, 0, 0]}><sphereGeometry args={[0.075, 16, 16]} /></mesh>
              </group>
            ))}
            <mesh material={steel} rotation={[Math.PI / 2, 0, 0]}><cylinderGeometry args={[0.13, 0.13, 0.12, 32]} /></mesh>
          </group>
        </group>
      </group>
    </group>
  );
};

const glowTex = (() => {
  let t: THREE.CanvasTexture | null = null;
  return () => {
    if (t) return t;
    const c = document.createElement('canvas'); c.width = c.height = 256;
    const x = c.getContext('2d')!; const g = x.createRadialGradient(128, 128, 0, 128, 128, 128);
    g.addColorStop(0, 'rgba(255,252,235,1)'); g.addColorStop(0.25, 'rgba(255,232,170,0.85)'); g.addColorStop(0.6, 'rgba(255,190,80,0.25)'); g.addColorStop(1, 'rgba(255,170,40,0)');
    x.fillStyle = g; x.fillRect(0, 0, 256, 256);
    t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; return t;
  };
})();

const Light: React.FC<{f: number}> = ({f}) => {
  const open = easeInOut(range(f, 68, 104));
  const flare = open * (0.85 + 0.15 * Math.sin(f / 3));
  const tex = useMemo(() => glowTex(), []);
  return (
    <group position={[DX, 0, -0.12]}>
      {/* the vault interior: a deep gold tunnel lit from the far end */}
      <mesh rotation={[Math.PI / 2, 0, 0]} position={[0, 0, -1.6]}>
        <cylinderGeometry args={[R, R * 0.55, 3.2, 72, 1, true]} />
        <meshStandardMaterial color="#d9a441" metalness={1} roughness={0.3} side={THREE.BackSide} emissive="#6b3d00" emissiveIntensity={0.6 * open} />
      </mesh>
      {[0.6, 1.4, 2.3].map((z, i) => (
        <mesh key={i} position={[0, 0, -z]}><torusGeometry args={[R * (1 - z * 0.14), 0.03, 10, 72]} /><meshStandardMaterial color="#fff0c0" metalness={1} roughness={0.2} emissive="#ffcc66" emissiveIntensity={open * 0.8} /></mesh>
      ))}
      <mesh position={[0, 0, -3.15]}><circleGeometry args={[R * 0.56, 64]} /><meshBasicMaterial color="#fff6dc" toneMapped={false} transparent opacity={0.2 + 0.8 * open} /></mesh>
      {/* bloom sprite + light rays */}
      <mesh position={[0, 0, 0.3]}><planeGeometry args={[5.5 * (0.6 + 0.4 * open), 5.5 * (0.6 + 0.4 * open)]} /><meshBasicMaterial map={tex} toneMapped={false} transparent opacity={0.85 * flare} blending={THREE.AdditiveBlending} depthWrite={false} /></mesh>
      {Array.from({length: 14}, (_, i) => {
        const a = (i / 14) * TAU + f * 0.004;
        const len = 2.6 + rand(i, 1) * 1.6;
        return (
          <mesh key={i} position={[Math.cos(a) * len * 0.5, Math.sin(a) * len * 0.5, 0.35]} rotation={[0, 0, a]}>
            <planeGeometry args={[len, 0.1 + rand(i, 2) * 0.16]} />
            <meshBasicMaterial color="#ffe7a8" toneMapped={false} transparent opacity={0.14 * flare} blending={THREE.AdditiveBlending} depthWrite={false} />
          </mesh>
        );
      })}
      <pointLight position={[0, 0, 1.2]} intensity={25 * open} distance={7} color="#ffe2a0" />
    </group>
  );
};

const FlyingNotes: React.FC<{f: number}> = ({f}) => {
  const tex = useBillTextures();
  const items = useMemo(() => Array.from({length: 22}, (_, i) => {
    const b = i % 4; const w = 0.95 + rand(i, 3) * 0.35;
    const geom = new THREE.PlaneGeometry(w, w / BILL_SRC[b].ar, 10, 1);
    return {b, w, geom, base: Float32Array.from(geom.attributes.position.array as Float32Array), st: 82 + rand(i, 1) * 44, a: rand(i, 2) * TAU, spread: 0.5 + rand(i, 4) * 1.6, spin: (rand(i, 5) - 0.5) * 0.3};
  }), []);
  if (tex.some((t) => !t)) return null;
  return (
    <group position={[DX, 0, 0]}>
      {items.map((it, i) => {
        const d = f - it.st;
        if (d < 0) return null;
        const t = d / 60;
        const z = 0.2 + t * 4.4;
        const x = Math.cos(it.a) * it.spread * t * 2.2 + t * 1.3;
        const y = Math.sin(it.a) * it.spread * t * 1.1 + Math.sin(d / 6 + i) * 0.1;
        if (z > 6.2) return null;
        bendPlane(it.geom, it.base, it.w, 0.35 * Math.sin(d / 5 + i), 0.04, d * 0.4);
        return (
          <mesh key={i} geometry={it.geom} position={[x, y, z]} rotation={[d * it.spin * 0.6, d * it.spin, d * it.spin * 0.8]}>
            <meshStandardMaterial map={tex[it.b]!} side={THREE.DoubleSide} roughness={0.55} />
          </mesh>
        );
      })}
    </group>
  );
};

export const FX3Vault: React.FC = () => {
  const f = useCurrentFrame();
  const name = easeOut(range(f, 96, 116));
  return (
    <Stage camera={{fov: 22, position: [0, 0.5, 8.6]}}
      overlay={
        <div dir="rtl" style={{position: 'absolute', left: 392, width: PANEL_X - 392 - 6, top: 70, textAlign: 'center', opacity: name, transform: `translateX(${(1 - name) * 30}px)`}}>
          <div style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 50, lineHeight: 1.5, color: DARK, filter: engrave, whiteSpace: 'nowrap'}}>{'آغا گەڵاڵی'}</div>
          <div style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 22, lineHeight: 1.6, color: DARK, filter: engrave}}>{'بۆ ئاڵوگۆڕی دراو'}</div>
        </div>
      }>
      <Env intensity={1.1} />
      <Cam f={f} />
      <ambientLight intensity={0.35} />
      <directionalLight position={[-3, 4, 6]} intensity={2.2} castShadow shadow-mapSize-width={1024} shadow-mapSize-height={1024}
        shadow-camera-left={-5} shadow-camera-right={5} shadow-camera-top={3} shadow-camera-bottom={-3} />
      <mesh position={[0, 0, -0.22]} receiveShadow><planeGeometry args={[30, 12]} /><shadowMaterial opacity={0.3} color="#3a2200" /></mesh>
      <Light f={f} />
      <Door f={f} />
      <FlyingNotes f={f} />
    </Stage>
  );
};
