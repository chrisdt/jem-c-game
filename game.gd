extends Node2D

const SPEED := 235.0
const CAMP := Vector2(470, 400)
const CAVE := Vector2(1480, 340)
var player := Vector2(560, 550)
var ground_art: Texture2D = preload("res://assets/green_planet.png")
const SCOUT_FRAMES: SpriteFrames = preload("res://assets/scout_frames.tres")
const WALK_FRAME_DISTANCE := 28.0
var walk_distance := 0.0
var scout: AnimatedSprite2D
var walking := false
var facing_left := false
var facing: StringName = &"down"
var underground := false
var ore := 0
var total_mined := 0
var upgraded := false
var won := false
var rocks: Array[Dictionary] = []
var message := "Welcome, Sunny Scout! Find 5 copper, then return to the camp workbench."
var cooldown := 0.0
var swing := 0.0
var elapsed := 0.0
var camera: Camera2D
var status: Label
var prompt: Label
var note: Label
var action_button: Button
var decorations: Array[Vector2] = []

func _ready() -> void:
	scout = AnimatedSprite2D.new()
	scout.name = "SunnyScout"
	scout.sprite_frames = SCOUT_FRAMES
	scout.animation = &"idle_down"
	scout.scale = Vector2.ONE * 0.15
	scout.offset = Vector2(0, -145)
	scout.position = player
	add_child(scout)
	seed(42)
	for i in range(150):
		decorations.append(Vector2(randf_range(40, 1920), randf_range(40, 1340)))
	reset_rocks()
	camera = Camera2D.new()
	camera.position = player
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2000
	camera.limit_bottom = 1400
	add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := Panel.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(680, 112)
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0.06, 0.13, 0.13, 0.9)
	hud_style.border_color = Color("b9a475")
	hud_style.set_border_width_all(1)
	hud_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", hud_style)
	layer.add_child(panel)
	var bottom := Panel.new()
	bottom.position = Vector2(12, 675)
	bottom.size = Vector2(1256, 113)
	bottom.add_theme_stylebox_override("panel", hud_style)
	layer.add_child(bottom)
	var title := Label.new()
	title.text = "SUNNY SCOUT   /   GREEN PLANET"
	title.position = Vector2(38, 28)
	title.add_theme_font_size_override("font_size", 25)
	layer.add_child(title)
	status = Label.new()
	status.position = Vector2(38, 67)
	status.add_theme_font_size_override("font_size", 19)
	layer.add_child(status)
	var controls := Label.new()
	controls.text = "WASD / arrows: walk    E / Space: interact    R: restart"
	controls.position = Vector2(38, 102)
	controls.add_theme_font_size_override("font_size", 14)
	layer.add_child(controls)
	note = Label.new()
	note.position = Vector2(24, 692)
	note.size = Vector2(1040, 60)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 20)
	layer.add_child(note)
	prompt = Label.new()
	prompt.position = Vector2(24, 758)
	prompt.add_theme_font_size_override("font_size", 18)
	layer.add_child(prompt)
	action_button = Button.new()
	action_button.text = "MINE / USE [E]"
	action_button.position = Vector2(1070, 710)
	action_button.size = Vector2(190, 65)
	action_button.pressed.connect(interact)
	layer.add_child(action_button)
	refresh_ui()

func reset_rocks() -> void:
	rocks.clear()
	for pos in [Vector2(700, 500), Vector2(850, 650), Vector2(1060, 580), Vector2(1120, 870), Vector2(720, 980), Vector2(1530, 960), Vector2(1670, 690)]:
		rocks.append({"pos": pos, "hp": 2, "hard": false, "cave": false})
	for pos in [Vector2(630, 640), Vector2(850, 470), Vector2(1050, 730), Vector2(1390, 610)]:
		rocks.append({"pos": pos, "hp": 2, "hard": false, "cave": true})
	for pos in [Vector2(1180, 450), Vector2(1450, 860), Vector2(1610, 640)]:
		rocks.append({"pos": pos, "hp": 4, "hard": true, "cave": true})

