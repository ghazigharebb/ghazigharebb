#!/bin/bash
# BREAKOUT build: Blender 1200 frames @60fps (full 720x200 layout, rendered at 1.5x) -> master + LED file
set -e
SP=${SP:-/tmp/wgbk}; BL=${BL:-python3}; cd "$(dirname "$0")"
$BL blender/breakout.py -- "$SP/bkfr" ${RES:-1080 300} ${SPP:-10} all
n=$(ls "$SP"/bkfr/b_*.png | wc -l); echo "frames: $n"; [ "$n" = 1200 ]
ffmpeg -loglevel error -y -framerate 60 -i "$SP"/bkfr/b_%04d.png -c:v libx264 -pix_fmt yuv420p -crf 14 -preset slow -r 60 -movflags +faststart wastaghareb_breakout_master_1080x300_60fps.mp4
ffmpeg -loglevel error -y -framerate 60 -i "$SP"/bkfr/b_%04d.png -vf "scale=720:200:flags=lanczos" -c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p -crf 14 -preset slow -r 60 -movflags +faststart wastaghareb_breakout_LED_720x200_60fps.mp4
ffmpeg -loglevel error -y -framerate 60 -i "$SP"/bkfr/b_%04d.png -vf "scale=720:200:flags=lanczos" -r 30 -c:v libx264 -profile:v main -level 3.1 -pix_fmt yuv420p -crf 14 -preset slow -movflags +faststart wastaghareb_breakout_LED_720x200_30fps.mp4
for f in wastaghareb_breakout_*.mp4; do ffprobe -v error -show_entries stream=width,height,nb_frames,r_frame_rate -show_entries format=duration,size -of csv=p=0 $f; done
echo BUILDBK_DONE
