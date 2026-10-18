extends Node2D

const ART: Texture2D = preload("res://assets/lava_mine.png")
const LAYOUT = preload("res://desert_layout.gd")
const FLOW: Shader = preload("res://shaders/lava_flow.gdshader")
const HOT_SPOTS := [Vector2(795,215),Vector2(890,300),Vector2(945,365),
	Vector2(820,550),Vector2(935,650),Vector2(1050,800),Vector2(1220,900)]
var rng := RandomNumberGenerator.new()
var embers: Array[Dictionary] = []
var emission_clock := 0.0

func _ready() -> void:
	rng.randomize()
	var ground := Sprite2D.new()
	ground.texture = ART
	ground.centered = false
	ground.scale = LAYOUT.WORLD_SIZE / ART.get_size()
	ground.z_index = -1
	var mask := Image.create(250, 175, false, Image.FORMAT_R8)
	for y in mask.get_height():
		for x in mask.get_width():
			var point := Vector2(x + 0.5, y + 0.5) * 8
			mask.set_pixel(x, y, Color.WHITE if LAYOUT.lava_contains(point) else Color.BLACK)
	var flow := ShaderMaterial.new()
	flow.shader = FLOW
	flow.set_shader_parameter("lava_mask", ImageTexture.create_from_image(mask))
	ground.material = flow
	add_child(ground)

func _process(delta: float) -> void:
	if is_visible_in_tree():
		advance(delta)

func advance(delta: float) -> void:
	emission_clock += delta
	while emission_clock >= 0.12:
		emission_clock -= 0.12
		var point: Vector2 = LAYOUT.from_art(HOT_SPOTS[rng.randi_range(0, HOT_SPOTS.size() - 1)])
		point += Vector2(rng.randf_range(-45,45), rng.randf_range(-30,30))
		if LAYOUT.lava_contains(point) and embers.size() < 32:
			var life := rng.randf_range(0.9, 1.8)
			embers.append({"pos":point, "velocity":Vector2(rng.randf_range(-8,8), -rng.randf_range(18,30)), "life":life, "total":life})
	for i in range(embers.size() - 1, -1, -1):
		var ember: Dictionary = embers[i]
		ember.life -= delta
		if ember.life <= 0:
			embers.remove_at(i)
		else:
			ember.pos += ember.velocity * delta
	queue_redraw()

func _draw() -> void:
	for ember in embers:
		var tint := Color("ffd27c")
		tint.a = sin(ember.life / ember.total * PI) * 0.75
		draw_line(ember.pos, ember.pos + Vector2(0, 3.5), tint, 1.5)
