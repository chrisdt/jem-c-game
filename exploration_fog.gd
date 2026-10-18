extends Sprite2D

const WORLD_SIZE := Vector2(2000, 1400)
const MASK_SIZE := Vector2i(250, 175)
const CELL := 8.0
const REVEAL_RADIUS := 265.0
const CLEAR_RADIUS := 210.0
const STAMP_DISTANCE := 12.0
const MIST: Shader = preload("res://shaders/exploration_mist.gdshader")

var maps: Dictionary = {}
var active_map := -1
var mist: ShaderMaterial

func _ready() -> void:
	name = "ExplorationMist"
	centered = false
	z_index = 1000
	var white := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	texture = ImageTexture.create_from_image(white)
	scale = WORLD_SIZE
	mist = ShaderMaterial.new()
	mist.shader = MIST
	mist.set_shader_parameter("clear_radius", CLEAR_RADIUS)
	mist.set_shader_parameter("reveal_radius", REVEAL_RADIUS)
	material = mist

func observe(map_id: int, point: Vector2) -> void:
	if not maps.has(map_id):
		var pixels := PackedByteArray()
		pixels.resize(MASK_SIZE.x * MASK_SIZE.y)
		pixels.fill(0)
		var mask := Image.create_from_data(MASK_SIZE.x, MASK_SIZE.y, false, Image.FORMAT_R8, pixels)
		maps[map_id] = {"pixels":pixels, "image":mask, "texture":ImageTexture.create_from_image(mask), "last_stamp":Vector2.INF}
	var switched := active_map != map_id
	if switched:
		active_map = map_id
		mist.set_shader_parameter("revealed_mask", maps[map_id].texture)
		var colours := [Color("8ca29c"), Color("455754"), Color("a1bac2"), Color("4f6575")]
		mist.set_shader_parameter("mist_colour", colours[map_id])
	mist.set_shader_parameter("scout_position", point)
	if switched or point.distance_to(maps[map_id].last_stamp) >= STAMP_DISTANCE:
		_stamp(point)

func reveal_motion(map_id: int, start: Vector2, finish: Vector2) -> void:
	# Actual movement can reveal a trail even during a slow frame. Map travel
	# calls observe() instead, so teleporting never clears a line across a map.
	observe(map_id, start)
	var steps := maxi(1, ceili(start.distance_to(finish) / (CLEAR_RADIUS * 0.5)))
	for i in range(1, steps + 1):
		observe(map_id, start.lerp(finish, float(i) / steps))

func _stamp(point: Vector2) -> void:
	var state: Dictionary = maps[active_map]
	var pixels: PackedByteArray = state.pixels
	var low := Vector2i(((point - Vector2.ONE * REVEAL_RADIUS) / CELL).floor()).clamp(Vector2i.ZERO, MASK_SIZE - Vector2i.ONE)
	var high := Vector2i(((point + Vector2.ONE * REVEAL_RADIUS) / CELL).ceil()).clamp(Vector2i.ZERO, MASK_SIZE - Vector2i.ONE)
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var distance := (Vector2(x + 0.5, y + 0.5) * CELL).distance_to(point)
			if distance >= REVEAL_RADIUS:
				continue
			var value := 255
			if distance > CLEAR_RADIUS:
				value = roundi((1 - smoothstep(CLEAR_RADIUS, REVEAL_RADIUS, distance)) * 255)
			var index := y * MASK_SIZE.x + x
			pixels[index] = maxi(pixels[index], value)
	state.pixels = pixels
	state.last_stamp = point
	state.image.set_data(MASK_SIZE.x, MASK_SIZE.y, false, Image.FORMAT_R8, pixels)
	state.texture.update(state.image)

func is_revealed(map_id: int, point: Vector2) -> bool:
	if not maps.has(map_id) or not Rect2(Vector2.ZERO, WORLD_SIZE).has_point(point):
		return false
	var cell := Vector2i((point / CELL).floor())
	return maps[map_id].pixels[cell.y * MASK_SIZE.x + cell.x] >= 248
