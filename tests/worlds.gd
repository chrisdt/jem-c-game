extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func explore(layout, start: Vector2, cave: bool) -> Array[Vector2]:
	const GRID := 16.0
	var first := Vector2i((start / GRID).round())
	var queue: Array[Vector2i] = [first]
	var visited := {first:true}
	var head := 0
	var points: Array[Vector2] = []
	while head < queue.size():
		var cell := queue[head]
		head += 1
		points.append(Vector2(cell)*GRID)
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if visited.has(next): continue
			var point := Vector2(next)*GRID
			if point.x < 0 or point.y < 0 or point.x > 2000 or point.y > 1400: continue
			if layout.can_walk(point,cave):
				visited[next] = true
				queue.append(next)
	return points

func reaches(points: Array[Vector2], target: Vector2) -> bool:
	for point in points:
		if point.distance_to(target) < 80: return true
	return false

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.player = game.rocks[0].pos
	game.start_mining(0)
	game.advance_mining(2)
	assert(game.ore == 1)
	game.player = game.SHIP
	game.cooldown = 0
	game.interact()
	assert(game.world == 1 and not game.underground and game.ore == 1)
	var layout = game.FROST_LAYOUT
	assert(layout.can_walk(game.player))
	assert(layout.can_walk(game.ICE_CAMP))
	assert(layout.can_walk(game.ICE_SHIP))
	assert(layout.can_walk(game.ICE_CAVE))
	assert(layout.can_walk(game.ICE_SPAWN,true))
	assert(layout.can_walk(game.ICE_EXIT,true))
	assert(not layout.can_walk(layout.from_art(Vector2(770,650))))
	assert(not layout.can_walk(layout.from_art(Vector2(740,300)),true))
	var bridge_start: Vector2 = layout.from_art(Vector2(640,500)) - layout.FOOT_OFFSET
	var crossed: Vector2 = layout.move_on_floor(bridge_start,Vector2(400,0))
	assert(crossed.x > layout.from_art(Vector2(885,500)).x)
	var edge_start: Vector2 = layout.from_art(Vector2(640,540)) - layout.FOOT_OFFSET
	var blocked: Vector2 = layout.move_on_floor(edge_start,Vector2(500,0))
	assert(blocked.x < layout.from_art(Vector2(650,540)).x)
	var surface := explore(layout,game.player,false)
	var mine := explore(layout,game.ICE_SPAWN,true)
	assert(reaches(surface,game.ICE_CAVE))
	assert(reaches(surface,game.ICE_SHIP))
	assert(reaches(mine,game.ICE_EXIT))
	for rock in game.rocks:
		assert(reaches(mine if rock.cave else surface,rock.pos),"Unreachable frost deposit: %s" % rock.pos)
	# New material timing, cancellation and upgrade gate.
	for i in range(3):
		game.player = game.rocks[i].pos
		game.start_mining(i)
		game.advance_mining(2.5)
		assert(game.frost_ore == i)
		game.advance_mining(0.5)
		assert(game.frost_ore == i+1)
	game.player = game.ICE_CAVE
	game.cooldown = 0
	game.interact()
	assert(game.underground and game.player == game.ICE_SPAWN)
	game.player = game.rocks[9].pos
	game.start_mining(9)
	assert(game.mining_target == -1 and not game.ice_won)
	game.player = game.ICE_EXIT
	game.cooldown = 0
	game.interact()
	assert(not game.underground and layout.can_walk(game.player))
	game.player = game.ICE_SHIP
	game.cooldown = 0
	game.interact()
	assert(game.world == 0 and game.rocks[0].hp == 0 and game.frost_ore == 3)
	for i in range(1,5):
		game.player = game.rocks[i].pos
		game.start_mining(i)
		game.advance_mining(2)
	game.player = game.CAMP
	game.cooldown = 0
	game.interact()
	assert(game.upgraded and game.ore == 0)
	game.player = game.SHIP
	game.cooldown = 0
	game.interact()
	assert(game.world == 1 and game.rocks[0].hp == 0 and game.frost_ore == 3)
	game.player = game.ICE_CAVE
	game.cooldown = 0
	game.interact()
	game.player = game.rocks[9].pos
	game.start_mining(9)
	game.advance_mining(9.5)
	assert(game.amethysts == 0 and not game.ice_won)
	game.advance_mining(0.5)
	assert(game.amethysts == 1 and game.ice_won)
	# Travel cannot interrupt an active mining session or teleport out of a mine.
	game.travel_to_other_planet()
	assert(game.world == 1 and game.underground)
	game.player = game.ICE_EXIT
	game.cooldown = 0
	game.interact()
	game.player = game.ICE_SHIP
	game.cooldown = 0
	game.interact()
	game.player = game.SHIP
	game.cooldown = 0
	game.interact()
	assert(game.world == 1 and game.ice_won and game.rocks[9].hp == 0)
	print("PASS: rocket travel, distinct surface/mine routes, bridge and canyon collision, all ore reachable, 3s/10s materials, upgrade, second mission and progress retained on return")
	quit()
