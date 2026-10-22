extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var layout = game.MINE_LAYOUT
	assert(not Geometry2D.triangulate_polygon(layout.FLOOR).is_empty())
	assert(layout.can_walk(game.MINE_SPAWN))
	assert(layout.can_walk(game.MINE_EXIT))
	for blocked in [Vector2(755, 640), Vector2(780, 450), Vector2(1070, 515), Vector2(50, 50), Vector2(1000, 900), Vector2(675, 880), Vector2(330, 720)]:
		assert(not layout.can_walk(layout.from_art(blocked)))
	# Even a slow frame must not jump through a pillar to the floor beyond it.
	var start: Vector2 = layout.from_art(Vector2(710, 425)) - layout.FOOT_OFFSET
	var stopped: Vector2 = layout.move_on_floor(start, Vector2(200, 0))
	assert(layout.can_walk(stopped))
	assert(stopped.x < layout.from_art(Vector2(780, 450)).x)
	# Explore actual traversable floor from the spawn to find every deposit,
	# the exit, and the four marked side chambers, rather than teleporting the player.
	const GRID := 16.0
	var first := Vector2i((game.MINE_SPAWN / GRID).round())
	var queue: Array[Vector2i] = [first]
	var visited := {first: true}
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if visited.has(next):
				continue
			var position := Vector2(next) * GRID
			if position.x < 0 or position.y < 0 or position.x > 2000 or position.y > 1400:
				continue
			if layout.can_walk(position):
				visited[next] = true
				queue.append(next)
	var targets: Array[Vector2] = [game.MINE_EXIT]
	for rock in game.rocks:
		if rock.cave:
			targets.append(rock.pos)
	for alcove in [Vector2(420, 230), Vector2(800, 220), Vector2(1350, 245), Vector2(1280, 830)]:
		targets.append(layout.from_art(alcove))
	for target in targets:
		var reachable := false
		for cell in queue:
			if (Vector2(cell) * GRID).distance_to(target) < 80:
				reachable = true
				break
		assert(reachable, "Unreachable mine location: %s" % target)
	# Doorways transition automatically without an interaction key.
	game.player = game.CAVE
	game.cooldown = 0
	game.move_player(Vector2.ZERO, 0.61)
	assert(game.underground and game.player == game.MINE_SPAWN)
	game.player = game.MINE_EXIT
	game.cooldown = 0
	game.move_player(Vector2.ZERO, 0.61)
	assert(not game.underground)
	print("PASS: cave walls, pool, pillars, slow-frame collision, connected ore and side chambers, entry and exit")
	quit()
