extends Node2D

const SPEED := 235.0
const CAMP := Vector2(470, 400)
const CAVE := Vector2(1480, 340)
const MINE_EXIT := Vector2(150, 610)
const MINE_SPAWN := Vector2(420, 620)
const MINE_LAYOUT = preload("res://mine_layout.gd")
const MINE_ART: Texture2D = preload("res://assets/moss_mine.png")
const SHIP := Vector2(240, 400)
const FROST_LAYOUT = preload("res://frost_layout.gd")
const ICE_ART: Texture2D = preload("res://assets/ice_planet.png")
const FROST_MINE_ART: Texture2D = preload("res://assets/frost_mine.png")
const AMETHYST_ART: Texture2D = preload("res://assets/amethyst_ore.png")
const ICE_CAMP := Vector2(570, 1060)
const ICE_SHIP := Vector2(260, 1070)
const ICE_CAVE := Vector2(1620, 280)
const ICE_EXIT := Vector2(968, 1230)
const ICE_SPAWN := Vector2(968, 1115)
const MINE_TRIGGER_RADIUS := 65.0
var mine_transition_cooldown := 0.0
var world := 0
var planet_rocks: Dictionary = {}
var frost_ore := 0
var amethysts := 0
var ice_won := false
var title: Label
var player := Vector2(560, 550)
const GREEN_ENVIRONMENT: PackedScene = preload("res://environment/green_planet.tscn")
var green_surface: Node2D
const COPPER_ART: Texture2D = preload("res://assets/copper_ore.png")
const BLUE_ORE_ART: Texture2D = preload("res://assets/blue_ore.png")
const SCOUT_FRAMES: SpriteFrames = preload("res://assets/scout_frames.tres")
const MINE_FRAMES: SpriteFrames = preload("res://assets/scout_mining_frames.tres")
const COPPER_SECONDS := 2.0
const CRYSTAL_SECONDS := 9.0
const STRIKE_SECONDS := 0.66
const IMPACT_PHASE := 0.22
# Pixel anchors keep boots planted across the painted poses.
const MINE_ANCHORS := {
	&"down": [Vector2(270, 425), Vector2(208, 430), Vector2(164, 426)],
	&"side": [Vector2(275, 393), Vector2(212, 356), Vector2(174, 361)],
	&"up": [Vector2(270, 395), Vector2(208, 394), Vector2(164, 394)],
}
var mining_target := -1
var mining_elapsed := 0.0
var next_strike := IMPACT_PHASE
var impact_flash := 0.0
var particles: Array[Dictionary] = []
var mining_fx: Node2D
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
var message := "New destination! Visit the rocket for Frost Canyon, or collect 5 copper for a stronger pick."
var cooldown := 0.0
var elapsed := 0.0
var camera: Camera2D
var status: Label
var prompt: Label
var note: Label
var action_button: Button
var decorations: Array[Vector2] = []

