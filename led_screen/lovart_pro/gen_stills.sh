#!/bin/bash
# Lovart (Nano Banana Pro) luxury scene stills — product kept identical via attachment, no text (text is composited later)
cd "$(dirname "$0")/../.."
P=.claude/skills/lovart-api/scripts/agent_skill.py; OUT=led_screen/lovart_pro/raw; M=led_screen/lovart_pro/manifest.txt
TPL='Ultra-premium luxury product commercial still, 21:9 wide cinematic frame. Use the attached product exactly as it is (same shape, colors, screen and branding, do not redesign it). It floats slightly tilted above a glossy black marble pedestal with a thin gold rim, placed in the LEFT THIRD of the frame. A single warm golden spotlight beam from above, fine floating gold dust particles, deep black background with soft golden haze, subtle reflections on the pedestal. The RIGHT HALF of the frame stays empty dark black (reserved for text). Photorealistic, high-end studio lighting, sharp focus. Absolutely NO text, NO letters, NO logos added anywhere.'
gen() { # name prompt [attachment]
  local A=""; [ -n "$3" ] && A="--attachments $3"
  r=$(timeout 1200 python3 $P chat --prompt "$2" $A --prefer-models '{"IMAGE":["generate_image_nano_banana_pro"]}' --json --download --output-dir $OUT 2>&1)
  f=$(echo "$r" | python3 -c "import sys,json;t=sys.stdin.read();d=json.loads(t[t.index('{'):]);print(d['downloaded'][0]['local_path'] if d.get('downloaded') else 'FAIL:'+str(d.get('final_status'))+str(d.get('failures')))" 2>&1 | tail -1)
  echo "$1 $f" | tee -a $M
}
for n in pb_maggo_stand pb_qi2_blue pb_anker20k pb_instacord adapter cable_coil magsafe; do
  u=$(timeout 120 python3 $P upload --file led_screen/ad/assets/$n.png | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])")
  gen $n "$TPL" "$u"
done
gen brand 'Ultra-premium luxury brand reveal still, 21:9 wide cinematic frame. An empty glossy black marble pedestal with a thin gold rim in the LEFT THIRD, a dramatic warm golden spotlight beam from above, volumetric golden light rays, fine floating gold dust and soft bokeh, deep black background with golden haze. The RIGHT HALF stays empty dark black for text. Photorealistic, high-end studio lighting. Absolutely NO text, NO letters, NO logos.'
gen hours 'Ultra-premium luxury still, 21:9 wide cinematic frame. An elegant black-and-gold luxury wall clock with a white dial and gold hands, floating in the LEFT THIRD above a glossy black marble pedestal with gold rim, warm golden spotlight, soft blurred night city lights bokeh in the deep dark background, fine gold dust. The RIGHT HALF stays empty dark (reserved for text). Photorealistic. NO text, NO letters, NO logos, the clock dial uses only simple tick marks without numbers.'
echo STILLS_DONE >> $M
