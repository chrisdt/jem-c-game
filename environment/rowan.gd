extends Node2D

# Feet share the same world plane as Scout's boots. Crop transparent atlas
# margins before fitting, so the source image size never sets character size.
const PEOPLE: Texture2D = preload("res://assets/npcs/earth_people_concept.png")
const FOOT := Vector2(590,454)
const MISSION_TITLE := "Ready for the Trail"
enum Mission { NOT_STARTED, ACTIVE, COMPLETE }
const INTRO: Array[String] = [
	"Let's get you ready for the trail. Find 3 copper and 2 fallen wood.",
	"Bring them to this workbench to craft a sword. It'll help with the snakes along the trails.",
]
var game: Node
var illustration: Sprite2D
var height := 0.0
var greeted := false
var introduced := false
var mission := Mission.NOT_STARTED
var completion_seen := false
var accepting_mission := false
var acknowledging_completion := false

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
	if mission == Mission.COMPLETE or game.trial.sword_owned:
		var result: Array[String] = ["That's a fine sword! You're ready for the trail."]
		if not completion_seen:
			result.append("Bea looks after Pinewood Trail. She may have a job for an explorer.")
		return result
	if mission == Mission.NOT_STARTED: return INTRO.duplicate()
	if game.ore < game.trial.SWORD_COPPER:
		return ["You have %d / 3 copper. Mine copper along Earth's trails with your pick or drill. You'll also need 2 fallen wood." % game.ore]
	if game.trial.wood < game.trial.SWORD_WOOD:
		return ["You've found the copper! You have %d / 2 wood. Gather fallen branches and logs beside the trails." % game.trial.wood]
	return ["You have everything you need. Use this workbench to craft your copper sword."]

func final_action() -> String:
	if mission == Mission.NOT_STARTED:
		return "Complete mission" if game.trial.sword_owned else "Accept mission"
	return "Done"

func conversation_started() -> void:
	# Remember what this conversation offers. Escape, a hidden speaker or scene
	# teardown must never accept an offer or acknowledge an unread ending.
	accepting_mission = mission == Mission.NOT_STARTED
	acknowledging_completion = game.trial.sword_owned and not completion_seen

func conversation_finished(completed: bool) -> void:
	if completed:
		introduced = true
		if accepting_mission and mission == Mission.NOT_STARTED:
			mission = Mission.ACTIVE
			game.message = "Mission started: Ready for the Trail. Gather 3 copper and 2 fallen wood, then craft a sword at camp."
			sync_mission()
		if acknowledging_completion and mission == Mission.COMPLETE:
			completion_seen = true
	accepting_mission = false
	acknowledging_completion = false

func sync_mission() -> void:
	# Sword ownership survives spending ingredients, equipping the drill and
	# travelling. The quest never consumes materials or grants a second sword.
	if mission == Mission.ACTIVE and game.trial.sword_owned:
		mission = Mission.COMPLETE
		game.message = "Ready for the Trail complete! Your copper sword is ready."

func progress_text() -> String:
	if mission == Mission.COMPLETE: return "Copper sword crafted"
	if game.ore >= game.trial.SWORD_COPPER and game.trial.wood >= game.trial.SWORD_WOOD:
		return "Materials ready · craft at camp"
	return "Copper %d/3 · Wood %d/2" % [mini(game.ore,game.trial.SWORD_COPPER),mini(game.trial.wood,game.trial.SWORD_WOOD)]

func _draw() -> void:
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.32))
	draw_circle(Vector2.ZERO,19,Color(0.08,0.14,0.06,0.18))
