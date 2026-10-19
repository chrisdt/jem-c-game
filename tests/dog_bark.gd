extends SceneTree

const CREATURE = preload("res://environment/ambient_creature.gd")
const EARTH = preload("res://earth_regions.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		if failures < 20: push_error(message)

func near_spot(dog, creature) -> Vector2:
	for radius in [65.0,95.0,120.0]:
		for ray in 16:
			var point: Vector2 = creature.position+Vector2.from_angle(ray*TAU/16)*radius
			if dog.can_stand(point) and dog.clear_route(point,creature.position,false): return point
	return Vector2.INF

func wall_pair(dog) -> Array[Vector2]:
	for y in range(240,1180,32):
		for x in range(160,1800,32):
			var point := Vector2(x,y)
			if not dog.can_stand(point): continue
			for ray in 8:
				var other := point+Vector2.from_angle(ray*TAU/8)*120
				if dog.can_stand(other) and not dog.clear_route(point,other,false): return [point,other]
	return []

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var dog = game.companion
	dog.set_process(false)
	dog.recruited = true
	var groups := 0
	var fled := 0
	for region in [0,1,4]:
		game.world = 0
		game.earth_region = region
		game.underground = true
		game.ore_rng.seed = 7003+region*37
		game.reset_rocks()
		if region > 0:
			var key := EARTH.key(region,true)
			game.earth_stream.store_texture(key,load(EARTH.ASSETS[key]))
			game.earth_stream.show_area(region,true)
		game.player = game.mine_spawn_position()
		game.refresh_ui()
		var habitat: Node = game.local_life if region == 0 else game.earth_stream.scenery.get_node("AmbientLife")
		check(habitat.creatures.size() == 5,"Mine did not begin with five critters")
		for creature in habitat.creatures:
			creature.set_process(false)
			creature.advance(0)
		# Nearby critters across real mine walls must not react.
		if region == 0:
			var pair := wall_pair(dog)
			check(pair.size() == 2,"No real mine wall fixture")
			if pair.size() == 2:
				for creature in habitat.creatures: creature.hide()
				var rat = habitat.creatures[0]
				var before: Vector2 = rat.position
				rat.position = pair[1]
				rat.show()
				dog.position = pair[0]
				game.player = pair[0]
				game.update_exploration()
				check(not dog.try_bark(),"Buddy barked through a solid mine wall")
				rat.position = before
				for creature in habitat.creatures: creature.show()
		for kind in [CREATURE.Kind.RAT,CREATURE.Kind.BAT]:
			var targets: Array = habitat.creatures.filter(func(c): return c.kind == kind and c.state not in ["flee","puff","gone"])
			if targets.is_empty(): continue
			var target = targets[0]
			var point := near_spot(dog,target)
			check(point.is_finite(),"No clear approach to a mine critter")
			if not point.is_finite(): continue
			dog.position = point
			game.player = point
			game.update_exploration()
			dog.bark_cooldown = 0
			dog.bark_remaining = 0
			var count_before: int = dog.bark_count
			if groups == 0:
				dog.recruited = false
				check(not dog.try_bark(),"Unrecruited dog scared wildlife")
				dog.recruited = true
				game.planet_menu.visible = true
				check(not dog.try_bark(),"Dog barked behind a menu")
				game.planet_menu.visible = false
				game.earth_transition = true
				check(not dog.try_bark(),"Dog barked during a loading fade")
				game.earth_transition = false
				dog.hide()
				check(not dog.try_bark(),"Hidden dog scared wildlife")
				dog.show()
				game.fog.maps.erase(game.area_id())
				game.fog.active_map = -1
				check(not dog.try_bark(),"Dog scared an unexplored critter")
				game.update_exploration()
			check(dog.try_bark(),"Buddy did not bark at a nearby rat or bat")
			check(dog.state == "bark" and dog.bark_count == count_before+1,"Bark pose/count missing")
			check(not dog.bark_audio.playing and dog.bark_audio.stream.get_length() > 0.5,"Silent gameplay started bark audio")
			check(not dog.try_bark() and dog.bark_count == count_before+1,"Bark cooldown allowed spam")
			var player_before: Vector2 = game.player
			var ore_before: int = game.ore
			var affected: Array = habitat.creatures.filter(func(c): return c.state in ["flee","puff"])
			check(not affected.is_empty(),"Bark did not scare any creatures")
			var starts: Array = affected.map(func(c): return c.position)
			var moving := false
			var puff := false
			for frame in 40:
				for i in affected.size():
					var creature = affected[i]
					creature.advance(0.05)
					check(creature.can_stand(creature.position),"Fleeing creature crossed a wall, pool, ore, doorway or leash")
					moving = moving or creature.position.distance_to(starts[i]) > 1
					puff = puff or creature.state == "puff"
					check(creature.get_child_count() == 1,"Smoke accumulated effect nodes")
			for creature in affected:
				check(creature.state == "gone" and not creature.visible and not creature.is_processing(),"Critter or smoke did not disappear")
			check(moving and puff,"Missing escape motion or smoke puff")
			check(game.player == player_before and game.ore == ore_before,"Scaring wildlife changed player position or materials")
			dog.advance(3.3)
			check(dog.bark_cooldown == 0,"Bark cooldown did not expire")
			groups += 1
			fled += affected.size()
		# Recreating scenery must preserve stable slots even after the first
		# rat is omitted, rather than renumbering and resurrecting later actors.
		var saved: Dictionary = game.scared_wildlife[game.area_id()].duplicate()
		if region == 0:
			game.local_life.clear()
			game.refresh_ui()
			habitat = game.local_life
		else:
			game.earth_stream.show_area(region,true)
			habitat = game.earth_stream.scenery.get_node("AmbientLife")
		check(habitat.creatures.size() == 5-saved.size(),"Scared critters respawned after returning to a mine")
		for creature in habitat.creatures: check(not saved.has(creature.scare_id),"Creature IDs shifted after another disappeared")
		print("Bark check: mine %d, %d critters remembered" % [region,saved.size()])
	# Standalone escape timing uses the same swept steps at low/high frame rates.
	var results: Array[Vector2] = []
	for fps in [30,144]:
		var rat := CREATURE.new()
		rat.kind = CREATURE.Kind.RAT
		rat.terrain = func(_point: Vector2) -> bool: return true
		rat.wander_radius = 500
		root.add_child(rat)
		rat.set_process(false)
		rat.scare_from(Vector2(-100,0))
		for frame in fps/2: rat.advance(1.0/fps)
		results.append(rat.position)
		rat.advance(2)
		check(rat.state == "gone","Slow-frame escape left a critter behind")
		rat.free()
	check(results[0].distance_to(results[1]) < 0.1,"Flee speed depends on frame rate")
	var alien := CREATURE.new()
	alien.terrain = func(_point: Vector2) -> bool: return true
	root.add_child(alien)
	alien.set_process(false)
	check(not alien.scare_from(Vector2.ZERO),"Alien was scared like an Earth mine animal")
	alien.free()
	dog.bark_audio.stop()
	game.free()
	await process_frame
	await process_frame
	if failures == 0:
		print("PASS: %d bark groups / %d fleeing critters in all three Earth mines; sound/poses, range/visibility/walls/cooldown, safe fleeing and smoke cleanup, stable session memory and frame-rate-independent escape" % [groups,fled])
	quit(1 if failures else 0)
