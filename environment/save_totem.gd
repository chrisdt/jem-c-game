extends Node2D

const STYLE = preload("res://ui/expedition_style.gd")
const BUBBLE = preload("res://ui/character_bubble.gd")
# Paths intentionally stay strings: a newly unpacked editor project may not
# have generated these textures yet. Never make game.gd parsing depend on them.
const ART := ["res://assets/saves/earth_totem.png","res://assets/saves/frost_totem.png","res://assets/saves/ember_totem.png"]
static var textures: Dictionary = {}
const COLOURS := [Color("51f6a6"),Color("72dbff"),Color("ffb339")]
# One checkpoint per world, at its starting camp.
const HOMES := {
	0:{0:Vector2(730,450)},
	1:{0:Vector2(580,1165)},
	2:{0:Vector2(1555,970)},
}
const RADIUS := 88.0
const REENTER_DISTANCE := 125.0
const RESAVE_SECONDS := 20.0
var game: Node
var session: Node
var picture: Sprite2D
var glow: Node2D
var bubble: BUBBLE
var area := -1
var colour := Color.WHITE
var seconds := 0.0
var flare := 0.0
var feedback := ""
var saving_started_ms := 0
var saving_area := -1
var feedback_generation := 0
var entered := false
var retry_after := 0.0
var points: Dictionary = {}
var restored_checkpoint := false

func _ready() -> void:
	name = "SaveTotem"
	session = get_node("/root/AdventureSave")
	picture = Sprite2D.new()
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(picture)
	glow = Node2D.new()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	glow.draw.connect(draw_glow)
	add_child(glow)
	bubble = BUBBLE.new()
	bubble.hint_width = 170
	bubble.center_hint = true
	add_child(bubble)
	session.checkpoint_started.connect(started)
	session.checkpoint_finished.connect(finished)
	refresh_area()

