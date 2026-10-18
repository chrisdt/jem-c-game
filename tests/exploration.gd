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
	var start: Vector2 = game.player
	var untouched := Vector2(1750,1100)
	check(game.fog.is_revealed(0,start),"Starting position is covered by mist")
	check(not game.fog.is_revealed(0,untouched),"Unvisited map started revealed")
	# A hidden deposit cannot leak through prompts or a direct mining request.
	var hidden := -1
	for i in game.rocks.size():
		if not game.rocks[i].cave and not game.rocks[i].discovered:
			hidden = i
			break
	check(hidden >= 0,"Random layout left no ore to discover")
	if hidden >= 0:
		game.player = game.rocks[hidden].pos
		check(game.nearest_rock() == -1,"Undiscovered ore appeared in a mining prompt")
		game.start_mining(hidden)
		check(game.mining_target == -1,"Undiscovered ore could be mined")
		game.move_player(Vector2.ZERO, 0.01)
		check(game.rocks[hidden].discovered and game.nearest_rock() == hidden,"Walking into view did not discover the deposit")
		game.start_mining(hidden)
		check(game.mining_target == hidden,"A discovered deposit could not be mined")
		game.cancel_mining()
	# Walk a long, real segment. Every part of the trail must remain clear.
	game.player = Vector2(650,700)
	game.update_exploration()
	game.move_player(Vector2.RIGHT, 2)
	for x in range(650,1120,32):
		check(game.fog.is_revealed(0,Vector2(x,700)),"A slow frame left a hole in the explored trail")
	check(game.fog.is_revealed(0,start),"Explored ground became covered again after leaving")
	var surface_state: PackedByteArray = game.fog.maps[0].pixels.duplicate()
	var locations: Array = game.rocks.map(func(rock): return rock.pos)
	# Each area has its own memory. Entering a mine never reveals a corridor
	# between the outdoor doorway and the underground arrival coordinates.
	game.player = game.CAVE
	game.move_player(Vector2.ZERO, 0.61)
	check(game.underground and game.fog.active_map == 1,"Mine did not switch its exploration map")
	check(game.fog.is_revealed(1,game.MINE_SPAWN),"Mine arrival is hidden")
	check(not game.fog.is_revealed(1,Vector2(1600,650)),"Unexplored mine was revealed by outdoor travel")
	game.player = game.MINE_EXIT
	game.move_player(Vector2.ZERO, 0.61)
	check(game.fog.active_map == 0 and game.fog.is_revealed(0,start),"Leaving the mine lost outdoor exploration")
	for i in surface_state.size():
		if surface_state[i] > game.fog.maps[0].pixels[i]:
			check(false,"Returning to the surface removed explored pixels")
			break
	game.travel_to_other_planet()
	check(game.fog.active_map == 2 and game.fog.is_revealed(2,game.player),"Second planet did not start around its landing point")
	check(not game.fog.is_revealed(2,Vector2(1680,450)),"Second planet inherited Green Planet exploration")
	game.travel_to_other_planet()
	check(game.rocks.map(func(rock): return rock.pos) == locations,"Returning to a planet moved its remaining ore")
	check(game.fog.is_revealed(0,start),"Planet travel lost exploration memory")
	if hidden >= 0:
		check(game.rocks[hidden].discovered,"Planet travel forgot a discovered deposit")
	# A new run gets clean exploration and a fresh layout.
	var fresh = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	fresh.set_process(false)
	check(not fresh.fog.is_revealed(0,untouched) and fresh.fog.maps.size() == 1,"New game retained old map discovery")
	check(fresh.rocks.map(func(rock): return rock.pos) != locations,"New game reused the old ore layout")
	if failures == 0:
		print("PASS: hidden ore cannot leak or be mined, proximity discovers ore, walked trails stay clear, maps are independent, travel preserves discovery/layouts and new runs reset them")
	quit(1 if failures else 0)
