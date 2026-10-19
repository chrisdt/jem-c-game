extends Node2D

const ART = preload("res://environment/trial_art.gd")
const FACING = preload("res://environment/wildlife_facing.gd")
const STYLE = preload("res://ui/expedition_style.gd")
const MAX_HEALTH := 9
const POSE_SCALES := [0.20,0.15,0.15]
const SPEED := 57.0
const REACH := 62.0
var trial: Node
var home := Vector2.ZERO
var target := Vector2.ZERO
var facing := Vector2.RIGHT
var health := MAX_HEALTH
var state := "roam"
var clock := 0.0
var elapsed := 0.0
var phase := 0.0
var hit_flash := 0.0
var health_seconds := 0.0
var seen := false
var fade := 0.0
var bitten := false
var rng := RandomNumberGenerator.new()
var pictures: Array[Sprite2D] = []
var current_frame := 0
var last_jab := -1
var damage_taken := 0

func _ready() -> void:
	rng.randomize()
	home = position
	target = position
	clock = rng.randf_range(0.1,0.6)
	for i in 2:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite)
		pictures.append(sprite)
	update_pose()

func can_stand(point: Vector2) -> bool:
	if point.distance_to(home) > 240 or trial.game.underground or trial.safe_at(point): return false
	for link in trial.game.EARTH.LINKS[trial.game.earth_region]:
		if point.distance_to(trial.game.EARTH.portal(trial.game.earth_region,link.side)) < 150: return false
	if trial.game.EARTH.has_mine(trial.game.earth_region) and point.distance_to(trial.game.cave_position()) < 150: return false
	for offset in [Vector2.ZERO,Vector2.LEFT*18,Vector2.RIGHT*18,Vector2.UP*16,Vector2.DOWN*16]:
		if not trial.floor_at(point+offset): return false
	for rock in trial.game.rocks:
		if not rock.cave and rock.hp > 0 and point.distance_to(rock.pos) < 75: return false
	if is_instance_valid(trial.game.gardens):
		for plant in trial.game.gardens.plants:
			if point.distance_to(plant.position) < (43 if plant.apple else 35): return false
	return true

func clear_route(point: Vector2) -> bool:
	var steps := maxi(1,ceili(position.distance_to(point)/5.0))
	for i in range(1,steps+1):
		if not can_stand(position.lerp(point,float(i)/steps)): return false
	return true

func choose_target() -> void:
	for attempt in 32:
		var point := home+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(25,130)
		if clear_route(point):
			target = point
			return
	target = position

func move_towards(point: Vector2, speed: float, delta: float) -> void:
	var previous := position
	var next := position.move_toward(point,speed*delta)
	if can_stand(next): position = next
	var motion := position-previous
	if not motion.is_zero_approx():
		facing = FACING.from_movement(motion,facing)
		phase += motion.length()/78.0

func advance(delta: float) -> void:
	if state == "gone": return
	elapsed += delta
	clock += delta
	hit_flash = maxf(0,hit_flash-delta)
	health_seconds = maxf(0,health_seconds-delta)
	if state == "puff":
		if clock >= 0.7:
			state = "gone"
			hide()
		queue_redraw()
		return
	if not seen: seen = trial.game.fog.is_revealed(trial.game.area_id(),position)
	if not seen:
		for picture in pictures: picture.hide()
		return
	fade = minf(1,fade+delta/0.6)
	var player: Vector2 = trial.game.player
	var distance := position.distance_to(player)
	var safe: bool = trial.safe_at(player) or trial.invulnerable > 0.7
	match state:
		"hurt":
			if clock > 0.22:
				state = "recover"
				clock = 0
		"warn":
			if distance > 100 or safe:
				state = "recover"
				clock = 0
			elif clock >= 0.5:
				state = "bite"
				clock = 0
				bitten = false
				target = player
		"bite":
			move_towards(target,130,delta)
			if not bitten and clock >= 0.07:
				bitten = true
				if position.distance_to(player) < 52: trial.hurt_player(1)
			if clock >= 0.18:
				state = "recover"
				clock = 0
		"recover":
			if clock >= 0.95:
				state = "roam"
				clock = 0
		"roam", "chase":
			if distance < 190 and not safe and player.distance_to(home) < 210 and clear_route(player):
				state = "chase"
				if distance < REACH:
					state = "warn"
					clock = 0
					facing = FACING.from_movement(player-position,facing)
				else: move_towards(player,SPEED,delta)
			else:
				state = "roam"
				if position.distance_to(target) < 4 or clock > 3:
					choose_target()
					clock = 0
				move_towards(target,25,delta)
	phase += delta*0.12 if state in ["warn","recover"] else 0.0
	update_pose()
	queue_redraw()