static func texture_for(world: int) -> Texture2D:
	if textures.has(world): return textures[world]
	var path: String = ART[world]
	var texture: Texture2D
	if not OS.has_feature("web") and FileAccess.file_exists(path):
		# Native/editor fallback reads the shipped PNG, independent of machine-
		# specific .godot/imported/*.ctex files. Web uses its packaged imports.
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			var factor := 256.0/maxi(image.get_width(),image.get_height())
			image.resize(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
			image.fix_alpha_edges()
			image.generate_mipmaps()
			texture = ImageTexture.create_from_image(image)
	else:
		texture = load(path) as Texture2D
	if texture != null: textures[world] = texture
	return texture

func refresh_area() -> void:
	visible = not game.run_session.timed and not game.underground and game.flight == 0 and not game.earth_transition and HOMES[game.world].has(game.current_region())
	if not visible:
		if is_instance_valid(bubble): bubble.dismiss()
		return
	var key: int = game.area_id()
	if area != key:
		area = key
		entered = restored_checkpoint
		retry_after = RESAVE_SECONDS if restored_checkpoint else 0.0
		restored_checkpoint = false
		flare = 0
		feedback = ""
		colour = COLOURS[game.world]
		if not points.has(key): points[key] = find_site(HOMES[game.world][game.current_region()])
		position = points[key]
		var texture := texture_for(game.world)
		if texture == null:
			hide()
			return
		# Faint alpha specks extend below the painted base. Crop to visible
		# pixels, as for NPC feet, so the stone touches its contact shadow.
		var bounds: Rect2i = game.HUMAN_NPC.visible_bounds(texture.get_image())
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(bounds)
		picture.texture = atlas
		picture.scale = Vector2.ONE*94.0/bounds.size.y
		picture.offset = Vector2(0,-bounds.size.y*0.5)
	visible = position.is_finite() and game.fog.is_revealed(key,position)

func find_site(preferred: Vector2) -> Vector2:
	for ring in 22:
		for ray in 24:
			var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*10
			var clear := true
			for offset in [Vector2.ZERO,Vector2(-32,0),Vector2(32,0),Vector2(0,-22),Vector2(0,22)]:
				if not game.trial.floor_at(point+offset): clear = false
			for rock in game.rocks:
				if not rock.cave and rock.hp > 0 and point.distance_to(rock.pos) < 130: clear = false
			for npc in game.npcs + game.frost_story.npcs + game.ember_story.npcs:
				if npc.home_region == game.current_region() and npc.position.distance_to(point) < 100: clear = false
			if clear: return point
	return Vector2.INF

func can_save() -> bool:
	if game.run_session.timed or game.underground or game.flight != 0 or game.earth_transition or game.trial.health <= 0: return false
	if not HOMES[game.world].has(game.current_region()) or not position.is_finite() or area != game.area_id(): return false
	if game.player.distance_to(position) > RADIUS or not game.trial.clear_line(game.player,position): return false
	for target in game.trial.targets():
		if target.health > 0 and target.position.distance_to(game.player) < 165: return false
	return true

func resume_checkpoint() -> void:
	# The starting map may already be the node's active area before restore.
	# Suppress both that case and a streamed restored area's first approach.
	restored_checkpoint = area != game.area_id()
	entered = true
	retry_after = RESAVE_SECONDS

func _process(delta: float) -> void:
	refresh_area()
	if not visible: return
	seconds += delta
	flare = maxf(0,flare-delta)
	retry_after = maxf(0,retry_after-delta)
	if game.player.distance_to(position) > REENTER_DISTANCE: entered = false
	if not game.menu_open() and not game.hud.help.visible and can_save() and not session.busy and (not entered or retry_after <= 0):
		entered = true
		retry_after = RESAVE_SECONDS
		keep_checkpoint()
	glow.queue_redraw()
	queue_redraw()

func keep_checkpoint() -> void:
	if not await session.checkpoint(game):
		if feedback != "Saving...": show_feedback("Check your checkpoint in Save",4)

func show_feedback(text: String, duration: float) -> void:
	if not is_visible_in_tree() or game.run_session.timed: return
	feedback = text
	bubble.hint_width = 170 if text in ["Saving...","Saved"] else 250
	bubble.show_hint(text,self,Vector2(0,-100),duration)

func started() -> void:
	if not can_save(): return
	feedback_generation += 1
	saving_area = game.area_id()
	saving_started_ms = Time.get_ticks_msec()
	show_feedback("Saving...",60)

func finished(kept: bool, online: bool) -> void:
	if saving_area < 0: return
	var generation := feedback_generation
	# Let even a fast local save show Saving before showing the result.
	var remaining := 0.4-(Time.get_ticks_msec()-saving_started_ms)/1000.0
	if remaining > 0: await get_tree().create_timer(remaining).timeout
	if generation != feedback_generation or game.area_id() != saving_area or not is_visible_in_tree() or game.run_session.timed: return
	saving_area = -1
	if kept:
		flare = 0.8
		show_feedback("Saved" if online else "Saved on this device",3)
	else:
		show_feedback("Couldn't save · open Save",4)

func _draw() -> void:
	if not visible: return
	draw_set_transform(Vector2(0,-2),0,Vector2(1,0.27))
	draw_circle(Vector2.ZERO,26,Color(0.025,0.06,0.07,0.18))
	draw_circle(Vector2.ZERO,19,Color(0.025,0.06,0.07,0.19))
	draw_set_transform(Vector2.ZERO)

func draw_glow() -> void:
	if not visible: return
	# One smooth 0.8-second coloured burst. No repeating flashes. The lit
	# area is centred on the crystal, leaving the pedestal's material intact.
	var pulse := sin(clampf(flare/0.8,0,1)*PI)
	var strength := 0.11+0.035*sin(seconds*2)+pulse*0.85
	var center := Vector2(0,-64)
	for i in range(20,0,-1):
		var radius := i/20.0*(17+pulse*17)
		glow.draw_circle(center,radius,Color(colour,strength*0.035))
	if flare > 0:
		for i in 7:
			var angle := i*TAU/7.0+0.3
			var at := center+Vector2.from_angle(angle)*(12+(1-flare/0.8)*27)
			glow.draw_circle(at,1.2,Color(colour,pulse*0.8))
