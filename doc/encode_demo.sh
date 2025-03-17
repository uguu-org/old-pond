#!/bin/bash

exec ffmpeg \
   -i captures/playdate-20250317-113427.gif \
   -vf 'scale=w=800:h=480:sws_flags=neighbor' \
   -preset veryslow \
   -y demo.mp4
