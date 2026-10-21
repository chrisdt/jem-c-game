extends Node2D

const ART = preload("res://environment/trial_art.gd")
const SNAKE = preload("res://environment/earth_snake.gd")
const FLOOR = preload("res://ore_spawns.gd")
const MINE = preload("res://mine_layout.gd")
const HOMES := {
	0:[Vector2(875,610),Vector2(1510,750),Vector2(650,1080)],
	1:[Vector2(880,573),Vector2(1347,880)],
	2:[Vector2(867,440),Vector2(1587,960)],
	3:[Vector2(693,680),Vector2(1550,535)],
	4:[Vector2(800,693),Vector2(1373,827)],
}
const SWORD_COPPER := 3
const SWORD_WOOD := 2
const DRILL_COPPER := 5
const MAX_HEALTH := 10 # Half-heart units: berries +2, apples +4.
const JAB_SECONDS := 0.32
const JAB_COOLDOWN := 0.42
const SWORD_DAMAGE := 3
const PICK_DAMAGE := 1
var game: Node
var health := MAX_HEALTH
var selected_tool := 0
var sword_owned := false
var wood := 0
var invulnerable := 0.0
var jab_time := -1.0
var jab_cooldown := 0.0
var jab_id := 0
var jab_direction := Vector2.DOWN
var jab_origin := Vector2.ZERO
var defeated := 0
var snakes: Array[Node2D] = []
var seconds := 0.0
var heal_clock := 0.0
var was_active := true
var active_area := -1
var records: Dictionary = {}
var mine_health: Dictionary = {}
var mine_defeated := 0
var encounter_areas: Dictionary = {}
var encounter_rng := RandomNumberGenerator.new()
var encounter_count := 0

func _ready() -> void:
	name = "EarthAdventure"
	y_sort_enabled = true
	encounter_rng.randomize()
	sync_area()

func sync_area() -> void:
	visible = game.world == 0 and not game.underground and game.flight == 0 and not game.earth_transition
	if game.flight != 0 or game.earth_transition: return
	var area: int = game.area_id()
	if area == active_area: return
	if game.current_region() > 0 and not game.earth_stream.textures.has(game.regions().key(game.current_region(),game.underground)): return
	if active_area >= 0:
		records[active_area] = []
		for snake in snakes:
			records[active_area].append({"spawn_id":snake.spawn_id,"home":snake.home,"position":snake.position,"health":snake.health,"seen":snake.seen,"fade":snake.fade,"phase":snake.phase,"fear_seconds":snake.fear_seconds,"scare_cooldown":snake.scare_cooldown,"target":snake.target})
	for snake in snakes:
		remove_child(snake)
		snake.free()
	snakes.clear()
	active_area = area
	jab_time = -1
	if game.world != 0 or game.underground: return
	if records.has(area):
		for record in records[area]:
			var snake := SNAKE.new()
			snake.trial = self
			snake.spawn_id = record.get("spawn_id","")
			snake.position = record.position
			add_child(snake)
			snake.home = record.home
			snake.health = record.health
			snake.seen = record.seen
			snake.fade = record.fade
			snake.phase = record.phase
			snake.fear_seconds = record.get("fear_seconds",0.0)
			snake.scare_cooldown = record.get("scare_cooldown",0.0)
			snake.target = record.get("target",record.position)
			snake.state = "gone" if snake.health <= 0 else ("flee" if snake.fear_seconds > 0 else "recover")
			snake.visible = snake.health > 0
			snake.update_pose()
			snakes.append(snake)
		return
	for slot in HOMES[game.earth_region].size():
		var preferred: Vector2 = HOMES[game.earth_region][slot]
		var snake := SNAKE.new()
		snake.trial = self
		snake.spawn_id = "%d/%d" % [game.earth_region,slot]
		snake.home = preferred
		var point := find_floor(preferred,snake)
		if not point.is_finite():
			snake.free()
			continue
		snake.position = point
		add_child(snake)
		snakes.append(snake)

func floor_at(point: Vector2) -> bool:
	if game.world != 0:
		return game.regions().can_walk(game.current_region(),game.underground,point) if game.current_region() > 0 else (game.FROST_LAYOUT.can_walk(point,game.underground) if game.world == 1 else game.DESERT_LAYOUT.can_walk(point,game.underground))
	if game.earth_region > 0: return game.EARTH.can_walk(game.earth_region,game.underground,point)
	if game.underground: return MINE.can_walk(point)
	return FLOOR.can_walk(0,false,point) and FLOOR.green_ground(point)

func clear_line(start: Vector2, finish: Vector2) -> bool:
	var steps := maxi(1,ceili(start.distance_to(finish)/6.0))
	for i in range(steps+1):
		if not floor_at(start.lerp(finish,float(i)/steps)): return false
	return true

