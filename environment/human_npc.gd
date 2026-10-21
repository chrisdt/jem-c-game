extends Node2D

# Shared foot anchor, art fitting and interaction contract for Earth's people.
# Transparent source margins must never determine a character's visible size.
var game: Node
var illustration: Sprite2D
var height := 0.0
var home_region := 0
var greeted := false
var introduced := false
const GREETING = preload("res://environment/npc_greeting.gd")
const REVEAL_SECONDS := 0.75
const WAVE_SECONDS := 2.4
var greeting_wave: MeshInstance2D
var reveal_time := 0.0
var has_waved := false
var wave_time := -1.0
var wave_blend := 0.0
const PORTRAITS: Texture2D = preload("res://assets/npcs/earth_compact_people.png")
const PORTRAIT_CELLS := {
	"rowan":Rect2i(70,5,340,545),"otis":Rect2i(410,5,360,545),
	"bea":Rect2i(785,5,375,545),"mara":Rect2i(1180,5,345,545),
	"iris":Rect2i(35,550,330,474),"finn":Rect2i(430,550,320,474),
	"nova":Rect2i(790,550,330,474),
}
var departing := false
var departed := false
var departure_time := 0.0
const DEPARTURE_SECONDS := 0.8

func fit_person(role: String) -> void:
	fit_sprite(PORTRAITS,PORTRAIT_CELLS[role])
	greeting_wave = GREETING.make(self,role)

func fit_sprite(source: Texture2D, source_region := Rect2i()) -> void:
	# The compact portraits share Scout's body proportions. Cap the complete
	# visible figure to Scout's height instead of enlarging a taller body to
	# match its face. Source image padding never determines the rendered size.
	var scout: Texture2D = game.MINER_FRAMES.get_frame_texture(&"idle_down",0)
	height = visible_bounds(scout.get_image()).size.y*0.15
	var source_image := source.get_image()
	var origin := Vector2i.ZERO
	if source_region.has_area():
		source_image = source_image.get_region(source_region)
		origin = source_region.position
	var bounds := visible_bounds(source_image)
	var art_scale := height/bounds.size.y
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(bounds.position+origin,bounds.size)
	illustration = Sprite2D.new()
	illustration.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	illustration.texture = atlas
	illustration.centered = false
	illustration.offset = Vector2(-(ground_centre(source_image,bounds)-bounds.position.x),-bounds.size.y)
	illustration.scale = Vector2.ONE*art_scale
	add_child(illustration)
	modulate.a = 0

static func ground_centre(image: Image, bounds: Rect2i) -> float:
	# Anchor the middle of the boots, rather than the whole silhouette: an
	# outstretched hand must not shift the feet away from their contact shadow.
	var boots := Rect2i(bounds.position+Vector2i(0,int(bounds.size.y*0.84)),Vector2i(bounds.size.x,bounds.size.y-int(bounds.size.y*0.84)))
	var feet := visible_bounds(image.get_region(boots))
	return boots.position.x+feet.position.x+feet.size.x*0.5

static func visible_bounds(image: Image) -> Rect2i:
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	var low := Vector2i(image.get_width(),image.get_height())
	var high := Vector2i(-1,-1)
	for y in image.get_height():
		for x in image.get_width():
			if data[(y*image.get_width()+x)*4+3] < 32: continue
			low.x = mini(low.x,x)
			low.y = mini(low.y,y)
			high.x = maxi(high.x,x)
			high.y = maxi(high.y,y)
	return Rect2i(low,high-low+Vector2i.ONE)

func sync_area() -> void:
	visible = not departed and game.world == 0 and game.earth_region == home_region and not game.underground and game.flight == 0 and not game.earth_transition and game.fog.is_revealed(game.area_id(),position)

func can_talk() -> bool:
	if departing or departed or quest_finished() or not is_visible_in_tree() or game.player.distance_to(position) >= 100: return false
	# In overlapping approach areas, keep the nearer workbench usable.
	return not game.at_workbench() or game.player.distance_to(position) < game.player.distance_to(game.camp_position())