func _ready() -> void:
	y_sort_enabled = true
	green_surface = GREEN_ENVIRONMENT.instantiate()
	add_child(green_surface)
	scout = AnimatedSprite2D.new()
	scout.name = "SunnyScout"
	scout.sprite_frames = SCOUT_FRAMES
	scout.animation = &"idle_down"
	scout.scale = Vector2.ONE * 0.15
	scout.offset = Vector2(0, -145)
	scout.position = player
	add_child(scout)
	mining_fx = Node2D.new()
	mining_fx.name = "MiningEffects"
	mining_fx.z_index = 1
	mining_fx.draw.connect(draw_mining_effects)
	add_child(mining_fx)
	seed(42)
	for i in range(150):
		decorations.append(Vector2(randf_range(40, 1920), randf_range(40, 1340)))
	reset_rocks()
	planet_rocks[world] = rocks
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
	title = Label.new()
	title.text = "SUNNY SCOUT   /   GREEN PLANET"
	title.position = Vector2(38, 28)
	title.add_theme_font_size_override("font_size", 25)
	layer.add_child(title)
	status = Label.new()
	status.position = Vector2(38, 67)
	status.add_theme_font_size_override("font_size", 19)
	layer.add_child(status)
	var controls := Label.new()
	controls.text = "WASD / arrows: walk    E / Space: mine or cancel    R: restart"
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
	if world == 1:
		for point in [Vector2(350,665),Vector2(465,500),Vector2(360,350),Vector2(1000,475),Vector2(1100,365),Vector2(1180,690)]:
			rocks.append({"pos":FROST_LAYOUT.from_art(point),"hp":2,"seconds":3.0,"hard":false,"cave":false})
		for point in [Vector2(725,740),Vector2(500,420),Vector2(1050,400)]:
			rocks.append({"pos":FROST_LAYOUT.from_art(point),"hp":2,"seconds":3.0,"hard":false,"cave":true})
		for point in [Vector2(320,320),Vector2(1210,280),Vector2(1240,160)]:
			rocks.append({"pos":FROST_LAYOUT.from_art(point),"hp":4,"seconds":10.0,"hard":true,"cave":true})
		return
	for pos in [Vector2(700, 500), Vector2(850, 650), Vector2(1060, 580), Vector2(1120, 870), Vector2(720, 980), Vector2(1530, 960), Vector2(1670, 690)]:
		rocks.append({"pos": pos, "hp": 2, "seconds": COPPER_SECONDS, "hard": false, "cave": false})
	for pos in [Vector2(630, 640), Vector2(850, 560), Vector2(1050, 730), Vector2(1290, 580)]:
		rocks.append({"pos": pos, "hp": 2, "seconds": COPPER_SECONDS, "hard": false, "cave": true})
	for pos in [Vector2(1180, 450), Vector2(1450, 860), Vector2(1610, 640)]:
		rocks.append({"pos": pos, "hp": 4, "seconds": CRYSTAL_SECONDS, "hard": true, "cave": true})

func camp_position() -> Vector2:
	return ICE_CAMP if world == 1 else CAMP

func cave_position() -> Vector2:
	return ICE_CAVE if world == 1 else CAVE

func exit_position() -> Vector2:
	return ICE_EXIT if world == 1 else MINE_EXIT

func ship_position() -> Vector2:
	return ICE_SHIP if world == 1 else SHIP

func mine_name() -> String:
	return "Frost Mine" if world == 1 else "Moss Mine"

func material_name(rock: Dictionary) -> String:
	if world == 1:
		return "amethyst" if rock.hard else "frost ore"
	return "blue crystal" if rock.hard else "copper"

func travel_to_other_planet() -> void:
	if underground or mining_target >= 0:
		return
	planet_rocks[world] = rocks
	world = 1 - world
	if planet_rocks.has(world):
		rocks = planet_rocks[world]
	else:
		rocks = []
		reset_rocks()
		planet_rocks[world] = rocks
	particles.clear()
	player = Vector2(390,1120) if world == 1 else Vector2(320,500)
	restore_walk_visual()
	scout.animation = StringName("idle_" + str(facing))
	scout.position = player
	camera.position = player
	camera.reset_smoothing()
	message = "Frost Canyon! Cross the bridge to the Frost Mine. Collect 3 frost ore and 1 amethyst." if world == 1 else "Back on Green Planet! Your ore and mining progress are still here."
	refresh_ui()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	cooldown = maxf(0, cooldown - delta)
	update_particles(delta)
	mining_fx.queue_redraw()
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	move_player(direction, delta)
	advance_mining(delta)
	camera.position = player
	refresh_ui()
	queue_redraw()

