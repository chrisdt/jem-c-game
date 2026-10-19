extends Node2D

enum Kind { FROSTLING, DUNE_SPRITE, RAT, BAT }
const ART: Texture2D = preload("res://assets/creatures/ambient_creatures.png")
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
var facing_left := false
var size_variation := 1.0
var speed := 23.0
var current_frame := -1

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
	if not settled:
		position = find_start()
		previous_stop = position
		settled = true
	var remaining := maxf(0,delta)
	while remaining > 0.00001:
		var step := minf(remaining,0.05)
		elapsed += step
		state_time += step
		if state == "walk":
			var next := position.move_toward(target,speed*step)
			if not can_stand(next):
				choose_target()
			else:
				var movement := next-position
				position = next
				walk_distance += movement.length()
				if absf(movement.x) > 0.01: facing_left = movement.x < 0
				if position.distance_to(target) < 0.5: rest()
		elif state_time >= rest_seconds:
			choose_target()
		remaining -= step
	update_pose()
	queue_redraw()

func update_pose() -> void:
	var frame := 0
	var bob := 0.0
	var tilt := 0.0
	if kind == Kind.BAT:
		frame = int((elapsed+flight_phase)*9) % 4
		bob = 48 + sin(elapsed*2.1+flight_phase)*7
		tilt = sin(elapsed*1.7+flight_phase)*0.04
	elif state == "walk":
		var stride := 6.0 if kind == Kind.RAT else 9.0
		frame = int(walk_distance/stride) % 4
		bob = absf(sin(walk_distance/stride*PI)) * (1.0 if kind == Kind.RAT else 1.8)
		tilt = sin(walk_distance/stride*PI)*0.018
	elif kind == Kind.RAT:
		frame = 2 if fmod(state_time,1.2) > 0.9 else 0
		tilt = sin(state_time*5)*0.012
	if current_frame != frame:
		current_frame = frame
		sprite.texture = frames[kind][frame]
	var region: Rect2 = frames[kind][frame].region
	sprite.offset = region.size*0.5-(ANCHORS[kind][frame]-region.position)
	if facing_left: sprite.offset.x = -sprite.offset.x
	sprite.flip_h = facing_left
	sprite.position.y = -bob
	sprite.rotation = tilt
	var breathing := 1.0 if state == "walk" or kind == Kind.BAT else 1.0+sin(elapsed*2+flight_phase)*0.012
	sprite.scale = Vector2(1,breathing)*ART_SCALES[kind]*size_variation

func _draw() -> void:
	var width := 11.0 if kind == Kind.RAT else (13.0 if kind == Kind.BAT else 18.0)
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,width*size_variation,Color(0.08,0.11,0.13,0.1 if kind == Kind.BAT else 0.16))
	draw_set_transform(Vector2.ZERO)
