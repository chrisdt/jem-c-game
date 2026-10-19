@tool
extends Node2D

const ART: Texture2D = preload("res://assets/duck_frames.png")
const WALK_FRAMES := [0, 1, 0, 2]
const PECK_FRAMES := [3, 4, 5, 3, 4, 5]
const FOOT_Y := [492.0, 484.0, 493.0, 415.0, 418.0, 415.0]
const WANDER_AREA := Rect2(890, 865, 165, 220)

@export_range(10.0, 40.0) var walk_speed := 21.0
@export var wander_area := WANDER_AREA
var shore_floor: Callable
var rng := RandomNumberGenerator.new()
var sprite: Sprite2D
var target := Vector2.ZERO
var state := "walk"
var state_time := 0.0
var rest_seconds := 1.0
var walk_distance := 0.0
var peck_count := 0

func _ready() -> void:
	rng.randomize()
	sprite = Sprite2D.new()
	sprite.name = "IllustratedDuck"
	sprite.texture = ART
	sprite.hframes = 3
	sprite.vframes = 2
	sprite.scale = Vector2.ONE * 0.13
	sprite.offset = Vector2(0, 256 - FOOT_Y[0])
	add_child(sprite)
	choose_target()
	queue_redraw()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and is_visible_in_tree():
		advance(delta)

func choose_target() -> void:
	for attempt in 48:
		var point := wander_area.position + Vector2(rng.randf(), rng.randf()) * wander_area.size
		if position.distance_to(point) > 12 and clear_route(point):
			target = point
			state = "walk"
			state_time = 0
			return
	state = "rest"
	state_time = 0
	rest_seconds = 1.5

func can_stand(point: Vector2) -> bool:
	return wander_area.has_point(point) and (not shore_floor.is_valid() or shore_floor.call(point))

func clear_route(finish: Vector2) -> bool:
	var steps := maxi(1, ceili(position.distance_to(finish) / 4.0))
	for i in range(1, steps + 1):
		if not can_stand(position.lerp(finish, float(i) / steps)):
			return false
	return true

func advance(delta: float) -> void:
	var remaining := maxf(0, delta)
	while remaining > 0.00001:
		var step := minf(remaining, 0.05)
		state_time += step
		if state == "walk":
			var next := position.move_toward(target, walk_speed * step)
			if not can_stand(next):
				choose_target()
				remaining -= step
				continue
			var movement := next - position
			position += movement
			walk_distance += movement.length()
			if absf(movement.x) > 0.01:
				sprite.flip_h = movement.x < 0
			if position.distance_to(target) < 1:
				state = "peck" if rng.randf() < 0.7 else "rest"
				peck_count += 1 if state == "peck" else 0
				state_time = 0
				rest_seconds = rng.randf_range(1.2, 2.4)
		elif state_time >= rest_seconds:
			choose_target()
		remaining -= step
	if state == "walk":
		sprite.frame = WALK_FRAMES[int(walk_distance / 4.5) % WALK_FRAMES.size()]
		sprite.position.y = -absf(sin(walk_distance / 4.5 * PI)) * 0.8
		sprite.rotation = sin(walk_distance / 4.5 * PI) * 0.025
	elif state == "peck":
		sprite.frame = PECK_FRAMES[int(state_time / 0.19) % PECK_FRAMES.size()]
		sprite.position.y = 0
		sprite.rotation = 0
	else:
		sprite.frame = 0
		sprite.position.y = 0
		sprite.rotation = 0
	# The painted peck poses have shorter silhouettes. Keep the webbed feet
	# on the same ground point instead of letting the whole bird float upward.
	sprite.offset = Vector2(0, 256 - FOOT_Y[sprite.frame])

func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 21, Color(0.12, 0.20, 0.07, 0.16))
	draw_set_transform(Vector2.ZERO)
