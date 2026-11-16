import React, {useMemo} from 'react';
import * as THREE from 'three';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {Env, bendPlane} from '../fx3d/common';
import {ShxCanvas, SAFE_HW, YELLOW, TAU, eIO, rng, rnd, useTex, useX3D, useShxFonts, X_WHITE, X_YELLOW} from './shx';

// 01 — "3D window": the screen is a box with real depth, computed for an eye standing on the pavement
// below the sign. The X and banknotes fly out past the yellow frame (the frame is part of the picture).
const EYE: [number, number, number] = [0, -0.8, 6.5];
const HW = SAFE_HW - 0.02, HH = 0.43, D = 2.4, RING = 0.3;

const Tunnel: React.FC<{f: number}> = ({f}) => {
  const logo = useTex('shexani/logo_tag_dark.svg');
  const facade = useMemo(() => {
    const s = new THREE.Shape(); s.moveTo(-4, -2); s.lineTo(4, -2); s.lineTo(4, 2); s.lineTo(-4, 2); s.closePath();
    const h = new THREE.Path(); h.moveTo(-HW, -HH); h.lineTo(-HW, HH); h.lineTo(HW, HH); h.lineTo(HW, -HH); h.closePath(); s.holes.push(h);
    return new THREE.ShapeGeometry(s);
  }, []);
  const lines = useMemo(() => {
    const pos: number[] = [], col: number[] = [];
    const y = new THREE.Color(YELLOW);
    const seg = (a: number[], b: number[]) => {
      [a, b].forEach((p) => { pos.push(p[0], p[1], p[2]); const k = Math.pow(1 - Math.min(1, -p[2] / D), 1.3) * 0.9 + 0.12; col.push(y.r * k, y.g * k, y.b * k); });
    };
    for (let x = -HW; x <= HW + 1e-3; x += (2 * HW) / 12) { seg([x, -HH, 0], [x, -HH, -D]); seg([x, HH, 0], [x, HH, -D]); }
    for (let yy = -HH; yy <= HH + 1e-3; yy += (2 * HH) / 4) { seg([-HW, yy, 0], [-HW, yy, -D]); seg([HW, yy, 0], [HW, yy, -D]); }
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); g.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
    return g;
  }, []);
  // rings rush toward the viewer (seamless: 12 ring spacings per loop)
  const off = ((f / 180) * 12 * RING) % RING;
  const rings = [];
  for (let k = 0; k < 9; k++) {
    const z = -k * RING - (RING - off);
    if (z < -D) continue;
    const a = Math.pow(1 - Math.min(1, -z / D), 1.5) * 0.85 + 0.05;
    rings.push(
      <lineLoop key={k}>
        <bufferGeometry><bufferAttribute attach="attributes-position" args={[new Float32Array([-HW, -HH, z, HW, -HH, z, HW, HH, z, -HW, HH, z]), 3]} /></bufferGeometry>
        <lineBasicMaterial color={YELLOW} transparent opacity={a} />
      </lineLoop>,
    );
  }
  const bar = (x: number, y: number, w: number, h: number, key: string) => <mesh key={key} position={[x, y, 0.004]}><planeGeometry args={[w, h]} /><meshBasicMaterial color={YELLOW} toneMapped={false} /></mesh>;
  const T = 0.024;
  return (
    <>
      <mesh geometry={facade}><meshBasicMaterial color="#000000" /></mesh>
      {/* box interior */}
      <mesh position={[0, 0, -D]}><planeGeometry args={[HW * 2, HH * 2]} /><meshBasicMaterial color="#0c0a06" /></mesh>
      <mesh position={[0, HH, -D / 2]} rotation={[Math.PI / 2, 0, 0]}><planeGeometry args={[HW * 2, D]} /><meshBasicMaterial color="#17130c" /></mesh>
      <mesh position={[0, -HH, -D / 2]} rotation={[-Math.PI / 2, 0, 0]}><planeGeometry args={[HW * 2, D]} /><meshBasicMaterial color="#100d08" /></mesh>
      <mesh position={[-HW, 0, -D / 2]} rotation={[0, Math.PI / 2, 0]}><planeGeometry args={[D, HH * 2]} /><meshBasicMaterial color="#13100a" /></mesh>
      <mesh position={[HW, 0, -D / 2]} rotation={[0, -Math.PI / 2, 0]}><planeGeometry args={[D, HH * 2]} /><meshBasicMaterial color="#13100a" /></mesh>
      <lineSegments geometry={lines}><lineBasicMaterial vertexColors /></lineSegments>
      {rings}
      {logo && <mesh position={[0, 0.1, -D + 0.01]}><planeGeometry args={[1.5, 1.5 / (1925.1 / 819.4)]} /><meshBasicMaterial map={logo} transparent toneMapped={false} opacity={1 - 0.8 * eIO(rng(f, 24, 78)) * (1 - eIO(rng(f, 148, 178)))} /></mesh>}
      {/* the fake frame: lives at the screen plane, so anything in front of it reads as outside the screen */}
      {bar(0, HH + T / 2, HW * 2 + T * 2, T, 't')}{bar(0, -HH - T / 2, HW * 2 + T * 2, T, 'b')}{bar(-HW - T / 2, 0, T, HH * 2, 'l')}{bar(HW + T / 2, 0, T, HH * 2, 'r')}
    </>
  );
};

