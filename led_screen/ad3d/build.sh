#!/bin/bash
# full pipeline: Blender frames -> content video -> composite with portrait panel -> 4K master + 720x200 LED file
set -e
SP=${SP:-/tmp/wg3d}; cd "$(dirname "$0")"
BL=${BL:-python3}
$BL blender/full3d.py -- "$SP/frames3d" ${RES:-1068 400} ${SPP:-10} all
n=$(ls "$SP"/frames3d/f_*.png | wc -l); echo "blender frames: $n"; [ "$n" = 600 ]
mkdir -p frames && cp "$SP"/frames3d/f_*.png frames/
ffmpeg -loglevel error -y -framerate 30 -i frames/f_%04d.png -c:v libx264 -pix_fmt yuv420p -crf 14 -preset slow -movflags +faststart wastaghareb_3d_blender_content.mp4
node render.mjs --scale 5.3333 --out wastaghareb_3d_4K_3840x1066.mp4 2>&1 | grep -v 404 | tail -1
ffmpeg -loglevel error -y -i wastaghareb_3d_4K_3840x1066.mp4 -vf "scale=720:200:flags=lanczos" -c:v libx264 -profile:v main -level 3.1 -pix_fmt yuv420p -preset slow -crf 14 -r 30 -movflags +faststart wastaghareb_3d_LED_720x200.mp4
for f in wastaghareb_3d_*.mp4; do ffprobe -v error -show_entries stream=width,height,nb_frames -show_entries format=duration,size -of csv=p=0 $f; done
echo BUILD3D_DONE
