#!/bin/bash
# Lovart (Nano Banana Pro) re-light of each gold still into its own premium accent colour; product/composition unchanged
cd "$(dirname "$0")/../.."
P=.claude/skills/lovart-api/scripts/agent_skill.py; OUT=led_screen/lovart_pro/color; L=led_screen/lovart_pro/colors.txt
while read name img color; do
  grep -q "^$name " $L 2>/dev/null && continue
  u=$(timeout 120 python3 $P upload --file "$img" | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])")
  PR="Edit this exact image. Keep the product, its exact shape, colors, screen and branding, the marble pedestal, the camera angle and the whole composition IDENTICAL. Only change the lighting color mood: the spotlight beam, the floating dust particles, the haze and the thin metallic rim of the pedestal become ${color}. Keep the background deep black and luxurious, keep the right half empty dark. Rich, powerful, premium, cinematic, not saturated or childish. Photorealistic. NO text, NO logos added."
  r=$(timeout 900 python3 $P chat --prompt "$PR" --attachments "$u" --prefer-models '{"IMAGE":["generate_image_nano_banana_pro"]}' --json --download --output-dir $OUT 2>&1)
  tid=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();print(json.loads(t[t.index('{'):]).get('thread_id',''))" 2>/dev/null)
  for i in $(seq 1 40); do
    f=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();d=json.loads(t[t.index('{'):]);v=[x['local_path'] for x in d.get('downloaded',[])];print(v[0] if v else '')" 2>/dev/null)
    [ -n "$f" ] && break; sleep 20; r=$(timeout 300 python3 $P result --thread-id "$tid" --json --download --output-dir $OUT 2>&1)
  done
  echo "$name ${f:-FAIL:$tid}" >> $L
done <<'LIST'
pb_anker165 led_screen/lovart_pro/raw/lovart_144d5558ac7d.png deep imperial gold (rich amber gold light)
pb_maggo_stand led_screen/lovart_pro/raw/lovart_47232ef3145b.png deep crimson ruby red (dark luxurious red light)
pb_qi2_blue led_screen/lovart_pro/raw/lovart_1cfbf88b2796.png deep royal sapphire blue (dark luxurious blue light)
pb_anker20k led_screen/lovart_pro/raw/lovart_1d0c83457fa1.png deep emerald green (dark luxurious emerald light)
pb_instacord led_screen/lovart_pro/raw/lovart_2197fd852bcc.png deep royal amethyst purple (dark luxurious violet light)
adapter led_screen/lovart_pro/raw/lovart_f5a62b650362.png cool platinum silver-white (icy premium metallic light)
cable_coil led_screen/lovart_pro/raw/lovart_c176716b3a17.png warm copper bronze (rich burnished copper light)
magsafe led_screen/lovart_pro/raw/lovart_df4789ac6102.png deep burgundy wine red (dark luxurious wine light)
hours led_screen/lovart_pro/raw/hours_f533b978aeb3.png warm gold against a deep midnight-blue night (luxurious gold and midnight light)
LIST
echo COLORS_DONE >> $L
