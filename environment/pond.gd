@tool
extends Node2D

const PARTS: Texture2D = preload("res://assets/pond_life.png")
const SWIM: Shader = preload("res://shaders/fish_swim.gdshader")
const GROUND: Texture2D = preload("res://assets/green_planet_ground.png")
const WIND_MESH = preload("res://environment/wind_mesh.gd")
const JUMP_SECONDS := 1.15

@export_range(3.0, 60.0) var minimum_jump_wait := 8.0
@export_range(3.0, 60.0) var maximum_jump_wait := 18.0
@export_range(20.0, 90.0) var jump_height := 55.0
var rng := RandomNumberGenerator.new()
var swimmer: MeshInstance2D
var jumper: Sprite2D
var phase := 0.0
var fish_position := Vector2.ZERO
var jump_time := -1.0
var jump_start := Vector2.ZERO
var jump_end := Vector2.ZERO
var next_jump_in := 6.0
var jump_count := 0
var ripples: Array[Dictionary] = []
var droplets: Array[Dictionary] = []
var ripple_wait := 0.0
var wake_wait := 0.0

func _ready() -> void:
	rng.randomize()
	phase = rng.randf_range(0, TAU)
	next_jump_in = rng.randf_range(5, 9)
	var cell := PARTS.get_size() / Vector2(4, 2)
	swimmer = MeshInstance2D.new()
	swimmer.name = "SwimmingFish"
	swimmer.texture = PARTS
	swimmer.mesh = WIND_MESH.make(cell)
	swimmer.scale = Vector2.ONE * 0.10
	swimmer.modulate = Color(0.72, 0.93, 0.94, 0.72)
	# Centre the mesh around the fish, before rotating it to its swim heading.
	var centered := Node2D.new()
	centered.name = "SwimHeading"
	add_child(centered)
	centered.add_child(swimmer)
	swimmer.position = -cell * 0.05
	var tail := ShaderMaterial.new()
	tail.shader = SWIM
	tail.set_shader_parameter("ground_texture", GROUND)
	swimmer.material = tail
	jumper = Sprite2D.new()
	jumper.name = "LeapingFish"
	var jump_art := AtlasTexture.new()
	jump_art.atlas = PARTS
	jump_art.region = Rect2(Vector2(cell.x * 3, cell.y), cell)
	jumper.texture = jump_art
	jumper.scale = Vector2.ONE * 0.105
	add_child(jumper)
	_update_visuals()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and is_visible_in_tree():
		advance(delta)

func swim_point(at: float) -> Vector2:
	# A smooth, gently turning route stays well inside the shoreline.
	return Vector2(sin(at) * 92, sin(at * 2 + 0.4) * 27 - 5)

func water_contains(point: Vector2) -> bool:
	return (point / Vector2(132, 60)).length_squared() < 1.0

func advance(delta: float) -> void:
	var remaining := maxf(0.0, delta)
	while remaining > 0.00001:
		var step := minf(remaining, 0.05)
		_advance_step(step)
		remaining -= step
	_update_visuals()
	queue_redraw()

func _advance_step(delta: float) -> void:
	for i in range(ripples.size() - 1, -1, -1):
		ripples[i].age += delta
		if ripples[i].age >= ripples[i].life:
			ripples.remove_at(i)
	for i in range(droplets.size() - 1, -1, -1):
		var drop := droplets[i]
		drop.life -= delta
		drop.velocity.y += 160 * delta
		drop.pos += drop.velocity * delta
		if drop.life <= 0:
			droplets.remove_at(i)
	if jump_time >= 0:
		jump_time += delta
		if jump_time >= JUMP_SECONDS:
			jump_time = -1
			phase += 0.48
			add_ripple(jump_end, true)
			_splash(jump_end)
			next_jump_in = rng.randf_range(minimum_jump_wait, maxf(minimum_jump_wait, maximum_jump_wait))
	else:
		phase += delta * 0.28
		next_jump_in -= delta
		if next_jump_in <= 0:
			jump_start = swim_point(phase)
			jump_end = swim_point(phase + 0.48)
			jump_time = 0
			jump_count += 1
			add_ripple(jump_start, true)
			_splash(jump_start, 4)
		wake_wait -= delta
		if wake_wait <= 0:
			add_ripple(swim_point(phase))
			wake_wait = 0.6
	ripple_wait -= delta
	if ripple_wait <= 0:
		add_ripple(Vector2(rng.randf_range(-62, 62), rng.randf_range(-22, 22)))
		ripple_wait = rng.randf_range(1.8, 3.2)

func _update_visuals() -> void:
	if swimmer == null:
		return
	swimmer.visible = jump_time < 0
	jumper.visible = jump_time >= 0
	if jump_time >= 0:
		var progress := clampf(jump_time / JUMP_SECONDS, 0, 1)
		fish_position = jump_start.lerp(jump_end, progress)
		jumper.position = fish_position - Vector2(0, 4 * jump_height * progress * (1 - progress))
		jumper.flip_h = jump_end.x < jump_start.x
		jumper.rotation = lerpf(-0.65, 0.65, progress) * (-1 if jumper.flip_h else 1)
	else:
		fish_position = swim_point(phase)
		var heading := swimmer.get_parent() as Node2D
		heading.position = fish_position
		heading.rotation = Vector2(92 * cos(phase), 54 * cos(phase * 2 + 0.4)).angle()

func add_ripple(point: Vector2, splash := false) -> void:
	if ripples.size() >= 16:
		ripples.pop_front()
	ripples.append({"pos":point, "age":0.0, "life":2.2 if splash else 1.5, "splash":splash})

func _splash(point: Vector2, count := 9) -> void:
	for i in count:
		droplets.append({"pos":point, "velocity":Vector2(rng.randf_range(-26, 26), rng.randf_range(-65, -30)), "life":rng.randf_range(0.4, 0.7)})

func _draw() -> void:
	for ripple in ripples:
		var progress: float = ripple.age / ripple.life
		var radius := lerpf(4, 34 if ripple.splash else 14, progress)
		var alpha := (0.26 if ripple.splash else 0.12) * (1 - progress)
		var points := PackedVector2Array()
		for i in 65:
			var angle := i * TAU / 64.0
			var point: Vector2 = ripple.pos + Vector2(cos(angle), sin(angle) * 0.38) * radius
			if water_contains(point):
				points.append(point)
			else:
				if points.size() >= 2:
					draw_polyline(points, Color(0.78, 0.96, 0.92, alpha), 0.9, true)
				points.clear()
		if points.size() >= 2:
			draw_polyline(points, Color(0.78, 0.96, 0.92, alpha), 0.9, true)
	if jump_time >= 0:
		draw_set_transform(fish_position, 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 9, Color(0.06, 0.25, 0.25, 0.18))
		draw_set_transform(Vector2.ZERO)
	for drop in droplets:
		draw_circle(drop.pos, 1.3, Color(0.83, 0.98, 0.98, minf(1, drop.life * 2)))
