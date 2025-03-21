--[[ Old pond, frog leaps in, water's sound

Short game about taking a frog to the moon.

Based on haiku by Matsuo Bashou and song by Miyazawa Kenji.

For PlayJam 7: https://itch.io/jam/playjam-7

--]]

import "CoreLibs/graphics"
import "CoreLibs/ui"
import "data"

----------------------------------------------------------------------
--{{{ Debug functions.

-- Print a message, and return true.  The returning true part allows this
-- function to be called inside assert(), which means this function will
-- be stripped in the release build by strip_lua.pl.
local function debug_log(msg)
	print(string.format("[%f]: %s", playdate.getElapsedTime(), msg))
	return true
end

-- Log an initial message on startup, and another one later when the
-- initialization is done.  This is for measuring startup time.
local random_seed = playdate.getSecondsSinceEpoch()
local title_version <const> = playdate.metadata.name .. " v" .. playdate.metadata.version
assert(debug_log(title_version .. " (debug build), random seed = " .. random_seed))
math.randomseed(random_seed)

-- Draw frame rate in debug builds.
local function debug_frame_rate()
	playdate.drawFPS(24, 220)
	return true
end

--}}}

----------------------------------------------------------------------
--{{{ Game data.

-- Constants.
local gfx <const> = playdate.graphics
local abs <const> = math.abs
local floor <const> = math.floor
local max <const> = math.max
local min <const> = math.min
local rand <const> = math.random
local sqrt <const> = math.sqrt

-- Song data.  Each "-1" marks the start of a line, all other numbers are
-- musical notes in number of semitones above C3.
--
-- It might be difficult to tell with the distorted frog croaking sounds,
-- but the song is Miyazawa Kenji's "Hoshi Meguri no Uta":
-- https://ja.wikipedia.org/wiki/%E6%98%9F%E3%82%81%E3%81%90%E3%82%8A%E3%81%AE%E6%AD%8C
local song_sequence <const> =
{
	--  a   ka  i   me  da  ma  no  sa  so  ri
	-1, 2,  7,  9,  11, 14, 14, 14, 16, 14, 11,        -- targets 1..10
	--  hi  ro  ge  ta  -   wa  shi no  tsu ba  sa
	-1, 7,  7,  7,  9,  11, 14, 14, 14, 9,  7,  4,     -- targets l1..21
	--  a   wo  i   me  da  ma  no  ko  i   nu
	-1, 2,  7,  9,  11, 14, 14, 14, 16, 14, 11,        -- targets 22..31
	--  hi  ka  ri  no  -   he  bi  no  to  gu  ro
	-1, 7,  7,  7,  9,  11, 14, 14, 14, 9,  7,  4,     -- targets 32..42
	--  o   ri  o   n   wa  ta  ka  ku  u   ta  hi
	-1, 14, 14, 16, 14, 11, 9,  7,  9,  11, 7,  4,     -- targets 43..53
	--  tsu yu  to  shi mo  to  wo  o   to  su
	-1, 2,  2,  2,  4,  7,  9,  14, 11, 9,  7,         -- targets 54..63
}

-- Layout info.
local REAL_MOON_X <const> = 76
local REAL_MOON_Y <const> = 0
local REFLECTED_MOON_X <const> = REAL_MOON_X
local REFLECTED_MOON_Y <const> = 200
local TREE_LAYER1_X <const> = REAL_MOON_X - 96
local TREE_LAYER1_Y <const> = 28
local TREE_LAYER2_X <const> = TREE_LAYER1_X - 42
local TREE_LAYER2_Y <const> = 56
local FLOATING_GRASS_ROWS = 2
local FLOATING_GRASS_LAYER1_X <const> = -20
local FLOATING_GRASS_LAYER1_Y <const> = 200 - FLOATING_GRASS_ROWS * 32
local FLOATING_GRASS_LAYER2_X <const> = -52
local FLOATING_GRASS_LAYER2_Y <const> = 184 - FLOATING_GRASS_ROWS * 32
local TITLE_X <const> = 165
local TITLE_Y <const> = 16
local INFO_TEXT_X <const> = 240
local INFO_TEXT_Y <const> = 227

-- Direction for which the frog should be facing at the start of a game.
local FROG_INITIAL_DIRECTION <const> = 15
assert(FROG_INITIAL_DIRECTION >= 0)
assert(FROG_INITIAL_DIRECTION <= 15)

-- Give up on generating paths without overlaps after this many attempts.
-- See init_targets().
local MAX_REGENERATION_ATTEMPTS <const> = 100

-- Indices into world2-table-64-64.png.
local STAR_VARIATIONS <const> =
{
	{-1, -1, -1, -1, -1, -1, -1, -1},
	{ 1,  1,  1,  2, -1,  1,  1,  2},
	{ 3,  3,  3,  4, -1,  3,  3,  4},
	{ 5,  5,  5,  6, -1,  5,  5,  6},
	{ 7,  7,  7,  8, -1,  7,  7,  8},
	{ 9,  9,  9,  9, 10, 10, 11, 11},
	{12, 12, 12, 12, 13, 13, 14, 14},
}

-- Base sprite index for leaf sprites.
--
-- Leaves come in sets of 8.  The first one is the one used for steady state,
-- remaining 7 are used for fade in and fade out animations.
local LEAF_SPRITE_INDEX_BASE <const> = 65

-- Base sprite index for ripple sprites.  16 total.
--
-- We used to bake the ripples into the leaf sprites, the thought was that
-- different leaves might generate different ripples.  But it didn't look all
-- that great and we ended up using the same set of elliptical ripples for
-- all leaves.  Since all ripples look the same, there was no need to bake
-- them into the sprites, so now we have a separate set of sprites for the
-- ripples.
local RIPPLE_SPRITE_INDEX_BASE <const> = 97

-- Leaf states.
local LEAF_INVISIBLE <const> = 0
local LEAF_FADE_IN <const> = 1
local LEAF_FADE_OUT <const> = 2
local LEAF_FLOATING <const> = 3
local LEAF_GOAL <const> = 4

-- Target data, initialized by init_world.  Each entry is a table with
-- these keys:
--   x, y = target position.
--   d = direction needed to leave current target to reach next target.
--   sprite = LEAF_SPRITE_INDEX_BASE + 8*{0,1,2,3}.
--   frame = leaf animation frame index (0..31).
--   ripple_frame = ripple animation frame index (0..31).
--	  state = one of leaf states above.
--   note = note to be played when frog is leaving this area, in number
--          of semitones.
--   line = song line index.  Targets for the next line will appear upon
--          reaching the end of the current line.
--
-- Instead of storing "note" and "line" alongside each target, we can maintain
-- a single song position index, and derive the relevant note and line values
-- from song_sequence instead.  We used to do that and it's a real mess having
-- to skip over all the entries at the start of each line, so now we just
-- spend a few extra bytes to make targets a flat table with no gaps.
local targets = nil

-- Index into targets table that tracks the frog's current progress.
-- Frog's current position is at targets[target_index], and the next target
-- will be at targets[target_index+1].  Last target will be the position of
-- the moon.
local target_index = 0

-- Global frame counter, used for controlling background animations.
--
-- This is reset whenever the game enters a new game state (whenever
-- game_state is assigned to a different value).
local global_frames = 0

-- Background cricket sounds.
local crickets = table.create(2, 0)
crickets[1] = playdate.sound.sampleplayer.new("sounds/crickets")
assert(crickets[1])
crickets[2] = crickets[1]:copy()
assert(crickets[2])

-- Cricket sound durations in seconds.
--
-- It's really hard to get a gapless and seamless loop playing in the
-- background, regardless of how much I edited the waveform.  So what I
-- have done instead is to have two copies of the same sound playing on two
-- separate alternating channels, and removing the gaps by overlapping the
-- playback a bit with volume envelope to blend the samples.
local CRICKET_DURATION <const> = 30
local OVERLAP_DURATION <const> = 1
assert(CRICKET_DURATION > 0)
assert(CRICKET_DURATION + OVERLAP_DURATION < crickets[1]:getLength())

-- Cricket channels and envelopes.
local cricket_channels = table.create(2, 0)
local cricket_envelopes = table.create(2, 0)
for i = 1, 2 do
	cricket_envelopes[i] = playdate.sound.envelope.new(OVERLAP_DURATION, 0, 0, OVERLAP_DURATION)
	cricket_envelopes[i]:setSustain(1)
	cricket_channels[i] = playdate.sound.channel.new()
	cricket_channels[i]:addSource(crickets[i])
	cricket_channels[i]:setVolumeMod(cricket_envelopes[i])
end

-- Timer for restarting cricket sounds, initialized on first frame.
local cricket_timer = nil

-- Currently playing cricket channel.
local cricket_active_channel = 1;

-- Cricket volume (0..3).
local cricket_volume = 1

-- Cricket volume selected from menu option.  When user requests a volume
-- change, we record the new selection here, and restart all the relevant
-- sounds over the next 2 frames.
local new_cricket_volume = 1

-- Croak/splash sounds.
local croak = playdate.sound.sampleplayer.new("sounds/croak")
local splash = playdate.sound.sampleplayer.new("sounds/splash")
assert(croak)
assert(splash)

-- Channel for croak/splash sounds.  These share the same channel, so that
-- playing a splash sound will cause the croak sound to stop.
local croak_channel = playdate.sound.channel.new()
croak_channel:addSource(croak)
croak_channel:addSource(splash)

-- Tile maps for various world layers, initialized in init_world().
local floating_grass = nil
local trees = nil
local stars = nil

-- Cached trees+floating_grass images.
local grass_and_tree_images = table.create(8, 0)

-- Offset for star tilemaps.  Each tilemap covers 512x512 pixels, and we draw
-- up to 4 copies of it to cover what's visible on screen.  The variables
-- here contain offsets for the tilemap in the upper left corner.  These are
-- usually adjusted in increments of 512, except in game_start() function
-- where we assign odd values to them to prevent discontinuities in scrolling.
local star_offset_x = 0
local star_offset_y = 0

-- Images.
local frog_images <const> = gfx.imagetable.new("images/frog")
local world128_images <const> = gfx.imagetable.new("images/world1")
local world64_images <const> = gfx.imagetable.new("images/world2")
local world32_images <const> = gfx.imagetable.new("images/world3")
local title_image <const> = gfx.image.new("images/title")
local info_image <const> = gfx.image.new("images/info")
assert(frog_images)
assert(world128_images)
assert(world64_images)
assert(world32_images)
assert(title_image)
assert(info_image)

-- Frog coordinates.
local frog_x = 0
local frog_y = 0

-- Frog animation frame (0..15).  0 = standing still, 1..15 = in-flight.
local frog_frame = 0

-- Frog animation speed.  1 = normal (default), 2 = fast.
local frog_frame_steps = 1

-- Frog direction (0..15).  0 = facing up, 4 = facing right.
--
-- Direction is only updated when frog_frame is zero.  This means when a
-- jump has been initiated, the frog is committed to that flight path until
-- it has landed.
local frog_direction = 0

-- Frog direction at last frame.
local frog_last_direction = 0

-- Number of frames for which the frog has remained idle.
local frog_idle_frames = 0

-- Number of idle frames to wait before drawing frog trajectory.  This takes
-- one of two values:
-- 15 = wait half a second before start drawing trajectory.
--      Used for "normal" and "agile" frogs.
-- -32 = make full trajectory visible all the time.
--       Used for "impatient" frogs.
local frog_min_idle_frames = 15

-- Game completion times in number of frames.
local last_completion_time = 0
local best_completion_time = 0

-- Timer for repeating left/right buttons.
local key_repeat_timer = nil

-- Off-screen buffer, used for menu screen and also fade-in transition.
local offscreen_buffer = gfx.image.new(400, 240, gfx.kColorClear)

-- Forward declarations of game states.
local game_title, game_starting, game_loop, game_splash, game_goal
local game_restart_scroll, game_restart_fade_out, game_restart_fade_in

-- Function pointer to current game state.
local game_state

--}}}

