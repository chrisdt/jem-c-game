extends Node2D

# Feet share the same world plane as Scout's boots. Crop transparent atlas
# margins before fitting, so the source image size never sets character size.
const PEOPLE: Texture2D = preload("res://assets/npcs/earth_people_concept.png")
const FOOT := Vector2(590,454)
const INTRO: Array[String] = [
	"Let's get you ready for the trail. Find 3 copper and 2 fallen wood.",
	"Bring them to this workbench to craft a sword. It'll help with the snakes along the trails.",
]
var game: Node
var illustration: Sprite2D
var height := 0.0
var greeted := false
var introduced := false

func _ready() -> void:
	name = "Rowan"
	position = FOOT
	var scout_art: Texture2D = game.MINER_FRAMES.get_frame_texture(&"idle_down",0)
	height = visible_bounds(scout_art.get_image()).size.y*0.15
	var bounds := visible_bounds(PEOPLE.get_image().get_region(Rect2i(0,0,768,1024)))
	var atlas := AtlasTexture.new()
	atlas.atlas = PEOPLE
	atlas.region = Rect2(bounds)
	illustration = Sprite2D.new()
	illustration.texture = atlas
	illustration.centered = false
	illustration.offset = Vector2(-bounds.size.x*0.5,-bounds.size.y)
	illustration.scale = Vector2.ONE*(height/bounds.size.y)
	add_child(illustration)
	sync_area()

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
	visible = game.world == 0 and game.earth_region == 0 and not game.underground and game.flight == 0 and not game.earth_transition and game.fog.is_revealed(game.area_id(),position)

func can_talk() -> bool:
	if not is_visible_in_tree() or game.player.distance_to(position) >= 100: return false
	# In the overlapping approach areas, use whichever person/station is closer.
	return not game.at_workbench() or game.player.distance_to(position) < game.player.distance_to(game.camp_position())

func pages() -> Array[String]:
	if game.trial.sword_owned:
		return ["That's a fine sword! You're ready for the trail."]
	if not introduced: return INTRO.duplicate()
	if game.ore < 3:
		return ["Look for copper along the trails. You'll need 3 copper and 2 fallen wood for your sword."]
	if game.trial.wood < 2:
		return ["You've found the copper! Look for fallen wood beside the trails. You'll need 2 pieces."]
	return ["You have everything you need. Use this workbench to craft your copper sword."]

func _draw() -> void:
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.32))
	draw_circle(Vector2.ZERO,19,Color(0.08,0.14,0.06,0.18))