func _process(delta: float) -> void:
	elapsed += delta
	cooldown = maxf(0, cooldown - delta)
	swing = maxf(0, swing - delta)
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	move_player(direction, delta)
	camera.position = player
	refresh_ui()
	queue_redraw()

func move_player(direction: Vector2, delta: float) -> void:
	if not direction.is_zero_approx():
		# Diagonals use their stronger axis; ties face up/down consistently.
		if absf(direction.x) > absf(direction.y):
			facing = &"side"
			facing_left = direction.x < 0
		else:
			facing = &"up" if direction.y < 0 else &"down"
			facing_left = false
	var next := player + direction.normalized() * SPEED * delta
	next = next.clamp(Vector2(90, 180), Vector2(1900, 1290))
	if underground:
		next = next.clamp(Vector2(260, 350), Vector2(1760, 1050))
	elif ((next - Vector2(1270, 960)) / Vector2(173, 117)).length() < 1.0:
		next = player
	var travelled := player.distance_to(next)
	player = next
	walking = travelled > 0.001
	if walking:
		walk_distance += travelled
		scout.animation = StringName("walk_" + str(facing))
		scout.frame = int(walk_distance / WALK_FRAME_DISTANCE) % 4
	else:
		walk_distance = 0.0
		scout.animation = StringName("idle_" + str(facing))
		scout.frame = 0
	scout.flip_h = facing_left
	scout.position = player


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			interact()
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()

func nearest_rock() -> int:
	var best := -1
	var distance := 100.0
	for i in rocks.size():
		if rocks[i].cave == underground and rocks[i].hp > 0:
			var d := player.distance_to(rocks[i].pos)
			if d < distance:
				best = i
				distance = d
	return best

func interact() -> void:
	if cooldown > 0:
		return
	cooldown = 0.3
	if not underground and player.distance_to(CAMP) < 140:
		if not upgraded and ore >= 5:
			ore -= 5
			upgraded = true
			message = "Stronger pick built! Enter the mine and break a glowing blue crystal."
		elif upgraded:
			message = "Your stronger pick is ready. Blue crystals are inside the mine!"
		else:
			message = "Workbench: collect 5 copper from the orange rocks nearby."
	elif (not underground and player.distance_to(CAVE) < 130) or (underground and player.distance_to(Vector2(350, 700)) < 120):
		underground = not underground
		player = Vector2(460, 700) if underground else Vector2(1430, 520)
		scout.position = player
		camera.reset_smoothing()
		message = "The Moss Mine. Follow the lanterns. Blue crystal needs a stronger pick." if underground else "Back in the sunshine. The workbench is at the landing camp."
	else:
		var i := nearest_rock()
		if i >= 0:
			if rocks[i].hard and not upgraded:
				message = "Too tough! Build a stronger pick at camp with 5 copper."
			else:
				swing = 0.2
				rocks[i].hp -= 2 if upgraded else 1
				if rocks[i].hp <= 0:
					if rocks[i].hard:
						won = true
						message = "MISSION COMPLETE! You discovered blue crystal! Keep exploring, or press R to play again."
					else:
						ore += 1
						total_mined += 1
						message = "Copper collected! %d / 5 for your upgrade." % ore if not upgraded else "More copper for your next adventure!"
	refresh_ui()

func refresh_ui() -> void:
	if status == null:
		return
	status.text = "%s   •   Copper: %d   •   %s" % ["MOSS MINE" if underground else "SURFACE", ore, "STRONG PICK" if upgraded else "STARTER PICK"]
	note.text = message
	prompt.text = "Explore the paths and look for ore."
	if not underground and player.distance_to(CAMP) < 140:
		prompt.text = "[E] Workbench — stronger pick costs 5 copper"
	elif (not underground and player.distance_to(CAVE) < 130) or (underground and player.distance_to(Vector2(350, 700)) < 120):
		prompt.text = "[E] Leave mine" if underground else "[E] Enter Moss Mine"
	elif nearest_rock() >= 0:
		prompt.text = "[E / Space] Mine this deposit"

