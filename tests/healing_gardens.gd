extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const GRASS = preload("res://environment/flower_placement.gd")
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
	game.gardens.set_process(false)
	check(game.gardens.plants.size() == 1 and not game.gardens.plants[0].apple,"Starting meadow must have one bush and no fruit trees")
	var remembered := {}
	for world in 3:
		if world != game.world:
			game.travel_to_other_planet(world)
			game.advance_flight(10)
		var counts := Vector2i.ZERO
		for region in 5:
			if region != game.current_region(): await TRAVEL.enter(game,region,false)
			game.refresh_ui()
			var garden = game.gardens
			check(garden.active_area == game.area_id() and garden.visible,"Garden is on the wrong area")
			check(garden.plants.size() <= 1,"Plants were crowded into a single district")
			check(game.earth_stream.textures.size() <= game.earth_stream.MAX_TEXTURES,"Healing plants bypassed the scenery cache bound")
			if world == 0 and region == 0: check(garden.plants.all(func(p): return not p.apple),"Fruit tree reappeared on the starting screen")
			for plant in garden.plants:
				counts.x += int(plant.apple)
				counts.y += int(not plant.apple)
				check(garden.clear_floor(plant.position),"Healing plant overlaps a rock, doorway or mineral")
				if world == 0:
					var painting: Texture2D = game.green_surface.get_node("Ground").texture if region == 0 else game.earth_stream.textures[game.regions().key(region,false)]
					var grass := GRASS.new(painting,game.regions().SIZE,garden.clear_floor)
					check(grass.fits(plant.position,0.24 if plant.apple else 0.16),"Earth food roots are on a path or rock instead of grass")
				game.player = plant.position+Vector2(0,30)
				game.fog.observe(game.area_id(),plant.position)
				game.trial.health = 10
				plant.advance(0.25,1)
				check(plant.discovered and plant.fade > 0,"Food did not reveal gradually with its own district's fog")
				check(not plant.collect() and not plant.picked,"Food was consumed at full health")
				game.planet_menu.open(world)
				game.trial.health = 4
				check(not plant.collect(),"A menu allowed hidden harvesting")
				game.planet_menu.dismiss()
				game.refresh_ui()
				check(game.hud.health_panel.visible,"Missing hearts outside the meadow while searching for food")
				check(plant.collect() and game.trial.health == (8 if plant.apple else 6),"Food healed the wrong amount outside the first screen")
				check(not plant.collect() and plant.picked,"A picked plant can heal repeatedly")
				remembered[game.area_id()] = plant.position
		check(counts == Vector2i(2,2),"Planet %d does not have two fruit trees and two berry bushes: %s" % [world,counts])
		# Travel all districts again: no respawns, stable positions, no large
		# retained image/tree collections for the previous district.
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
				for plant in game.gardens.plants: check(plant.picked,"Mine trip reset harvested fruit")
	# Returning by rocket also keeps the first world's harvest state.
	game.travel_to_other_planet(0)
	game.advance_flight(10)
	check(game.gardens.plants.size() == 1 and game.gardens.plants[0].picked,"Rocket return reset Earth's starting bush")
	check(game.trial.snakes.size() == 3 and game.trial.defeated == 0,"Sparse gardens altered the combat encounter")
	game.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("PASS: no starter fruit trees; two trees/two bushes per world across 15 districts, grass/floor/ore/door clearance, fog fade, exact healing, health HUD away from home, full-health/menu protection, bounded active plants/textures, and harvest memory through all mines and rocket trips")
	quit(1 if failures else 0)