func face_direction(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		# Diagonals use their stronger axis; ties face up/down consistently.
		if absf(direction.x) > absf(direction.y):
			facing = &"side"
			facing_left = direction.x < 0
		else:
			facing = &"up" if direction.y < 0 else &"down"
			facing_left = false

func restore_walk_visual() -> void:
	scout.sprite_frames = SCOUT_FRAMES
	scout.scale = Vector2.ONE * 0.15
	scout.offset = Vector2(0, -145)
	scout.rotation = 0.0

func move_player(direction: Vector2, delta: float) -> void:
	mine_transition_cooldown = maxf(0, mine_transition_cooldown - delta)
	var previous := player
	if mining_target >= 0:
		if direction.is_zero_approx():
			walking = false
			return
		cancel_mining()
	face_direction(direction)
	restore_walk_visual()
	var next := player + direction.normalized() * SPEED * delta
	next = next.clamp(Vector2(90, 180), Vector2(1900, 1290))
	if world == 1:
		next = FROST_LAYOUT.move_on_floor(player,direction.normalized() * SPEED * delta,underground)
	elif underground:
		next = MINE_LAYOUT.move_on_floor(player, direction.normalized() * SPEED * delta)
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
	check_mine_transition(previous)

func check_mine_transition(previous: Vector2) -> void:
	if mine_transition_cooldown > 0:
		return
	var doorway := exit_position() if underground else cave_position()
	var closest := Geometry2D.get_closest_point_to_segment(doorway, previous, player)
	if closest.distance_to(doorway) >= MINE_TRIGGER_RADIUS:
		return
	cancel_mining()
	particles.clear()
	underground = not underground
	player = (ICE_SPAWN if world == 1 else MINE_SPAWN) if underground else (Vector2(1575,385) if world == 1 else Vector2(1430,520))
	walking = false
	walk_distance = 0
	scout.animation = StringName("idle_" + str(facing))
	scout.frame = 0
	scout.position = player
	camera.position = player
	camera.reset_smoothing()
	mine_transition_cooldown = 0.6
	message = ("Frost Mine: follow either branch to find amethyst. A stronger pick is required." if world == 1 else "The Moss Mine. Follow the lanterns. Blue crystal needs a stronger pick.") if underground else "Back outside. The rocket and workbench are at your landing camp."
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
	if mining_target >= 0:
		cancel_mining()
		refresh_ui()
		return
	if cooldown > 0:
		return
	cooldown = 0.3
	if not underground and player.distance_to(ship_position()) < 95:
		travel_to_other_planet()
	elif not underground and player.distance_to(camp_position()) < 140:
		if not upgraded and ore >= 5:
			ore -= 5
			upgraded = true
			message = "Stronger pick built! Find amethyst in the Frost Mine." if world == 1 else "Stronger pick built! Enter the mine and break a glowing blue crystal."
		elif upgraded:
			message = "Your stronger pick is ready. Find amethyst in the Frost Mine!" if world == 1 else "Your stronger pick is ready. Blue crystals are inside the mine!"
		else:
			message = "Workbench: bring 5 copper from Green Planet to build a stronger pick." if world == 1 else "Workbench: collect 5 copper from the orange rocks nearby."
	else:
		var i := nearest_rock()
		if i >= 0:
			if rocks[i].hard and not upgraded:
				message = "Too tough! Bring 5 copper from Green Planet to a workbench for a stronger pick." if world == 1 else "Too tough! Build a stronger pick at camp with 5 copper."
			else:
				start_mining(i)
	refresh_ui()

func start_mining(index: int) -> void:
	if index < 0 or index >= rocks.size():
		return
	var rock: Dictionary = rocks[index]
	if rock.hp <= 0 or rock.cave != underground or player.distance_to(rock.pos) >= 100:
		return
	if rock.hard and not upgraded:
		message = "Too tough! Bring 5 copper from Green Planet to a workbench for a stronger pick." if world == 1 else "Too tough! Build a stronger pick at camp with 5 copper."
		return
	mining_target = index
	mining_elapsed = 0.0
	next_strike = IMPACT_PHASE
	walk_distance = 0.0
	walking = false
	face_direction(rock.pos - player)
	message = "Mining %s. Walk or press E again to cancel." % material_name(rock)
	update_mining_visual()

func cancel_mining() -> void:
	mining_target = -1
	mining_elapsed = 0.0
	impact_flash = 0.0
	restore_walk_visual()
	scout.animation = StringName("idle_" + str(facing))
	scout.flip_h = facing_left
	message = "Mining cancelled. You can start again whenever you're ready."

func update_mining_visual() -> void:
	var phase := fmod(mining_elapsed, STRIKE_SECONDS)
	var pose := mini(2, int(phase / (STRIKE_SECONDS / 3.0)))
	scout.sprite_frames = MINE_FRAMES
	scout.animation = StringName("mine_" + str(facing))
	scout.frame = pose
	scout.scale = Vector2.ONE * 0.22
	scout.flip_h = facing_left
	var texture_size := scout.sprite_frames.get_frame_texture(scout.animation, pose).get_size()
	var anchor: Vector2 = MINE_ANCHORS[facing][pose]
	scout.offset = texture_size * 0.5 - anchor + Vector2(0, 20.0 / 0.22)
	if facing_left:
		scout.offset.x = -scout.offset.x
	scout.position = player

func advance_mining(delta: float) -> void:
	if mining_target < 0:
		return
	var rock: Dictionary = rocks[mining_target]
	if rock.hp <= 0 or rock.cave != underground or player.distance_to(rock.pos) >= 100:
		cancel_mining()
		return
	mining_elapsed = minf(mining_elapsed + delta, rock.seconds)
	while next_strike <= mining_elapsed:
		emit_impact(rock, false)
		impact_flash = 0.16
		next_strike += STRIKE_SECONDS
	update_mining_visual()
	if mining_elapsed >= rock.seconds:
		rock.hp = 0
		emit_impact(rock, true)
		mining_target = -1
		mining_elapsed = 0.0
		impact_flash = 0.0
		restore_walk_visual()
		scout.animation = StringName("idle_" + str(facing))
		if world == 1:
			if rock.hard: amethysts += 1
			else: frost_ore += 1
			ice_won = frost_ore >= 3 and amethysts >= 1
			message = "FROST MISSION COMPLETE! You found frost ore and amethyst!" if ice_won else "Frost mission: %d / 3 frost ore, %d / 1 amethyst." % [frost_ore,amethysts]
		elif rock.hard:
			won = true
			message = "MISSION COMPLETE! You discovered blue crystal! Visit the rocket to explore Frost Canyon."
		else:
			ore += 1
			total_mined += 1
			message = "Copper collected! %d / 5 for your upgrade." % ore if not upgraded else "More copper for your next adventure!"

func emit_impact(rock: Dictionary, finished: bool) -> void:
	var origin: Vector2 = rock.pos + (player - rock.pos).normalized() * 12 + Vector2(0, -25)
	for i in (18 if finished else 9):
		var spark := i % 3 == 0
		var life := randf_range(0.4, 0.8)
		var tint := (Color("d4a5ff") if rock.hard else Color("92e8f4")) if world == 1 else (Color("92e8f4") if rock.hard else Color("ffc16f"))
		particles.append({"pos": origin, "velocity": Vector2(randf_range(-65, 65), randf_range(-100, -30)), "life": life, "max_life": life, "spark": spark, "tint": tint if spark else Color("c8b79b"), "size": randf_range(2.5, 4.0)})
	while particles.size() > 96:
		particles.pop_front()

func update_particles(delta: float) -> void:
	impact_flash = maxf(0, impact_flash - delta)
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		particle.life -= delta
		if particle.life <= 0:
			particles.remove_at(i)
		else:
			particle.velocity.y += 150 * delta
			particle.pos += particle.velocity * delta

func refresh_ui() -> void:
	green_surface.visible = world == 0 and not underground
	if status == null:
		return
	title.text = "SUNNY SCOUT   /   " + ("FROST CANYON" if world == 1 else "GREEN PLANET")
	var place := mine_name().to_upper() if underground else "SURFACE"
	status.text = "%s   •   Copper: %d   •   %s" % [place, ore, "STRONG PICK" if upgraded else "STARTER PICK"]
	if world == 1:
		status.text = "%s   •   Frost: %d/3   •   Amethyst: %d/1" % [place,frost_ore,amethysts]
	note.text = message
	action_button.text = "CANCEL [E]" if mining_target >= 0 else "MINE / USE [E]"
	if mining_target >= 0:
		var rock: Dictionary = rocks[mining_target]
		prompt.text = "%s — %.1fs left   •   Walk or press E to cancel" % [material_name(rock).capitalize(), maxf(0, rock.seconds - mining_elapsed)]
		return
	prompt.text = "Explore the paths and look for ore."
	if not underground and player.distance_to(ship_position()) < 95:
		prompt.text = "[E] Fly to Green Planet" if world == 1 else "[E] Fly to Frost Canyon — second planet"
	elif not underground and player.distance_to(camp_position()) < 140:
		prompt.text = "[E] Workbench — stronger pick costs 5 copper"
	elif (not underground and player.distance_to(cave_position()) < 130) or (underground and player.distance_to(exit_position()) < 120):
		prompt.text = "Walk into the doorway to leave the mine" if underground else "Walk into the entrance to enter " + mine_name()
	elif nearest_rock() >= 0:
		var rock: Dictionary = rocks[nearest_rock()]
		prompt.text = "[E / Space] Mine %s — %ds" % [material_name(rock),int(rock.seconds)]

func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, color)

