extends SceneTree

const LIFE = preload("res://environment/ambient_life.gd")
const CREATURE = preload("res://environment/ambient_creature.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		if failures <= 15: push_error(description)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.trial.invulnerable = 10000
	var total := 0
	var maps := 0
	for world in range(3):
		game.world = world
		for region in range(5):
			for cave in [false,true]:
				if cave and not game.regions().has_mine(region): continue
				game.set_current_region(region)
				game.underground = cave
				game.ore_rng.seed = 3107+world*137+region*19+int(cave)
				game.reset_rocks()
				var habitat := LIFE.new()
				root.add_child(habitat)
				habitat.populate(world,region,cave,game.regions(),game)
				var expected := 5 if cave else (0 if world == 0 else 4)
				check(habitat.creatures.size() == expected,"Wrong creature population: %d/%d/%s" % [world,region,cave])
				if expected == 0:
					habitat.free()
					continue
				maps += 1
				total += expected
				var starting_failures := failures
				var poses: Array[Dictionary] = []
				for i in habitat.creatures.size():
					var actor = habitat.creatures[i]
					actor.set_process(false)
					actor.rng.seed = 5051+world*101+region*11+i
					actor.advance(0)
					poses.append({})
					check(actor.can_stand(actor.position),"No safe starting floor: %d/%d/%s actor %d at %s" % [world,region,cave,i,actor.position/LIFE.SCALE])
					if world > 0 and not cave:
						check(actor.kind == (CREATURE.Kind.FROSTLING if world == 1 else CREATURE.Kind.DUNE_SPRITE),"Earth animals appeared on another planet")
					else:
						check(actor.kind in [CREATURE.Kind.RAT,CREATURE.Kind.BAT],"Alien appeared in an Earth mine")
				var player_before: Vector2 = game.player
				var ore_before: int = game.ore
				for frame in 1000:
					for i in habitat.creatures.size():
						var actor = habitat.creatures[i]
						actor.advance(0.1)
						check(actor.can_stand(actor.position),"Creature crossed water/lava/wall, ore or a doorway: %d/%d/%s at %s" % [world,region,cave,actor.position/LIFE.SCALE])
						poses[i][actor.current_frame] = true
						if actor.kind == CREATURE.Kind.BAT:
							check(actor.sprite.position.y < -40,"Bat stopped flying above its floor projection")
				for i in habitat.creatures.size():
					var actor = habitat.creatures[i]
					check(actor.walk_distance > 120 and actor.stops >= 3,"Creature did not roam and pause: %d/%d/%s actor %d, distance %.1f" % [world,region,cave,i,actor.walk_distance])
					check(poses[i].size() >= 3,"Creature did not animate its walk or wings")
				check(game.player == player_before and game.ore == ore_before,"Ambient creatures changed the player or materials")
				habitat.hide()
				for actor in habitat.creatures:
					var before: float = actor.elapsed
					actor._process(5)
					check(actor.elapsed == before,"Hidden wildlife kept advancing")
				var previous: WeakRef = weakref(habitat.creatures[0])
				habitat.free()
				check(previous.get_ref() == null,"Unloaded creature was retained")
				print("Creature check %d/%d/%s: %d actors, %d failures" % [world,region,cave,expected,failures-starting_failures])
	# Local/base actors must not restart on every HUD refresh, or survive a
	# trip into a streamed district, another mine or another planet.
	game.world = 1
	game.set_current_region(0)
	game.underground = false
	game.reset_rocks()
	game.refresh_ui()
	var original: Node2D = game.local_life.creatures[0]
	game.refresh_ui()
	check(game.local_life.creatures[0] == original,"Refreshing the HUD restarted ambient movement")
	game.set_current_region(1)
	game.refresh_ui()
	check(not is_instance_valid(original) and game.local_life.creatures.is_empty(),"Home aliens remained after following a trail")
	var stream = game.earth_stream
	stream.REGIONS = game.regions()
	stream.store_texture("frozen_basin",load(game.regions().ASSETS.frozen_basin))
	stream.show_area(1,false)
	check(stream.scenery.has_node("AmbientLife"),"Streamed district has no ambient creatures")
	var previous: WeakRef = weakref(stream.scenery.get_node("AmbientLife"))
	stream.store_texture("prism_pass",load(game.regions().ASSETS.prism_pass))
	stream.show_area(2,false)
	check(previous.get_ref() == null and stream.textures.size() <= 3,"Streamed wildlife was retained outside the existing cache budget")
	stream.deactivate()
	game.world = 0
	game.set_current_region(0)
	game.underground = true
	game.reset_rocks()
	game.refresh_ui()
	check(game.local_life.creatures.size() == 5,"Moss Mine is missing bats and rats")
	for seed_value in 20:
		game.local_life.clear()
		game.ore_rng.seed = 7001+seed_value*37
		game.reset_rocks()
		game.refresh_ui()
		for actor in game.local_life.creatures:
			actor.advance(0)
			check(actor.can_stand(actor.position),"Moss Mine ore layout left no safe wildlife start")
	game.underground = false
	game.refresh_ui()
	check(game.local_life.creatures.is_empty(),"Mine animals followed the player onto Earth's surface")
	if failures == 0:
		print("PASS: %d themed creatures across %d areas, safe roaming/pauses/animated poses, bats aloft, no player/material effects, hidden pause and local/streamed cleanup" % [total,maps])
	quit(1 if failures else 0)
