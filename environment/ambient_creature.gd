extends Node2D

enum Kind { FROSTLING, DUNE_SPRITE, RAT, BAT }
const ART: Texture2D = preload("res://assets/creatures/ambient_creatures.png")
const FACING = preload("res://environment/wildlife_facing.gd")
const VERTICAL = preload("res://environment/wildlife_vertical.gd")
const STYLE = preload("res://ui/expedition_style.gd")
# The painted poses have different padding. Atlas regions and individual foot
# anchors keep the body steady without trimming or resampling the source art.
const ROWS := [Vector2(55,310),Vector2(397,310),Vector2(745,210),Vector2(980,220)]
const COLUMNS := [[0,313,627,941,1254],[0,313,627,941,1254],[0,313,640,941,1254],[0,313,624,964,1254]]
const ANCHORS := [
	[Vector2(167,348),Vector2(482,345),Vector2(790,346),Vector2(1105,348)],
	[Vector2(167,685),Vector2(482,690),Vector2(790,689),Vector2(1105,691)],
	[Vector2(173,932),Vector2(484,931),Vector2(800,932),Vector2(1100,932)],
	[Vector2(197,1139),Vector2(510,1143),Vector2(814,1142),Vector2(1113,1145)],
]
const ART_SCALES := [0.22,0.22,0.13,0.18]
const SPEEDS := [23.0,28.0,46.0,38.0]
static var frames: Dictionary = {}

var kind: Kind = Kind.FROSTLING
var terrain: Callable
var game: Node
var cave := false
var landmarks: Array[Vector2] = []
var home := Vector2.ZERO
var wander_radius := 175.0
var wander_bounds := Rect2()
var rng := RandomNumberGenerator.new()
var sprite: Sprite2D
var target := Vector2.ZERO
var previous_stop := Vector2.ZERO
var state := "rest"
var state_time := 0.0
var rest_seconds := 1.0
var walk_distance := 0.0
var stops := 0
var elapsed := 0.0
var flight_phase := 0.0
var settled := false
var facing := Vector2.RIGHT
var size_variation := 1.0
var speed := 23.0
var current_frame := -1
const FLEE_SECONDS := 0.75
const PUFF_SECONDS := 0.6
var scare_id := -1
var scare_area := -1
var smoke_centre := Vector2.ZERO
var hostile := false
var health := 6
var last_jab := -1
var hit_flash := 0.0
var health_seconds := 0.0
var strike_done := false

func max_health() -> int:
	return 3 if kind == Kind.BAT else 6

func hostile_active() -> bool:
	return hostile and is_instance_valid(game) and game.world == 0 and game.underground and game.area_id() == scare_area

func _ready() -> void:
	rng.randomize()
	home = position
	previous_stop = position
	size_variation = rng.randf_range(0.92,1.06)
	speed = SPEEDS[kind] * rng.randf_range(0.9,1.12)
	flight_phase = rng.randf_range(0,TAU)
	rest_seconds = rng.randf_range(0.5,3.5)
	sprite = Sprite2D.new()
	sprite.name = "IllustratedCreature"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	if not frames.has(kind):
		var poses: Array[AtlasTexture] = []
		for i in 4:
			var texture := AtlasTexture.new()
			texture.atlas = ART
			texture.region = Rect2(COLUMNS[kind][i],ROWS[kind].x,COLUMNS[kind][i+1]-COLUMNS[kind][i],ROWS[kind].y)
			texture.filter_clip = true
			poses.append(texture)
		frames[kind] = poses
	update_pose()

func _process(delta: float) -> void:
	if is_visible_in_tree(): advance(delta)

