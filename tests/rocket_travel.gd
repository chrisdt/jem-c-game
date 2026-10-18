extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func board(game) -> void:
	game.player = game.ship_position()
	game.scout.position = game.player
	game.update_exploration()
	game.cooldown = 0
	game.interact()
	game.planet_menu.choose(0 if game.world == 1 else 1)

func run() -> void:
	var scene = load("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.ore = 4
	game.upgraded = true
	game.rocks[0].hp = 0
	var positions: Array = game.rocks.map(func(rock): return rock.pos)
	board(game)
	var departure: Vector2 = game.player
	var explored: PackedByteArray = game.fog.maps[0].pixels.duplicate()
	check(game.flight == game.Flight.IGNITION and game.world == 0, "Boarding skipped ignition or changed worlds immediately")
	check(not game.scout.visible and game.action_button.disabled, "Character or controls remained active aboard the rocket")
	check(not game.hud_layer.visible and game.flight_caption_panel.visible, "Flight HUD obscures the rocket or its caption is missing")
	check(game.rocket.z_index > game.fog.z_index and game.rocket.thrust > 0, "Ignition is hidden by mist or has no boosters")
	game.advance_flight(0.3)
	var time: float = game.flight_elapsed
	game.move_player(Vector2.RIGHT, 1)
	game.interact()
	game.action_button.pressed.emit()
	game.start_mining(1)
	game.travel_to_other_planet()
	check(game.player == departure and game.mining_target == -1 and game.flight_elapsed == time, "Movement, mining or repeated boarding interrupted flight")
	game.advance_flight(game.FLIGHT_DURATIONS[game.Flight.IGNITION] - game.flight_elapsed + 0.01)
	check(game.flight == game.Flight.ASCENT and game.world == 0, "Rocket did not start taking off on its original planet")
	var height0: float = game.rocket.altitude
	game.advance_flight(0.3)
	var height1: float = game.rocket.altitude
	game.advance_flight(0.3)
	var height2: float = game.rocket.altitude
	check(height1 > height0 and height2 - height1 > height1 - height0, "Rocket ascent does not accelerate upward")
	check(game.rocket.thrust == 1 and not game.scout.visible, "Takeoff lost its boosters or left the character behind")
	game.advance_flight(game.FLIGHT_DURATIONS[game.Flight.ASCENT] - game.flight_elapsed + 0.001)
	check(game.world == 1 and game.flight == game.Flight.DESCENT, "Planet did not switch exactly between ascent and descent")
	check(game.travel_fade.color.a > 0.99 and game.rocket.altitude > 900, "Map change was exposed or destination rocket started on the ground")
	check(not game.green_surface.visible and game.rocket.frost, "Destination environment was not activated")
	check(game.fog.maps[0].pixels == explored, "Aerial travel revealed a strip of the old map")
	check(game.fog.active_map == 2 and not game.fog.is_revealed(2, Vector2(1600, 400)), "Landing revealed unrelated areas on the new planet")
	height0 = game.rocket.altitude
	game.advance_flight(0.5)
	height1 = game.rocket.altitude
	game.advance_flight(0.5)
	height2 = game.rocket.altitude
	check(height0 > height1 and height1 > height2 and height0 - height1 > height1 - height2, "Descent does not slow as the rocket approaches the ground")
	check(game.rocket.thrust > 0.7 and not game.scout.visible, "Braking boosters stopped before landing")
	game.advance_flight(game.FLIGHT_DURATIONS[game.Flight.DESCENT] - game.flight_elapsed + 0.001)
	check(game.flight == game.Flight.TOUCHDOWN and game.rocket.altitude == 0 and game.rocket.thrust == 0, "Touchdown did not ground the rocket and turn off its engine")
	check(not game.scout.visible and game.action_button.disabled, "Controls unlocked before touchdown settled")
	game.advance_flight(1)
	check(game.flight == game.Flight.IDLE and game.scout.visible and not game.action_button.disabled, "Controls or character were not restored after landing")
	check(game.hud_layer.visible and not game.flight_caption_panel.visible, "Normal HUD did not return after landing")
	check(game.rocket.position == game.ICE_SHIP and game.rocket.z_index < game.fog.z_index, "Landed rocket is on the wrong pad or above the normal scenery")
	check(game.camera.position == game.player and game.camera.position_smoothing_enabled and game.travel_fade.color.a == 0, "Landing did not restore the camera or clear the fade")
	check(game.FROST_LAYOUT.can_walk(game.player) and game.ore == 4 and game.upgraded, "Landing is blocked or inventory/upgrades were lost")
	var landed: Vector2 = game.player
	game.move_player(Vector2.RIGHT, 0.1)
	check(game.player != landed, "Walking did not resume after landing")
	# Simulate several frame rates, a huge frame, and both directions of travel.
	for step in [1.0 / 30.0, 1.0 / 60.0, 0.73, 30.0]:
		var expected: int = 1 - game.world
		board(game)
		for frame in 1000:
			if game.flight == game.Flight.IDLE:
				break
			game.advance_flight(step)
		check(game.flight == game.Flight.IDLE and game.world == expected, "Flight stalled or switched worlds repeatedly at timestep %s" % step)
		check(game.scout.visible and not game.action_button.disabled and game.rocket.altitude == 0, "Flight left controls or artwork stuck at timestep %s" % step)
	# Finish back on Green Planet to inspect the original session state.
	if game.world != 0:
		board(game)
		game.advance_flight(30)
	check(game.rocks.map(func(rock): return rock.pos) == positions and game.rocks[0].hp == 0, "Round trips reset ore positions or mined deposits")
	check(game.ore == 4 and game.upgraded and game.fog.is_revealed(0, departure), "Round trips lost inventory, upgrades or discovery")
	game.underground = true
	game.refresh_ui()
	game.travel_to_other_planet()
	check(game.flight == game.Flight.IDLE and not game.rocket.visible, "Rocket appeared underground or launched out of a mine")
	game.underground = false
	game.refresh_ui()
	# Restarting during a flight creates a normal, playable initial scene.
	board(game)
	var fresh = scene.instantiate()
	root.add_child(fresh)
	fresh.set_process(false)
	check(fresh.flight == fresh.Flight.IDLE and fresh.scout.visible and not fresh.action_button.disabled and fresh.travel_fade.color.a == 0, "New game inherited an interrupted flight")
	game.queue_free()
	fresh.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: ignition, input lock, accelerating takeoff, covered planet switch, booster braking, touchdown, controls/camera recovery, frame rates, session progress and reset")
	quit(1 if failures else 0)
