extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for world in [0, 1]:
		game.world = world
		game.underground = false
		game.mine_transition_cooldown = 0
		game.player = game.cave_position() + Vector2(0, 110)
		game.cooldown = 0
		game.interact()
		check(not game.underground,"The use key still enters a mine before reaching the doorway")
		# Actual walking enters, even while the separate use-key cooldown runs.
		game.cooldown = 10
		game.move_player(Vector2.UP, 0.25)
		check(game.underground,"Walking into planet %d mine did not enter" % world)
		var spawn: Vector2 = game.ICE_SPAWN if world == 1 else game.MINE_SPAWN
		check(game.player == spawn,"Mine arrival did not use its safe spawn")
		game.move_player(Vector2.UP, 0.15)
		check(game.underground,"Holding movement bounced straight back outside")
		game.move_player(Vector2.ZERO, 0.6)
		game.player = game.exit_position() + (Vector2(0, -110) if world == 1 else Vector2(110, 0))
		game.move_player(Vector2.DOWN if world == 1 else Vector2.LEFT, 0.25)
		check(not game.underground,"Walking to planet %d exit did not leave" % world)
		game.move_player(Vector2.ZERO, 1)
		check(not game.underground,"Standing at the outdoor arrival point re-entered the mine")
		if world == 1:
			check(game.FROST_LAYOUT.can_walk(game.player),"Frost outdoor arrival is outside the walkable floor")
	# A slow frame must not step all the way across the entrance trigger.
	game.world = 0
	game.underground = false
	game.mine_transition_cooldown = 0
	game.player = game.CAVE + Vector2(0,110)
	game.move_player(Vector2.UP, 1)
	check(game.underground,"A slow frame skipped the automatic doorway")
	if failures == 0:
		print("PASS: walk into both mines and exits without E, safe arrivals, held input, independent use cooldown and slow-frame crossing")
	quit(1 if failures else 0)
