extends SceneTree

const EARTH = preload("res://earth_regions.gd")
const WATER = preload("res://environment/earth_water.gd")
const POND = preload("res://environment/pond.gd")
const DUCK = preload("res://environment/duck.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		if failures <= 12: push_error(description)

func run() -> void:
	var expected := {"willow":Vector2i(5,3),"quarry":Vector2i(3,2),"moss":Vector2i(1,0),"crystal_depths":Vector2i(3,0)}
	for key in expected:
		var failures_before := failures
		var parent := Node2D.new()
		root.add_child(parent)
		var path: String = "res://assets/moss_mine.png" if key == "moss" else EARTH.ASSETS[key]
		var painting := load(path) as Texture2D
		var habitat := WATER.add_to(parent,key,painting)
		var fish: Array = []
		var ducks: Array = []
		for child in habitat.get_children():
			if child.get_script() == POND: fish.append(child)
			elif child.get_script() == DUCK: ducks.append(child)
		check(fish.size() == expected[key].x and ducks.size() == expected[key].y,"Missing pond wildlife: "+key)
		var mask: Texture2D = habitat.get_node("ShimmeringWater").material.get_shader_parameter("water_mask")
		check(mask != null and mask.get_size().x <= 256,"Water effect has no bounded shoreline mask")
		for i in fish.size():
			fish[i].set_process(false)
			fish[i].rng.seed = 301 + i
			fish[i].phase = i * 1.2
			fish[i].next_jump_in = 5 + i
			check(fish[i].ground_texture == painting,"Fish are masked against another area's painting")
		for i in ducks.size():
			ducks[i].set_process(false)
			ducks[i].rng.seed = 431 + i
			ducks[i].choose_target()
		# Two minutes exercise complete swim loops, independent random jumps,
		# splash cleanup and shoreline walks, including the narrow cave pools.
		for frame in 1200:
			for swimmer in fish:
				swimmer.advance(0.1)
				check(swimmer.water_contains(swimmer.fish_position),"Fish crossed a bank or stone island: %s %s" % [key,swimmer.position+swimmer.fish_position])
				check(swimmer.ripples.size() <= 16 and swimmer.droplets.size() <= 12,"Pond effects accumulated")
			for duck in ducks:
				duck.advance(0.1)
				check(duck.can_stand(duck.position),"Duck walked off its dry bank: "+key)
		for swimmer in fish:
			check(swimmer.jump_count >= 4,"Fish did not occasionally jump: "+key)
		for duck in ducks:
			check(duck.walk_distance > 120 and duck.peck_count >= 3,"Duck did not walk and peck: "+key)
		habitat.hide()
		for animal in fish + ducks:
			var before: Variant = animal.phase if animal.get_script() == POND else animal.position
			animal._process(5)
			check(before == (animal.phase if animal.get_script() == POND else animal.position),"Hidden pond wildlife kept advancing")
		parent.free()
		print("Pond check %s: %d fish, %d ducks, %d failures" % [key,fish.size(),ducks.size(),failures-failures_before])
	# The real streamer installs and frees these actors with the district; a
	# dry district must not inherit the marsh's animals or water shader.
	var stream = load("res://environment/earth_stream.gd").new()
	root.add_child(stream)
	stream.store_texture("willow",load(EARTH.ASSETS.willow))
	stream.show_area(2,false)
	check(stream.scenery.has_node("PondHabitat"),"Streamed marsh has no wildlife")
	var previous: WeakRef = weakref(stream.scenery.get_node("PondHabitat"))
	stream.store_texture("pinewood",load(EARTH.ASSETS.pinewood))
	stream.show_area(1,false)
	check(previous.get_ref() == null and not stream.scenery.has_node("PondHabitat"),"Unloaded pond actors survived in a dry district")
	stream.deactivate()
	stream.free()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	check(game.green_surface.has_node("PondLife02"),"Landing Meadow still has only one fish")
	check(not game.moss_water.visible and game.moss_water.process_mode == Node.PROCESS_MODE_DISABLED,"Mine fish are active on the surface")
	game.underground = true
	game.refresh_ui()
	check(game.moss_water.visible and not game.green_surface.visible,"Moss Mine water did not follow the mine transition")
	game.world = 1
	game.refresh_ui()
	check(not game.moss_water.visible and game.moss_water.process_mode == Node.PROCESS_MODE_DISABLED,"Earth mine wildlife remained active off-world")
	if failures == 0:
		print("PASS: fish in all six Earth ponds/pools, multiple independent fish, shoreline ducks, bounded masks/effects, mine visibility and streamed wildlife cleanup")
	quit(1 if failures else 0)