func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, color)

func label_at(pos: Vector2, text: String, color := Color("f6e5b8"), size := 20) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 2000, 1400), Color("182d2b") if underground else Color("719c58"))
	if underground:
		draw_rect(Rect2(220, 300, 1580, 810), Color("354342"))
		for p in decorations:
			if p.x > 250 and p.x < 1780 and p.y > 330 and p.y < 1080:
				ellipse(p, Vector2(10, 5), Color("424e46"))
		for p in [Vector2(700, 340), Vector2(1050, 1000), Vector2(1360, 340), Vector2(1700, 980)]:
			ellipse(p, Vector2(100, 65), Color("263638"))
		for p in [Vector2(440, 550), Vector2(800, 850), Vector2(1100, 560), Vector2(1530, 1000)]:
			for j in range(5, 0, -1):
				draw_circle(p, j * 22, Color(1, 0.65, 0.2, 0.018))
			draw_rect(Rect2(p - Vector2(7, 15), Vector2(14, 24)), Color("ffc56b"))
			draw_line(p + Vector2(-20, 30), p + Vector2(-20, -70), Color("826747"), 13)
			draw_line(p + Vector2(-30, -70), p + Vector2(75, -70), Color("826747"), 13)
		label_at(Vector2(270, 690), "EXIT →")
	else:
		draw_texture_rect(ground_art, Rect2(0, 0, 2000, 1400), false)
		label_at(CAMP + Vector2(-95, -110), "CAMP / UPGRADE")
		label_at(CAVE + Vector2(-65, -140), "MOSS MINE")
		for point in [CAMP, CAVE + Vector2(0, 85)]:
			draw_arc(point, 36, 0, TAU, 40, Color(1, 0.89, 0.63, 0.55 + sin(elapsed * 2) * 0.15), 2)
		var buddy := Vector2(990 + sin(elapsed * 0.5) * 65, 940 + cos(elapsed * 0.5) * 35)
		ellipse(buddy, Vector2(23, 17), Color("ead9aa"))
		draw_circle(buddy + Vector2(17, -10), 12, Color("ead9aa"))
		draw_circle(buddy + Vector2(22, -12), 3, Color("263f3a"))
	for rock in rocks:
		if rock.cave != underground or rock.hp <= 0:
			continue
		var p: Vector2 = rock.pos
		ellipse(p + Vector2(0, 13), Vector2(35, 20), Color(0, 0, 0, 0.16))
		var points := PackedVector2Array([p + Vector2(-32, 8), p + Vector2(-24, -22), p + Vector2(0, -35), p + Vector2(25, -18), p + Vector2(34, 12), p + Vector2(0, 24)])
		draw_colored_polygon(points, Color("607579") if rock.hard else Color("747b69"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-32, 8), p + Vector2(-24, -22), p + Vector2(0, -35), p + Vector2(-4, 5)]), Color("879697") if rock.hard else Color("9b9c7f"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 5), p + Vector2(25, -18), p + Vector2(34, 12), p + Vector2(0, 24)]), Color("465e64") if rock.hard else Color("59634e"))
		for offset in [Vector2(-12, -7), Vector2(9, -15), Vector2(13, 9)]:
			draw_circle(p + offset, 7, Color("76d9e7") if rock.hard else Color("e6a36a"))
		if player.distance_to(p) < 100:
			draw_arc(p, 43, 0, TAU, 40, Color("ffe4a0"), 2)
	ellipse(player + Vector2(0, 20), Vector2(23, 9), Color(0, 0, 0, 0.25))
	if swing > 0:
		draw_arc(player + Vector2(-30 if facing_left else 30, -5), 34, -1.4, 0.7, 16, Color(1, 0.9, 0.65, swing * 4), 4)
