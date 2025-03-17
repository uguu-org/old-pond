#!/bin/bash
# Assemble a single frame for launcher image (jump phase).
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

# Set leaf placement.
LEAF_CROP_X=$(($FRAME / 2 * 128))
LEAF_CROP_Y=1280
LEAF_CROP="128x100+$LEAF_CROP_X+$LEAF_CROP_Y"
LEAF_CORNER_X=$((25 + 350 - 128))
LEAF_CORNER_Y=$((43 + 155 - 100))
LEAF_PLACE="128x100+$LEAF_CORNER_X+$LEAF_CORNER_Y"

# Set frog placement.
#
# We are using sprite #13, which has a jump vector of (-92,-19).
FROG_CROP_X=$(($FRAME / 2 * 128))
FROG_CROP_Y=1792
FROG_CROP="128x100+$FROG_CROP_X+$FROG_CROP_Y"
FROG_DX=$((-92 * $FRAME / 16))
FROG_DY=$((-19 * $FRAME / 16))
FROG_PLACE="128x100+$(($LEAF_CORNER_X+$FROG_DX))+$(($LEAF_CORNER_Y+$FROG_DY))"

# Set moon placement.
MOON_CROP_X=$((($FRAME % 8) * 128))
MOON_CROP_Y=2560
MOON_CROP="64x32+$MOON_CROP_X+$MOON_CROP_Y"
MOON_CORNER_X=$(($LEAF_CORNER_X + 64 - 92 - 32))
MOON_CORNER_Y=$(($LEAF_CORNER_Y + 64 - 19 - 16))
MOON_PLACE="64x32+$MOON_CORNER_X+$MOON_CORNER_Y"

exec convert \
   -size 400x240 "xc:#000000" -colorspace Gray -depth 8 \
   "(" "$WORLD_INPUT" -crop "$MOON_CROP" +repage -geometry "$MOON_PLACE" ")" -composite \
   "(" "$WORLD_INPUT" -crop "$LEAF_CROP" +repage -geometry "$LEAF_PLACE" ")" -composite \
   "(" "$FROG_INPUT" -crop "$FROG_CROP" +repage -geometry "$FROG_PLACE" ")" -composite \
   "$OUTPUT"