func can_stand(point: Vector2) -> bool:
	if point.distance_to(home) > wander_radius or not terrain.is_valid(): return false
	if wander_bounds.has_area() and not wander_bounds.has_point(point): return false
	var footprint := 10.0 if kind in [Kind.RAT,Kind.BAT] else 15.0
	for offset in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		if not terrain.call(point+offset*footprint): return false
	for landmark in landmarks:
		if point.distance_to(landmark) < 130: return false
	if is_instance_valid(game) and game.has_method("area_id"):
		for rock in game.rocks:
			if rock.cave == cave and rock.hp > 0 and point.distance_to(rock.pos) < 78: return false
	return true

func clear_route(finish: Vector2) -> bool:
	var steps := maxi(1,ceili(position.distance_to(finish)/4.0))
	for i in range(1,steps+1):
		if not can_stand(position.lerp(finish,float(i)/steps)): return false
	return true

func room_to_wander(point: Vector2) -> bool:
	if not can_stand(point): return false
	for i in 12:
		var direction := Vector2.from_angle(i*TAU/12.0)
		if can_stand(point+direction*18) and can_stand(point+direction*36): return true
	return false

func find_start() -> Vector2:
	if room_to_wander(home): return home
	for ring in range(1,9):
		for ray in 24:
			var point := home+Vector2.from_angle(ray*TAU/24.0)*wander_radius*ring/8.0
			if room_to_wander(point): return point
	return home

func choose_target() -> void:
	for attempt in 48:
		var direction := Vector2.from_angle(rng.randf()*TAU)
		var point := position+direction*rng.randf_range(28,95) if attempt < 32 else home+direction*sqrt(rng.randf())*wander_radius
		if position.distance_to(point) >= 18 and clear_route(point):
			previous_stop = position
			target = point
			state = "walk"
			state_time = 0
			return
	if position.distance_to(previous_stop) >= 18 and clear_route(previous_stop):
		target = previous_stop
		previous_stop = position
		state = "walk"
		state_time = 0
		return
	rest()

func rest() -> void:
	state = "rest"
	state_time = 0
	stops += 1
	rest_seconds = rng.randf_range(0.7,1.8) if kind == Kind.BAT else rng.randf_range(1.5,4.0)

func advance(delta: float) -> void:
	if state == "gone": return
	if hostile and (not hostile_active() or game.trial.blocked()): return
	if state in ["flee","puff"]:
		advance_escape(delta)
		return
	if not settled:
		position = find_start()
		previous_stop = position
		settled = true
	if hostile:
		advance_hostile(delta)
		return
	var remaining := maxf(0,delta)
	while remaining > 0.00001:
		var step := minf(remaining,0.05)
		elapsed += step
		state_time += step
		wander_step(step)
		remaining -= step
	update_pose()
	queue_redraw()

func wander_step(step: float) -> void:
	if state == "walk":
		var next := position.move_toward(target,speed*step)
		if not can_stand(next): choose_target()
		else:
			var movement := next-position
			position = next
			walk_distance += movement.length()
			facing = FACING.from_movement(movement,facing)
			if position.distance_to(target) < 0.5: rest()
	elif state_time >= rest_seconds: choose_target()

func hostile_move(finish: Vector2, velocity: float, step: float) -> void:
	var next := position.move_toward(finish,velocity*step)
	if not clear_route(next): return
	var movement := next-position
	position = next
	walk_distance += movement.length()
	facing = FACING.from_movement(movement,facing)

