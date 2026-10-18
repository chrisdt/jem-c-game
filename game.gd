extends Node2D

const SPEED := 235.0
const CAMP := Vector2(380, 460)
const CAVE := Vector2(1500, 420)
var player := Vector2(470, 550)
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
	layer.add_child(panel)
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
	var next := player + direction.normalized() * SPEED * delta
	next = next.clamp(Vector2(90, 180), Vector2(1900, 1290))
	if underground:
		next = next.clamp(Vector2(260, 350), Vector2(1760, 1050))
	elif next.distance_to(Vector2(1260, 1060)) < 145:
		next = player
	player = next
	camera.position = player
	refresh_ui()
	queue_redraw()

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
		var path := PackedVector2Array([CAMP, Vector2(670, 620), Vector2(1000, 790), Vector2(1300, 650), CAVE])
		draw_polyline(path, Color("b3a477"), 100, true)
		draw_polyline(PackedVector2Array([Vector2(1000, 790), Vector2(850, 1100), Vector2(1450, 1180)]), Color("b3a477"), 60, true)
		for p in decorations:
			draw_line(p, p + Vector2(3, -7), Color("86ad62"), 2)
			if int(p.x) % 7 == 0:
				draw_circle(p, 3, Color("e6d88d"))
		ellipse(Vector2(1260, 1060), Vector2(150, 115), Color("4e8177"))
		ellipse(Vector2(1260, 1060), Vector2(133, 98), Color("65b4ac"))
		for i in 6:
			draw_arc(Vector2(1240, 1040), 25 + i * 14, 0.2, 2.6, 20, Color("90c8b8"), 2)
		for p in [Vector2(180, 800), Vector2(550, 1030), Vector2(900, 280), Vector2(1700, 300), Vector2(1750, 1140), Vector2(300, 1100), Vector2(1100, 250)]:
			draw_rect(Rect2(p, Vector2(14, 45)), Color("726b45"))
			for offset in [Vector2(-14, -5), Vector2(22, -18), Vector2(4, -40)]:
				draw_circle(p + offset, 40, Color("3f7954"))
				draw_circle(p + offset - Vector2(6, 8), 30, Color("518a58"))
		ellipse(CAVE + Vector2(0, -30), Vector2(115, 90), Color("667262"))
		ellipse(CAVE, Vector2(65, 65), Color("172f30"))
		draw_line(CAVE + Vector2(-65, 45), CAVE + Vector2(-65, -60), Color("b39164"), 15)
		draw_line(CAVE + Vector2(65, 45), CAVE + Vector2(65, -60), Color("b39164"), 15)
		draw_line(CAVE + Vector2(-80, -60), CAVE + Vector2(80, -60), Color("b39164"), 18)
		label_at(CAVE + Vector2(-65, -100), "MOSS MINE")
		ellipse(Vector2(220, 440), Vector2(52, 65), Color("c5d9c7"))
		draw_circle(Vector2(220, 415), 23, Color("508c93"))
		draw_rect(Rect2(CAMP - Vector2(65, 30), Vector2(130, 60)), Color("795d43"))
		draw_rect(Rect2(CAMP - Vector2(70, 40), Vector2(140, 25)), Color("c79e67"))
		label_at(CAMP + Vector2(-85, -65), "CAMP / UPGRADE")
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
		for offset in [Vector2(-12, -7), Vector2(9, -15), Vector2(13, 9)]:
			draw_circle(p + offset, 7, Color("76d9e7") if rock.hard else Color("e6a36a"))
		if player.distance_to(p) < 100:
			draw_arc(p, 43, 0, TAU, 40, Color("ffe4a0"), 2)
	ellipse(player + Vector2(0, 20), Vector2(21, 9), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(player + Vector2(-24, -5), Vector2(16, 27)), Color("307e81"))
	draw_line(player + Vector2(-9, 12), player + Vector2(-10, 24), Color("3d514b"), 9)
	draw_line(player + Vector2(9, 12), player + Vector2(10, 24), Color("3d514b"), 9)
	ellipse(player + Vector2(0, 2), Vector2(17, 20), Color("ed9447"))
	draw_circle(player + Vector2(0, -22), 22, Color("f1e1ba"))
	draw_circle(player + Vector2(2, -22), 16, Color("578f9a"))
	ellipse(player + Vector2(4, -18), Vector2(10, 11), Color("e9b17e"))
	ellipse(player + Vector2(1, -29), Vector2(11, 6), Color("78523d"))
	var tool := player + Vector2(27, -5 if swing > 0 else 12)
	draw_line(player + Vector2(13, 3), tool, Color("ed9447"), 9)
	draw_line(tool + Vector2(-6, 12), tool + Vector2(8, -18), Color("aa8254"), 5)
	draw_line(tool + Vector2(-2, -18), tool + Vector2(19, -10), Color("9ee5df") if upgraded else Color("d5d8c5"), 6)
