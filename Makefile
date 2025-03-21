# Toplevel Makefile for Old pond project.
#
# For debug builds:
#
#   make
#
# For release builds:
#
#   make release
#
# Only `pdc` from Playdate SDK is needed for these, plus a few standard
# command line tools.
#
# To refresh game data and build, do one of the following:
#
#   make -j refresh_data && make
#   make -j refresh_data && make release
#
# Refreshing game data requires a few more tools and libraries, see
# data/Makefile for more information.  At a minimum, you will likely need
# to edit data/svg_to_png.sh to set the correct path to Inkscape.

package_name=old_pond
data_dir=data
source_dir=source
release_source_dir=release_source

# Debug build.
$(package_name).pdx/pdxinfo: \
	$(source_dir)/data.lua \
	$(source_dir)/main.lua \
	$(source_dir)/pdxinfo
	pdc $(source_dir) $(package_name).pdx

# Release build.
release: $(package_name).zip

$(package_name).zip:
	-rm -rf $(package_name).pdx $(release_source_dir) $@
	cp -R $(source_dir) $(release_source_dir)
	rm $(release_source_dir)/data.lua
	perl $(data_dir)/inline_data.pl $(source_dir)/data.lua $(source_dir)/main.lua | perl $(data_dir)/inline_constants.pl | perl $(data_dir)/strip_lua.pl > $(release_source_dir)/main.lua
	pdc -s $(release_source_dir) $(package_name).pdx
	zip -9 -r $@ $(package_name).pdx

# Refresh data files in source directory.
refresh_data:
	$(MAKE) -C $(data_dir)
	cp -f $(data_dir)/data.lua $(source_dir)/
	cp -f $(data_dir)/*-table*.png $(source_dir)/images/
	cp -f $(data_dir)/title.png $(source_dir)/images/
	cp -f $(data_dir)/info.png $(source_dir)/images/
	cp -f $(data_dir)/*.wav $(source_dir)/sounds/
	cp -f $(data_dir)/icon.png $(source_dir)/launcher/icon.png
	cp -f $(data_dir)/icon-highlighted.png $(source_dir)/launcher/icon-highlighted/1.png
	cp -f $(data_dir)/card0.png $(source_dir)/launcher/card.png
	cp -f $(data_dir)/card0.png $(source_dir)/launcher/card-highlighted/1.png
	cp -f $(data_dir)/card1.png $(source_dir)/launcher/card-highlighted/2.png
	cp -f $(data_dir)/card2.png $(source_dir)/launcher/card-highlighted/3.png
	cp -f $(data_dir)/card3.png $(source_dir)/launcher/card-highlighted/4.png
	cp -f $(data_dir)/card4.png $(source_dir)/launcher/card-highlighted/5.png
	cp -f $(data_dir)/card5.png $(source_dir)/launcher/card-highlighted/6.png
	cp -f $(data_dir)/card6.png $(source_dir)/launcher/card-highlighted/7.png
	cp -f $(data_dir)/card7.png $(source_dir)/launcher/card-highlighted/8.png
	cp -f $(data_dir)/card8.png $(source_dir)/launcher/card-highlighted/9.png
	cp -f $(data_dir)/card9.png $(source_dir)/launcher/card-highlighted/10.png
	cp -f $(data_dir)/card10.png $(source_dir)/launcher/card-highlighted/11.png
	cp -f $(data_dir)/card11.png $(source_dir)/launcher/card-highlighted/12.png
	cp -f $(data_dir)/card12.png $(source_dir)/launcher/card-highlighted/13.png
	cp -f $(data_dir)/card13.png $(source_dir)/launcher/card-highlighted/14.png
	cp -f $(data_dir)/card14.png $(source_dir)/launcher/card-highlighted/15.png
	cp -f $(data_dir)/card15.png $(source_dir)/launcher/card-highlighted/16.png
	cp -f $(data_dir)/launcher0.png $(source_dir)/launcher/launchImages/1.png
	cp -f $(data_dir)/launcher1.png $(source_dir)/launcher/launchImages/2.png
	cp -f $(data_dir)/launcher2.png $(source_dir)/launcher/launchImages/3.png
	cp -f $(data_dir)/launcher3.png $(source_dir)/launcher/launchImages/4.png
	cp -f $(data_dir)/launcher4.png $(source_dir)/launcher/launchImages/5.png
	cp -f $(data_dir)/launcher5.png $(source_dir)/launcher/launchImages/6.png
	cp -f $(data_dir)/launcher6.png $(source_dir)/launcher/launchImages/7.png
	cp -f $(data_dir)/launcher7.png $(source_dir)/launcher/launchImages/8.png
	cp -f $(data_dir)/launcher8.png $(source_dir)/launcher/launchImages/9.png
	cp -f $(data_dir)/launcher9.png $(source_dir)/launcher/launchImages/10.png
	cp -f $(data_dir)/launcher10.png $(source_dir)/launcher/launchImages/11.png
	cp -f $(data_dir)/launcher11.png $(source_dir)/launcher/launchImages/12.png
	cp -f $(data_dir)/launcher12.png $(source_dir)/launcher/launchImages/13.png
	cp -f $(data_dir)/launcher13.png $(source_dir)/launcher/launchImages/14.png
	cp -f $(data_dir)/launcher14.png $(source_dir)/launcher/launchImages/15.png
	cp -f $(data_dir)/launcher15.png $(source_dir)/launcher/launchImages/16.png
	cp -f $(data_dir)/launcher16.png $(source_dir)/launcher/launchImages/17.png
	cp -f $(data_dir)/launcher17.png $(source_dir)/launcher/launchImages/18.png
	cp -f $(data_dir)/launcher18.png $(source_dir)/launcher/launchImages/19.png
	cp -f $(data_dir)/launcher19.png $(source_dir)/launcher/launchImages/20.png
	cp -f $(data_dir)/launcher20.png $(source_dir)/launcher/launchImages/21.png
	cp -f $(data_dir)/launcher21.png $(source_dir)/launcher/launchImages/22.png
	cp -f $(data_dir)/launcher22.png $(source_dir)/launcher/launchImages/23.png
	cp -f $(data_dir)/launcher23.png $(source_dir)/launcher/launchImages/24.png
	cp -f $(data_dir)/launcher24.png $(source_dir)/launcher/launchImages/25.png
	cp -f $(data_dir)/launcher24.png $(source_dir)/launcher/launchImage.png

clean:
	$(MAKE) -C $(data_dir) clean
	-rm -rf $(package_name).pdx $(package_name).zip $(release_source_dir)
