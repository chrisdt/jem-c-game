extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(game.ore == 0 and not game.upgraded)
	assert(game.green_surface.visible)
	# Exercise the movement path used by keyboard input, including diagonal speed
	# and blocked movement; the visual must settle to idle when motion stops.
	game.player = Vector2(600, 600)
	game.move_player(Vector2.RIGHT, 0.1)
	assert(is_equal_approx(game.player.x, 623.5))
	assert(game.walking and game.scout.animation == &"walk_side")
	# Each cardinal direction selects the correct artwork and keeps it at rest.
	for sample in [[Vector2.UP, &"up", false], [Vector2.DOWN, &"down", false], [Vector2.LEFT, &"side", true], [Vector2.RIGHT, &"side", false]]:
		game.move_player(sample[0], 0.01)
		assert(game.scout.animation == StringName("walk_" + str(sample[1])))
		assert(game.scout.flip_h == sample[2])
		var moving_texture = game.scout.sprite_frames.get_frame_texture(game.scout.animation, 1)
		game.move_player(Vector2.ZERO, 0.01)
		assert(game.scout.animation == StringName("idle_" + str(sample[1])))
		assert(game.scout.sprite_frames.get_frame_texture(game.scout.animation, 0) == moving_texture)
		assert(game.scout.flip_h == sample[2])
	var frames = game.scout.sprite_frames
	assert(frames.get_frame_texture(&"walk_up", 0).atlas != frames.get_frame_texture(&"walk_down", 0).atlas)
	assert(frames.get_frame_texture(&"walk_side", 0).atlas != frames.get_frame_texture(&"walk_down", 0).atlas)
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
	assert(not game.walking and str(game.scout.animation).begins_with("idle_"))
	game.player = Vector2(1900, 1290)
	game.move_player(Vector2.ONE, 0.1)
	assert(not game.walking and str(game.scout.animation).begins_with("idle_"))
	game.player = Vector2(1090, 960)
	game.move_player(Vector2.RIGHT, 0.1)
	assert(game.player == Vector2(1090, 960))
	assert(not game.walking and str(game.scout.animation).begins_with("idle_"))
	print("PASS: directional walk cycle, retained idle facing, diagonal speed, pond and map boundaries")
	# Timed copper collection; the first click starts work and cannot award early.
	for i in range(5):
		game.player = game.rocks[i].pos
		game.cooldown = 0
		game.interact()
		assert(game.mining_target == i)
		game.advance_mining(1.5)
		assert(game.ore == i)
		game.advance_mining(0.5)
		assert(game.ore == i + 1)
	assert(game.ore == 5)
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	assert(game.upgraded and game.ore == 0)
	game.player = game.CAVE
	game.cooldown = 0
	game.move_player(Vector2.ZERO, 0.61)
	assert(game.underground and not game.green_surface.visible)
	game.player = Vector2(1180, 450)
	game.cooldown = 0
	game.interact()
	game.advance_mining(8.5)
	assert(not game.won)
	game.advance_mining(0.5)
	assert(game.won)
	game.player = game.MINE_EXIT
	game.cooldown = 0
	game.move_player(Vector2.ZERO, 0.61)
	assert(not game.underground and game.green_surface.visible)
	print("PASS: mining, inventory, upgrade, mine entry, crystal mission and exit")
	quit()
