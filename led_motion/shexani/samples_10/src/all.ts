import React from 'react';
import {S01Window} from './S01Window';
import {S02Doors} from './S02Doors';
import {S03Float} from './S03Float';
import {S04FlipWall} from './S04FlipWall';
import {S05Arrows} from './S05Arrows';
import {S06Cradle} from './S06Cradle';
import {S07UV} from './S07UV';
import {S08OneLine} from './S08OneLine';
import {S09Press} from './S09Press';
import {S10Time} from './S10Time';
export const SHX: [string, React.FC][] = [
  ['S01', S01Window], ['S02', S02Doors], ['S03', S03Float], ['S04', S04FlipWall], ['S05', S05Arrows],
  ['S06', S06Cradle], ['S07', S07UV], ['S08', S08OneLine], ['S09', S09Press], ['S10', S10Time],
];
