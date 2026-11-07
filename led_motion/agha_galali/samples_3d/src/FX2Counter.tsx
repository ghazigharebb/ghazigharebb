import React, {useMemo} from 'react';
import * as THREE from 'three';
import {useThree} from '@react-three/fiber';
import {useCurrentFrame} from 'remotion';
import {Env, Stage, useImageTexture, bendPlane, range, easeInOut, easeOut, PANEL_X} from './common';
import {DARK, engrave} from '../agha/AghaGalali';

// A stack of real 25,000 IQD notes riffled like a counting machine + a rolling mechanical counter.
const NW = 1.62, NH = NW / 2.218;
const PX = -0.45; // pivot between the two stacks (world x)
const STACK = 46; // notes that flip during the shot
const RATE = 1.6; // frames between flips
const T0 = 12;

const Cam: React.FC<{f: number}> = ({f}) => {
  const {camera} = useThree();
  const t = easeInOut(range(f, 0, 150));
  camera.position.set(-0.1 - 0.7 * t, 2.7 - 0.5 * t, 4.9 - 0.3 * t);
  camera.lookAt(-0.05, -0.15, 0);
  return null;
};

const Note: React.FC<{tex: THREE.Texture; back: THREE.Texture; flip: number; idx: number; restY: number; landY: number}> = ({tex, back, flip, idx, restY, landY}) => {
  // pivot = left short edge of the right stack; flip 0..1 rotates the note over to the left stack
  const geom = useMemo(() => new THREE.PlaneGeometry(NW, NH, 18, 2), []);
  const base = useMemo(() => Float32Array.from(geom.attributes.position.array as Float32Array), [geom]);
  const ang = Math.PI * easeInOut(flip);
  const bend = Math.sin(Math.PI * flip) * 1.1; // paper bends mid-flight
  bendPlane(geom, base, NW, -bend, 0.02 * Math.sin(Math.PI * flip), idx);
  const y = restY + (landY - restY) * flip + Math.sin(Math.PI * flip) * 0.25;
  return (
    <group position={[PX, y, 0]} rotation={[-Math.PI / 2, 0, 0]}>
      <group rotation={[0, -ang, 0]}>
        <group position={[NW / 2, 0, 0]}>
          <mesh geometry={geom} castShadow>
            <meshStandardMaterial map={tex} roughness={0.6} metalness={0} side={THREE.FrontSide} />
          </mesh>
          <mesh geometry={geom} rotation={[0, 0, 0]} castShadow>
            <meshStandardMaterial map={back} roughness={0.6} side={THREE.BackSide} />
          </mesh>
        </group>
      </group>
    </group>
  );
};

const Stacks: React.FC<{f: number}> = ({f}) => {
  const tex = useImageTexture('notes/iqd.jpg');
  if (!tex) return null;
  const th = 0.012;
  const flipped = Math.max(0, Math.min(STACK, (f - T0) / RATE));
  const notes = [];
  // flying notes (only the ones in the air are animated individually)
  for (let i = 0; i < STACK; i++) {
    const start = T0 + i * RATE;
    const fl = range(f, start, start + 9);
    if (fl <= 0 || fl >= 1) continue;
    notes.push(<Note key={i} tex={tex} back={tex} flip={fl} idx={i} restY={(STACK - i) * th} landY={i * th} />);
  }
  const rightCount = STACK - Math.floor(flipped);
  const leftCount = Math.floor(Math.max(0, (f - T0 - 9) / RATE));
  return (
    <group>
      {/* right stack (to be counted) */}
      <mesh position={[PX + NW / 2, (rightCount * th) / 2, 0]} castShadow receiveShadow>
        <boxGeometry args={[NW, Math.max(0.001, rightCount * th), NH]} />
        <meshStandardMaterial attach="material-0" color="#d8c9b3" /><meshStandardMaterial attach="material-1" color="#d8c9b3" />
        <meshStandardMaterial attach="material-2" map={tex} /><meshStandardMaterial attach="material-3" color="#cdbba3" />
        <meshStandardMaterial attach="material-4" color="#e6d8c4" /><meshStandardMaterial attach="material-5" color="#e6d8c4" />
      </mesh>
      {/* left stack (counted) */}
      <mesh position={[PX - NW / 2, (Math.min(leftCount, STACK) * th) / 2, 0]} castShadow receiveShadow>
        <boxGeometry args={[NW, Math.max(0.001, Math.min(leftCount, STACK) * th), NH]} />
        <meshStandardMaterial attach="material-0" color="#d8c9b3" /><meshStandardMaterial attach="material-1" color="#d8c9b3" />
        <meshStandardMaterial attach="material-2" map={tex} /><meshStandardMaterial attach="material-3" color="#cdbba3" />
        <meshStandardMaterial attach="material-4" color="#e6d8c4" /><meshStandardMaterial attach="material-5" color="#e6d8c4" />
      </mesh>
      {notes}
      {/* gold band that holds the counted stack, snaps on at the end */}
      <mesh position={[PX - NW / 2, (STACK * th) / 2, 0]} scale={[1, 1, easeOut(range(f, 112, 122))]} visible={f > 112}>
        <boxGeometry args={[0.24, STACK * th + 0.02, NH + 0.02]} />
        <meshStandardMaterial color="#f0c25a" metalness={1} roughness={0.25} />
      </mesh>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.002, 0]} receiveShadow>
        <planeGeometry args={[30, 20]} />
        <shadowMaterial opacity={0.28} color="#3a2200" />
      </mesh>
    </group>
  );
};

