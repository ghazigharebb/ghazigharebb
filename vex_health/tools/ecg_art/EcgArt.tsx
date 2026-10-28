import React, {useMemo} from 'react';
import {AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, Easing} from 'remotion';
import {ThreeCanvas} from '@remotion/three';
import {useThree} from '@react-three/fiber';
import * as THREE from 'three';
import {RoundedBoxGeometry} from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';
import {RoomEnvironment} from 'three/examples/jsm/environments/RoomEnvironment.js';

// X-ray style monochrome forearm + fist + VEX band, on pure black (matches the ECG pages)
const SKIN = new THREE.MeshPhysicalMaterial({color: '#a8a8a8', roughness: 0.62, metalness: 0, sheen: 0.7, sheenColor: new THREE.Color('#ffffff'), sheenRoughness: 0.4, clearcoat: 0.15});
const FABRIC = new THREE.MeshStandardMaterial({color: '#141414', roughness: 0.95});
const CASE = new THREE.MeshStandardMaterial({color: '#1c1c1e', roughness: 0.35, metalness: 0.6});
const METAL = new THREE.MeshStandardMaterial({color: '#f2f2f2', roughness: 0.14, metalness: 1});

const Env: React.FC = () => {
  const {gl, scene} = useThree();
  useMemo(() => {
    const pm = new THREE.PMREMGenerator(gl);
    scene.environment = pm.fromScene(new RoomEnvironment(), 0.04).texture;
    scene.environmentIntensity = 0.35;
    gl.toneMapping = THREE.ACESFilmicToneMapping;
    gl.toneMappingExposure = 0.85;
    scene.fog = new THREE.Fog('#000000', 24, 44);
  }, [gl, scene]);
  return null;
};

const Capsule: React.FC<{a: [number, number, number]; b: [number, number, number]; r: number; m?: THREE.Material}> = ({a, b, r, m = SKIN}) => {
  const {pos, quat, len} = useMemo(() => {
    const A = new THREE.Vector3(...a), B = new THREE.Vector3(...b);
    const d = B.clone().sub(A);
    const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), d.clone().normalize());
    return {pos: A.clone().add(B).multiplyScalar(0.5), quat: q, len: d.length()};
  }, [a, b]);
  return (
    <mesh position={pos} quaternion={quat} material={m}>
      <capsuleGeometry args={[r, Math.max(0.01, len), 10, 24]} />
    </mesh>
  );
};

// forearm along +X (wrist at x=0), fist toward -X, palm down
const Arm: React.FC = () => {
  const arm = useMemo(() => {
    const pts: THREE.Vector2[] = [];
    for (let i = 0; i <= 24; i++) {
      const t = i / 24;
      pts.push(new THREE.Vector2(2.45 + 1.1 * Math.pow(t, 0.7), t * 34));
    }
    const g = new THREE.LatheGeometry(pts, 64);
    g.rotateZ(-Math.PI / 2);
    g.scale(1, 0.82, 1);
    return g;
  }, []);
  const palm = useMemo(() => new RoundedBoxGeometry(4.6, 2.5, 5.2, 6, 1.1), []);
  const fingers = [-1.95, -0.65, 0.65, 1.95];
  return (
    <group>
      <mesh geometry={arm} material={SKIN} position={[-0.2, 0, 0]} />
      {/* wrist joint */}
      <mesh material={SKIN} position={[-0.6, 0, 0]} scale={[1, 0.82, 1]}>
        <sphereGeometry args={[2.5, 48, 32]} />
      </mesh>
      {/* palm / back of hand */}
      <mesh geometry={palm} material={SKIN} position={[-3.4, 0.05, 0]} rotation={[0, 0, -0.08]} />
      {/* curled fingers: proximal goes forward, middle curls down, tip tucks back */}
      {fingers.map((z, i) => {
        const s = i === 3 ? 0.85 : i === 0 ? 0.95 : 1;
        return (
          <group key={i}>
            <Capsule a={[-5.0, 0.45, z]} b={[-6.7 * s - 0.1, 0.05, z]} r={0.66 * s} />
            <Capsule a={[-6.7 * s - 0.1, 0.05, z]} b={[-6.9 * s - 0.1, -1.25, z]} r={0.62 * s} />
            <Capsule a={[-6.9 * s - 0.1, -1.25, z]} b={[-5.9 * s, -1.75, z]} r={0.58 * s} />
          </group>
        );
      })}
      {/* thumb */}
      <Capsule a={[-2.4, -0.5, 2.3]} b={[-4.2, -1.1, 2.7]} r={0.7} />
      <Capsule a={[-4.2, -1.1, 2.7]} b={[-5.4, -1.5, 2.1]} r={0.6} />
    </group>
  );
};

// the band sits ~one finger above the wrist bone
const Band: React.FC<{glow: number}> = ({glow}) => {
  const strap = useMemo(() => {
    const s = new THREE.Shape();
    s.absarc(0, 0, 3.05, 0, Math.PI * 2, false);
    const h = new THREE.Path();
    h.absarc(0, 0, 2.72, 0, Math.PI * 2, true);
    s.holes.push(h);
    const g = new THREE.ExtrudeGeometry(s, {depth: 2.3, bevelEnabled: true, bevelSize: 0.08, bevelThickness: 0.08, bevelSegments: 3, curveSegments: 96});
    g.translate(0, 0, -1.15);
    g.rotateY(Math.PI / 2);
    g.scale(1, 0.84, 1);
    return g;
  }, []);
  const pod = useMemo(() => new RoundedBoxGeometry(2.5, 0.75, 3.3, 5, 0.32), []);
  const plate = useMemo(() => new RoundedBoxGeometry(1.5, 0.14, 2.2, 4, 0.06), []);
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({color: '#f4f4f4', roughness: 0.12, metalness: 1, emissive: new THREE.Color('#5CC68A'), emissiveIntensity: 0}), []);
  glowMat.emissiveIntensity = glow * 1.6;
  return (
    <group position={[1.7, 0, 0]}>
      <mesh geometry={strap} material={FABRIC} />
      <mesh geometry={pod} material={CASE} position={[0, 2.55, 0]} />
      <mesh geometry={plate} material={glow > 0 ? glowMat : METAL} position={[0, 2.95, 0]} />
    </group>
  );
};

