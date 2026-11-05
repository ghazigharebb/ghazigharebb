# آغا گەڵاڵی — LED motion loop (936×260)

- `agha_galali_LED_936x260.mp4` — H.264, 936×260, 30 fps, 15 s, 450 frames, silent, seamless loop.
- Source: Remotion composition `AghaGalali` (`src/AghaGalali.tsx`), logo in `src/LogoAG.tsx`.

Timeline: 0–4 s name reveal · 4–9.5 s currency coins + exchange swaps · 9.5–12.5 s FIB card · 12.5–15 s exchange-board reels → gold glare back to frame 0.

Note: `LogoAG.tsx` is a vector re-drawing traced from an LED photo, not the original logo file.
Render: put `src/*` in a Remotion project's `src/` (plus `index.ts`), `public/*` in `public/`, then
`npx remotion render src/index.ts AghaGalali out.mp4 --muted --crf=12`.

## v3 (real banknotes incl. 25,000 IQD, safe area)
- `agha_galali_LED_936x260_v3.mp4` — still 936×260. On the installed sign the left ~110 px are not visible
  (measured from a photo), so all text/notes sit in x = 122…680; the gold background still fills the full frame.
- Real banknote images (official specimens / public-domain scans from Wikimedia Commons) in `public/notes/`.
  USD 100 (public domain, BEP), EUR 100 Europa specimen (ECB), GBP 50 Series G specimen (Bank of England).
  IQD 25,000 (2003 series) from en.wikipedia "Dinar-25000.jpg" (small scan, upscaled 2x).
- `calibration_936x260.mp4/.png` — ruler chart (marks every 10 px, numbers every 50 px) to see exactly where the screen cuts.
