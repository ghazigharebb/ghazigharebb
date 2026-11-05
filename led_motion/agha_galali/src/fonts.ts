import {useEffect, useState} from 'react';
import {continueRender, delayRender, staticFile} from 'remotion';
const AR = 'U+0600-06FF,U+0750-077F,U+FB50-FDFF,U+FE70-FEFF,U+200C-200F';
const LAT = 'U+0020-007E,U+00A0-00FF,U+2000-206F';
const faces: [string, string, string, string?][] = [
  ['NKufi', 'fonts/nkufi-900.woff2', '900', AR],
  ['NKufi', 'fonts/nkufi-900-latin.woff2', '900', LAT],
  ['Reem', 'fonts/reem-700.woff2', '700', AR],
  ['Vazir', 'fonts/vazir-900.woff2', '900', AR],
  ['NSans', 'fonts/kurdish-900-arabic.woff2', '900', AR],
  ['NSans', 'fonts/kurdish-900-latin.woff2', '900', LAT],
];
let loaded: Promise<void> | null = null;
export const useFonts = () => {
  const [h] = useState(() => delayRender('fonts'));
  useEffect(() => {
    loaded = loaded ?? Promise.all(faces.map(([n, u, w, r]) => new FontFace(n, `url(${staticFile(u)})`, {weight: w, unicodeRange: r}).load()))
      .then((l) => { l.forEach((f) => document.fonts.add(f)); });
    loaded.then(() => continueRender(h)).catch((e) => { console.error(e); continueRender(h); });
  }, [h]);
};