// index finger of the other hand reaching the electrode
const Finger: React.FC<{p: number}> = ({p}) => {
  // p: 0 = far, 1 = touching
  const tip = new THREE.Vector3(1.7, 3.55, 0.15);
  const far = new THREE.Vector3(2.8, 6, 13.5);
  const T = far.clone().lerp(tip, p);
  const dir = new THREE.Vector3(0.12, 0.35, 0.93).normalize();
  const j1 = T.clone().add(dir.clone().multiplyScalar(1.9));
  const j2 = j1.clone().add(new THREE.Vector3(0.1, 0.5, 0.86).normalize().multiplyScalar(2.3));
  const j3 = j2.clone().add(new THREE.Vector3(0.1, 0.6, 0.8).normalize().multiplyScalar(2.8));
  const v = (x: THREE.Vector3): [number, number, number] => [x.x, x.y, x.z];
  const hand = j3.clone().add(new THREE.Vector3(0.7, 1.1, 2.6));
  return (
    <group>
      <Capsule a={v(T.clone().add(dir.clone().multiplyScalar(0.35)))} b={v(j1)} r={0.52} />
      <Capsule a={v(j1)} b={v(j2)} r={0.56} />
      <Capsule a={v(j2)} b={v(j3)} r={0.62} />
      {/* back of the hand, running off the bottom of the frame */}
      <Capsule a={v(j3)} b={v(hand)} r={1.05} />
      <Capsule a={v(hand)} b={v(hand.clone().add(new THREE.Vector3(0.6, 1.6, 6)))} r={1.35} />
      {/* curled middle finger knuckle */}
      <Capsule a={v(j3.clone().add(new THREE.Vector3(1.2, -0.3, 0.2)))} b={v(j3.clone().add(new THREE.Vector3(1.0, -1.1, -0.9)))} r={0.6} />
    </group>
  );
};

const Ripple: React.FC<{k: number}> = ({k}) => (
  <mesh position={[1.7, 3.05, 0]} rotation={[-Math.PI / 2, 0, 0]} scale={[1 + k * 2.6, 1 + k * 2.6, 1]}>
    <ringGeometry args={[1.2, 1.32, 64]} />
    <meshBasicMaterial color="#5CC68A" transparent opacity={(1 - k) * 0.8} toneMapped={false} />
  </mesh>
);

const Lights: React.FC = () => (
  <>
    <ambientLight intensity={0.03} />
    <directionalLight position={[-4, 10, 6]} intensity={1.5} />
    <directionalLight position={[4, 3, -12]} intensity={4.2} color="#ffffff" />
    <directionalLight position={[-12, -1, -4]} intensity={2.4} />
  </>
);

const Cam: React.FC<{pos: [number, number, number]; look: [number, number, number]; fov: number}> = ({pos, look, fov}) => {
  const {camera} = useThree();
  const c = camera as THREE.PerspectiveCamera;
  c.position.set(...pos);
  c.fov = fov;
  c.lookAt(...look);
  c.updateProjectionMatrix();
  return null;
};

// guide: side view of the arm + band, slow seamless sway (loop)
export const EcgGuide: React.FC = () => {
  const f = useCurrentFrame();
  const {width, height, durationInFrames} = useVideoConfig();
  const a = Math.sin((f / durationInFrames) * Math.PI * 2);
  return (
    <AbsoluteFill style={{background: '#000'}}>
      <ThreeCanvas width={width} height={height} gl={{antialias: true}}>
        <Env />
        <Lights />
        <Cam pos={[-1.5 + a * 1.2, 6, 25]} look={[-0.2, -0.2, 0]} fov={32} />
        <group rotation={[0.18, -0.12 + a * 0.05, 0.05]}>
          <Arm />
          <Band glow={0} />
        </group>
      </ThreeCanvas>
    </AbsoluteFill>
  );
};

// measure: top-front view, finger comes in, touches the electrode, contact ripple (loop)
export const EcgTouch: React.FC = () => {
  const f = useCurrentFrame();
  const {width, height, fps} = useVideoConfig();
  const t = f / fps; // 0..3.5
  const ease = Easing.inOut(Easing.cubic);
  const p = t < 1.2 ? ease(t / 1.2) : t < 2.7 ? 1 : 1 - ease(Math.min(1, (t - 2.7) / 0.8));
  const touching = t >= 1.2 && t < 2.7;
  const k = touching ? (t - 1.2) / 1.5 : 0;
  const glow = touching ? 0.6 + 0.4 * Math.sin((t - 1.2) * 8) : 0;
  return (
    <AbsoluteFill style={{background: '#000'}}>
      <ThreeCanvas width={width} height={height} gl={{antialias: true}}>
        <Env />
        <Lights />
        <Cam pos={[-2, 17, 17]} look={[0.2, 0.6, 1.4]} fov={36} />
        <group rotation={[0, -0.12, 0]}>
          <Arm />
          <Band glow={glow} />
          <Finger p={p} />
          {touching && <Ripple k={(k * 2) % 1} />}
          {touching && <Ripple k={(k * 2 + 0.5) % 1} />}
        </group>
      </ThreeCanvas>
    </AbsoluteFill>
  );
};

export const ecgFrames = {guide: 96, touch: 84};
export {interpolate};
