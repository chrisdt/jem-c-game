extends RefCounted

# Exercise the real loading/state transition while letting focused mining tests
# select a district without duplicating the separate walking-route fixtures.
static func enter(game, region: int, cave: bool) -> void:
	var data = game.regions()
	var arrival: Vector2 = data.MINE_SPAWNS[region] if cave else data.arrival(region,data.LINKS[region][0].side)
	game.begin_earth_transition(region,cave,arrival,game.player)
	var deadline := Time.get_ticks_msec()+12000
	while game.earth_transition and Time.get_ticks_msec() < deadline:
		game.advance_earth_transition(0.05)
		await game.get_tree().process_frame
	assert(not game.earth_transition,"Test area did not finish loading")
	assert(game.current_region() == region and game.underground == cave,"Test arrived in the wrong area")
