#!/bin/bash
# Seedance 2.5 first->last frame morph clips: clip i starts on colour still i and ends on still i+1 (wraps), so the chain loops
cd "$(dirname "$0")/../.."
P=.claude/skills/lovart-api/scripts/agent_skill.py; OUT=led_screen/lovart_pro/morph; L=led_screen/lovart_pro/morphs.txt
mapfile -t ROWS < <(grep -v COLORS_DONE led_screen/lovart_pro/colors.txt)
N=${#ROWS[@]}; ONLY=${ONLY:-all}
up() { timeout 120 python3 $P upload --file "$1" | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])"; }
for i in $(seq 0 $((N-1))); do
  [ "$ONLY" != all ] && [ "$ONLY" != "$i" ] && continue
  a=(${ROWS[$i]}); b=(${ROWS[$(((i+1)%N))]})
  grep -q "^${a[0]}>${b[0]} " $L 2>/dev/null && continue
  u1=$(up ${a[1]}); u2=$(up ${b[1]})
  PR="Create a 5-second seamless cinematic product transition video, 21:9. Image 1 is the exact FIRST frame and image 2 is the exact LAST frame. Seconds 0 to 2.5: the product from image 1 hovers in its spotlight above the marble pedestal and slowly rotates a little in 3D, photorealistic. Seconds 2.5 to 5: in the same position it elegantly transforms into the product of image 2 with a premium liquid-metal and light-particle morph (no cut, no fade to black), while the light colour smoothly shifts from the colour of image 1 to the colour of image 2. The camera and pedestal stay fixed. The video ends exactly on image 2. The right half stays dark and empty. No text, no new objects, no audio."
  r=$(timeout 1800 python3 $P chat --prompt "$PR" --attachments "$u1" "$u2" --prefer-models '{"VIDEO":["generate_video_seedance_v2_5"]}' --json --download --output-dir $OUT 2>&1)
  tid=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();print(json.loads(t[t.index('{'):]).get('thread_id',''))" 2>/dev/null)
  for k in $(seq 1 80); do
    f=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();d=json.loads(t[t.index('{'):]);v=[x['local_path'] for x in d.get('downloaded',[]) if x['local_path'].endswith('.mp4')];print(v[0] if v else '')" 2>/dev/null)
    [ -n "$f" ] && break; sleep 30; r=$(timeout 600 python3 $P result --thread-id "$tid" --json --download --output-dir $OUT 2>&1)
  done
  echo "${a[0]}>${b[0]} ${f:-FAIL:$tid}" >> $L
done
[ "$ONLY" = all ] && echo MORPHS_DONE >> $L