func advance_hostile(delta: float) -> void:
	var trial: Node = game.trial
	var remaining := maxf(0,delta)
	while remaining > 0.00001:
		var step := minf(remaining,1.0/120.0)
		remaining -= step
		elapsed += step
		state_time += step
		hit_flash = maxf(0,hit_flash-step)
		health_seconds = maxf(0,health_seconds-step)
		var player: Vector2 = game.player
		var distance := position.distance_to(player)
		var safe: bool = trial.safe_at(player) or trial.invulnerable > 0.7
		var revealed: bool = game.fog.is_revealed(scare_area,position)
		match state:
			"alert":
				if state_time >= 1.25: rest()
			"hurt":
				if state_time > 0.22:
					state = "recover"
					state_time = 0
			"warn":
				if distance > 125 or safe or not revealed or not trial.clear_line(position,player): rest()
				elif state_time >= 0.5:
					state = "attack"
					state_time = 0
					strike_done = false
					target = player
			"attack":
				hostile_move(target,140 if kind == Kind.BAT else 115,step)
				if not strike_done and state_time >= 0.08:
					strike_done = true
					if distance < 94 and revealed and trial.clear_line(position,player): trial.hurt_player(1)
				if state_time >= 0.22:
					state = "recover"
					state_time = 0
			"recover":
				if state_time > 0.95: rest()
			_:
				if revealed and not safe and distance < 210 and player.distance_to(home) < wander_radius+80 and trial.clear_line(position,player):
					state = "chase"
					facing = FACING.from_movement(player-position,facing)
					if distance <= 83:
						state = "warn"
						state_time = 0
					else: hostile_move(player,90 if kind == Kind.BAT else 75,step)
				else:
					if state == "chase": rest()
					wander_step(step)
	update_pose()
	queue_redraw()

func take_hit(jab_id: int, origin: Vector2, damage: int) -> bool:
	if not hostile_active() or game.trial.blocked() or health <= 0 or damage <= 0 or last_jab == jab_id or state in ["flee","puff","gone"]: return false
	if not game.fog.is_revealed(scare_area,position): return false
	last_jab = jab_id
	health = maxi(0,health-damage)
	if not game.trial.mine_health.has(scare_area): game.trial.mine_health[scare_area] = {}
	game.trial.mine_health[scare_area][scare_id] = health
	hit_flash = 0.16
	health_seconds = 2.0
	state_time = 0
	if health == 0:
		remember_removed()
		game.trial.mine_defeated += 1
		begin_puff()
	else:
		state = "hurt"
		var away := (position-origin).normalized()
		for i in 6:
			var next := position+away*3
			if can_stand(next): position = next
		update_pose()
	queue_redraw()
	return true

func remember_removed() -> void:
	if is_instance_valid(game) and game.has_method("area_id") and scare_area >= 0 and scare_id >= 0:
		if is_instance_valid(game.get("missions")): game.missions.cleared(kind)
		if not game.scared_wildlife.has(scare_area): game.scared_wildlife[scare_area] = {}
		game.scared_wildlife[scare_area][scare_id] = true

func update_pose() -> void:
	var frame := 0
	var bob := 0.0
	var tilt := 0.0
	if kind == Kind.BAT:
		frame = int((elapsed+flight_phase)*(14 if state == "flee" else 9)) % 4
		bob = 48 + sin(elapsed*2.1+flight_phase)*7 + (state_time*25 if state == "flee" else 0.0)
		tilt = sin(elapsed*1.7+flight_phase)*0.04
	elif state in ["walk","flee","chase","attack"]:
		var stride := 6.0 if kind == Kind.RAT else 9.0
		frame = int(walk_distance/stride) % 4
		bob = absf(sin(walk_distance/stride*PI)) * (1.0 if kind == Kind.RAT else 1.8)
		tilt = sin(walk_distance/stride*PI)*0.018
	elif kind == Kind.RAT:
		frame = 2 if fmod(state_time,1.2) > 0.9 else 0
		tilt = sin(state_time*5)*0.012
	current_frame = frame
	var base_scale: float = ART_SCALES[kind]*size_variation
	if facing.y != 0:
		VERTICAL.apply(sprite, kind + VERTICAL.Species.FROSTLING, facing, frame, base_scale)
	else:
		sprite.texture = frames[kind][frame]
		var region: Rect2 = frames[kind][frame].region
		sprite.offset = region.size*0.5-(ANCHORS[kind][frame]-region.position)
		if facing.x < 0: sprite.offset.x = -sprite.offset.x
		sprite.flip_h = facing.x < 0
		sprite.scale = Vector2.ONE*base_scale
	sprite.position.y = -bob
	sprite.rotation = tilt
	var breathing := 1.0 if state in ["walk","flee","chase","attack"] or kind == Kind.BAT else 1.0+sin(elapsed*2+flight_phase)*0.012
	sprite.scale.y *= breathing
	sprite.modulate = Color(1.8,1.5,1.1) if hit_flash > 0 else Color.WHITE

