extends Node2D

const ART: Texture2D = preload("res://assets/rocket.png")
const ART_SCALE := 220.0 / 1331.0
var body: Sprite2D
var altitude := 0.0
var thrust := 0.0
var frost := false
var clock := 0.0
var dust_clock := 0.0
var dust: Array[Dictionary] = []

func _ready() -> void:
	name = "ScoutRocket"
	z_index = 2
	var cutout := AtlasTexture.new()
	cutout.atlas = ART
	cutout.region = Rect2(40, 25, 990, 1350)
	body = Sprite2D.new()
	body.texture = cutout
	body.centered = false
	body.scale = Vector2.ONE * ART_SCALE
	add_child(body)
	set_flight(0, 0)

func reset_pad(point: Vector2, icy: bool) -> void:
	position = point
	frost = icy
	dust.clear()
	dust_clock = 0
	set_flight(0, 0)

func set_flight(height: float, power: float) -> void:
	altitude = maxf(0, height)
	thrust = clampf(power, 0, 1)
	if body != null:
		body.position = Vector2(-517 * ART_SCALE, -220 - altitude)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	clock += delta
	if thrust > 0.1 and altitude < 140:
		dust_clock += delta
		while dust_clock >= 0.035:
			dust_clock -= 0.035
			var side := -1.0 if randf() < 0.5 else 1.0
			var life := randf_range(0.5, 1.0)
			dust.append({"pos":Vector2(side * randf_range(12, 26), -3), "velocity":Vector2(side * randf_range(60, 145), randf_range(-35, -12)), "life":life, "total":life, "size":randf_range(10, 18)})
	else:
		dust_clock = 0
	for i in range(dust.size() - 1, -1, -1):
		var puff: Dictionary = dust[i]
		puff.life -= delta
		if puff.life <= 0:
			dust.remove_at(i)
		else:
			puff.pos += puff.velocity * delta
			puff.velocity *= exp(-delta * 1.5)
	queue_redraw()

func oval(center: Vector2, radius: Vector2, tint: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * i / 32
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, tint)

func jet(origin: Vector2, width: float, length: float, tint: Color) -> void:
	var points := PackedVector2Array([
		origin + Vector2(-width, 0), origin + Vector2(-width * 0.8, length * 0.4),
		origin + Vector2(-width * 0.3, length * 0.75), origin + Vector2(0, length),
		origin + Vector2(width * 0.4, length * 0.7), origin + Vector2(width * 0.85, length * 0.3),
		origin + Vector2(width, 0)])
	draw_colored_polygon(points, tint)

func _draw() -> void:
	var shadow := maxf(0, 1 - altitude / 600)
	oval(Vector2(4, 2), Vector2(61, 16) * (0.45 + shadow * 0.55), Color(0.06, 0.12, 0.15, shadow * 0.22))
	if thrust > 0:
		var nozzle := Vector2(0, -27 - altitude)
		var flicker := 0.92 + sin(clock * 49) * 0.07 + sin(clock * 81) * 0.04
		var length := (25 + thrust * 95) * flicker
		for radius in [25.0, 40.0, 58.0]:
			draw_circle(nozzle + Vector2(0, length * 0.3), radius * thrust, Color(0.5, 0.86, 1, thrust * 0.035))
		jet(nozzle, 16 * thrust, length, Color(1, 0.54, 0.16, 0.85))
		jet(nozzle, 11 * thrust, length * 0.8, Color(0.35, 0.84, 1, 0.95))
		jet(nozzle, 6 * thrust, length * 0.56, Color(0.91, 0.98, 1))
	for puff in dust:
		var age: float = 1 - puff.life / puff.total
		var tint := Color("dceef6") if frost else Color("cabb99")
		tint.a = sin(age * PI) * 0.27
		oval(puff.pos, Vector2(puff.size, puff.size * 0.52) * (1 + age * 1.4), tint)
