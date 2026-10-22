extends SceneTree

const TRAVEL = preload("res://tests/support/area_travel.gd")
const CREATURE = preload("res://environment/ambient_creature.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		if failures < 25: push_error(description)

func open_floor(game) -> Vector2:
	for y in range(220,1170,28):
		for x in range(180,1790,28):
			var point := Vector2(x,y)
			if game.trial.safe_at(point): continue
			var fits := true
			for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				for length in [0.0,30.0,60.0,90.0]:
					if not game.trial.floor_at(point+d*length): fits = false
			for direction in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				for probe in [Vector2.ZERO,Vector2.LEFT*10,Vector2.RIGHT*10,Vector2.UP*10,Vector2.DOWN*10]:
					if not game.trial.targets()[0].terrain.call(point+direction*57+probe): fits = false
			for rock in game.rocks:
				if rock.cave and point.distance_to(rock.pos) < 175: fits = false
			if fits: return point
	return Vector2.INF

func prepare(game, enemy, origin: Vector2, direction: Vector2) -> void:
	game.trial.jab_time = -1
	game.trial.jab_cooldown = 0
	game.trial.invulnerable = 0
	game.trial.health = 10
	game.player = origin
	game.scout.position = origin
	game.face_direction(direction)
	game.restore_walk_visual()
	enemy.health = enemy.max_health()
	enemy.position = origin+direction*57
	enemy.home = origin
	enemy.wander_radius = 250
	enemy.wander_bounds = Rect2()
	enemy.target = enemy.position
	enemy.state = "rest"
	enemy.state_time = 0
	enemy.settled = true
	enemy.last_jab = -1
	enemy.show()
	enemy.sprite.show()
	game.fog.observe(game.area_id(),enemy.position)
	game.update_exploration()
	enemy.update_pose()

func wall_pair(game) -> Array[Vector2]:
	for y in range(200,1200,24):
		for x in range(160,1800,24):
			var point := Vector2(x,y)
			if not game.trial.floor_at(point) or game.trial.safe_at(point): continue
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				var other: Vector2 = point+direction*90
				if game.trial.floor_at(other) and not game.trial.clear_line(point,other): return [point,other]
	return []

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.companion.set_process(false)
	game.trial.sword_owned = true
	game.trial.selected_tool = 1
	for world in range(3):
		if world > 0:
			game.travel_to_other_planet(world)
			game.advance_flight(10)
		for region in [0,1,4]:
			await TRAVEL.enter(game,region,true)
			print("COMBAT ",world,"/",region)
			var habitat: Node = game.local_life if region == 0 else game.earth_stream.scenery.get_node("AmbientLife")
			check(habitat.creatures.size() == 5,"Mine did not begin with its two rats and three bats")
			for enemy in habitat.creatures:
				enemy.set_process(false)
				enemy.health = 0
				enemy.state = "gone"
				enemy.hide()
			var origin := open_floor(game)
			check(origin.is_finite(),"Mine has no clear combat fixture")
			if not origin.is_finite(): continue
			var ids: Array[int] = []
			for kind in [CREATURE.Kind.RAT,CREATURE.Kind.BAT]:
				var enemy: Node = habitat.creatures.filter(func(c): return c.kind == kind)[0]
				check(enemy.hostile,"Mine rat/bat is still passive")
				var wall := wall_pair(game)
				check(wall.size() == 2,"No narrow mine wall fixture")
				if wall.size() == 2:
					prepare(game,enemy,wall[0],(wall[1]-wall[0]).normalized())
					enemy.position = wall[1]
					game.fog.observe(game.area_id(),enemy.position)
					game.trial.start_jab()
					game.trial.advance(0.12)
					check(enemy.health == enemy.max_health(),"Sword hit a mine foe through a solid wall")
					enemy.advance(0.8)
					check(game.trial.health == 10,"Mine foe attacked through a solid wall")
				for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
					prepare(game,enemy,origin,direction)
					check(game.trial.start_jab(),"Sword could not attack in a mine")
					game.trial.advance(0.12)
					check(enemy.health == enemy.max_health()-3,"Directional mine sword hit dealt the wrong damage %d/%d kind=%d dir=%s active=%s at=%s" % [world,region,kind,direction,enemy.hostile_active(),origin])
					check(not enemy.take_hit(game.trial.jab_id,game.player,3),"One jab struck a mine creature twice")
					game.trial.advance(0.5)
				prepare(game,enemy,origin,Vector2.RIGHT)
				game.trial.selected_tool = 0
				game.trial.start_jab()
				game.trial.advance(0.12)
				check(enemy.health == enemy.max_health()-1,"Mine pick attack is not weaker than the sword")
				game.trial.advance(0.5)
				game.trial.selected_tool = 1
				# A warned real lunge causes one half-heart hit, then recovery.
				prepare(game,enemy,origin,Vector2.RIGHT)
				enemy.advance(0.20)
				check(enemy.state == "warn" and game.trial.health == 10,"Mine enemy attacked without a warning")
				enemy.advance(0.40)
				check(game.trial.health == 9,"Mine attack did not remove exactly half a heart")
				enemy.advance(0.3)
				check(game.trial.health == 9,"One mine lunge applied repeated contact damage")
				game.planet_menu.open(0)
				var clock: float = enemy.state_time
				enemy.advance(2)
				check(enemy.state_time == clock and not game.trial.start_jab(),"Mine combat advanced behind a menu")
				game.planet_menu.dismiss()
				game.hud.help.show()
				enemy.advance(2)
				check(enemy.state_time == clock,"Mine enemy advanced behind help")
				game.hud.help.hide()
				game.camp_menu.show()
				enemy.advance(2)
				check(enemy.state_time == clock,"Mine enemy advanced behind crafting")
				game.camp_menu.dismiss()
				game.player = game.mine_spawn_position()
				game.trial.invulnerable = 0
				check(not game.trial.hurt_player(1),"Mine arrival has no safe recovery area")
				# Repeated AI steps stay inside real floor and leash constraints.
				prepare(game,enemy,origin,Vector2.RIGHT)
				game.trial.invulnerable = 10000
				for frame in 300:
					enemy.advance(1.0/60.0)
					check(enemy.can_stand(enemy.position),"Hostile rat/bat crossed floor %d/%d kind=%d at=%s" % [world,region,kind,enemy.position])
				# Zero health restores the player at the mine's safe spawn with gear.
				game.player = origin
				game.trial.health = 1
				game.trial.invulnerable = 0
				game.ore = 7
				game.trial.wood = 3
				check(game.trial.hurt_player(1) and game.trial.health == 10,"Mine defeat did not recover full health")
				check(game.player == game.mine_spawn_position() and game.ore == 7 and game.trial.wood == 3 and game.trial.sword_owned,"Mine recovery lost materials or equipment")
				# Sword defeats puff in place and stay removed after unloading.
				prepare(game,enemy,origin,Vector2.RIGHT)
				for strike in range(enemy.max_health()/3):
					# Re-centre the fixture after knockback before each real jab.
					enemy.position = origin+Vector2.RIGHT*57
					game.player = origin
					game.face_direction(Vector2.RIGHT)
					game.trial.jab_cooldown = 0
					game.trial.start_jab()
					game.trial.advance(0.15)
					game.trial.advance(0.5)
				check(enemy.health == 0 and enemy.state == "puff","Defeated mine enemy did not turn into smoke %d/%d kind=%d hp=%d state=%s origin=%s enemy=%s" % [world,region,kind,enemy.health,enemy.state,origin,enemy.position])
				enemy.advance(1)
				check(enemy.state == "gone" and not enemy.visible,"Mine enemy smoke did not clean up")
				ids.append(enemy.scare_id)
			var partial: Node = habitat.creatures.filter(func(c): return c.kind == CREATURE.Kind.RAT)[1]
			prepare(game,partial,origin,Vector2.RIGHT)
			check(partial.take_hit(7777,game.player,3),"Partial mine hit was rejected")
			var partial_id: int = partial.scare_id
			await TRAVEL.enter(game,region,false)
			await TRAVEL.enter(game,region,true)
			habitat = game.local_life if region == 0 else game.earth_stream.scenery.get_node("AmbientLife")
			check(habitat.creatures.all(func(c): return c.scare_id not in ids),"Defeated rat or bat respawned on mine return")
			var restored: Array = habitat.creatures.filter(func(c): return c.scare_id == partial_id)
			check(restored.size() == 1 and restored[0].health == 3,"Unloading reset a surviving rat's partial damage")
			# Buddy's existing bark cancels a threat and preserves removal memory.
			if not restored.is_empty():
				var enemy: Node = restored[0]
				enemy.set_process(false)
				enemy.advance(0)
				check(enemy.scare_from(game.player),"A hostile rat cannot be scared off")
				var before: int = game.trial.health
				enemy.advance(2)
				check(enemy.state == "gone" and game.trial.health == before,"Scared mine enemy still attacked")
			await TRAVEL.enter(game,region,false)
	game.queue_free()
	await process_frame
	await process_frame
	if failures == 0: print("PASS: all nine Earth/Frost/Ember mines, four-direction sword hits on rats/bats, weaker pick damage, warned half-heart lunges and invulnerability, menu/help/craft pause, safe terrain/arrival/recovery, smoke cleanup, partial-health/defeat memory and scare cancellation")
	quit(1 if failures else 0)
