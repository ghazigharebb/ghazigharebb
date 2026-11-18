# Shexani — LED still (936×260)

- `shexani_LED_936x260.png` — main: the brand's storefront fascia (Ink ground, white wordmark, yellow X,
  yellow band) with the official Kurdish logo + tagline (vector SVG from the brand package), and a side panel:
  currencies (دۆلار · یۆرۆ · پاوەند · لیرە) and phone ٠٧٥١ ٩٩٩ ٢٠٠٠ (from the brand README).
- `shexani_LED_936x260_10s.mp4` — the same still as a 10 s H.264 clip, for controllers that only take video.
- `alternatives/` — logo-only centred on Ink, and the primary on-yellow version.

All text and the logo sit in x = 122…936: the left ~110 px of the installed sign are not visible.
Source: `src/ShexaniStill.tsx` (Remotion), fonts Noto Kufi Arabic 800 / Noto Sans Arabic 700 per the brand guide.

## v2 — safe on both sides
The installed screen showed the right edge cropped (the "ش" of the wordmark was lost), while the earlier
Agha Galali photo showed the left edge cropped. So the main file now keeps every element inside x = 140…796:
up to 140 px can be lost on either side without losing anything. The background still fills 936×260.
The program on the controller was using a 1920×534 copy of the video — use the 936×260 file directly
(send it as a document, not as a WhatsApp photo/video, which recompresses and resizes).
`calibration_936x260.*` shows a ruler (every 10 px, numbers every 50 px) to measure the exact visible area.

## Master loop — `shexani_LED_936x260_15s.mp4`
936×260, 30 fps, 450 frames, 15 s, H.264 Main, silent, seamless loop. Flip-disc coin wall + the two meeting arrows.
The official logo with the name and tagline is on screen in every frame (big in the centre at the loop point,
docked on the right otherwise). All content sits in x = 140…796.

- 0–1.5 s  logo hero on the coin wall, then docks right
- 1.5–8.2 s  five currencies, each born from the arrows meeting (X): IQD, USD, EUR, GBP, Iranian toman —
  real banknote + Kurdish name + the symbol written in discs on the wall
- 8.2–10.9 s  FIB, Qi Card, NassWallet cards + "ناردن و وەرگرتنی پارە"
- 10.9–12.2 s  $ € £ ₺ on the wall + "و هەموو دراوەکانی تر"
- 12.2–15 s  the whole wall turns Shexani Yellow in one wave, logo returns to the centre on yellow, wave back to Ink

Source: `master/src/Master.tsx` (Remotion, 2D canvas wall + motion-blurred stage), assets in `master/public/`.

## Master v2 — `shexani_LED_936x260_v2_20s.mp4` (replaces the 15 s coin-wall version, kept in `old/`)
936×260, 30 fps, 600 frames, 20 s, H.264 Main, seamless loop. One item at a time, large, 2.5 s each.
Left: Shexani-Yellow panel whose edge is the arrow of the logo, with a deck of real banknotes and service cards;
right: the official logo, fixed in every frame. Items: IQD, USD, EUR, GBP, Iranian toman, then FIB, Qi Card and
NassWallet each on its own. Once per loop the yellow sweeps the whole sign. Source: `master/src/Master2.tsx`.

## Master v3 — `shexani_LED_936x260_v3_20s.mp4` (current)
Same design as v2 with the motion redone and a larger logo (324 px wide, was 268):
items move horizontally only — the outgoing one eases away to the left and fades, the incoming one arrives
from the logo side on a quintic ease-out and stops with zero velocity; no bounce, no float, nothing moves
while an item is held (measured: ~0 pixel change per frame apart from the single sheen pass).