func safe_at(point: Vector2) -> bool:
	if game.world != 0:
		if game.underground: return point.distance_to(game.mine_spawn_position()) < 110 or point.distance_to(game.exit_position()) < 110
		if game.has_base() and (point.distance_to(game.ship_position()) < 160 or point.distance_to(game.camp_position()) < 175): return true
		for person in game.frost_story.npcs:
			if game.world == 1 and person.home_region == game.current_region() and point.distance_to(person.position) < 105: return true
		for link in game.regions().LINKS[game.current_region()]:
			if point.distance_to(game.regions().portal(game.current_region(),link.side)) < 130: return true
		return false
	if game.underground:
		return point.distance_to(game.exit_position()) < 140 or point.distance_to(game.mine_spawn_position()) < 95
	if game.earth_region == 0 and point.distance_to(game.CAMP) < 230: return true
	for npc in game.npcs:
		if is_instance_valid(npc) and not npc.departed and npc.home_region == game.earth_region and point.distance_to(npc.position) < 85: return true
	for link in game.EARTH.LINKS[game.earth_region]:
		if point.distance_to(game.EARTH.portal(game.earth_region,link.side)) < 130: return true
	return false

func find_floor(preferred: Vector2, snake: Node) -> Vector2:
	for ring in range(16):
		for ray in 24:
			var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*10
			if snake.can_stand(point): return point
	return Vector2.INF

func is_active() -> bool:
	return true

func blocked() -> bool:
	return game.get_tree().paused or game.flight != 0 or game.earth_transition or game.menu_open() or game.hud.help.visible

func mining_encounter(rock: Dictionary) -> bool:
	# One chance per deposit, and at most one mining alert per area. Resuming
	# work, visiting another district or flying home cannot farm encounters.
	if game.world != 0 or not is_active() or blocked() or not sword_owned or safe_at(game.player) or rock.get("encounter_checked",false): return false
	rock["encounter_checked"] = true
	if encounter_areas.has(game.area_id()) or encounter_rng.randf() >= 0.35: return false
	var enemy: Node2D
	var nearby := 0
	for candidate in targets():
		if candidate.health <= 0 or candidate.state in ["gone","puff","flee"]: continue
		var distance: float = candidate.position.distance_to(game.player)
		if distance < 230: nearby += 1
		if distance < 185 and game.fog.is_revealed(game.area_id(),candidate.position) and clear_line(candidate.position,game.player):
			enemy = candidate
	# Avoid adding another threat to an existing close fight.
	if nearby > 1: return false
	if enemy == null and not game.underground:
		if snakes.filter(func(s): return s.health > 0).size() >= 4: return false
		var snake := SNAKE.new()
		snake.trial = self
		for ring in [140.0,165.0,185.0]:
			for ray in 24:
				var point: Vector2 = game.player+Vector2.from_angle(ray*TAU/24.0)*ring
				snake.home = point
				if snake.can_stand(point) and clear_line(point,game.player) and game.fog.is_revealed(game.area_id(),point):
					snake.position = point
					enemy = snake
					break
			if enemy != null: break
		if enemy == null:
			snake.free()
			return false
		add_child(snake)
		snakes.append(snake)
	if enemy == null: return false
	if game.underground:
		enemy.state = "alert"
		enemy.state_time = 0
	else:
		enemy.seen = true
		enemy.state = "stir"
		enemy.clock = 0
		enemy.update_pose()
	encounter_areas[game.area_id()] = true
	encounter_count += 1
	game.message = "Something stirred nearby! Move to pause mining, defend yourself, then return to finish this deposit."
	return true

func sword_equipped() -> bool:
	return is_active() and sword_owned and selected_tool == 1

func equip(index: int) -> void:
	if not is_active() or blocked() or jab_time >= 0 or index not in [0,1]: return
	if index == 1 and not sword_owned:
		game.message = "Craft a sword at Earth camp: 3 copper + 2 wood. Find fallen branches along the trails."
		game.refresh_ui()
		return
	if game.mining_target >= 0: game.cancel_mining()
	if is_instance_valid(game.story): game.story.cancel_work()
	if is_instance_valid(game.frost_story): game.frost_story.cancel_work()
	selected_tool = index
	game.walking = false
	game.restore_walk_visual()
	game.refresh_ui()

func start_jab() -> bool:
	if not is_active() or blocked() or jab_time >= 0 or jab_cooldown > 0: return false
	if selected_tool == 1 and not sword_owned: return false
	if game.mining_target >= 0: game.cancel_mining()
	if is_instance_valid(game.story): game.story.cancel_work()
	if is_instance_valid(game.frost_story): game.frost_story.cancel_work()
	jab_direction = Vector2.UP if game.facing == &"up" else (Vector2.DOWN if game.facing == &"down" else (Vector2.LEFT if game.facing_left else Vector2.RIGHT))
	jab_origin = game.player
	jab_time = 0
	jab_cooldown = JAB_COOLDOWN
	jab_id += 1
	game.walking = false
	game.walk_distance = 0
	update_jab_pose()
	return true

