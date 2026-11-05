import {AbsoluteFill} from 'remotion';
import {useFonts} from './fonts';
export const FontTest = () => {
  useFonts();
  const fams = [['NKufi', 900], ['Reem', 700], ['Vazir', 900], ['NSans', 900]] as const;
  return (<AbsoluteFill style={{background: 'linear-gradient(110deg,#8a5a0b,#e2b13c 45%,#fff1b8 50%,#c9971f 70%,#6e4507)', display: 'grid', gridTemplateColumns: '1fr 1fr', placeItems: 'center'}}>
    {fams.map(([f, w]) => (<div key={f} dir="rtl" style={{fontFamily: f, fontWeight: w, fontSize: 84, color: '#1d1204', lineHeight: 1.3, textAlign: 'center'}}>{'آغا گەڵاڵی'}<div style={{fontSize: 20}}>{f}</div></div>))}
  </AbsoluteFill>);
};
