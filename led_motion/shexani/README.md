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