const FlyX: React.FC<{f: number}> = ({f}) => {
  const x3 = useX3D(0.16, 0.014);
  const p = eIO(rng(f, 24, 78)) * (1 - eIO(rng(f, 148, 178)));
  const z = -1.75 + 2.75 * p;
  return (
    <group position={[0, 0.1 - 0.2 * p, z]} rotation={[0.1 * Math.sin(f / 17), p * TAU + 0.22 * Math.sin(f / 23), 0]} scale={0.42}>
      <mesh geometry={x3.l} material={X_WHITE} />
      <mesh geometry={x3.r} material={X_YELLOW} />
    </group>
  );
};

const NOTES = Array.from({length: 11}, (_, i) => ({b: i % 4, st: 58 + i * 8.5, x0: (rnd(i, 1) - 0.5) * 1.5, y0: (rnd(i, 2) - 0.5) * 0.4, sp: (rnd(i, 3) - 0.5) * 0.25, ph: rnd(i, 4) * TAU}));
const SRC = [['notes/iqd.jpg', 2.218], ['notes/usd.jpg', 2.375], ['notes/eur.jpg', 1.927], ['notes/gbp.jpg', 1.87]] as const;
const Note: React.FC<{f: number; i: number; tex: THREE.Texture | null}> = ({f, i, tex}) => {
  const n = NOTES[i]; const ar = SRC[n.b][1]; const w = 0.62;
  const geom = useMemo(() => new THREE.PlaneGeometry(w, w / ar, 12, 1), [ar]);
  const base = useMemo(() => Float32Array.from(geom.attributes.position.array as Float32Array), [geom]);
  const d = f - n.st;
  if (!tex || d < 0 || d > 54) return null;
  const t = d / 54;
  const z = -2.2 + t * t * 6.4 + t * 1.2;
  bendPlane(geom, base, w, 0.5 * Math.sin(d / 6 + n.ph), 0.03, d * 0.4);
  return (
    <mesh geometry={geom} position={[n.x0 * (1 + t * 1.3), n.y0 - 0.34 * t - 0.1 * t * t, z]} rotation={[d * 0.09 + n.ph, d * n.sp, Math.sin(d / 9 + n.ph) * 0.7]}>
      <meshStandardMaterial map={tex} side={THREE.DoubleSide} roughness={0.5} />
    </mesh>
  );
};
const Notes: React.FC<{f: number}> = ({f}) => {
  const tex = [useTex(SRC[0][0]), useTex(SRC[1][0]), useTex(SRC[2][0]), useTex(SRC[3][0])];
  return <>{NOTES.map((n, i) => <Note key={i} f={f} i={i} tex={tex[n.b]} />)}</>;
};

export const S01Window: React.FC = () => {
  useShxFonts();
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{background: '#000'}}>
      <ShxCanvas eye={EYE}>
        <Env intensity={0.9} />
        <ambientLight intensity={0.55} />
        <directionalLight position={[-1.5, 1, 5]} intensity={1.3} />
        <Tunnel f={f} />
        <Notes f={f} />
        <FlyX f={f} />
      </ShxCanvas>
    </AbsoluteFill>
  );
};
