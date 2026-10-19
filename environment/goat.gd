@tool
extends Node2D

const ART: Texture2D = preload("res://assets/goat_frames.png")
const FACING = preload("res://environment/wildlife_facing.gd")
const VERTICAL = preload("res://environment/wildlife_vertical.gd")
const GROUND: Texture2D = preload("res://assets/green_planet_ground.png")
const TERRAIN = preload("res://ore_spawns.gd")
const WALK_FRAMES := [1, 0, 2, 0]
const GRAZE_FRAMES := [3, 4, 5, 4, 5, 4]
const FOOT_Y := [487.0, 483.0, 488.0, 424.0, 424.0, 424.0]
static var ground_image: Image

@export_range(10.0, 35.0) var walk_speed := 22.0
@export_range(80.0, 200.0) var wander_radius := 145.0
@export_range(0.1, 0.25) var body_scale := 0.15
var rng := RandomNumberGenerator.new()
var sprite: Sprite2D
var home := Vector2.ZERO
var target := Vector2.ZERO
var previous_stop := Vector2.ZERO
var state := "graze"
var state_time := 0.0
var rest_seconds := 2.0
var walk_distance := 0.0
var graze_count := 0
var settled := false
var facing := Vector2.RIGHT
var tree_roots: Array[Vector2] = []

func _ready() -> void:
	rng.randomize()
	home = position
	if ground_image == null:
		ground_image = GROUND.get_image()
	for item in get_parent().get_children():
		if str(item.name).begins_with("Tree"):
			tree_roots.append(item.position)
	sprite = Sprite2D.new()
	sprite.name = "IllustratedGoat"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.texture = ART
	sprite.hframes = 3
	sprite.vframes = 2
	sprite.scale = Vector2.ONE * body_scale
	add_child(sprite)
	rest_seconds = rng.randf_range(0.5, 4.5)
	state = "graze" if rng.randf() < 0.65 else "rest"
	update_pose()
	queue_redraw()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and is_visible_in_tree():
		advance(delta)

func can_stand(point: Vector2) -> bool:
	if point.distance_to(home) > wander_radius:
		return false
	# Check the painted ground beneath the feet, including a small footprint.
	# The ore terrain mask also excludes the pond, cliff and mossy boulders.
	var grass_samples := 0
	for offset in [Vector2.ZERO, Vector2(-18,0), Vector2(18,0), Vector2(0,-8), Vector2(0,8)]:
		var foot: Vector2 = point + offset
		if not TERRAIN.green_ground(foot):
			return false
		var pixel := Vector2i(foot / Vector2(2000,1400) * Vector2(ground_image.get_size()))
		pixel = pixel.clamp(Vector2i.ZERO, ground_image.get_size() - Vector2i.ONE)
		var colour := ground_image.get_pixelv(pixel)
		if colour.g >= colour.r * 1.035 and colour.g >= colour.b * 1.2:
			grass_samples += 1
	# Painted flowers and dry flecks should not split one grassy meadow into
	# tiny isolated pixels. Sand paths still fail the footprint majority.
	if grass_samples < 3:
		return false
	for root in tree_roots:
		if point.distance_to(root) < 38:
			return false
	var game := get_parent().get_parent()
	if game.has_method("area_id"):
		for rock in game.rocks:
			if not rock.cave and rock.hp > 0 and point.distance_to(rock.pos) < 80:
				return false
	return true

func find_grass() -> Vector2:
	if room_to_wander(home):
		return home
	for ring in range(1, 9):
		for ray in 24:
			var point := home + Vector2.from_angle(TAU * ray / 24.0) * wander_radius * ring / 8.0
			if room_to_wander(point):
				return point
	return home

func room_to_wander(point: Vector2) -> bool:
	if not can_stand(point):
		return false
	for ray in 12:
		var direction := Vector2.from_angle(TAU * ray / 12.0)
		if can_stand(point + direction * 12) and can_stand(point + direction * 24) and can_stand(point + direction * 36):
			return true
	return false

func clear_route(finish: Vector2) -> bool:
	var steps := maxi(1, ceili(position.distance_to(finish) / 1.5))
	for i in range(1, steps + 1):
		if not can_stand(position.lerp(finish, float(i) / steps)):
			return false
	return true

func choose_target() -> void:
	for attempt in 48:
		# Nearby grazing spots remain reachable when random ore or a painted
		# path divides the larger meadow into smaller grassy patches.
		var angle := Vector2.from_angle(rng.randf() * TAU)
		var point := position + angle * rng.randf_range(18, 70) if attempt < 32 else home + angle * sqrt(rng.randf()) * wander_radius
		if position.distance_to(point) > 16 and clear_route(point):
			previous_stop = position
			target = point
			state = "walk"
			state_time = 0
			return
	# A narrow patch always has the same clear route back to its last stop.
	# Use it if random destinations all fall across sand, water or deposits.
	if position.distance_to(previous_stop) > 16 and clear_route(previous_stop):
		target = previous_stop
		previous_stop = position
		state = "walk"
		state_time = 0
		return
	state = "graze"
	state_time = 0
	rest_seconds = rng.randf_range(2, 5)
	graze_count += 1

func advance(delta: float) -> void:
	if not settled:
		# Ore is generated after the environment is added. Settle on a clear
		# grassy patch before the first visible frame, avoiding those deposits.
		position = find_grass()
		previous_stop = position
		settled = true
	var remaining := maxf(0, delta)
	while remaining > 0.00001:
		var step := minf(remaining, 0.05)
		state_time += step
		if state == "walk":
			var next := position.move_toward(target, walk_speed * step)
			if not can_stand(next):
				choose_target()
			else:
				var movement := next - position
				position = next
				walk_distance += movement.length()
				facing = FACING.from_movement(movement, facing)
				if position.distance_to(target) < 1:
					state = "graze" if rng.randf() < 0.85 else "rest"
					graze_count += 1 if state == "graze" else 0
					state_time = 0
					rest_seconds = rng.randf_range(3, 6)
		elif state_time >= rest_seconds:
			choose_target()
		remaining -= step
	update_pose()

func update_pose() -> void:
	var frame := 0
	if state == "walk":
		frame = WALK_FRAMES[int(walk_distance / 7.0) % WALK_FRAMES.size()]
		sprite.position.y = -absf(sin(walk_distance / 7.0 * PI)) * 0.5
	elif state == "graze":
		frame = GRAZE_FRAMES[int(state_time / 0.32) % GRAZE_FRAMES.size()]
		sprite.position.y = 0
	else:
		sprite.position.y = 0
	if facing.y != 0:
		VERTICAL.apply(sprite, VERTICAL.Species.GOAT, facing, frame, body_scale)
	else:
		sprite.texture = ART
		sprite.hframes = 3
		sprite.vframes = 2
		sprite.frame = frame
		sprite.flip_h = facing.x < 0
		sprite.scale = Vector2.ONE * body_scale
		sprite.offset = Vector2(0, 256 - FOOT_Y[frame])

func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, body_scale * 175, Color(0.12, 0.20, 0.07, 0.16))
	draw_set_transform(Vector2.ZERO)