// rolling odometer: each column scrolls continuously, lower columns blur when fast
const Odometer: React.FC<{value: number; speed: number}> = ({value, speed}) => {
  const digits = 8; // 25,000,000
  const cols = [];
  for (let k = digits - 1; k >= 0; k--) {
    // real odometer: a column only turns while every column below it is rolling from 9 to 0
    const p = Math.pow(10, k);
    const whole = Math.floor(value / p) % 10;
    const roll = k === 0 ? value % 1 : Math.min(1, Math.max(0, (value % p) / (p / 10) - 9));
    const pos = whole + roll;
    const colSpeed = speed / Math.pow(10, k);
    const blur = Math.min(4, colSpeed * 0.9);
    cols.push(
      <div key={k} style={{width: 26, height: 46, overflow: 'hidden', position: 'relative', borderRadius: 6,
        background: 'linear-gradient(180deg,#05112a,#173a73 50%,#05112a)', boxShadow: 'inset 0 0 0 1.5px #e9c25a, inset 0 6px 8px rgba(0,0,0,0.6), inset 0 -6px 8px rgba(0,0,0,0.6)'}}>
        <div style={{position: 'absolute', left: 0, right: 0, top: 0, transform: `translateY(${-pos * 46 - 46}px)`, filter: `blur(${blur}px)`}}>
          {[9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((d, i) => (
            <div key={i} style={{height: 46, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'NSans', fontWeight: 900, fontSize: 32,
              backgroundImage: 'linear-gradient(180deg,#fff6cf,#f3c94f 45%,#b8860b 70%,#ffe9a0)', WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent'}}>{d}</div>
          ))}
        </div>
      </div>,
    );
    if (k === 6 || k === 3) cols.push(<div key={'c' + k} style={{width: 7, alignSelf: 'flex-end', color: '#f3c94f', fontFamily: 'NSans', fontWeight: 900, fontSize: 26, lineHeight: 1}}>,</div>);
  }
  return <div dir="ltr" style={{display: 'flex', gap: 3, alignItems: 'center'}}>{cols}</div>;
};

export const FX2Counter: React.FC = () => {
  const f = useCurrentFrame();
  const t = range(f, T0, 112);
  const target = 25000000;
  const val = target * easeOut(t);
  const perFrame = (target * 3 * Math.pow(1 - t, 2)) / (112 - T0); // value change per frame
  const done = range(f, 112, 120);
  const pop = 1 + 0.08 * Math.sin(Math.PI * done);
  return (
    <Stage camera={{fov: 24, position: [-1, 3.4, 5.6]}}
      overlay={
        <div style={{position: 'absolute', left: 414, width: PANEL_X - 414 - 4, top: 58, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
          opacity: range(f, 4, 14), transform: `scale(${pop})`}}>
          <div style={{padding: 8, borderRadius: 12, background: 'linear-gradient(180deg,#2a2a2c,#050505)', boxShadow: `0 0 0 3px #e9c25a, 0 0 0 5px #6b4305, 0 10px 18px rgba(40,20,0,0.5), 0 0 ${24 * done}px ${8 * done}px rgba(255,230,150,${0.8 * done})`}}>
            <Odometer value={val} speed={t > 0 && t < 1 ? perFrame : 0} />
          </div>
          <div dir="rtl" style={{fontFamily: 'NKufi', fontWeight: 900, fontSize: 30, color: DARK, filter: engrave, lineHeight: 1.5}}>{'دیناری عێراقی'}</div>
        </div>
      }>
      <Env intensity={1} />
      <Cam f={f} />
      <ambientLight intensity={0.5} />
      <directionalLight position={[-2, 6, 3]} intensity={2.4} castShadow shadow-mapSize-width={1024} shadow-mapSize-height={1024}
        shadow-camera-left={-5} shadow-camera-right={5} shadow-camera-top={5} shadow-camera-bottom={-5} />
      <Stacks f={f} />
    </Stage>
  );
};
