# Build images, sounds and other supporting data.  Takes ~2 minutes to build
# and costs ~30M of disk space.
#
# Requires gcc, perl, netpbm, ImageMagick, Inkscape, and ffmpeg.
# gcc also needs libpng, and perl needs libxml.
#
# See svg_to_png.sh for more details on Inkscape.

targets = \
	frog-table-128-96.png \
	world1-table-128-128.png \
	world2-table-64-64.png \
	world3-table-64-32.png \
	title.png \
	info.png \
	crickets.wav \
	croak.wav \
	splash.wav \
	data.lua \
	icon.png \
	icon-highlighted.png \
	card0.png \
	card1.png \
	card2.png \
	card3.png \
	card4.png \
	card5.png \
	card6.png \
	card7.png \
	launcher0.png \
	launcher1.png \
	launcher2.png \
	launcher3.png \
	launcher4.png \
	launcher5.png \
	launcher6.png \
	launcher7.png \
	launcher8.png \
	launcher9.png \
	launcher10.png \
	launcher11.png \
	launcher12.png \
	launcher13.png \
	launcher14.png \
	launcher15.png \
	launcher16.png \
	launcher17.png \
	launcher18.png \
	launcher19.png \
	launcher20.png \
	launcher21.png \
	launcher22.png \
	launcher23.png \
	launcher24.png \
	itch_cover.png

# Common compiler flags for C/C++ tools.
#
# "-march=native -O3" produces the fastest executables, although these flags
# are here mostly for readability.  For any particular executable, most of
# the time will be spent inside the pre-compiled libpng, and the overall
# build time will be dominated by Inkscape.
cflags = -march=native -O3 -Wall -Wextra -pedantic


# ......................................................................
# {{{ Primary build artifacts.

all: $(targets)

frog-table-128-96.png: t_frog.png crop_table.exe optimize_png.pl
	./crop_table.exe 128 128 128 96 0 0 < $< | perl optimize_png.pl > $@

world1-table-128-128.png: t_world.png t_world_trees.png optimize_png.pl
	convert t_world_trees.png "(" $< -crop "1024x1024+0+1280" +repage ")" -append png:- | perl optimize_png.pl > $@

world2-table-64-64.png: t_world.png crop_table.exe optimize_png.pl
	convert $< -crop "1024x256+0+2304" png:- | ./crop_table.exe 128 128 64 64 0 0 | perl optimize_png.pl > $@

world3-table-64-32.png: t_world.png crop_table.exe optimize_png.pl
	convert $< -crop "1024x256+0+2560" png:- | ./crop_table.exe 128 64 64 32 0 0 | perl optimize_png.pl > $@

title.png: t_world.png optimize_png.pl
	convert $< -crop "208x112+0+0" png:- | perl optimize_png.pl > $@

info.png: t_world.png optimize_png.pl
	convert $< -crop "156x9+0+128" png:- | perl optimize_png.pl > $@

itch_cover.png: t_itch_cover.png optimize_png.pl
	perl optimize_png.pl $< > $@

# Reduce the file size for background cricket sounds.  We can afford the
# quality loss here since it's mostly ambient noise anyways.
#
# We can also make it mono, and 90% of the players wouldn't notice because
# they are not playing with headphones (according to 2024 Playdate census).
# I am keeping the stereo sound because I am in the 10%.
crickets.wav: sounds/crickets.wav
	ffmpeg -loglevel fatal -i $< -ar 22050 -acodec adpcm_ima_wav -y $@

croak.wav: sounds/croak.wav
	cp $< $@

splash.wav: sounds/splash.wav
	cp $< $@

data.lua: t_rates.lua t_offsets.lua
	cat $^ > $@

# }}}

# ......................................................................
# {{{ Launcher images.

icon.png: t_icon.png optimize_png.pl
	perl optimize_png.pl $< > $@

icon-highlighted.png: t_icon_highlighted.png optimize_png.pl
	perl optimize_png.pl $< > $@

card0.png: t_card0.png optimize_png.pl
	perl optimize_png.pl $< > $@

card1.png: t_card1.png optimize_png.pl
	perl optimize_png.pl $< > $@

card2.png: t_card2.png optimize_png.pl
	perl optimize_png.pl $< > $@

card3.png: t_card3.png optimize_png.pl
	perl optimize_png.pl $< > $@

card4.png: t_card4.png optimize_png.pl
	perl optimize_png.pl $< > $@

card5.png: t_card5.png optimize_png.pl
	perl optimize_png.pl $< > $@

card6.png: t_card6.png optimize_png.pl
	perl optimize_png.pl $< > $@

card7.png: t_card7.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher0.png: t_launcher0.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher1.png: t_launcher1.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher2.png: t_launcher2.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher3.png: t_launcher3.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher4.png: t_launcher4.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher5.png: t_launcher5.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher6.png: t_launcher6.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher7.png: t_launcher7.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher8.png: t_launcher8.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher9.png: t_launcher9.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher10.png: t_launcher10.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher11.png: t_launcher11.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher12.png: t_launcher12.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher13.png: t_launcher13.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher14.png: t_launcher14.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher15.png: t_launcher15.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher16.png: t_launcher16.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher17.png: t_launcher17.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher18.png: t_launcher18.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher19.png: t_launcher19.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher20.png: t_launcher20.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher21.png: t_launcher21.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher22.png: t_launcher22.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher23.png: t_launcher23.png optimize_png.pl
	perl optimize_png.pl $< > $@