func label_at(pos: Vector2, text: String, color := Color("f6e5b8"), size := 20) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if underground or world == 1:
		draw_rect(Rect2(0, 0, 2000, 1400), Color("182d2b") if underground else Color("719c58"))
	if underground:
		draw_texture_rect(FROST_MINE_ART if world == 1 else MINE_ART, Rect2(Vector2.ZERO, MINE_LAYOUT.WORLD_SIZE), false)
		var lamps: PackedVector2Array = FROST_LAYOUT.LAMPS if world == 1 else MINE_LAYOUT.LAMPS
		for i in lamps.size():
			var lamp := MINE_LAYOUT.from_art(lamps[i])
			var flicker := 0.012 + sin(elapsed * 4.3 + i * 2.1) * 0.004
			for radius in [25, 40, 58]:
				draw_circle(lamp, radius, Color(1.0, 0.65, 0.22, flicker))
		label_at(exit_position() + Vector2(-85, -95 if world == 1 else 80), "WALK TO SURFACE", Color("ffe4ac"), 16)
		draw_arc(exit_position(), 35, 0, TAU, 40, Color(1.0, 0.89, 0.63, 0.6), 2)
	else:
		if world == 1:
			draw_texture_rect(ICE_ART, Rect2(0, 0, 2000, 1400), false)
		label_at(camp_position() + Vector2(-95, -110), "CAMP / UPGRADE")
		label_at(cave_position() + Vector2(-65, -140), mine_name().to_upper())
		label_at(ship_position() + Vector2(-65, 80), "[E] ROCKET", Color("ffe4ac"), 18)
		for point in [camp_position(), cave_position() + Vector2(0, 85), ship_position()]:
			draw_arc(point, 36, 0, TAU, 40, Color(1, 0.89, 0.63, 0.55 + sin(elapsed * 2) * 0.15), 2)

	for rock_index in rocks.size():
		var rock: Dictionary = rocks[rock_index]
		if rock.cave != underground or rock.hp <= 0:
			continue
		var p: Vector2 = rock.pos
		if rock_index == mining_target and impact_flash > 0:
			p.x += sin(impact_flash * 110) * 2.5
		ellipse(p + Vector2(0, 13), Vector2(35, 20), Color(0, 0, 0, 0.16))
		var ore_art: Texture2D = (AMETHYST_ART if rock.hard else BLUE_ORE_ART) if world == 1 else (BLUE_ORE_ART if rock.hard else COPPER_ART)
		draw_texture_rect(ore_art, Rect2(p + Vector2(-50, -52), Vector2(100, 86)), false)
		if player.distance_to(p) < 100:
			draw_arc(p, 43, 0, TAU, 40, Color("ffe4a0"), 2)
	ellipse(player + Vector2(0, 20), Vector2(23, 9), Color(0, 0, 0, 0.25))
	if mining_target >= 0:
		var target: Dictionary = rocks[mining_target]
		var bar_pos: Vector2 = target.pos + Vector2(-48, -72)
		draw_rect(Rect2(bar_pos, Vector2(96, 10)), Color("182c2a"))
		draw_rect(Rect2(bar_pos + Vector2(2, 2), Vector2(92 * mining_elapsed / target.seconds, 6)), (Color("cb8af7") if target.hard else Color("82ddec")) if world == 1 else (Color("82ddec") if target.hard else Color("efa15a")))

func draw_mining_effects() -> void:
	for particle in particles:
		var tint: Color = particle.tint
		tint.a = particle.life / particle.max_life
		if particle.spark:
			mining_fx.draw_line(particle.pos, particle.pos - particle.velocity.normalized() * 7, tint, 2)
		else:
			mining_fx.draw_circle(particle.pos, particle.size * (2.0 - tint.a), tint)
