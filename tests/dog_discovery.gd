extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		if failures < 15: push_error(message)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var dog = game.companion
	dog.set_process(false)
	check(game.earth_rocks.size() == 1 and game.earth_stream.texture_loads == 0,"Choosing a dog location loaded unvisited areas")
	var districts: Dictionary = {}
	var positions: Dictionary = {}
	for seed_value in 100:
		dog.choose_discovery(seed_value)
		var region: int = dog.discovery_region
		check(region >= 1 and region <= 4,"Dog starts in Landing Meadow or an invalid district")
		districts[region] = true
		game.earth_region = 0
		game.underground = false
		dog.sync_area()
		check(not dog.visible,"Unfound dog appeared on the starting screen")
		game.earth_region = region%4+1
		dog.sync_area()
		check(not dog.visible,"Dog appeared in multiple districts")
		game.earth_region = region
		game.underground = true
		dog.sync_area()
		check(not dog.visible,"Unfound dog started in a mine")
		game.underground = false
		game.ore_rng.seed = seed_value*101+37
		game.reset_rocks()
		dog.sync_area()
		check(dog.visible and dog.can_stand(dog.position),"Random dog start is unreachable or overlaps an obstacle/deposit")
		check(game.EARTH.spawn_clear(region,false,dog.position,false),"Random dog start blocks a trail, doorway or tree")
		var point: Vector2 = dog.position
		positions[str(region)+str(point)] = true
		game.earth_region = 0
		dog.sync_area()
		game.earth_region = region
		dog.sync_area()
		check(dog.position == point,"Dog moved his hiding spot when the player revisited")
		game.world = 1
		dog.sync_area()
		check(not dog.visible,"Unfound dog appeared on an alien planet")
		game.world = 0
		dog.sync_area()
		check(dog.position == point,"Rocket travel rerolled the unfound dog")
	check(districts.size() == 4 and positions.size() == 100,"Dog starts did not vary across the other four Earth districts")
	check(game.earth_stream.texture_loads == 0,"Selecting dog starts loaded background textures")
	game.player = dog.position+Vector2(25,0)
	game.update_exploration()
	dog.advance(0)
	check(dog.recruited,"Randomly placed dog could not be befriended")
	var previous: int = dog.discovery_region
	dog.choose_discovery(777)
	check(dog.recruited and dog.discovery_region == previous,"Location selection reset an existing friendship")
	game.earth_region = 0
	game.player = game.surface_arrival_position()
	game.reset_rocks()
	game.refresh_ui()
	check(dog.visible and dog.can_stand(dog.position),"Befriended dog could not follow Scout home")
	game.free()
	await process_frame
	var fresh = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	fresh.set_process(false)
	fresh.companion.set_process(false)
	check(not fresh.companion.recruited and not fresh.companion.visible and fresh.scared_wildlife.is_empty(),"A new game retained friendship or scared critters")
	fresh.free()
	if failures == 0: print("PASS: 100 distinct dog starts across all four later Earth districts, never the starting screen/mine/alien world, safe approaches and stable revisit/rocket position, no early scenery loads, friendship and fresh-game reset")
	quit(1 if failures else 0)