func update_jab_pose() -> void:
	if jab_time < 0: return
	if selected_tool == 0:
		# Reuse the illustrated mining swing, without starting a mining job or
		# changing its progress. A fitted drill uses its own braced poses.
		var pose := 0 if jab_time < 0.065 else (1 if jab_time < 0.20 else 2)
		game.set_mining_pose(pose)
		return
	var frame := 1 if jab_time < 0.065 else (2 if jab_time < 0.19 else (3 if jab_time < 0.27 else 0))
	var frozen_art: bool = game.world > 0 or game.frost_story.frostfang
	game.scout.material = null
	game.scout.sprite_frames = game.FROST_ART.make_jab_frames(game.world > 0) if frozen_art else ART.make_jab_frames()
	game.scout.animation = StringName("jab_"+str(game.facing))
	game.scout.frame = frame
	game.scout.flip_h = game.facing_left
	game.scout.position = game.player
	game.scout.rotation = 0
	if frozen_art: game.FROST_ART.fit_jab(game.scout,game.world > 0,game.facing,frame,not game.frost_story.frostfang)
	else: ART.fit_jab(game.scout,game.facing,frame)

func check_jab_hits() -> void:
	# Only the narrow area in front of the jab can hit. Each snake remembers
	# this jab's ID, preventing held frames from applying repeated damage.
	var start := jab_origin+jab_direction*12
	var finish := jab_origin+jab_direction*78
	for enemy in targets():
		if enemy.health <= 0: continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.position,start,finish)
		if enemy.position.distance_to(closest) < 25 and (enemy.position-jab_origin).dot(jab_direction) > 8 and clear_line(jab_origin,enemy.position):
			var damage: int = (7 if game.frost_story.frostfang else (5 if is_instance_valid(game.story) and game.story.sword_improved else SWORD_DAMAGE)) if selected_tool == 1 else PICK_DAMAGE
			if enemy.take_hit(jab_id,jab_origin,damage) and game.frost_story.frostfang and selected_tool == 1:
				enemy.set_meta("frost_slow",1.25)

func targets() -> Array:
	if not is_active(): return []
	if game.world == 1: return game.frost_story.yetis
	if game.world != 0: return []
	if not game.underground: return snakes
	var habitat: Node = game.local_life if game.earth_region == 0 else (game.earth_stream.scenery.get_node_or_null("AmbientLife") if is_instance_valid(game.earth_stream.scenery) else null)
	return habitat.creatures if habitat != null else []

func advance(delta: float) -> void:
	sync_area()
	var active := is_active()
	visible = active and not game.underground and game.flight == 0 and not game.earth_transition
	if active != was_active or game.flight != 0 or game.earth_transition:
		if jab_time >= 0:
			jab_time = -1
			game.restore_walk_visual()
		game.scout.modulate = Color.WHITE
		was_active = active
	if not active or blocked(): return
	var remaining := maxf(0,delta)
	while remaining > 0.00001:
		var step := minf(remaining,1.0/120.0)
		remaining -= step
		seconds += step
		if game.world == 1 and not game.underground and game.current_region() == 0 and game.player.distance_to(game.ICE_CAMP) < 150:
			heal_clock += step
			if heal_clock >= 1.5:
				heal(1)
				heal_clock = 0
		else: heal_clock = 0
		invulnerable = maxf(0,invulnerable-step)
		jab_cooldown = maxf(0,jab_cooldown-step)
		if jab_time >= 0:
			jab_time += step
			if jab_time >= 0.065 and jab_time <= 0.20: check_jab_hits()
			if jab_time >= JAB_SECONDS:
				jab_time = -1
				game.restore_walk_visual()
			else: update_jab_pose()
		for snake in snakes: snake.advance(step)
	game.scout.modulate = Color(1.3,0.78,0.65,0.66+0.34*sin(seconds*35)) if invulnerable > 0 and invulnerable < 1.3 else Color.WHITE

func hurt_player(amount: int) -> bool:
	if not is_active() or blocked() or invulnerable > 0 or amount <= 0: return false
	if safe_at(game.player): return false
	health = maxi(0,health-amount)
	if game.mining_target >= 0: game.cancel_mining()
	if is_instance_valid(game.story): game.story.cancel_work()
	if is_instance_valid(game.frost_story): game.frost_story.cancel_work()
	invulnerable = 1.3
	game.message = "A yeti hit! Return to Canyon Camp to warm up and recover." if game.world == 1 else "A small bite! Berries heal one heart; apples heal two."
	if health == 0:
		if game.mining_target >= 0: game.cancel_mining()
		jab_time = -1
		game.player = game.mine_spawn_position() if game.underground else ((game.EARTH_START if game.world == 0 else game.surface_arrival_position()) if game.current_region() == 0 else game.regions().arrival(game.current_region(),game.regions().LINKS[game.current_region()][0].side))
		game.scout.position = game.player
		health = MAX_HEALTH
		invulnerable = 2.5
		game.camera.position = game.player
		game.camera.reset_smoothing()
		game.restore_walk_visual()
		game.message = "A safe place to recover. Your materials and crafted tools are safe."
	game.refresh_ui()
	return true

func heal(amount: int) -> int:
	var before := health
	health = mini(MAX_HEALTH,health+maxi(0,amount))
	return health-before