func update_pose() -> void:
	if pictures.is_empty(): return
	var row := 0 if facing.y == 0 else (1 if facing.y > 0 else 2)
	# Front/rear paintings have a longer body silhouette. Fit those views
	# separately so turning never makes a small ground creature look giant.
	var pose_scale: float = POSE_SCALES[row]
	var cycle := fposmod(phase*6.0,6.0)
	current_frame = int(cycle)
	var blend := smoothstep(0,1,fmod(cycle,1.0))
	for i in 2:
		var frame := (current_frame+i)%6
		var pose := ART.snake_pose(row,frame)
		var picture := pictures[i]
		picture.texture = pose.texture
		picture.offset = picture.texture.get_size()*0.5-pose.anchor+Vector2(0,20.0/pose_scale)
		picture.flip_h = facing.x < 0
		if picture.flip_h: picture.offset.x = -picture.offset.x
		picture.scale = Vector2.ONE*pose_scale
		picture.modulate = Color(1.9,1.6,1.3) if hit_flash > 0 else Color.WHITE
		picture.modulate.a = (1-blend if i == 0 else blend)*smoothstep(0,1,fade)
		picture.visible = seen and health > 0

func take_hit(jab_id: int, origin: Vector2, damage: int) -> bool:
	if health <= 0 or not seen or last_jab == jab_id or not trial.is_active() or trial.blocked(): return false
	if damage <= 0: return false
	last_jab = jab_id
	damage_taken += mini(health,damage)
	health = maxi(0,health-damage)
	health_seconds = 2.0
	hit_flash = 0.16
	clock = 0
	if health == 0:
		state = "puff"
		for picture in pictures: picture.hide()
		trial.defeated += 1
	else:
		state = "hurt"
		var away := (position-origin).normalized()
		for i in 8:
			var next := position+away*3.0
			if can_stand(next): position = next
	update_pose()
	queue_redraw()
	return true

func _draw() -> void:
	if state == "puff":
		var t := clampf(clock/0.7,0,1)
		for i in 9:
			var angle := i*TAU/9.0
			var at := Vector2.from_angle(angle)*(8+18*t)+Vector2(0,8-16*t)
			draw_circle(at,11+8*t,Color(0.86,0.87,0.80,(1-smoothstep(0.2,1,t))*0.55))
		draw_circle(Vector2(0,8-16*t),15+10*t,Color(0.90,0.91,0.85,(1-t)*0.60))
		return
	if not seen or health <= 0: return
	if state == "warn":
		draw_string(STYLE.HEADING,Vector2(-4,-35),"!",HORIZONTAL_ALIGNMENT_CENTER,12,22,Color("ffd374"))
	if health_seconds > 0:
		draw_rect(Rect2(-18,-30,36,5),Color("143638"))
		draw_rect(Rect2(-17,-29,34*float(health)/MAX_HEALTH,3),Color("d9ae58"))
	if hit_flash > 0:
		for i in 5:
			var direction := Vector2.from_angle(i*TAU/5.0+0.2)
			draw_line(Vector2(0,-3)+direction*12,Vector2(0,-3)+direction*22,Color(1,0.91,0.61,hit_flash/0.16),2,true)
