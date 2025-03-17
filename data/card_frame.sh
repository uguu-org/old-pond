#!/bin/bash
# Assemble a single frame for card image.
#
# bash card_frame.sh {t_world.png} {t_frog.png} {frame} {output.png}
#
# We could have inlined this inside the Makefile, but it's more readable to
# write it as a script.

if [[ $# != 4 ]]; then
   echo "$0 {t_world.png} {t_frog.png} {frame} {output.png}"
   exit 1
fi

WORLD_INPUT=$1
FROG_INPUT=$2
FRAME=$3
OUTPUT=$4

# Set leaf placement.
LEAF_CROP_X=$(($FRAME * 128))
LEAF_CROP_Y=1408
LEAF_CROP="128x100+$LEAF_CROP_X+$LEAF_CROP_Y"
LEAF_CORNER_X=$((350 - 128))
LEAF_CORNER_Y=$((155 - 100))
LEAF_PLACE="128x100+$LEAF_CORNER_X+$LEAF_CORNER_Y"

# Set frog placement.
#
# Note that the input crop region for the frog is adjusted to compensate
# for the vertical leaf offsets: 1, 2, 3, 4, 3, 2, 1, 0
#
# We are using sprite #13, which has a jump vector of (-92,-19).
FROG_DY=$(perl -e "print 4 - abs((($FRAME + 1) & 7) - 4)")
FROG_CROP_X=0
FROG_CROP_Y=$((1792-$FROG_DY))
FROG_CROP="128x100+$FROG_CROP_X+$FROG_CROP_Y"
FROG_PLACE="$LEAF_PLACE"

# Set moon placement.
MOON_CROP_X=$(($FRAME*128))
MOON_CROP_Y=2560
MOON_CROP="64x32+$MOON_CROP_X+$MOON_CROP_Y"
MOON_CORNER_X=$(($LEAF_CORNER_X + 64 - 92 - 32))
MOON_CORNER_Y=$(($LEAF_CORNER_Y + 64 - 19 - 16))
MOON_PLACE="64x32+$MOON_CORNER_X+$MOON_CORNER_Y"

# Set title text placement.
TITLE_CROP_X=256
TITLE_CROP_Y=0
TITLE_CROP="160x90+$TITLE_CROP_X+$TITLE_CROP_Y"
TITLE_PLACE="160x90+4+4"

exec convert \
   -size 350x155 "xc:#000000" -colorspace Gray -depth 8 \
   "(" "$WORLD_INPUT" -crop "$MOON_CROP" +repage -geometry "$MOON_PLACE" ")" -composite \
   "(" "$WORLD_INPUT" -crop "$LEAF_CROP" +repage -geometry "$LEAF_PLACE" ")" -composite \
   "(" "$FROG_INPUT" -crop "$FROG_CROP" +repage -geometry "$FROG_PLACE" ")" -composite \
   "(" "$WORLD_INPUT" -crop "$TITLE_CROP" +repage -geometry "$TITLE_PLACE" ")" -composite \
   "$OUTPUT"
