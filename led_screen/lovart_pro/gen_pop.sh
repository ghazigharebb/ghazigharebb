#!/bin/bash
# Seedance 2.5 first->last frame morph clips: clip i starts on colour still i and ends on still i+1 (wraps), so the chain loops
cd "$(dirname "$0")/../.."
P=.claude/skills/lovart-api/scripts/agent_skill.py; OUT=led_screen/lovart_pro/pop; L=led_screen/lovart_pro/pops.txt
mapfile -t ROWS < <(grep -v COLORS_DONE led_screen/lovart_pro/colors.txt)
N=${#ROWS[@]}; ONLY=${ONLY:-all}
up() { timeout 120 python3 $P upload --file "$1" | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])"; }
for i in $(seq 0 $((N-1))); do
  [ "$ONLY" != all ] && [ "$ONLY" != "$i" ] && continue
  a=(${ROWS[$i]}); b=(${ROWS[$(((i+1)%N))]})
  grep -q "^${a[0]}>${b[0]} " $L 2>/dev/null && continue
  u1=$(up ${a[1]}); u2=$(up ${b[1]})
  PR="Create a 5-second cinematic 3D product commercial shot, 21:9, photorealistic, smooth continuous motion at constant speed with no pauses. Image 1 is the exact FIRST frame and image 2 is the exact LAST frame. 0.0-2.0 s: the product from image 1 lifts off the marble pedestal, rotates in 3D (about 40 degrees, showing its sides and depth) and flies straight TOWARD THE CAMERA, growing large as if coming out of the screen, staying fully in sharp focus. 2.0-3.0 s: it smoothly flies back and settles in its original place above the pedestal. 3.0-5.0 s: in that same place it elegantly transforms into the product of image 2 with a premium liquid-metal and light-particle morph (no cut, no fade to black) while the light colour shifts from the colour of image 1 to the colour of image 2. The pedestal stays fixed. End exactly on image 2. The right half stays dark and empty. No text, no new objects, no audio."
  r=$(timeout 1800 python3 $P chat --prompt "$PR" --attachments "$u1" "$u2" --prefer-models '{"VIDEO":["generate_video_seedance_v2_5"]}' --json --download --output-dir $OUT 2>&1)
  tid=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();print(json.loads(t[t.index('{'):]).get('thread_id',''))" 2>/dev/null)
  for k in $(seq 1 80); do
    f=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();d=json.loads(t[t.index('{'):]);v=[x['local_path'] for x in d.get('downloaded',[]) if x['local_path'].endswith('.mp4')];print(v[0] if v else '')" 2>/dev/null)
    [ -n "$f" ] && break; sleep 30; r=$(timeout 600 python3 $P result --thread-id "$tid" --json --download --output-dir $OUT 2>&1)
  done
  echo "${a[0]}>${b[0]} ${f:-FAIL:$tid}" >> $L
done
[ "$ONLY" = all ] && echo POPS_DONE >> $L
