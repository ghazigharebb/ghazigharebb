import {Composition} from 'remotion';
import {AghaGalali} from './AghaGalali';
export const Root = () => (
  <>
    <Composition id="AghaGalali" component={AghaGalali} durationInFrames={450} fps={30} width={936} height={260} />
  </>
);
