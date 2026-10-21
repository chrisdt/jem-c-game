extends RefCounted

# Exercise the real loading/state transition while letting focused mining tests
# select a district without duplicating the separate walking-route fixtures.
static func enter(game, region: int, cave: bool) -> void:
	# Geometry/state fixtures isolate the map loader from the campaign gate.
	# earth_story.gd tests the locked transition and earns real quarry access.
	if game.world == 0 and region == 4: game.story.quarry_open = true
	var data = game.regions()
	var arrival: Vector2 = data.MINE_SPAWNS[region] if cave else data.arrival(region,data.LINKS[region][0].side)
	game.begin_earth_transition(region,cave,arrival,game.player)
	var previous := Time.get_ticks_msec()
	var deadline := previous+60000
	while game.earth_transition and Time.get_ticks_msec() < deadline:
		var now := Time.get_ticks_msec()
		# Headless frames can run much faster than real downloads/decompression.
		# Do not turn a few milliseconds of loading into a 24-second timeout.
		game.advance_earth_transition(clampf((now-previous)/1000.0,0.001,0.05))
		previous = now
		await game.get_tree().process_frame
	assert(not game.earth_transition,"Test area did not finish loading")
	assert(game.current_region() == region and game.underground == cave,"Test arrived in the wrong area")

static func depart(game, destination: int = -1) -> void:
	# Existing travel/mining fixtures are independent of the story. Supply the
	# launch preconditions only for boarding, preserving their original tool
	# balance. The full story test exercises the real repair chain and gates.
	var before := arm_launch(game)
	game.travel_to_other_planet(destination)
	restore_launch(game,before)

static func arm_launch(game) -> Array:
	var story = game.story
	var before := [story.rocket_repaired,story.suit_ready,story.drill_improved,story.sword_improved]
	story.rocket_repaired = true
	story.suit_ready = true
	story.drill_improved = true
	story.sword_improved = true
	return before

static func restore_launch(game, before: Array) -> void:
	var story = game.story
	story.rocket_repaired = before[0]
	story.suit_ready = before[1]
	story.drill_improved = before[2]
	story.sword_improved = before[3]
