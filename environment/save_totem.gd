extends Node2D

const STYLE = preload("res://ui/expedition_style.gd")
const ART := [preload("res://assets/saves/earth_totem.png"),preload("res://assets/saves/frost_totem.png"),preload("res://assets/saves/ember_totem.png")]
const COLOURS := [Color("51f6a6"),Color("72dbff"),Color("ffb339")]
# Exactly two outdoor checkpoints per world: starting camp + a far district.
const HOMES := {
	0:{0:Vector2(730,450),3:Vector2(1170,780)},
	1:{0:Vector2(860,1050),4:Vector2(1450,1090)},
	2:{0:Vector2(1370,1100),4:Vector2(660,750)},
}
const RADIUS := 88.0
const REENTER_DISTANCE := 125.0
const RESAVE_SECONDS := 20.0
var game: Node
var session: Node
var picture: Sprite2D
var glow: Node2D
var caption: Label
var area := -1
var colour := Color.WHITE
var seconds := 0.0
var flare := 0.0
var message_seconds := 0.0
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
	caption = Label.new()
	caption.position = Vector2(-150,-132)
	caption.size = Vector2(300,40)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font",STYLE.BODY)
	caption.add_theme_font_size_override("font_size",15)
	caption.add_theme_color_override("font_color",Color("fff3d0"))
	caption.add_theme_color_override("font_outline_color",Color("142c2a"))
	caption.add_theme_constant_override("outline_size",5)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	session.checkpoint_saved.connect(saved)
	refresh_area()

func refresh_area() -> void:
	visible = not game.run_session.timed and not game.underground and game.flight == 0 and not game.earth_transition and HOMES[game.world].has(game.current_region())
	if not visible: return
	var key: int = game.area_id()
	if area != key:
		area = key
		entered = restored_checkpoint
		retry_after = RESAVE_SECONDS if restored_checkpoint else 0.0
		restored_checkpoint = false
		flare = 0
		message_seconds = 0
		colour = COLOURS[game.world]
		if not points.has(key): points[key] = find_site(HOMES[game.world][game.current_region()])
		position = points[key]
		var texture: Texture2D = ART[game.world]
		var bounds := texture.get_image().get_used_rect()
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
	message_seconds = maxf(0,message_seconds-delta)
	retry_after = maxf(0,retry_after-delta)
	caption.visible = message_seconds > 0 or game.player.distance_to(position) < 150
	if message_seconds <= 0: caption.text = "Save totem · walk close"
	if game.player.distance_to(position) > REENTER_DISTANCE: entered = false
	if not game.menu_open() and not game.hud.help.visible and can_save() and not session.busy and (not entered or retry_after <= 0):
		entered = true
		retry_after = RESAVE_SECONDS
		keep_checkpoint()
	glow.queue_redraw()
	queue_redraw()

func keep_checkpoint() -> void:
	if not await session.checkpoint(game):
		caption.text = "Check your checkpoint · Save menu"
		message_seconds = 4

func saved() -> void:
	if not visible or game.run_session.timed or game.player.distance_to(position) > RADIUS: return
	flare = 0.8
	message_seconds = 3.0
	caption.text = "Adventure saved"

func _draw() -> void:
	if not visible: return
	draw_set_transform(Vector2(0,2),0,Vector2(1,0.36))
	draw_circle(Vector2.ZERO,30,Color(0.025,0.06,0.07,0.23))
	draw_circle(Vector2.ZERO,22,Color(0.025,0.06,0.07,0.17))
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
