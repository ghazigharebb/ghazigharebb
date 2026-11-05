#!/bin/bash
# photoreal 3D build: Blender scenes 1-4 -> composite (wipes + portrait panel) -> 4K master + 720x200 LED
set -e
SP=${SP:-/tmp/wgpro}; BL=${BL:-python3}; cd "$(dirname "$0")"
for s in 1 2 3 4; do $BL blender/pro3d.py -- $s "$SP/profr" ${RES:-1068 400} ${SPP:-12} all; done
n=$(ls "$SP"/profr/s*_*.png | wc -l); echo "blender frames: $n"; [ "$n" = 672 ]
mkdir -p frames && cp "$SP"/profr/s*_*.png frames/
node render.mjs --scale 5.3333 --out wastaghareb_pro3d_4K_3840x1066.mp4 2>&1 | grep -v 404 | tail -1
ffmpeg -loglevel error -y -i wastaghareb_pro3d_4K_3840x1066.mp4 -vf "scale=720:200:flags=lanczos" -c:v libx264 -profile:v main -level 3.1 -pix_fmt yuv420p -preset slow -crf 14 -r 30 -movflags +faststart wastaghareb_pro3d_LED_720x200.mp4
for f in wastaghareb_pro3d_*.mp4; do ffprobe -v error -show_entries stream=width,height,nb_frames -show_entries format=duration,size -of csv=p=0 $f; done
echo BUILDPRO_DONE
