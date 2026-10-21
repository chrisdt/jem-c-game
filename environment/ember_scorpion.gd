extends Node2D

const ART = preload("res://environment/ember_art.gd")
const MAX_HEALTH := 22
var guardian := false
var sting := true
var attacks := 0
var expedition: Node
var spawn_id := ""
var home := Vector2.ZERO
var health := MAX_HEALTH
var state := "rest"
var clock := 0.0
var last_jab := -1
var facing := 1
var walk_distance := 0.0
var seen := false
var fade := 0.0
var picture: Sprite2D
var target := Vector2.ZERO
var slow := 0.0
var hit_flash := 0.0

func _ready() -> void:
	picture = Sprite2D.new()
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(picture)
	update_pose()
func record() -> Dictionary:
	return {"health":health,"position":position,"seen":seen,"fade":fade,"slow":slow}
func restore(data: Dictionary) -> void:
	health = data.health
	position = data.position
	seen = data.seen
	fade = data.fade
	slow = data.get("slow",0.0)
	state = "gone" if health <= 0 else "rest"
	visible = health > 0
	update_pose()
func change(next: String) -> void:
	state = next
	clock = 0
func move_toward_point(point: Vector2, speed: float, delta: float) -> void:
	var before := position
	var motion := point-position
	if motion.length() < 1: return
	var next := position.move_toward(point,speed*delta)
	if expedition.floor_at(next,expedition.game.current_region(),false) and expedition.game.trial.clear_line(position,next): position = next
	var moved := position-before
	if moved.length() > 0.01:
		walk_distance += moved.length()
		facing = (2 if moved.y < 0 else 1) if absf(moved.y) > absf(moved.x) else (3 if moved.x < 0 else 0)
func maximum_health() -> int: return 30 if guardian else MAX_HEALTH
func advance(delta: float) -> void:
	if state == "gone" or expedition.game.trial.blocked(): return
	var game: Node = expedition.game
	if not seen: seen = game.fog.is_revealed(game.area_id(),position)
	if not seen:
		picture.hide()
		return
	fade = minf(0.75,fade+delta)
	modulate.a = smoothstep(0,0.75,fade)
	hit_flash = maxf(0,hit_flash-delta)
	slow = maxf(0,slow-delta)
	var remaining := maxf(0,delta)*(0.55 if slow > 0 and state != "puff" else 1.0)
	while remaining > 0.00001:
		var step := minf(remaining,1.0/60.0)
		remaining -= step
		clock += step
		var distance := position.distance_to(game.player)
		var safe: bool = game.trial.safe_at(game.player)
		var clear: bool = game.trial.clear_line(position,game.player)
		match state:
			"puff":
				if clock >= 0.7:
					state = "gone"
					hide()
			"rest":
				if not safe and distance < 230 and clear: change("chase")
			"chase":
				if safe or distance > 330 or not clear: change("return")
				elif distance < 80:
					target = game.player
					var aim := target-position
					facing = (2 if aim.y < 0 else 1) if absf(aim.y) > absf(aim.x) else (3 if aim.x < 0 else 0)
					sting = attacks%2 == 0
					change("warn")
				else: move_toward_point(game.player,76,step)
			"warn":
				if safe: change("return")
				elif clock >= (0.95 if sting else 0.65):
					if distance < 95 and game.player.distance_to(target) < 48 and clear:
						if game.trial.hurt_player(3 if sting else 2) and sting and game.trial.health < game.trial.MAX_HEALTH:
							game.trial.apply_poison()
					attacks += 1
					change("recover")
			"recover","hurt":
				if clock >= (1.1 if state == "recover" else 0.28): change("rest")
			"return":
				move_toward_point(home,50,step)
				if position.distance_to(home) < 4 or clock > 4: change("rest")
	update_pose()
	queue_redraw()
func take_hit(id: int, _origin: Vector2, damage: int) -> bool:
	var game: Node = expedition.game
	if health <= 0 or not seen or id == last_jab or game.trial.blocked() or damage <= 0: return false
	last_jab = id
	health = maxi(0,health-damage)
	hit_flash = 0.18
	if game.trial.weapon_is_frost() and game.trial.selected_tool == 1: slow = 1.25
	change("puff" if health == 0 else "hurt")
	if health == 0: game.message = "The scorpion vanished in a sandy puff!"
	update_pose()
	queue_redraw()
	return true
func update_pose() -> void:
	if not is_instance_valid(picture): return
	var row := 0 if facing in [0,3] else (1 if facing == 1 else 2)
	var frame := 1+int(walk_distance/15)%2 if state in ["chase","return"] else (3 if state == "warn" else 0)
	var pose: Dictionary = ART.scorpion_pose(row,frame)
	picture.texture = pose.texture
	picture.scale = Vector2.ONE*pose.scale
	picture.offset = picture.texture.get_size()*0.5-pose.anchor
	picture.flip_h = facing == 3
	if picture.flip_h: picture.offset.x = -picture.offset.x
	picture.visible = seen and health > 0
	picture.modulate = Color(1.4,1.15,1.1) if hit_flash > 0 else (Color(0.7,1.1,1.35) if slow > 0 else Color.WHITE)
	if state == "warn": picture.rotation = sin(clock*28)*0.025
	else: picture.rotation = 0
func _draw() -> void:
	if not seen: return
	draw_set_transform(Vector2(0,3),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,27,Color(0.08,0.035,0.015,0.18))
	draw_set_transform(Vector2.ZERO)
	if state == "warn":
		draw_string(ThemeDB.fallback_font,Vector2(-5,-112),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("72f4cc") if sting else Color("ffcb6b"))
	if health > 0 and health < maximum_health():
		draw_rect(Rect2(-21,-101,42,4),Color(0.08,0.035,0.02,0.85))
		draw_rect(Rect2(-21,-101,42*float(health)/maximum_health(),4),Color("ffb85b"))
	if state == "puff":
		var t := clock/0.7
		for i in 9:
			var point := Vector2(0,-35)+Vector2.from_angle(i*TAU/9)*(5+28*t)
			draw_circle(point,12+10*t,Color(1,0.83,0.58,sin(t*PI)*0.65))