----------------------------------------------------------------------
--{{{ Game functions.

-- Get game_state name for debug logging.
local function state_name(state)
	if state == game_title then return "game_title" end
	if state == game_starting then return "game_starting" end
	if state == game_loop then return "game_loop" end
	if state == game_splash then return "game_splash" end
	if state == game_goal then return "game_goal" end
	if state == game_restart_scroll then return "game_restart_scroll" end
	if state == game_restart_fade_out then return "game_restart_fade_out" end
	if state == game_restart_fade_in then return "game_restart_fade_in" end
	return "UNKNOWN"
end

-- State update function.
local function set_next_game_state(state)
	assert(debug_log("@" .. global_frames .. " " .. state_name(game_state) .. " -> " .. state_name(state)))
	game_state = state
	global_frames = 0
end

-- Manage background crickets.
local function background_crickets()
	if not cricket_timer then
		-- Start playing cricket sound.
		cricket_timer = playdate.timer.new(
			(CRICKET_DURATION - OVERLAP_DURATION) * 1000,
			function()
				assert(cricket_active_channel == 1 or cricket_active_channel == 2)
				if cricket_volume == 0 then return end
				cricket_active_channel = 3 - cricket_active_channel
				crickets[cricket_active_channel]:play()
				cricket_envelopes[cricket_active_channel]:trigger(cricket_volume, CRICKET_DURATION)
			end)
		cricket_timer.repeats = true
		crickets[cricket_active_channel]:play()
		cricket_envelopes[cricket_active_channel]:trigger(cricket_volume, CRICKET_DURATION)

	elseif cricket_volume ~= new_cricket_volume then
		-- Restart crickets on volume change.
		cricket_volume = new_cricket_volume

		-- Stop currently playing sounds before progressing further.  This is
		-- mostly no-op because sound is already stopped when user opened the
		-- system menu, and also because we are using envelopes (see below).
		crickets[1]:stop()
		crickets[2]:stop()

		-- Set envelope to make the sound fade out.  We trigger at a low
		-- velocity and fade out after a short duration, because simply
		-- triggering at zero velocity doesn't seem to do anything.
		cricket_envelopes[1]:trigger(0.1, 0.1)
		cricket_envelopes[2]:trigger(0.1, 0.1)

		-- Restart crickets at the next update.
		cricket_timer:remove()
		cricket_timer = nil
	end
end

-- Check if two targets are too close, returns true if so.
--
-- The scenario we want to avoid is having more than one target that is within
-- jumping distance of the current target, since that creates a confusion as
-- to what the correct direction would be.
local function targets_too_close(i, j)
	-- Consecutive targets are always within jumping distance, so this function
	-- should not be used to check those.
	assert(i < j)
	assert(j - i ~= 1)

	assert(targets[i])
	assert(targets[j])

	-- See velocity constants in data/generate_offset_table.pl
	--
	-- Technically the minimum distance we need is 100, but we add a bit more
	-- margin here to avoid placing targets that seem to be almost reachable.
	-- Some trajectory paths might still graze the edges of leaves, but
	-- generally it should be sufficiently obvious where the next targets are.
	local dx <const> = targets[i].x - targets[j].x
	local dy <const> = (targets[i].y - targets[j].y) * 2
	return dx * dx + dy * dy <= 120 * 120
end

-- Check if a range of targets contain overlaps, returns true if so.
local function targets_overlap(a, b)
	assert(a >= 1)
	assert(b <= #targets)
	assert(a + 2 <= b)
	for i = a, b - 2 do
		for j = i + 2, b do
			if targets_too_close(i, j) then
				assert(debug_log(string.format("[%d] at (%d,%d) is too close to [%d] at (%d,%d)", i, targets[i].x, targets[i].y, j, targets[j].x, targets[j].y)))
				return true
			end
		end
	end
end

-- Allocate target table based on song_sequence.
--
-- This produces a flattened "targets" table without gaps.
local function allocate_targets()
	local song_length <const> = #song_sequence
	targets = table.create(song_length + 1, 0)

	-- Populate "note" and "line" data from song_sequence.
	--
	-- Also select random sprite variations.
	local o = 1
	local current_line = 0
	for i = 1, song_length do
		if song_sequence[i] == -1 then
			current_line += 1
		else
			targets[o] =
			{
				sprite = LEAF_SPRITE_INDEX_BASE + rand(0, 3) * 8,
				note = song_sequence[i],
				line = current_line
			}
			o += 1
		end
	end

	-- Add one more entry for the final goal.  Only "line" is needed here.
	-- "note" is not needed since frog never leaves this target, and "sprite"
	-- is not needed because reflected moon will be used.
	targets[o] = { line = current_line }
	assert(#targets == song_length - current_line + 1)
end

-- Initialize target positions.
local function init_targets()
	-- Start with the first target at (0,0) and expand from there.  We will
	-- shift the entire path later so that the goal is aligned at the moon.
	targets[1].x = 0
	targets[1].y = 0

	-- Set the initial direction so that jumping immediately at the start
	-- of the game is always the correct move.
	targets[1].d = FROG_INITIAL_DIRECTION

	-- Index to the first target at the start of the current line.
	--
	-- When regenerating target positions, the first target within a line
	-- always remain unchanged.  This is because their positions were already
	-- determined with the previous line.
	local line_start = 1

	-- Number of regeneration retries.  In the unlikely event where we just
	-- kept getting unlucky over and over, we will simply give up after some
	-- fixed number of attempts and just live with the overlapping paths.
	-- This is not ideal, but better than being stuck in an infinite loop.
	--
	-- In practice, because the directions chosen at each step are half turns,
	-- the probability of getting stuck is very low.
	local regeneration_attempts = 0

	local o = 2
	while o < #targets do
		assert(o > 1)
		local previous_target <const> = targets[o - 1]
		assert(previous_target)

		-- Set position for current target based on previous selected direction.
		targets[o].x = previous_target.x + movement_offsets[previous_target.d + 1][1]
		targets[o].y = previous_target.y + movement_offsets[previous_target.d + 1][2]

		if o + 1 == #targets then
			-- Next target is the moon (goal).  Final direction is always up.
			targets[o].d = 0

		else
			-- Set direction to leave current target.
			--
			-- If consecutive targets share the same note, we want to use the same
			-- direction for leaving those targets.  We do this to make the rhythm
			-- of the frog better match the song.
			--
			-- For example, in the first line:
			--
			--   a -> ka -> i -> me -> DA -> MA -> NO
			--
			-- The frog starts at "a", jumps a random direction to reach "ka",
			-- and jumps at a different direction to reach "i" all the way up to
			-- "DA".  There the frog should be able to make two more consecutive
			-- jumps at the same direction to reach "MA" and "NO".
			if targets[o].note == previous_target.note then
				targets[o].d = previous_target.d
				assert(debug_log(string.format("[%d] at (%d,%d): line=%d, note=%d (same), direction=%d", o, targets[o].x, targets[o].y, targets[o].line, targets[o].note, targets[o].d)))
			else
				if (rand(2) & 1) == 0 then
					targets[o].d = (previous_target.d + rand(1, 5)) & 15
				else
					targets[o].d = (previous_target.d - rand(1, 5)) & 15
				end
				assert(targets[o].d ~= previous_target.d)
				assert(debug_log(string.format("[%d] at (%d,%d): line=%d, note=%d (different), direction=%d", o, targets[o].x, targets[o].y, targets[o].line, targets[o].note, targets[o].d)))
			end
			assert(targets[o].d >= 0)
			assert(targets[o].d <= 15)
		end

		-- Check for overlaps at the end of current line.
		--
		-- Only targets within the current line plus start of next line are
		-- checked.  Targets on different lines can overlap, because they are
		-- not visible on screen at the same time.
		--
		-- The reason why we don't show all targets at once is because we want
		-- the visible targets to match the song lines, although the fact that
		-- it also helps in minimizing amount of work needed to check for
		-- overlaps is rather convenient.
		if o + 1 == #targets or targets[o].line ~= targets[o + 1].line then
			-- Reached end of song or end of current line.  Set the position
			-- for the next target target (either goal or start of next line),
			-- then check the range for overlap.
			targets[o + 1].x = targets[o].x + movement_offsets[targets[o].d + 1][1]
			targets[o + 1].y = targets[o].y + movement_offsets[targets[o].d + 1][2]
			if regeneration_attempts < MAX_REGENERATION_ATTEMPTS and
			   targets_overlap(line_start, o + 1) then
				-- Found an overlap, regenerate the current line again.
				assert(debug_log("Regenerate " .. line_start .. " .. " .. o))
				if line_start == 1 then
					o = 2
				else
					o = line_start
				end
				regeneration_attempts += 1
			else
				-- Found no overlaps, proceed to next line.
				assert(debug_log("Completed " .. line_start .. " .. " .. o))
				o += 1
				line_start = o
			end
		else
			-- Still on the same line.
			o += 1
		end
	end
	assert(debug_log("Regeneration attempts = " .. regeneration_attempts))

	-- Final target position should have already been populated when we
	-- check for overlaps.
	assert(o > 1)
	assert(o == #targets)
	assert(targets[o].x == targets[o - 1].x)
	assert(targets[o].y == targets[o - 1].y + movement_offsets[1][2])

	-- Shift all targets so that we end up at the reflected moon.
	local dx <const> = REFLECTED_MOON_X + 32 - targets[o].x
	local dy <const> = REFLECTED_MOON_Y + 16 - targets[o].y
	for i = 1, #targets do
		targets[i].x += dx
		targets[i].y += dy
	end
end

-- Check if starting position is sufficiently far from goal position, return
-- true if so.
--
-- This is needed due to the scrolling hack we did in game_starting state:
-- If frog's starting position and the moon fits in the same screen, player
-- will likely notice the inconsistent scrolling trick that we have done, so
-- we regenerate the target positions when that happens.
local function start_and_goal_on_separate_screens()
	assert(debug_log(string.format("start=(%d,%d) -> goal=(%d,%d), distance=(%d,%d)", targets[1].x, targets[1].y, targets[#targets].x, targets[#targets].y, abs(targets[1].x - targets[#targets].x), abs(targets[1].y - targets[#targets].y))))
	return abs(targets[1].x - targets[#targets].x) > 400 or
	       abs(targets[1].y - targets[#targets].y) > 240
end

-- Check if the goal position is sufficiently far from all intermediate
-- target positions except the one just before it, return true if so.
--
-- We check for overlap of targets during generation for each wave of targets
-- that would be visible at the same time, but the moon is always visible, so
-- we need to check for overlap against it across all targets.
local function targets_sufficiently_far_from_goal()
	local goal <const> = #targets
	for i = 1, goal - 2 do
		if targets_too_close(i, goal) then
			assert(debug_log(string.format("[%d] at (%d,%d) is too close to [%d] at (%d,%d)", i, targets[i].x, targets[i].y, goal, targets[goal].x, targets[goal].y)))
			return false
		end
	end
	return true
end

-- Initialize world tile maps.
local function init_world()
	-- Allocate tilemaps.
	if not trees then
		trees = table.create(8, 0)
		stars = table.create(8, 0)
		for frame = 1, 8 do
			trees[frame] = table.create(2, 0)
			stars[frame] = table.create(2, 0)
			for layer = 1, 2 do
				trees[frame][layer] = gfx.tilemap.new()
				stars[frame][layer] = gfx.tilemap.new()
			end
		end
		floating_grass = { gfx.tilemap.new(), gfx.tilemap.new() }
	end

	-- Select tree tile base indices (Fisher-Yates shuffle).
	local tree_indices = { 1, 2, 3, 4, 5, 6, 7, 8 }
	for i = 8, 2, -1 do
		local j = rand(1, i)
		tree_indices[i], tree_indices[j] = tree_indices[j], tree_indices[i]
	end

	-- Set tree animation phase.
	local tree_phase = table.create(8, 0)
	for i = 1, 8 do
		tree_phase[i] = rand(0, 7)
	end

	-- Initialize tree tilemaps.
	for frame = 1, 8 do
		for layer = 1, 2 do
			local tile_indices = table.create(4, 0)
			for i = 1, 4 do
				local j <const> = (layer - 1) * 4 + i
				tile_indices[i] = tree_indices[j] + (((tree_phase[j] + frame) & 7) << 3)
			end
			assert(trees[frame])
			assert(trees[frame][layer])
			trees[frame][layer]:setImageTable(world128_images)
			trees[frame][layer]:setTiles(tile_indices, 4)
		end
	end

	-- Initialize floating grass.
	local tree_tile_indices = table.create(8 * FLOATING_GRASS_ROWS, 0)
	for layer = 1, 2 do
		for i = 1, 8 * FLOATING_GRASS_ROWS do
			tree_tile_indices[i] = rand(17, 32)
		end
		assert(floating_grass[layer])
		floating_grass[layer]:setImageTable(world32_images)
		floating_grass[layer]:setTiles(tree_tile_indices, 8)
	end

	-- Initialize stars.
	local variation_index = { table.create(8 * 8, 0), table.create(8 * 8, 0) }
	for i = 1, 8 * 8 do
		variation_index[1][i] = rand(#STAR_VARIATIONS)
		variation_index[2][i] = rand(#STAR_VARIATIONS)
	end
	local star_tile_indices = table.create(8 * 8, 0)
	for frame = 1, 8 do
		for layer = 1, 2 do
			for i = 1, 8 * 8 do
				star_tile_indices[i] = STAR_VARIATIONS[variation_index[layer][i]][rand(8)]
				assert(star_tile_indices[i] == -1 or (star_tile_indices[i] >= 1 and star_tile_indices[i] <= 14))
			end
			assert(stars[frame])
			assert(stars[frame][layer])
			stars[frame][layer]:setImageTable(world64_images)
			stars[frame][layer]:setTiles(star_tile_indices, 8)
		end
	end

	-- Initialize targets.
	--
	-- We will take a few tries at this, after which we will just give up and go
	-- with whatever we have.
	allocate_targets()
	for i = 1, 5 do
		assert(debug_log("Generating path (attempt " .. i .. ")"))
		init_targets()
		if start_and_goal_on_separate_screens() and
		   targets_sufficiently_far_from_goal() then
			assert(debug_log("Completed generation in " .. i .. " attempt(s)"))
			break
		end
	end
end

-- Given a single component of the current draw offset and current star offset,
-- return updated star offset to keep stars within view.
local function update_offset_component(dx, sx)
	local visible_x <const> = -dx
	if visible_x < sx then
		return sx - ((sx - visible_x + 511) & 0xfffffe00)
	end
	if visible_x >= sx + 512 then
		return sx + ((visible_x - sx) & 0xfffffe00)
	end
	return sx
end
assert(update_offset_component(0, 0) == 0)
assert(update_offset_component(-511, 0) == 0)
assert(update_offset_component(-512, 0) == 512)
assert(update_offset_component(-513, 0) == 512)
assert(update_offset_component(-1023, 0) == 512)
assert(update_offset_component(-1024, 0) == 1024)
assert(update_offset_component(1, 0) == -512)
assert(update_offset_component(511, 0) == -512)
assert(update_offset_component(512, 0) == -512)
assert(update_offset_component(513, 0) == -1024)
assert(update_offset_component(1023, 0) == -1024)
assert(update_offset_component(1024, 0) == -1024)
assert(update_offset_component(1025, 0) == -1536)

assert(update_offset_component(-511, 100) == 100)
assert(update_offset_component(-512, 100) == 100)
assert(update_offset_component(-611, 100) == 100)
assert(update_offset_component(-612, 100) == 612)
assert(update_offset_component(0, 100) == -412)
assert(update_offset_component(411, 100) == -412)
assert(update_offset_component(412, 100) == -412)
assert(update_offset_component(413, 100) == -924)

assert(update_offset_component(0, -100) == -100)
assert(update_offset_component(-411, -100) == -100)
assert(update_offset_component(-412, -100) == 412)
assert(update_offset_component(101, -100) == -612)
assert(update_offset_component(611, -100) == -612)
assert(update_offset_component(612, -100) == -612)
assert(update_offset_component(613, -100) == -1124)

-- Log star offset updates.
local function debug_star_offsets(dx, dy)
	local nx <const> = update_offset_component(dx, star_offset_x)
	local ny <const> = update_offset_component(dy, star_offset_y)
	if nx ~= star_offset_x or ny ~= star_offset_y then
		debug_log(string.format("Draw offset = (%d,%d), star offset (%d,%d) -> (%d,%d)", dx, dy, star_offset_x, star_offset_y, nx, ny))
	end
	return true
end

-- Draw background stars.
local function draw_stars()
	-- Adjust star offsets to cover screen area.
	local dx <const>, dy <const> = gfx.getDrawOffset()
	assert(debug_star_offsets(dx, dy))
	star_offset_x = update_offset_component(dx, star_offset_x)
	star_offset_y = update_offset_component(dy, star_offset_y)

	-- Select which frames to display.
	--
	-- We have two layers of stars with 8 frames each, and we increment the
	-- frames for each layer separately, alternating the updates every 4 frames.
	-- This means within a 64 frame loop, we get 16 variations of background
	-- stars updating every 4 frames.
	--
	-- We used to update both layers simultaneously, resulting in the same
	-- 64 frame loop but with only 8 variations.  This seems like a waste
	-- when we have two separate layers, so now we stagger the updates.
	local f1 <const> = ((global_frames >> 3) & 7) + 1
	local f2 <const> = (((global_frames + 4) >> 3) & 7) + 1
	for ox = 0, 512, 512 do
		if star_offset_x + dx + ox >= 400 then
			break
		end
		stars[f1][1]:draw(star_offset_x + ox, star_offset_y)
		stars[f2][2]:draw(star_offset_x + ox - 17, star_offset_y - 17)
		if star_offset_y + dy + 512 < 240 then
			stars[f1][1]:draw(star_offset_x + ox, star_offset_y + 512)
			stars[f2][2]:draw(star_offset_x + ox - 17, star_offset_y + 512 - 17)
		end
	end
end

-- Draw static real moon.
local function draw_real_moon()
	if last_completion_time > 0 then
		world64_images:drawImage(16, REAL_MOON_X, REAL_MOON_Y)
	else
		world64_images:drawImage(15, REAL_MOON_X, REAL_MOON_Y)
	end
end

-- Draw animated reflected moon.
local function draw_reflected_moon()
	local f <const> = ((global_frames >> 2) & 7) + 1
	world32_images:drawImage(f, REFLECTED_MOON_X, REFLECTED_MOON_Y)
end

-- Draw reflected moon perturbed by splash.
local function draw_perturbed_moon()
	local f <const> = ((global_frames >> 2) & 7) + 9
	world32_images:drawImage(f, REFLECTED_MOON_X, REFLECTED_MOON_Y)
end

-- Optionally update cached image for trees and grass.
local function cache_grass_and_trees(f)
	if grass_and_tree_images[f] then return end

	grass_and_tree_images[f] = gfx.image.new(400, REFLECTED_MOON_Y, gfx.kColorClear)
	gfx.pushContext(grass_and_tree_images[f])
		gfx.clear(gfx.kColorClear)

		-- Draw floating grass.
		floating_grass[1]:draw(FLOATING_GRASS_LAYER1_X, FLOATING_GRASS_LAYER1_Y)
		floating_grass[2]:draw(FLOATING_GRASS_LAYER2_X, FLOATING_GRASS_LAYER2_Y)

		-- Draw trees.
		trees[f][1]:draw(TREE_LAYER1_X, TREE_LAYER1_Y)
		trees[f][2]:draw(TREE_LAYER2_X, TREE_LAYER2_Y)
	gfx.popContext()
end

-- Draw title screen background.
local function draw_title_background()
	-- Draw stars and moons.
	draw_stars()
	draw_real_moon()
	draw_reflected_moon()

	-- Draw grass and trees.
	local f <const> = ((global_frames >> 2) & 7) + 1
	cache_grass_and_trees(f)
	grass_and_tree_images[f]:draw(0, 0)
end

-- Leave title screen and enter starting state.
local function transition_to_starting_state()
	-- Initialize frog.
	assert(targets[1])
	frog_x = targets[1].x
	frog_y = targets[1].y
	frog_direction = FROG_INITIAL_DIRECTION
	assert(debug_log(string.format("Frog at (%d,%d), goal at (%d,%d)", frog_x, frog_y, targets[#targets].x, targets[#targets].y)))

	-- Reset targets.
	for i = 1, #targets do
		assert(targets[i])
		targets[i].state = LEAF_INVISIBLE
		targets[i].frame = 0
		targets[i].ripple_frame = 0
	end
	target_index = 1

	-- Transition to starting state.
	set_next_game_state(game_starting)
end

-- Draw rectangles around each target.
local function debug_draw_target_bounding_boxes()
	gfx.setColor(gfx.kColorWhite)
	for i = 1, #targets do
		assert(targets[i])
		if targets[i].state ~= LEAF_INVISIBLE then
			local x <const> = targets[i].x - 35
			local y <const> = targets[i].y - 18
			gfx.drawRect(x, y, 70, 36)
			gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
			gfx.drawText(i, x + 4, y + 4)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			gfx.drawText(i, x + 3, y + 3)
		end
	end
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
	return true
end

-- Compute vertical shift for floating leaves when frog is sitting on top.
local function floating_offset()
	return 4 - abs(((global_frames >> 2) & 7) - 4)
end

-- Update world animation.
local function update_world()
	assert(targets)
	assert(targets[target_index], "target_index = " .. target_index)
	if target_index == 1 or targets[target_index].line > targets[target_index - 1].line then
		-- At the beginning of the game, or arriving at the start of the new
		-- line.  Make all targets for the current line visible, plus first
		-- target of the next line.  We need to make the first target of the
		-- next line visible because we to know the direction for leaving the
		-- last target in the current line.
		--
		-- Note that last target is never touched, because it's the position
		-- of the moon.
		local current_line <const> = targets[target_index].line
		for i = target_index, #targets - 1 do
			if targets[i].state == LEAF_INVISIBLE then
				assert(debug_log(string.format("Show [%d] (line %d) at (%d,%d)", i, targets[i].line, targets[i].x, targets[i].y)))
				targets[i].state = LEAF_FADE_IN
				targets[i].frame = 0
				targets[i].ripple_frame = 0
			end
			if targets[i].line ~= current_line then
				break
			end
		end
	end

	-- Draw and animate ripples.
	for i = 1, #targets do
		assert(targets[i])
		local r <const> = targets[i].ripple_frame
		if r > 0 then
			-- Ripple is currently being animated, although it may not be visible
			-- until it reached frame 2.
			if r > 1 then
				-- Frames 2..31
				local f <const> = (r >> 1) + RIPPLE_SPRITE_INDEX_BASE
				assert(f >= RIPPLE_SPRITE_INDEX_BASE)
				assert(f < RIPPLE_SPRITE_INDEX_BASE + 16)
				world128_images:drawImage(f, targets[i].x - 64, targets[i].y - 64)
			end

			-- Keep animating this ripple until it reaches zero.
			--
			-- Note that ripple animation continues even after frog has already
			-- left the target, and there may be multiple concurrent ripple
			-- animations in progress.  Previously, we have at most one ripple
			-- that is being animated based on which target the frog is currently
			-- sitting on, but that leads to an abrupt cut in animation when
			-- frog jumps from one target to the next.  By keeping track of
			-- ripple states on a per-leaf basis, we are able to animate the
			-- ripples individually.
			targets[i].ripple_frame = (r + 1) & 31

		else
			-- Ripple is currently invisible (frame 0).  If current target matches
			-- frog progress, we will increment the frame counter here so that
			-- ripple animation will start.
			--
			-- We only check for matching indices to decide whether to start
			-- ripple animation or not, even though frog may have already
			-- splashed down.  This means if the user just misses a target, the
			-- intended target will still show ripples.  This is considered a
			-- feature.
			--
			-- Final target (moon) is not eligible for ripples.
			if i == target_index and i < #targets then
				targets[i].ripple_frame = 1
			end
		end
	end

	-- Draw and animate leaves.
	for i = 1, #targets do
		assert(targets[i])
		if targets[i].state == LEAF_FADE_IN then
			-- Apply vertical drift if frog is sitting on current target.  This
			-- happens at the start of the game when all targets of the first
			-- line is being faded in, including the one that the frog is
			-- sitting on.
			--
			-- If we don't apply this drift, player will observe a sudden drop
			-- of a few pixels at the start of the game.
			local f <const> = (15 - targets[i].frame) >> 1
			if i == target_index then
				world128_images:drawImage(targets[i].sprite + f, targets[i].x - 64, targets[i].y - 64 + floating_offset())
			else
				world128_images:drawImage(targets[i].sprite + f, targets[i].x - 64, targets[i].y - 64)
			end
			targets[i].frame += 1
			if targets[i].frame == 16 then
				targets[i].frame = 0
				targets[i].state = LEAF_FLOATING
			end

		elseif targets[i].state == LEAF_FADE_OUT then
			local f <const> = targets[i].frame >> 1
			world128_images:drawImage(targets[i].sprite + f, targets[i].x - 64, targets[i].y - 64)
			targets[i].frame += 1
			if targets[i].frame == 16 then
				targets[i].frame = 0
				targets[i].state = LEAF_INVISIBLE
			end

		elseif targets[i].state == LEAF_FLOATING then
			if i == target_index then
				-- Draw oscillating leaf.
				world128_images:drawImage(targets[i].sprite, targets[i].x - 64, targets[i].y - 64 + floating_offset())
			else
				-- Draw static leaf.
				world128_images:drawImage(targets[i].sprite, targets[i].x - 64, targets[i].y - 64)
			end
		end
	end
	assert(debug_draw_target_bounding_boxes())
end

-- Draw trajectory on where the frog will land.
--
-- It's not so easy to tell which direction the frog is facing due to
-- how the sprites are rendered, and it's especially not easy with the
-- projection effect we have in place, so we have this beginner-friendly
-- feature that draws a dotted line toward the destination spot.
--
-- Experts may save time by not waiting for this dotted line and just go.
local function draw_trajectory()
	local x0 = nil
	local y0 = nil
	gfx.setLineWidth(1)

	-- Draw a dotted line that gets progressively longer depending on
	-- how long we have been idling.  We skip the first few steps so that
	-- the start of the line originates near the frog's head, as opposed to
	-- the frog's origin which is located near its feet.
	for i = 7, min(max(frog_idle_frames - frog_min_idle_frames, 7), 32) do
		-- Compute in-flight position as a parabolic curve.
		local t <const> = i / 32
		assert(t > 0)
		assert(t <= 1)
		local z = t - 0.5
		z = (1 - 4 * (z * z)) * 32
		assert(frog_direction >= 0)
		assert(frog_direction <= 15)
		local m <const> = movement_offsets[frog_direction + 1]
		local x <const> = frog_x + m[1] * t
		local y <const> = frog_y + m[2] * t - z

		-- For the first step, we will skip the drawing part and only record
		-- the position.  Line drawing starts on the second step, and all
		-- subsequent steps reuse the position computed in the previous step.
		if i > 7 then
			if ((frog_idle_frames - i) & 7) <= 3 then
				gfx.setColor(gfx.kColorBlack)
			else
				gfx.setColor(gfx.kColorWhite)
			end
			gfx.drawLine(x0, y0, x, y)
		end
		x0 = x
		y0 = y
	end
end

-- Check where the frog has landed, and update game_state or target_index
-- accordingly.
local function check_landing()
	-- Remove the target that the frog has just jumped away from.
	targets[target_index].state = LEAF_FADE_OUT

	-- Check if frog has landed in a good spot.
	target_index += 1
	local next_target = targets[target_index]
	assert(next_target)
	if frog_x == next_target.x and frog_y == next_target.y then
		-- Successful landing.
		if target_index == #targets then
			-- Game has completed with player reaching the goal.
			last_completion_time = global_frames
			if best_completion_time == 0 then
				best_completion_time = last_completion_time
			else
				best_completion_time = min(best_completion_time, last_completion_time)
			end
			splash:play()
			set_next_game_state(game_goal)
		end
		return
	end

	-- Fell into water without reaching goal.
	last_completion_time = 0
	splash:play()
	set_next_game_state(game_splash)
end

-- Draw idle frog, with oscillating vertical movement to match drifting leaves.
local function draw_frog()
	frog_images:drawImage((frog_direction << 3) + 1, frog_x - 64, frog_y - 64 + floating_offset())
end

-- Handle input and update frog states.
local function update_frog()
	-- Update animation state when frog is currently moving.
	if frog_frame > 0 then
		-- Draw frog sprite with interpolated position.
		--
		-- We only need to linearly interpolate the movement along the plane,
		-- since vertical movement is baked into the sprites.
		--
		-- Frog images are 128x96 with center at (64,64).
		local f <const> = min(frog_frame, 15)
		local t <const> = f / 16
		local m <const> = movement_offsets[frog_direction + 1]
		local x <const> = frog_x + m[1] * t - 64
		local y <const> = frog_y + m[2] * t - 64
		frog_images:drawImage((frog_direction << 3) + (f >> 1) + 1, x, y)

		-- Update frog animation.
		frog_frame += frog_frame_steps
		if frog_frame >= 16 then
			-- Update frog position.
			frog_x += movement_offsets[frog_direction + 1][1]
			frog_y += movement_offsets[frog_direction + 1][2]
			assert(frog_x == floor(frog_x))
			assert(frog_y == floor(frog_y))
			frog_frame = 0

			-- Check where the frog has landed.
			check_landing()
		end
		return
	end

	-- Draw idle frog.
	draw_frog()

	-- Set direction from crank.
	--
	-- Left/right button input is handled via button callbacks.
	if not playdate.isCrankDocked() then
		frog_direction = floor(playdate.getCrankPosition() * 16 / 360 + 0.5) & 15
		assert(frog_direction >= 0)
		assert(frog_direction <= 15)
	end

	-- Check for idleness.  If frog has not changed direction for too long,
	-- we will start drawing its trajectory for where it will land.
	if frog_direction == frog_last_direction then
		frog_idle_frames += 1
		if frog_idle_frames > frog_min_idle_frames then
			draw_trajectory()
		end
	else
		frog_last_direction = frog_direction
		frog_idle_frames = 0
	end

	-- Begin jump on A/B/Up.
	if playdate.buttonJustPressed(playdate.kButtonUp) or
	   playdate.buttonJustPressed(playdate.kButtonA) or
	   playdate.buttonJustPressed(playdate.kButtonB) then
		frog_frame = frog_frame_steps
		frog_idle_frames = 0
		croak:play(1, rate_multiplier[targets[target_index].note])
	end

	-- Debug backdoor: make down button set direction automatically and jump.
	if playdate.buttonJustPressed(playdate.kButtonDown) then
		assert(target_index < #targets)
		local next_target = targets[target_index + 1]
		assert(next_target)
		for i = 1, 16 do
			if frog_x + movement_offsets[i][1] == next_target.x and
			   frog_y + movement_offsets[i][2] == next_target.y then
				frog_direction = i - 1
				break
			end
		end
		frog_frame = frog_frame_steps
		frog_idle_frames = 0
		croak:play(1, rate_multiplier[targets[target_index].note])
	end
end

-- Handle state updates for game_splash and game_goal states.
local function update_splash(moon_function)
	assert(global_frames >= 0)
	assert(global_frames <= 7)

	draw_stars()
	update_world()
	moon_function()

	-- 129..136 are the splash frames.
	frog_images:drawImage(129 + global_frames, frog_x - 64, frog_y - 64)
	if global_frames == 7 then
		-- Use scrolling transition if reflected moon is currently visible
		-- on screen, otherwise use fade transitions.
		local moon_x <const> = REFLECTED_MOON_X + 200 - frog_x
		local moon_y <const> = REFLECTED_MOON_Y + 120 - frog_y
		assert(debug_log(string.format("Moon position on screen: (%d,%d)", moon_x, moon_y)))
		if moon_x >= 0 and moon_x < 400 and
		   moon_y >= 0 and moon_y < 240 then
			set_next_game_state(game_restart_scroll)
		else
			set_next_game_state(game_restart_fade_out)
		end
	end
end

-- Remove key repeat timer.
local function maybe_remove_key_repeat_timer()
	if key_repeat_timer then
		key_repeat_timer:remove()
		key_repeat_timer = nil
	end
end

--}}}

----------------------------------------------------------------------
--{{{ Game states and callbacks.

-- Title screen.
game_title = function()
	if not targets then
		init_world()
		return
	end
	gfx.setDrawOffset(0, 0)

	-- Draw background elements.
	draw_title_background()

	-- Draw title text.
	if global_frames > 60 then
		title_image:draw(TITLE_X, TITLE_Y)
		if global_frames > 90 then
			info_image:draw(INFO_TEXT_X, INFO_TEXT_Y)
		end
	elseif global_frames > 30 then
		local a <const> = (global_frames - 30) / 30
		title_image:drawFaded(TITLE_X, TITLE_Y, a, gfx.image.kDitherTypeBayer8x8)
	end

	-- Start when player has pressed a button.
	--
	-- Left/Right button pressed are handled by callbacks.
	if playdate.buttonJustPressed(playdate.kButtonUp) or
	   playdate.buttonJustPressed(playdate.kButtonDown) or
	   playdate.buttonJustPressed(playdate.kButtonA) or
	   playdate.buttonJustPressed(playdate.kButtonB) then
		transition_to_starting_state()
	end
end

-- Transition toward starting position.
game_starting = function()
	if global_frames < 30 then
		-- Scroll up and fade out title background elements.
		--
		-- Note that the scroll amount is a multiple of 2, which causes the
		-- trees to be aligned to even pixels.  We need this because the trees
		-- use ordered dithering, and when the scrolling operation combined with
		-- the fade out effect (with setDitherPattern below), it produces an
		-- undesirable shimmering effect.  Changing the dither type for the
		-- fade out effect doesn't really help, the only thing that works is
		-- to align pixels, as we have done here.
		--
		-- Alternatively, we can scroll to an odd number of pixels and drop
		-- the lowest bit.  But that causes a stutter effect: if the average
		-- scroll amount is 5 pixels, the screen is jumping by 4 or 6 pixels
		-- every other frame instead of a constant scroll amount on every frame.
		--
		-- Another alternative is to only align the trees, and scroll everything
		-- else without alignment.  This causes the trees to go out of alignment
		-- with the stars by up to 1 pixel.  This honestly isn't so noticeable,
		-- but it seems like a silly complication to have when we can just
		-- scroll by even number of pixels.
		--
		-- We are not so concerned about scroll alignment anywhere else because
		-- in all other instances, everything on screen uses Floyd-Steinberg,
		-- and aren't susceptible to the shimmering effect.
		gfx.setDrawOffset(0, global_frames * -6)
		draw_title_background()
		gfx.setColor(gfx.kColorBlack)
		gfx.setDitherPattern((30 - global_frames) / 30, gfx.image.kDitherTypeBayer8x8)
		gfx.fillRect(0, 0, 400, REFLECTED_MOON_Y)
		return
	end

	-- Keep scrolling up a bit more so that the moon is no longer visible.
	--
	-- After 2 seconds, we would have scrolled 6*60 = 360 pixels, which is
	-- more than the minimum 240 pixels needed.  If we did go with the
	-- minimum, the moon should have been roughly just outside of the
	-- current viewport, even though it most likely isn't.  By scrolling a
	-- bit further, we create a better illusion of being lost somewhere in
	-- the pond.
	--
	-- We could also scroll to the frog's real starting position and do away
	-- with all these scrolling hacks, but usually the starting position is
	-- far away, and we don't want to scroll that much.
	if global_frames < 60 then
		gfx.setDrawOffset(0, global_frames * -6)
		draw_stars()
		draw_reflected_moon()
		return
	end

	-- Skip forward a few frames so that global_frames is in sync with the
	-- vertical drift cycle.  This is so that when we transition to game_loop
	-- state and resets global_frames, we will not experience the sudden
	-- shift in frog's vertical position.
	if global_frames == 60 then
		global_frames = 96
		assert(floating_offset() == 0)
	end

	-- Compute draw offset to center the viewport on the frog, and update
	-- star offsets to compensate for the sudden jump.
	local dx <const>, dy <const> = gfx.getDrawOffset()
	local nx <const> = 200 - frog_x
	local ny <const> = 120 - frog_y
	star_offset_x -= nx - dx
	star_offset_y -= ny - dy
	gfx.setDrawOffset(nx, ny)

	-- Fade in frog.
	draw_stars()
	local a <const> = (global_frames - 96) / 15
	frog_images:getImage((frog_direction << 3) + 1):drawFaded(frog_x - 64, frog_y - 64, a, gfx.image.kDitherTypeBayer8x8)
	if global_frames >= 111 then
		set_next_game_state(game_loop)
	end
end

-- Main game loop.
game_loop = function()
	-- Follow frog.
	local f <const> = min(frog_frame, 15)
	local x <const> = frog_x + (f / 16) * movement_offsets[frog_direction + 1][1]
	local y <const> = frog_y + (f / 16) * movement_offsets[frog_direction + 1][2]
	gfx.setDrawOffset(200 - x, 120 - y)

	draw_stars()
	draw_reflected_moon()
	update_world()
	update_frog()
end

-- Game ended without reaching goal.
game_splash = function()
	update_splash(draw_reflected_moon)
end

-- Reached goal.  This is roughly the same as game_splash.
game_goal = function()
	update_splash(draw_perturbed_moon)
end

-- Make the current objects disappear.
game_restart_fade_out = function()
	draw_stars()
	draw_reflected_moon()
	update_world()

	-- Don't draw the frog here since it's already underwater.

	gfx.setColor(gfx.kColorBlack)
	gfx.setDitherPattern((30 - global_frames) / 30, gfx.image.kDitherTypeBayer8x8)
	gfx.fillRect(frog_x - 300, frog_y - 220, 600, 440)

	if global_frames == 30 then
		set_next_game_state(game_restart_fade_in)

		-- Since screen is completely blank at this point, we can reset the
		-- star offsets without worrying about discontinuities.
		star_offset_x = 0
		star_offset_y = 0
	end
end

-- Transition back to title screen with fade in.
game_restart_fade_in = function()
	gfx.setDrawOffset(0, 0)

	-- Fade in reflected moon and other background elements in two phases.
	gfx.setColor(gfx.kColorBlack)
	if global_frames < 30 then
		-- Fade in real and reflected moons.
		draw_stars()
		draw_real_moon()
		draw_reflected_moon()
		gfx.setDitherPattern(global_frames / 30, gfx.image.kDitherTypeBayer8x8)
		gfx.fillRect(0, 0, 400, 240)

	else
		-- Draw real and reflected moons.
		draw_stars()
		draw_real_moon()
		draw_reflected_moon()

		-- Fade in trees.
		--
		-- This is about the only place where our frame rate drops, and it's
		-- due to using drawFaded on a large bitmap.  Caching the tree images
		-- helped a bit and the frame rate improved to about ~20fps.
		local f <const> = ((global_frames >> 2) & 7) + 1
		cache_grass_and_trees(f)
		local a <const> = (global_frames - 30) / 30
		grass_and_tree_images[f]:drawFaded(0, 0, a, gfx.image.kDitherTypeBayer8x8)

		-- Move to next state.
		if global_frames == 60 then
			set_next_game_state(game_title)
		end
	end

end

-- Transition back to title screen with scroll + fade in.
game_restart_scroll = function()
	draw_stars()
	draw_reflected_moon()

	-- Scroll toward origin.
	local offset_x <const>, offset_y <const> = gfx.getDrawOffset()
	local distance2 <const> = offset_x * offset_x + offset_y * offset_y
	local done_with_scrolling = false
	if distance2 > 6 * 6 then
		local d <const> = 6 / sqrt(distance2)
		local dx <const> = offset_x - floor(offset_x * d)
		local dy <const> = offset_y - floor(offset_y * d)
		gfx.setDrawOffset(dx, dy)
	else
		gfx.setDrawOffset(0, 0)
		done_with_scrolling = true
	end

	-- Fade out all leaves.
	for i = 1, #targets do
		if targets[i].state ~= LEAF_INVISIBLE then
			targets[i].state = LEAF_FADE_OUT
		end
	end
	update_world()

	if global_frames >= 30 then
		-- Draw the real moon while we are still scrolling.
		draw_real_moon()
	else
		-- Fade in the real moon.
		gfx.pushContext(offscreen_buffer)
			gfx.clear(gfx.kColorClear)
			draw_real_moon()
		gfx.popContext()
		local a <const> = global_frames / 30
		offscreen_buffer:drawFaded(0, 0, a, gfx.image.kDitherTypeBayer8x8)
	end

	-- Transition to next state.
	if done_with_scrolling and global_frames >= 30 then
		set_next_game_state(game_restart_fade_in)
		-- Skip the fade-in phase for the moons.
		global_frames = 30
	end
end

-- Start at title screen.
game_state = game_title

-- Disable crank dock/undock sound effects.
playdate.setCrankSoundsDisabled(true)

-- Add menu option to regenerate world.
playdate.getSystemMenu():addMenuItem("reset", function()
	-- Mark targets for regeneration.
	targets = nil

	-- Since completion time is dependent on generated path, we will reset
	-- those as well.
	last_completion_time = 0
	best_completion_time = 0

	-- Invalidate cached background images, since those will be regenerated.
	for i = 1, 8 do
		grass_and_tree_images[i] = nil
	end

	-- Restart at title screen.
	set_next_game_state(game_title)
end)

-- Add menu option to adjust frog speed.
playdate.getSystemMenu():addOptionsMenuItem(
	"frog", {"normal", "agile", "impatient"}, function(selected)
		if selected == "agile" then
			frog_frame_steps = 2
			frog_min_idle_frames = 15
		elseif selected == "impatient" then
			frog_frame_steps = 2
			frog_min_idle_frames = -32
		else
			frog_frame_steps = 1
			frog_min_idle_frames = 15
		end
	end)

-- Add menu option to adjust cricket volume.
playdate.getSystemMenu():addOptionsMenuItem(
	"crickets", {"normal", "lively", "asleep"}, function(selected)
		if selected == "lively" then
			new_cricket_volume = 3
		elseif selected == "asleep" then
			new_cricket_volume = 0
		else
			new_cricket_volume = 1
		end
	end)

-- Playdate callbacks.
function playdate.update()
	-- Start background cricket sounds.
	--
	-- This always happens in every state, even when we are still initializing
	-- the world.
	background_crickets()
	playdate.timer.updateTimers()

	-- We use solid black background in all states.
	gfx.clear(gfx.kColorBlack)

	global_frames += 1
	game_state()
	assert(debug_frame_rate())
end

function playdate.leftButtonDown()
	maybe_remove_key_repeat_timer()

	if game_state ~= game_loop then
		if game_state == game_title then
			transition_to_starting_state()
		end
		return
	end

	key_repeat_timer = playdate.timer.keyRepeatTimer(function()
		if frog_frame == 0 and playdate.isCrankDocked() then
			frog_direction = (frog_direction + 15) & 15
		end
	end)
end
playdate.leftButtonUp = maybe_remove_key_repeat_timer

function playdate.rightButtonDown()
	maybe_remove_key_repeat_timer()

	if game_state ~= game_loop then
		if game_state == game_title then
			transition_to_starting_state()
		end
		return
	end

	key_repeat_timer = playdate.timer.keyRepeatTimer(function()
		if frog_frame == 0 and playdate.isCrankDocked() then
			frog_direction = (frog_direction + 1) & 15
		end
	end)
end
playdate.rightButtonUp = maybe_remove_key_repeat_timer

function playdate.gameWillPause()
	gfx.pushContext(offscreen_buffer)
		gfx.clear(gfx.kColorWhite)

		-- Show game completion time if player has completed the course at
		-- least once, otherwise show instructions.
		if best_completion_time > 0 then
			if last_completion_time > 0 then
				gfx.drawText(string.format("Completion time: *%0.02f*", last_completion_time / 30), 4, 4)
				gfx.drawText(string.format("Best time: *%0.02f*", best_completion_time / 30), 4, 26)
			else
				gfx.drawText(string.format("Best time: *%0.02f*", best_completion_time / 30), 4, 4)
			end
		else
			gfx.drawText("*Crank*: Turn", 4, 4)
			gfx.drawText("*Up*/*A*/*B*: Jump", 4, 26)
			gfx.drawText("(docked) *Left*/*Right*: Turn", 4, 48)
		end

		gfx.drawText("The moon in the sky", 4, 90)
		gfx.drawText("is too far for little frog,", 4, 112)
		gfx.drawText("but the moon's reflection", 4, 134)
		gfx.drawText("is just a few hops away.", 4, 156)

		gfx.drawText("Old pond... v" .. playdate.metadata.version, 4, 198)
		gfx.drawText("omoikane@uguu.org", 4, 220)
	gfx.popContext()
	playdate.setMenuImage(offscreen_buffer)
end

assert(debug_log("Game initialized"))

--}}}
