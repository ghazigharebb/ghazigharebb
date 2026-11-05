#!/bin/bash
# 46 s loop @60fps: master 1440x400 -> LED 720x200 (60 fps + 30 fps fallback)
set -e; cd "$(dirname "$0")"
node capture.mjs --video
ffmpeg -loglevel error -y -i master_1440x400_60fps.mp4 -vf "scale=720:200:flags=lanczos" -c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p -crf 14 -preset slow -r 60 -movflags +faststart wastaghareb_LED_720x200_60fps.mp4
ffmpeg -loglevel error -y -i master_1440x400_60fps.mp4 -vf "scale=720:200:flags=lanczos" -r 30 -c:v libx264 -profile:v main -level 3.1 -pix_fmt yuv420p -crf 14 -preset slow -movflags +faststart wastaghareb_LED_720x200_30fps.mp4
for f in *.mp4; do ffprobe -v error -show_entries stream=width,height,nb_frames,r_frame_rate -show_entries format=duration,size -of csv=p=0 $f; done
echo FINAL_DONE
