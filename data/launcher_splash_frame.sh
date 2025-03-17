#!/bin/bash
# Assemble a single frame for launcher image (splash phase).
#
# bash launcher_jump_frame.sh {t_world.png} {t_frog.png} {frame} {output.png}

if [[ $# != 4 ]]; then
   echo "$0 {t_world.png} {t_frog.png} {frame} {output.png}"
   exit 1
fi

WORLD_INPUT=$1
FROG_INPUT=$2
FRAME=$3
OUTPUT=$4

# Leaf placement from launcher_jump_frame.sh
LEAF_CORNER_X=$((25 + 350 - 128))
LEAF_CORNER_Y=$((43 + 155 - 100))

# Set frog placement.
#
# Using the frog splash images.
FROG_CROP_X=$(($FRAME * 128))
FROG_CROP_Y=2048
FROG_CROP="128x100+$FROG_CROP_X+$FROG_CROP_Y"
FROG_DX=-92
FROG_DY=-19
FROG_PLACE="128x100+$(($LEAF_CORNER_X+$FROG_DX))+$(($LEAF_CORNER_Y+$FROG_DY))"

# Set moon placement.
MOON_CROP_X=$(($FRAME * 128))
MOON_CROP_Y=2624
MOON_CROP="64x32+$MOON_CROP_X+$MOON_CROP_Y"
MOON_CORNER_X=$(($LEAF_CORNER_X + 64 - 92 - 32))
MOON_CORNER_Y=$(($LEAF_CORNER_Y + 64 - 19 - 16))
MOON_PLACE="64x32+$MOON_CORNER_X+$MOON_CORNER_Y"

exec convert \
   -size 400x240 "xc:#000000" -colorspace Gray -depth 8 \
   "(" "$WORLD_INPUT" -crop "$MOON_CROP" +repage -geometry "$MOON_PLACE" ")" -composite \
   "(" "$FROG_INPUT" -crop "$FROG_CROP" +repage -geometry "$FROG_PLACE" ")" -composite \
   "$OUTPUT"