func scare_from(origin: Vector2) -> bool:
	if kind not in [Kind.RAT,Kind.BAT] or state in ["flee","puff","gone"]: return false
	advance(0)
	var away := (position-origin).normalized()
	if away.is_zero_approx(): away = Vector2.RIGHT
	var score := 0.0
	target = position
	for ray in 16:
		var direction := away.rotated(ray*TAU/16)
		if direction.dot(away) < -0.001: continue
		for distance in [90.0,60.0,30.0]:
			var candidate: Vector2 = position+direction*distance
			var candidate_score: float = (candidate-position).dot(away)+distance*0.15
			if candidate_score > score and clear_route(candidate):
				score = candidate_score
				target = candidate
	state = "flee"
	state_time = 0
	remember_removed()
	if position.distance_to(target) < 1: begin_puff()
	return true

func begin_puff() -> void:
	state = "puff"
	state_time = 0
	smoke_centre = sprite.position+Vector2(0,-7)
	sprite.hide()
	queue_redraw()

func advance_escape(delta: float) -> void:
	var remaining := maxf(0,delta)
	while remaining > 0.00001 and state != "gone":
		var duration := FLEE_SECONDS if state == "flee" else PUFF_SECONDS
		var step := minf(minf(remaining,0.05),duration-state_time)
		state_time += step
		elapsed += step
		remaining -= step
		if state == "flee":
			var next := position.move_toward(target,step*(145.0 if kind == Kind.RAT else 165.0))
			if not clear_route(next):
				begin_puff()
				continue
			walk_distance += position.distance_to(next)
			facing = FACING.from_movement(next-position,facing)
			position = next
			update_pose()
			if state_time >= FLEE_SECONDS or position.distance_to(target) < 0.5: begin_puff()
		elif state_time >= PUFF_SECONDS:
			state = "gone"
			hide()
			set_process(false)
	queue_redraw()

func _draw() -> void:
	if state == "gone": return
	if state == "puff":
		var t := clampf(state_time/PUFF_SECONDS,0,1)
		for i in 8:
			var direction := Vector2.from_angle(i*TAU/8+0.2)
			var point := smoke_centre+direction*(4+19*t)+Vector2(0,-13*t)
			var radius := (6.0+i%3)*(1+0.7*t)
			draw_circle(point,radius,Color(0.62,0.67,0.64,(1-t)*0.65))
			draw_circle(point+Vector2(-1,-2),radius*0.8,Color(0.88,0.9,0.84,(1-t)*0.8))
		draw_circle(smoke_centre+Vector2(-2,-13*t),9+12*t,Color(0.86,0.88,0.82,(1-t)*0.8))
		return
	var width := 11.0 if kind == Kind.RAT else (13.0 if kind == Kind.BAT else 18.0)
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,width*size_variation,Color(0.08,0.11,0.13,0.1 if kind == Kind.BAT else 0.16))
	draw_set_transform(Vector2.ZERO)
	if hostile:
		var y := -82.0 if kind == Kind.BAT else -30.0
		if state in ["warn","alert"]: draw_string(STYLE.HEADING,Vector2(-4,y),"!",HORIZONTAL_ALIGNMENT_CENTER,12,22,Color("ffd374"))
		if health_seconds > 0:
			draw_rect(Rect2(-16,y,32,5),Color("143638"))
			draw_rect(Rect2(-15,y+1,30*float(health)/max_health(),3),Color("d9ae58"))
