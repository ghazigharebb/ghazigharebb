import React, {useMemo} from 'react';
import * as THREE from 'three';
import {useThree} from '@react-three/fiber';
import {interpolate, useCurrentFrame} from 'remotion';
import {Env, Stage, useCanvasTexture, useGlyphs, GlyphJSON, range, easeOutBack, easeInOut, TAU, SAFE_L, PANEL_X, CANVAS_L, CANVAS_W} from './common';
import nameJson from './name_glyphs.json';

// A brand "banknote" for Agha Galali (not a currency design): thick 3D card, iridescent foil strip,
// and a back-light pass that reveals the logo as a watermark.
const TW = 1024, TH = 460;
const CW = 4.9, CH = (CW * TH) / TW;
const ZONE_SHIFT = ((SAFE_L + PANEL_X) / 2 - (CANVAS_L + CANVAS_W / 2)) / 66.9;
const WM_X = (180 / TW - 0.5) * CW; // watermark window centre (card space)

const drawFront = (ctx: CanvasRenderingContext2D, img: Record<string, HTMLImageElement>) => {
  const g = ctx.createLinearGradient(0, 0, TW, TH);
  g.addColorStop(0, '#071a3d'); g.addColorStop(0.5, '#133a75'); g.addColorStop(1, '#061533');
  ctx.fillStyle = g; ctx.fillRect(0, 0, TW, TH);
  // guilloche rosettes + waves
  ctx.lineWidth = 1.4;
  const ros = (cx: number, cy: number, r: number, k: number, amp: number, n: number, a: number) => {
    ctx.strokeStyle = `rgba(233,194,90,${a})`;
    for (let j = 0; j < n; j++) {
      ctx.beginPath();
      for (let i = 0; i <= 720; i++) { const t = (i / 720) * TAU; const rr = r + amp * Math.sin(k * t + (j / n) * (TAU / k)); const x = cx + rr * Math.cos(t), y = cy + rr * Math.sin(t) * 0.82; i ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
      ctx.stroke();
    }
  };
  ros(560, 230, 170, 24, 16, 6, 0.22); ros(560, 230, 120, 18, 12, 5, 0.18); ros(900, 230, 95, 16, 9, 4, 0.25);
  for (let w = 0; w < 9; w++) {
    ctx.strokeStyle = `rgba(233,194,90,${0.08 + (w % 3) * 0.03})`; ctx.beginPath();
    for (let x = 0; x <= TW; x += 4) { const y = 40 + w * 48 + Math.sin(x / 38 + w) * 9; x ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
    ctx.stroke();
  }
  // watermark window
  ctx.fillStyle = 'rgba(255,255,255,0.07)'; ctx.strokeStyle = 'rgba(233,194,90,0.55)'; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.ellipse(180, 230, 118, 158, 0, 0, TAU); ctx.fill(); ctx.stroke();
  // frame
  ctx.strokeStyle = '#e9c25a'; ctx.lineWidth = 7; ctx.strokeRect(14, 14, TW - 28, TH - 28);
  ctx.lineWidth = 2; ctx.strokeRect(28, 28, TW - 56, TH - 56);
  // name + line (browser-shaped Kurdish)
  const gold = ctx.createLinearGradient(0, 120, 0, 240);
  gold.addColorStop(0, '#fff6cf'); gold.addColorStop(0.45, '#f3c94f'); gold.addColorStop(0.7, '#b8860b'); gold.addColorStop(1, '#ffe9a0');
  ctx.direction = 'rtl'; ctx.textAlign = 'center'; ctx.textBaseline = 'alphabetic';
  // the name itself is real 3D gold lettering on top of the card (see Card); only the line is printed
  ctx.font = '900 40px NKufi'; ctx.fillStyle = gold; ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 6; ctx.shadowOffsetY = 2;
  ctx.fillText('بۆ ئاڵوگۆڕی دراو', 530, 330);
  ctx.shadowBlur = 0; ctx.shadowOffsetY = 0;
  ctx.direction = 'ltr'; ctx.font = '900 26px NSans'; ctx.fillStyle = 'rgba(243,201,79,0.9)';
  ctx.textAlign = 'left'; ctx.fillText('AG  000 001', 330, 410); ctx.textAlign = 'right'; ctx.fillText('AG  000 001', 760, 70);
  // logo medallion
  const lg = img['logo_ag.png'];
  if (lg && lg.width) { ctx.save(); ctx.shadowColor = 'rgba(0,0,0,0.7)'; ctx.shadowBlur = 10; ctx.drawImage(lg, 840, 165, 132, 122); ctx.restore(); }
};

const drawBack = (ctx: CanvasRenderingContext2D, img: Record<string, HTMLImageElement>) => {
  const g = ctx.createRadialGradient(TW / 2, TH / 2, 20, TW / 2, TH / 2, TW / 2);
  g.addColorStop(0, '#1d4b92'); g.addColorStop(1, '#081a3c');
  ctx.fillStyle = g; ctx.fillRect(0, 0, TW, TH);
  ctx.strokeStyle = '#e9c25a'; ctx.lineWidth = 7; ctx.strokeRect(14, 14, TW - 28, TH - 28);
  const lg = img['logo_ag.png'];
  if (lg && lg.width) ctx.drawImage(lg, TW / 2 - 130, TH / 2 - 120, 260, 240);
};

const drawWatermark = (ctx: CanvasRenderingContext2D, img: Record<string, HTMLImageElement>) => {
  ctx.fillStyle = '#000'; ctx.fillRect(0, 0, TW, TH);
  const lg = img['logo_ag.png'];
  if (lg && lg.width) { ctx.filter = 'grayscale(1) brightness(1.6) blur(2px)'; ctx.drawImage(lg, 180 - 95, 230 - 88, 190, 176); ctx.filter = 'none'; }
};

const Card: React.FC<{f: number}> = ({f}) => {
  const front = useCanvasTexture(TW, TH, drawFront, ['logo_ag.png']);
  const back = useCanvasTexture(TW, TH, drawBack, ['logo_ag.png']);
  const wm = useCanvasTexture(TW, TH, drawWatermark, ['logo_ag.png']);
  const goldEdge = useMemo(() => new THREE.MeshStandardMaterial({color: '#f0c25a', metalness: 1, roughness: 0.25}), []);
  const glyphs = useGlyphs(nameJson as GlyphJSON, 0.46, 0.05, 0.014);
  const glyphMat = useMemo(() => new THREE.MeshStandardMaterial({color: '#ffd06a', metalness: 1, roughness: 0.18}), []);
  const holo = useMemo(() => {
    const c = document.createElement('canvas'); c.width = 512; c.height = 64;
    const x = c.getContext('2d')!;
    for (let i = 0; i < 512; i++) { x.fillStyle = `hsl(${(i / 512) * 720},90%,${62 + 10 * Math.sin(i / 9)}%)`; x.fillRect(i, 0, 1, 64); }
    const t = new THREE.CanvasTexture(c); t.wrapS = t.wrapT = THREE.RepeatWrapping; t.colorSpace = THREE.SRGBColorSpace; t.repeat.set(0.35, 1); t.rotation = 1.2; return t;
  }, []);
  const glow = useMemo(() => {
    const c = document.createElement('canvas'); c.width = c.height = 256;
    const x = c.getContext('2d')!; const g = x.createRadialGradient(128, 128, 0, 128, 128, 128);
    g.addColorStop(0, 'rgba(255,250,230,1)'); g.addColorStop(0.35, 'rgba(255,230,160,0.6)'); g.addColorStop(1, 'rgba(255,200,90,0)');
    x.fillStyle = g; x.fillRect(0, 0, 256, 256);
    const t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; return t;
  }, []);
  const enter = easeOutBack(range(f, 0, 42), 1.2);
  const beamX = interpolate(f, [58, 112], [-4.2, 4.2], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  // watermark glows while the beam is behind its window
  const wmI = Math.exp(-Math.pow(beamX - WM_X, 2) / 0.9) * 2.2 + range(f, 112, 130) * 0.6;
  const rotY = (1 - enter) * -TAU * 0.85 + 0.22 * Math.cos(f / 28);
  const rotX = 0.1 * Math.sin(f / 33);
  holo.offset.x = f * 0.012 + rotY * 0.6;
  if (!front || !back || !wm) return null;
  return (
    <group position={[ZONE_SHIFT, 0.02, (1 - enter) * -5]} rotation={[rotX, rotY, (1 - enter) * 0.4]}>
      {/* back light (visible around the edges as it passes) */}
      <mesh position={[beamX, 0, -0.35]} rotation={[0, 0, 0.25]}>
        <planeGeometry args={[1.8, 4.2]} />
        <meshBasicMaterial map={glow} toneMapped={false} transparent opacity={f > 56 && f < 114 ? 1 : 0} blending={THREE.AdditiveBlending} depthWrite={false} />
      </mesh>
      <mesh castShadow>
        <boxGeometry args={[CW, CH, 0.035]} />
        <primitive object={goldEdge} attach="material-0" />
        <primitive object={goldEdge} attach="material-1" />
        <primitive object={goldEdge} attach="material-2" />
        <primitive object={goldEdge} attach="material-3" />
        <meshPhysicalMaterial attach="material-4" map={front} roughness={0.5} clearcoat={0.35} clearcoatRoughness={0.3} envMapIntensity={0.35}
          emissive="#fff1c8" emissiveMap={wm} emissiveIntensity={wmI} />
        <meshPhysicalMaterial attach="material-5" map={back} roughness={0.5} clearcoat={0.35} envMapIntensity={0.35} />
      </mesh>
      {/* iridescent security foil */}
      <mesh position={[(805 / TW - 0.5) * CW, 0, 0.02]}>
        <planeGeometry args={[(52 / TW) * CW, CH * 0.9]} />
        <meshStandardMaterial map={holo} metalness={0.55} roughness={0.2} emissive="#ffffff" emissiveMap={holo} emissiveIntensity={0.35} />
      </mesh>
      {/* embossed 3D gold name */}
      <group position={[(530 / TW - 0.5) * CW, 0.2, 0.05]}>
        {glyphs.map((g, i) => <mesh key={i} geometry={g.geom} material={glyphMat} position={[g.cx, g.cy, 0]} castShadow />)}
      </group>
    </group>
  );
};

const Cam: React.FC<{f: number}> = ({f}) => {
  const {camera} = useThree();
  const t = easeInOut(range(f, 0, 150));
  camera.position.set(ZONE_SHIFT + 0.8 - 1.2 * t, 0.6 - 0.8 * t, 9.2);
  camera.lookAt(ZONE_SHIFT, 0, 0);
  return null;
};

export const FX5Holo: React.FC = () => {
  const f = useCurrentFrame();
  // a moving light so the foil changes colour as it sweeps
  const lx = Math.sin(f / 18) * 4;
  return (
    <Stage camera={{fov: 22, position: [0, 0, 9.2]}}>
      <Env intensity={1.15} />
      <Cam f={f} />
      <ambientLight intensity={0.35} />
      <directionalLight position={[-3, 4, 6]} intensity={2} castShadow shadow-mapSize-width={1024} shadow-mapSize-height={1024}
        shadow-camera-left={-5} shadow-camera-right={5} shadow-camera-top={3} shadow-camera-bottom={-3} />
      <pointLight position={[lx + ZONE_SHIFT, 1.5, 3]} intensity={7} distance={8} color="#ffffff" />
      <mesh position={[0, 0, -0.6]} receiveShadow><planeGeometry args={[30, 12]} /><shadowMaterial opacity={0.25} color="#3a2200" /></mesh>
      <Card f={f} />
    </Stage>
  );
};
