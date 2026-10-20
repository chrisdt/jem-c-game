extends Node2D

# Shared foot anchor, art fitting and interaction contract for Earth's people.
# Transparent source margins must never determine a character's visible size.
var game: Node
var illustration: Sprite2D
var height := 0.0
var home_region := 0
var greeted := false
var introduced := false

func fit_sprite(source: Texture2D, source_region := Rect2i()) -> void:
	var scout_art: Texture2D = game.MINER_FRAMES.get_frame_texture(&"idle_down",0)
	height = visible_bounds(scout_art.get_image()).size.y*0.15
	var source_image := source.get_image()
	var origin := Vector2i.ZERO
	if source_region.has_area():
		source_image = source_image.get_region(source_region)
		origin = source_region.position
	var bounds := visible_bounds(source_image)
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(bounds.position+origin,bounds.size)
	illustration = Sprite2D.new()
	illustration.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	illustration.texture = atlas
	illustration.centered = false
	illustration.offset = Vector2(-bounds.size.x*0.5,-bounds.size.y)
	illustration.scale = Vector2.ONE*(height/bounds.size.y)
	add_child(illustration)

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
	visible = game.world == 0 and game.earth_region == home_region and not game.underground and game.flight == 0 and not game.earth_transition and game.fog.is_revealed(game.area_id(),position)

func can_talk() -> bool:
	if not is_visible_in_tree() or game.player.distance_to(position) >= 100: return false
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

func _draw() -> void:
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.32))
	draw_circle(Vector2.ZERO,19,Color(0.08,0.14,0.06,0.18))
