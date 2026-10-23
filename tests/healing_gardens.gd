extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const GRASS = preload("res://environment/flower_placement.gd")
const WILD = preload("res://environment/wild_food_art.gd")
const PLANT = preload("res://environment/healing_plant.gd")
var failures := 0
var harvested := 0
var locations: Array = []

func _initialize() -> void: call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.gardens.set_process(false)
	game.frost_story.set_process(false)
	game.ember_story.set_process(false)
	check(game.gardens.plants.size() == 1 and not game.gardens.plants[0].apple,"Starting meadow must have one bush and no fruit trees")
	var remembered := {}
	var kinds := {}
	for world in 3:
		if world != game.world:
			TRAVEL.depart(game,world)
			check(not game.gardens.visible,"Food remains visible during rocket flight")
			game.advance_flight(10)
			game.missions.fruit_used = false
		var counts := Vector2i.ZERO
		for region in 5:
			if region != game.current_region(): await TRAVEL.enter(game,region,false)
			game.refresh_ui()
			var garden = game.gardens
			check(garden.active_area == game.area_id() and garden.visible,"Garden is on the wrong outdoor area")
			check(garden.plants.size() == (1 if world > 0 or region < 4 else 0),"Missing or crowded outdoor food in %d/%d" % [world,region])
			check(game.earth_stream.textures.size() <= game.earth_stream.MAX_TEXTURES,"Healing plants bypassed the scenery cache bound")
			for plant in garden.plants:
				counts.x += int(plant.hearts() == 2)
				counts.y += int(plant.hearts() == 1)
				check(garden.clear_floor(plant.position),"Healing plant overlaps a rock, doorway, quest prop or mineral")
				check(game.trial.floor_at(plant.position),"Food requires standing off the walkable map")
				if world == 0:
					check(plant.wild_kind == -1 and (region != 0 or not plant.apple),"Native food changed Earth's starter garden")
					var painting: Texture2D = game.green_surface.get_node("Ground").texture if region == 0 else game.earth_stream.textures[game.regions().key(region,false)]
					var grass := GRASS.new(painting,game.regions().SIZE,garden.clear_floor)
					check(grass.fits(plant.position,0.24 if plant.apple else 0.16),"Earth food roots are on a path or rock instead of grass")
				else:
					check(not plant.apple and plant.wild_kind in ([0,1] if world == 1 else [2,3]),"Wrong world's plant or an Earth fruit tree appeared")
					kinds[plant.wild_kind] = true
					var snow_or_sand: Image = garden.ground_painting().get_image()
					if snow_or_sand.is_compressed(): snow_or_sand.decompress()
					snow_or_sand.resize(384,269,Image.INTERPOLATE_TRILINEAR)
					check(garden.wild_ground_fits(plant.position,snow_or_sand),"Native roots are not on clear snow or sand")
					check(plant.illustration.texture == WILD.SHEET,"Native plant still uses Earth's artwork")
				locations.append({"world":world,"region":region,"kind":plant.wild_kind,"x":plant.position.x,"y":plant.position.y})
				game.player = plant.position+Vector2(0,30)
				game.fog.observe(game.area_id(),plant.position)
				game.trial.health = 10
				plant.advance(0.25,1)
				check(plant.discovered and plant.fade > 0,"Food did not reveal with its own district's fog")
				check(not plant.collect() and not plant.picked,"Food was consumed at full health")
				game.planet_menu.open(world)
				game.trial.health = 4
				check(not plant.collect(),"A menu allowed hidden harvesting")
				game.planet_menu.dismiss()
				paused = true
				check(not plant.collect(),"Pause allowed harvesting")
				paused = false
				game.refresh_ui()
				check(game.hud.health_panel.visible,"Missing health HUD while searching for food")
				var anchor: Vector2 = plant.illustration.position
				var expected: int = 4+plant.hearts()*2
				check(plant.collect() and game.trial.health == expected,"Food healed the wrong amount in %d/%d" % [world,region])
				check(not plant.collect() and plant.picked,"A picked plant can heal repeatedly")
				if world > 0:
					check(plant.illustration.position == anchor,"Harvesting moves the plant's roots")
					check(not game.missions.fruit_used,"Alien food completes Earth's optional fruit objective")
					check(game.message == WILD.MESSAGES[plant.wild_kind],"Healing message names the wrong food")
					# The real collection path clamps either healing amount at five hearts.
					var cap_plant := PLANT.new()
					cap_plant.garden = garden
					cap_plant.wild_kind = plant.wild_kind
					cap_plant.position = plant.position
					cap_plant.discovered = true
					garden.add_child(cap_plant)
					game.trial.health = 9
					check(cap_plant.collect() and game.trial.health == 10,"Native food exceeds the health cap")
					cap_plant.free()
				remembered[game.area_id()] = plant.position
				harvested += 1
		check(counts == (Vector2i(2,2) if world == 0 else Vector2i(2,3)),"Wrong sparse food counts in world %d: %s" % [world,counts])
		for region in range(4,-1,-1):
			if region != game.current_region(): await TRAVEL.enter(game,region,false)
			game.refresh_ui()
			for plant in game.gardens.plants:
				check(plant.picked and plant.position == remembered[game.area_id()],"Revisiting respawned or moved harvested food")
				check(not plant.collect(),"Revisited food healed twice")
			if game.regions().has_mine(region):
				await TRAVEL.enter(game,region,true)
				check(game.gardens.plants.is_empty() and not game.gardens.visible,"Surface plants leaked into a mine")
				await TRAVEL.enter(game,region,false)
				for plant in game.gardens.plants: check(plant.picked,"Mine trip reset harvested food")
	check(kinds.size() == 4,"Not all four approved wild foods appeared")
	TRAVEL.depart(game,0)
	game.advance_flight(10)
	check(game.gardens.plants.size() == 1 and game.gardens.plants[0].picked,"Rocket return reset Earth's starting bush")
	for world in [1,2]:
		TRAVEL.depart(game,world)
		game.advance_flight(10)
		check(game.gardens.plants.size() == 1 and game.gardens.plants[0].picked,"Rocket return respawned native food")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var file := FileAccess.open("res://build/healing-gardens.json",FileAccess.WRITE)
	check(file != null,"Cannot write healing garden audit report")
	if file != null: file.store_string(JSON.stringify({"locations":locations,"harvested":harvested,"failures":failures},"\t"))
	game.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("PASS: four Earth plants and ten native Frost/Ember plants across all 15 outdoor districts; all four foods, clear snow/sand and quest/ore/door clearance, exact healing/cap, fog/wind, full-health/menu/pause protection, and picked artwork/state through every mine and rocket return")
	quit(1 if failures else 0)
