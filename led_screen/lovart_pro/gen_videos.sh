#!/bin/bash
# Seedance 2.5 (via Lovart) — one 5 s pop-out clip per still listed in manifest.txt; no audio needed (stripped at compositing)
cd "$(dirname "$0")/../.."
P=.claude/skills/lovart-api/scripts/agent_skill.py; OUT=led_screen/lovart_pro/clips; M=led_screen/lovart_pro/manifest.txt; V=led_screen/lovart_pro/videos.txt
mkdir -p $OUT; M=${MANIFEST:-$M}
PROMPT='Animate this exact image into a 5-second 21:9 cinematic 3D product shot. Keep the object, pedestal, lighting and composition identical, photorealistic. Motion: the object slowly rotates in 3D (about 30 degrees) while rising off the pedestal, then in the last 2 seconds it glides forward TOWARD THE CAMERA and grows larger, as if coming out of the screen, staying fully inside the frame and in sharp focus. The golden spotlight shimmers, gold dust drifts toward the camera. The right half stays dark and empty. No text, no new objects, no cuts, smooth motion, no audio.'
grep -v STILLS_DONE "$M" | while read name img; do
  case "$img" in FAIL*) echo "$name FAIL_STILL" >> $V; continue;; esac
  grep -q "^$name " $V 2>/dev/null && continue
  u=$(timeout 120 python3 $P upload --file "$img" | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])")
  r=$(timeout 3000 python3 $P chat --prompt "$PROMPT" --attachments "$u" --prefer-models '{"VIDEO":["generate_video_seedance_v2_5"]}' --json --download --output-dir $OUT 2>&1)
  tid=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();print(json.loads(t[t.index('{'):]).get('thread_id',''))" 2>/dev/null)
  for i in $(seq 1 60); do
    f=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();d=json.loads(t[t.index('{'):]);v=[x['local_path'] for x in d.get('downloaded',[]) if x['local_path'].endswith('.mp4')];print(v[0] if v else '')" 2>/dev/null)
    [ -n "$f" ] && break; sleep 30
    r=$(timeout 600 python3 $P result --thread-id "$tid" --json --download --output-dir $OUT 2>&1)
  done
  echo "$name ${f:-FAIL:$tid}" >> $V
done
echo VIDEOS_DONE >> $V
