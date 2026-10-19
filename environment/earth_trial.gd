extends Node2D

const ART = preload("res://environment/trial_art.gd")
const SNAKE = preload("res://environment/earth_snake.gd")
const FLOOR = preload("res://ore_spawns.gd")
const MAX_HEALTH := 10 # Half-heart units: berries +2, apples +4.
const JAB_SECONDS := 0.32
const JAB_COOLDOWN := 0.42
const SWORD_DAMAGE := 3
const PICK_DAMAGE := 1
var game: Node
var health := MAX_HEALTH
var selected_tool := 0
var invulnerable := 0.0
var jab_time := -1.0
var jab_cooldown := 0.0
var jab_id := 0
var jab_direction := Vector2.DOWN
var jab_origin := Vector2.ZERO
var defeated := 0
var snakes: Array[Node2D] = []
var seconds := 0.0
var was_active := true

func _ready() -> void:
	name = "LandingMeadowTrial"
	y_sort_enabled = true
	for preferred in [Vector2(875,610),Vector2(1510,750),Vector2(650,1080)]:
		var snake := SNAKE.new()
		snake.trial = self
		snake.home = preferred
		var point := find_floor(preferred,snake)
		if not point.is_finite():
			snake.free()
			continue
		snake.position = point
		add_child(snake)
		snakes.append(snake)

func floor_at(point: Vector2) -> bool:
	return FLOOR.can_walk(0,false,point) and FLOOR.green_ground(point)

func find_floor(preferred: Vector2, snake: Node) -> Vector2:
	for ring in range(16):
		for ray in 24:
			var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*10
			if snake.can_stand(point): return point
	return Vector2.INF

func is_active() -> bool:
	return game.world == 0 and game.earth_region == 0 and not game.underground

func blocked() -> bool:
	return game.flight != 0 or game.earth_transition or game.planet_menu.visible or game.hud.help.visible

func sword_equipped() -> bool:
	return is_active() and selected_tool == 1

func equip(index: int) -> void:
	if not is_active() or blocked() or jab_time >= 0 or index not in [0,1]: return
	if game.mining_target >= 0: game.cancel_mining()
	selected_tool = index
	game.walking = false
	game.restore_walk_visual()
	game.refresh_ui()

func start_jab() -> bool:
	if not is_active() or blocked() or jab_time >= 0 or jab_cooldown > 0: return false
	if game.mining_target >= 0: game.cancel_mining()
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
	game.scout.sprite_frames = ART.make_jab_frames()
	game.scout.animation = StringName("jab_"+str(game.facing))
	game.scout.frame = frame
	game.scout.flip_h = game.facing_left
	game.scout.position = game.player
	game.scout.rotation = 0
	ART.fit_jab(game.scout,game.facing,frame)

func check_jab_hits() -> void:
	# Only the narrow area in front of the jab can hit. Each snake remembers
	# this jab's ID, preventing held frames from applying repeated damage.
	var start := jab_origin+jab_direction*12
	var finish := jab_origin+jab_direction*78
	for snake in snakes:
		if snake.health <= 0: continue
		var closest := Geometry2D.get_closest_point_to_segment(snake.position,start,finish)
		if snake.position.distance_to(closest) < 25 and (snake.position-jab_origin).dot(jab_direction) > 8:
			var clear := true
			var steps := maxi(1,ceili(jab_origin.distance_to(snake.position)/8.0))
			for i in range(steps+1):
				if not floor_at(jab_origin.lerp(snake.position,float(i)/steps)):
					clear = false
					break
			if clear: snake.take_hit(jab_id,jab_origin,SWORD_DAMAGE if selected_tool == 1 else PICK_DAMAGE)

func advance(delta: float) -> void:
	var active := is_active()
	visible = active and game.flight == 0 and not game.earth_transition
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
	if game.player.distance_to(game.CAMP) < 230: return false
	health = maxi(0,health-amount)
	invulnerable = 1.3
	game.message = "A small bite! Berries heal one heart; apples heal two."
	if health == 0:
		if game.mining_target >= 0: game.cancel_mining()
		jab_time = -1
		game.player = Vector2(560,550)
		game.scout.position = game.player
		health = MAX_HEALTH
		invulnerable = 2.5
		game.camera.position = game.player
		game.camera.reset_smoothing()
		game.restore_walk_visual()
		game.message = "Back at camp, feeling better. Your materials are safe."
	game.refresh_ui()
	return true

func heal(amount: int) -> int:
	var before := health
	health = mini(MAX_HEALTH,health+maxi(0,amount))
	return health-before