launcher24.png: t_launcher24.png optimize_png.pl
	perl optimize_png.pl $< > $@

t_icon.png: t_color_world.png fs_dither.exe
	convert $< -crop "64x64+768+2432" +repage -resize '50%' png:- | ./fs_dither.exe - $@

t_icon_highlighted.png: t_color_world.png fs_dither.exe
	convert $< -crop "64x64+896+2432" +repage -resize '50%' png:- | ./fs_dither.exe - $@

t_card0.png: card_frame.sh t_world.png t_frog.png
	bash $^ 0 $@

t_card1.png: card_frame.sh t_world.png t_frog.png
	bash $^ 1 $@

t_card2.png: card_frame.sh t_world.png t_frog.png
	bash $^ 2 $@

t_card3.png: card_frame.sh t_world.png t_frog.png
	bash $^ 3 $@

t_card4.png: card_frame.sh t_world.png t_frog.png
	bash $^ 4 $@

t_card5.png: card_frame.sh t_world.png t_frog.png
	bash $^ 5 $@

t_card6.png: card_frame.sh t_world.png t_frog.png
	bash $^ 6 $@

t_card7.png: card_frame.sh t_world.png t_frog.png
	bash $^ 7 $@

t_launcher0.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 0 $@

t_launcher1.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 1 $@

t_launcher2.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 2 $@

t_launcher3.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 3 $@

t_launcher4.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 4 $@

t_launcher5.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 5 $@

t_launcher6.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 6 $@

t_launcher7.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 7 $@

t_launcher8.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 8 $@

t_launcher9.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 9 $@

t_launcher10.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 10 $@

t_launcher11.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 11 $@

t_launcher12.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 12 $@

t_launcher13.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 13 $@

t_launcher14.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 14 $@

t_launcher15.png: launcher_jump_frame.sh t_world.png t_frog.png
	bash $^ 15 $@

t_launcher16.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 0 $@

t_launcher17.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 1 $@

t_launcher18.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 2 $@

t_launcher19.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 3 $@

t_launcher20.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 4 $@

t_launcher21.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 5 $@

t_launcher22.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 6 $@

t_launcher23.png: launcher_splash_frame.sh t_world.png t_frog.png
	bash $^ 7 $@

t_launcher24.png: t_world.png
	convert -size "400x240" "xc:#000000" -colorspace Gray -depth 8 "(" $< -crop "64x32+0+2560" +repage -geometry "64x32+187+127" ")" -composite $@

# }}}

# ......................................................................
# {{{ Intermediate files.

# These are written to the current directory like everything else, but
# they mostly follow the naming convention of having a "t_" prefix, so
# it's easy to tell which files are transient.

t_rates.lua: generate_rate_table.pl
	perl $< > $@

t_offsets.lua: generate_offset_table.pl
	perl $< > $@

t_frog.png: t_color_frog.png fs_dither.exe
	./fs_dither.exe $< $@

t_color_frog.png: t_frog.svg svg_to_png.sh
	./svg_to_png.sh $< $@

t_frog.svg: frog.svg select_layers.pl remove_unused_defs.pl
	perl select_layers.pl '^frog.*' t_frog.png $< | perl remove_unused_defs.pl > $@

t_world.png: t_color_world.png fs_dither.exe
	./fs_dither.exe $< $@

# Bayer is used for the trees because it results in less flicker on the
# device.  Floyd-Steinberg is used for everything else because everything
# else looks better that way.
t_world_trees.png: t_color_world.png dither.exe
	./dither.exe $< - | convert png:- -crop 1024x1024+0+256 $@

t_color_world.png: t_color_world0.png t_color_world1.png t_color_world2.png t_color_world3.png t_color_world4.png t_color_world5.png t_color_world6.png t_color_world7.png
	convert -append $^ $@

t_color_world0.png: t_world0.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 0 1024 384

t_color_world1.png: t_world1.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 256 1024 384

t_color_world2.png: t_world2.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 256 1024 384

t_color_world3.png: t_world3.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 256 1024 384

t_color_world4.png: t_world4.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 256 1024 384

t_color_world5.png: t_world5.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 256 1024 384

t_color_world6.png: t_world6.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 256 1024 384

t_color_world7.png: t_world7.svg svg_to_png.sh
	./svg_to_png.sh $< $@ 0 256 1024 2048

t_world.svg: world.svg select_layers.pl remove_unused_defs.pl
	perl select_layers.pl '^world.*' t_world.png $< | perl remove_unused_defs.pl > $@

t_world0.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 0 $< > $@

t_world1.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 1 $< > $@

t_world2.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 2 $< > $@

t_world3.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 3 $< > $@

t_world4.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 4 $< > $@

