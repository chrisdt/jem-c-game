extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.ore == 0 and not game.upgraded)
	# Exercise the movement path used by keyboard input, including diagonal speed
	# and blocked movement; the visual must settle to idle when motion stops.
	game.player = Vector2(600, 600)
	game.move_player(Vector2.RIGHT, 0.1)
	assert(is_equal_approx(game.player.x, 623.5))
	assert(game.walking and game.scout.animation == &"walk")
	game.walk_distance = 0.0
	for expected_frame in [1, 2, 3, 0]:
		game.move_player(Vector2.RIGHT, 28.0 / game.SPEED)
		assert(game.scout.frame == expected_frame)
	var before: Vector2 = game.player
	game.move_player(Vector2(1, 1), 0.1)
	assert(is_equal_approx(before.distance_to(game.player), 23.5))
	game.move_player(Vector2.LEFT, 0.1)
	assert(game.scout.flip_h)
	game.move_player(Vector2.ZERO, 0.1)
	assert(not game.walking and game.scout.animation == &"idle")
	game.player = Vector2(1900, 1290)
	game.move_player(Vector2.ONE, 0.1)
	assert(not game.walking and game.scout.animation == &"idle")
	game.player = Vector2(1090, 960)
	game.move_player(Vector2.RIGHT, 0.1)
	assert(game.player == Vector2(1090, 960))
	assert(not game.walking and game.scout.animation == &"idle")
	print("PASS: walk cycle, diagonal speed, facing, idle, pond and map boundaries")
	# Two hits per deposit; moving between deposits also allows cooldown to expire.
	for i in range(5):
		game.player = game.rocks[i].pos
		for hit in range(2):
			game.cooldown = 0
			game.interact()
	assert(game.ore == 5)
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	assert(game.upgraded and game.ore == 0)
	game.player = game.CAVE
	game.cooldown = 0
	game.interact()
	assert(game.underground)
	game.player = Vector2(1180, 450)
	for hit in range(2):
		game.cooldown = 0
		game.interact()
	assert(game.won)
	game.player = Vector2(350, 700)
	game.cooldown = 0
	game.interact()
	assert(not game.underground)
	print("PASS: mining, inventory, upgrade, mine entry, crystal mission and exit")
	quit()
