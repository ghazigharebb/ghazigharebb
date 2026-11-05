# آغا گەڵاڵی — LED motion loop (936×260)

- `agha_galali_LED_936x260.mp4` — H.264, 936×260, 30 fps, 15 s, 450 frames, silent, seamless loop.
- Source: Remotion composition `AghaGalali` (`src/AghaGalali.tsx`), logo in `src/LogoAG.tsx`.

Timeline: 0–4 s name reveal · 4–9.5 s currency coins + exchange swaps · 9.5–12.5 s FIB card · 12.5–15 s exchange-board reels → gold glare back to frame 0.

Note: `LogoAG.tsx` is a vector re-drawing traced from an LED photo, not the original logo file.
Render: put `src/*` in a Remotion project's `src/` (plus `index.ts`), `public/*` in `public/`, then
`npx remotion render src/index.ts AghaGalali out.mp4 --muted --crf=12`.