t_world5.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 5 $< > $@

t_world6.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 6 $< > $@

t_world7.svg: t_world.svg perturb_leaves.pl
	perl perturb_leaves.pl 7 $< > $@

# Cover image for itch.io is basically the same as the game's title screen,
# except we do the layout manually in Inkscape.  Because the image elements
# are assembled using clones of the original, we need to include all the world
# layers in the input SVG.
t_itch_cover.png: t_itch_cover.svg t_aa_svg_to_png.sh
	bash t_aa_svg_to_png.sh $< $@ 0 2048 630 2548

t_itch_cover.svg: world.svg select_layers.pl remove_unused_defs.pl
	perl select_layers.pl '^(itch cover|world).*' t_itch_cover.png $< | perl remove_unused_defs.pl > $@

# SVG rasterizer script with anti-aliasing enabled (i.e. without the flag
# to disable anti-aliasing).
t_aa_svg_to_png.sh: svg_to_png.sh
	grep -vF "export-png-antialias=0" $< > $@

# }}}

# ......................................................................
# {{{ Tools.

dither.exe: dither.c
	gcc $(cflags) $< -lpng -o $@

fs_dither.exe: fs_dither.c
	gcc $(cflags) $< -lpng -o $@

random_dither.exe: random_dither.c
	gcc $(cflags) $< -lpng -o $@

crop_table.exe: crop_table.c
	gcc $(cflags) $< -lpng -o $@

shrink_tiles.exe: shrink_tiles.c
	gcc $(cflags) $< -lpng -o $@

# }}}

# ......................................................................
# {{{ Tests and maintenance commands.

test: \
	test_passed.brighten \
	test_passed.check_ref \
	test_passed.cleanup_styles \
	test_passed.crop_table \
	test_passed.dither \
	test_passed.element_count \
	test_passed.generate_build_graph \
	test_passed.inline_constants \
	test_passed.no_text_in_frog \
	test_passed.no_text_in_world \
	test_passed.no_text_in_itch_cover \
	test_passed.select_layers \
	test_passed.shrink_tiles \
	test_passed.strip_lua

test_passed.dither: dither.exe test_dither.sh
	./test_dither.sh $< && touch $@

test_passed.remove_unused_defs: remove_unused_defs.pl test_remove_unused_defs.sh
	./test_remove_unused_defs.sh $< && touch $@

test_passed.select_layers: select_layers.pl test_select_layers.sh
	./test_select_layers.sh $< && touch $@

test_passed.generate_build_graph: generate_build_graph.pl test_generate_build_graph.sh
	./test_generate_build_graph.sh $< && touch $@

test_passed.strip_lua: strip_lua.pl test_strip_lua.sh
	./test_strip_lua.sh $< && touch $@

test_passed.check_ref: check_ref.pl test_check_ref.sh
	./test_check_ref.sh $< && touch $@

test_passed.inline_constants: inline_constants.pl test_inline_constants.sh
	./test_inline_constants.sh $< && touch $@

test_passed.element_count: element_count.pl test_element_count.sh
	./test_element_count.sh $< && touch $@

test_passed.cleanup_styles: cleanup_styles.pl test_cleanup_styles.sh
	./test_cleanup_styles.sh $< && touch $@

test_passed.brighten: brighten.pl test_brighten.sh
	./test_brighten.sh $< && touch $@

test_passed.crop_table: crop_table.exe test_crop_table.sh
	./test_crop_table.sh $< && touch $@

test_passed.shrink_tiles: shrink_tiles.exe test_shrink_tiles.sh
	./test_shrink_tiles.sh $< && touch $@

test_passed.no_text_in_frog: t_frog.svg element_count.pl
	! ( perl element_count.pl $< | grep '^text' ) && touch $@

test_passed.no_text_in_world: t_world.svg element_count.pl
	! ( perl element_count.pl $< | grep '^text' ) && touch $@

test_passed.no_text_in_itch_cover: t_itch_cover.svg element_count.pl
	! ( perl element_count.pl $< | grep '^text' ) && touch $@

# Test frog images.
debug_frog0: t_frog.png
	convert $< -background blue -crop "128x2048+0+0" -extent "1024x2048" "(" +clone -crop "128x256+0+256" +repage -geometry "128x256+128+0" ")" -composite "(" +clone -crop "128x256+0+512" +repage -geometry "128x256+256+0" ")" -composite "(" +clone -crop "128x256+0+768" +repage -geometry "128x256+384+0" ")" -composite -crop "512x256+0+0" six:-

debug_frog1: t_frog.png
	convert $< -background blue -crop "128x2048+0+0" -extent "1024x2048" "(" +clone -crop "128x256+0+1280" +repage -geometry "128x256+128+1024" ")" -composite "(" +clone -crop "128x256+0+1536" +repage -geometry "128x256+256+1024" ")" -composite "(" +clone -crop "128x256+0+1792" +repage -geometry "128x256+384+1024" ")" -composite -crop "512x256+0+1024" six:-

clean:
	-rm -f $(targets) *.exe *.o test_passed.* t_*

# }}}
