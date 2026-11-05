import {Composition} from 'remotion';
import {AghaGalali} from './AghaGalali';
import {FontTest} from './FontTest';
export const Root = () => (
  <>
    <Composition id="AghaGalali" component={AghaGalali} durationInFrames={450} fps={30} width={936} height={260} />
    <Composition id="FontTest" component={FontTest} durationInFrames={1} fps={30} width={936} height={520} />
  </>
);
