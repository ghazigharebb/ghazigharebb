#!/bin/bash
# finish the production: brand + hours clips, composite every item, then the full ordered loop
cd "$(dirname "$0")"; R=../..; P=$R/.claude/skills/lovart-api/scripts/agent_skill.py; S=${SCRATCH:-/tmp}
H=""; for i in $(seq 1 60); do
  H=$(cd $R && timeout 300 python3 $P result --thread-id 995bf955-5725-4378-903f-f30b0794ef94 --json --download --output-dir led_screen/lovart_pro/raw 2>&1 | python3 -c "import sys,json;t=sys.stdin.read();d=json.loads(t[t.index('{'):]);v=[x['local_path'] for x in d.get('downloaded',[])];print(v[0] if v else '')" 2>/dev/null)
  [ -n "$H" ] && break; sleep 30; done
echo "hours still: $H"
until grep -q VIDEOS_DONE videos.txt 2>/dev/null; do sleep 30; done
sed -i '/VIDEOS_DONE/d' videos.txt
printf "brand led_screen/lovart_pro/raw/lovart_338d3da9e8c7.png\n" > manifest_extra.txt; [ -n "$H" ] && echo "hours $H" >> manifest_extra.txt
(cd $R && MANIFEST=led_screen/lovart_pro/manifest_extra.txt led_screen/lovart_pro/gen_videos.sh)
cat videos.txt
mkdir -p final
for n in brand pb_anker165 pb_maggo_stand pb_qi2_blue pb_anker20k pb_instacord adapter cable_coil magsafe hours; do
  c=$(grep "^$n " videos.txt | tail -1 | awk '{print $2}'); case "$c" in ""|FAIL*) echo "skip $n ($c)"; continue;; esac
  TMPDIR_FRAMES=$S node compose.mjs $n $R/$c final || echo "compose failed $n"
done
ls final/*_LED_720x200_60fps.mp4 > /dev/null 2>&1 || exit 1
: > final/order.txt
for n in brand pb_anker165 pb_maggo_stand pb_qi2_blue pb_anker20k pb_instacord adapter cable_coil magsafe hours; do [ -f final/${n}_1440x400_60fps.mp4 ] && echo "file '${n}_1440x400_60fps.mp4'" >> final/order.txt; done
(cd final && ffmpeg -loglevel error -y -f concat -safe 0 -i order.txt -an -c:v libx264 -pix_fmt yuv420p -crf 14 -preset slow -r 60 -movflags +faststart ALL_wastaghareb_1440x400_60fps.mp4 && \
 ffmpeg -loglevel error -y -i ALL_wastaghareb_1440x400_60fps.mp4 -an -vf scale=720:200:flags=lanczos -c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p -crf 14 -preset slow -r 60 -movflags +faststart ALL_wastaghareb_LED_720x200_60fps.mp4)
ls -la final; echo FINISH_DONE
