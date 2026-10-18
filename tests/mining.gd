extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	# Directional mining poses and the impact event agree with the swing cycle.
	for sample in [[Vector2(-70, 0), &"side", false], [Vector2(70, 0), &"side", true], [Vector2(0, 70), &"up", false], [Vector2(0, -70), &"down", false]]:
		game.player = game.rocks[0].pos + sample[0]
		game.update_exploration()
		game.start_mining(0)
		assert(game.scout.animation == StringName("mine_" + str(sample[1])))
		assert(game.scout.flip_h == sample[2] and game.scout.frame == 0)
		game.move_player(Vector2.ZERO, 0.1)
		assert(str(game.scout.animation).begins_with("mine_"))
		game.advance_mining(0.23)
		assert(game.scout.frame == 1 and not game.particles.is_empty())
		game.advance_mining(0.23)
		assert(game.scout.frame == 2)
		game.cancel_mining()
		assert(str(game.scout.animation).begins_with("idle_"))
		assert(game.scout.scale == Vector2.ONE * 0.15)
	game.update_particles(1.0)
	assert(game.particles.is_empty())
	# Copper takes the full two seconds, then awards only once.
	game.player = game.rocks[0].pos + Vector2(-70, 0)
	game.update_exploration()
	game.start_mining(0)
	game.advance_mining(1.99)
	assert(game.ore == 0 and game.rocks[0].hp > 0)
	game.advance_mining(0.02)
	assert(game.ore == 1 and game.rocks[0].hp == 0 and game.mining_target == -1)
	game.advance_mining(20.0)
	game.start_mining(0)
	assert(game.ore == 1 and game.mining_target == -1)
	# Keyboard/button cancellation and movement discard partial progress.
	game.player = game.rocks[1].pos + Vector2(-70, 0)
	game.update_exploration()
	game.cooldown = 0
	game.interact()
	game.advance_mining(1.0)
	game.interact()
	game.advance_mining(4.0)
	assert(game.mining_target == -1 and game.ore == 1)
	game.start_mining(1)
	assert(game.mining_elapsed == 0)
	game.advance_mining(1.0)
	game.move_player(Vector2.LEFT, 0.1)
	assert(game.mining_target == -1 and game.ore == 1)
	# A target becoming out of reach or in another scene cannot keep progressing.
	game.player = game.rocks[1].pos
	game.update_exploration()
	game.start_mining(1)
	game.player += Vector2(200, 0)
	game.advance_mining(3.0)
	assert(game.mining_target == -1 and game.ore == 1)
	game.player = game.rocks[1].pos
	game.update_exploration()
	game.start_mining(1)
	game.underground = true
	game.advance_mining(3.0)
	assert(game.mining_target == -1 and game.ore == 1)
	# Crystal stays locked until the upgrade, and does not award at copper timing.
	var crystal := 11
	game.player = game.rocks[crystal].pos + Vector2(-70, 0)
	game.update_exploration()
	game.start_mining(crystal)
	assert(game.mining_target == -1 and not game.won)
	game.upgraded = true
	game.start_mining(crystal)
	game.advance_mining(2.0)
	assert(not game.won and game.mining_target == crystal)
	game.advance_mining(6.99)
	assert(not game.won)
	game.advance_mining(0.02)
	assert(game.won and game.mining_target == -1)
	# Different simulation frame sizes produce the same 2-second outcome.
	game.underground = false
	for step in [1.0 / 30.0, 1.0 / 144.0]:
		game.reset_rocks()
		game.player = game.rocks[0].pos
		game.update_exploration()
		var before: int = game.ore
		game.start_mining(0)
		var time := 0.0
		while time + step < 1.99:
			game.update_particles(step)
			game.advance_mining(step)
			time += step
		assert(game.ore == before)
		game.advance_mining(2.01 - time)
		assert(game.ore == before + 1)
	game.update_particles(1.0)
	assert(game.particles.is_empty())
	print("PASS: directional mining, impact effects, 2s/9s timing, cancellation, tool restrictions, one-time rewards, frame-rate independence and cleanup")
	quit()