func greeting_text() -> String:
	return "Hello, explorer!"

func pages() -> Array[String]:
	return []

func final_action() -> String:
	return "Done"

func conversation_started() -> void:
	pass

func conversation_finished(completed: bool) -> void:
	if completed: introduced = true

func quest_finished() -> bool:
	return false

func begin_departure() -> void:
	if departing or departed: return
	departing = true
	departure_time = 0
	greeted = true
	wave_time = -1
	wave_blend = 0
	if is_instance_valid(greeting_wave): greeting_wave.hide()
	queue_redraw()

func presentation_paused() -> bool:
	return game.get_tree().paused or game.menu_open() or game.hud.help.visible or game.flight != 0 or game.earth_transition

func advance_presentation(delta: float) -> void:
	if departed or not is_visible_in_tree() or presentation_paused(): return
	reveal_time = minf(REVEAL_SECONDS,reveal_time+maxf(0,delta))
	modulate.a = smoothstep(0,REVEAL_SECONDS,reveal_time)
	if departing or quest_finished():
		queue_redraw()
		return
	# Greet once when an explorer actually approaches; revealing a distant
	# neighbour should not consume their wave before the player reaches them.
	if not has_waved and modulate.a >= 0.7 and game.player.distance_to(position) < 200:
		has_waved = true
		wave_time = 0
	if wave_time >= 0:
		wave_time = minf(WAVE_SECONDS,wave_time+maxf(0,delta))
		wave_blend = smoothstep(0,0.2,wave_time)*(1-smoothstep(WAVE_SECONDS-0.2,WAVE_SECONDS,wave_time))
		greeting_wave.show()
		greeting_wave.modulate.a = wave_blend
		greeting_wave.material.set_shader_parameter("wave_angle",0.16*sin(wave_time*TAU*1.7)*sin(PI*wave_time/WAVE_SECONDS))
		illustration.modulate.a = 1-wave_blend
		if wave_time >= WAVE_SECONDS:
			wave_time = -1
			greeting_wave.hide()
			illustration.modulate.a = 1
	queue_redraw()

func advance_departure(delta: float) -> void:
	if departed: return
	if presentation_paused(): return
	if not departing and quest_finished():
		if not is_visible_in_tree():
			departed = true
			hide()
			return
		begin_departure()
	if not departing: return
	departure_time = minf(DEPARTURE_SECONDS,departure_time+maxf(0,delta))
	illustration.modulate.a = 1-smoothstep(0.05,0.3,departure_time)
	if departure_time >= DEPARTURE_SECONDS:
		departed = true
		departing = false
		hide()
	queue_redraw()

func _process(delta: float) -> void:
	advance_presentation(delta)
	advance_departure(delta)

func _draw() -> void:
	# Layer soft ellipses at the boot anchor. Keep the contact narrow and let
	# it fade with the person instead of drawing an opaque floating platform.
	var shadow_alpha := 1-smoothstep(0,0.35,departure_time) if departing else 1.0
	draw_set_transform(Vector2(0,1.8),0,Vector2(1,0.32))
	for layer in 4:
		draw_circle(Vector2.ZERO,23-layer*3,Color(0.06,0.10,0.035,(0.035+layer*0.014)*shadow_alpha))
	draw_set_transform(Vector2.ZERO)
	if departing:
		var t := departure_time/DEPARTURE_SECONDS
		var centre := Vector2(0,-height*0.45-14*t)
		# Fill the middle and vary the surrounding lobes like the mine critter
		# puff; an evenly spaced ring alone reads as a hollow flower.
		draw_circle(centre,17+13*t,Color(0.90,0.90,0.84,sin(t*PI)*0.60))
		for i in 11:
			var angle := i*TAU/11+0.17*sin(i*2.7)
			var at := centre+Vector2.from_angle(angle)*(7+19*t)*(0.72+0.12*(i%3))
			draw_circle(at,9+2*(i%3)+8*t,Color(0.88,0.88,0.80,sin(t*PI)*0.42))
		return
