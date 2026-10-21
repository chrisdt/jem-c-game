extends "res://environment/human_npc.gd"

const ART = preload("res://environment/ember_art.gd")
const GRID = preload("res://environment/wind_mesh.gd")
var role := "sol"

func _ready() -> void:
	name = role.capitalize()
	var spec: Dictionary = game.ember_story.PEOPLE[role]
	home_region = spec.region
	position = game.ember_story.fit_floor(spec.foot,home_region,false)
	# Atlas bounds/boot anchors are measured offline. Avoid scanning millions
	# of source pixels in GDScript every time a browser starts the game.
	height = 87.45
	var column: int = ["sol","luma","brasa","orin"].find(role)
	var record: Dictionary = ART.metadata.sunstone_folk[0][column]
	illustration = Sprite2D.new()
	illustration.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	illustration.texture = ART.texture(ART.PEOPLE,"sunstone_folk",0,column)
	illustration.centered = false
	illustration.offset = -Vector2(record.anchor[0],record.anchor[1])
	illustration.scale = Vector2.ONE*(height/record.region[3])
	add_child(illustration)
	modulate.a = 0
	var wave: Dictionary = ART.metadata.sunstone_folk[1][column]
	var region: Rect2 = ART.FROST.rect(wave.region)
	var art_scale: float = height/region.size.y
	greeting_wave = MeshInstance2D.new()
	greeting_wave.texture = ART.PEOPLE
	greeting_wave.mesh = GRID.make(region.size)
	greeting_wave.scale = Vector2.ONE*art_scale
	greeting_wave.position = -Vector2(wave.anchor[0],wave.anchor[1])*art_scale
	var material := ShaderMaterial.new()
	material.shader = GREETING.WAVE
	material.set_shader_parameter("atlas_origin",region.position/ART.PEOPLE.get_size())
	material.set_shader_parameter("atlas_size",region.size/ART.PEOPLE.get_size())
	material.set_shader_parameter("cell_size",region.size)
	material.set_shader_parameter("elbow",Vector2(0.24,0.50))
	material.set_shader_parameter("palm",Vector2(0.17,0.30))
	greeting_wave.material = material
	greeting_wave.hide()
	add_child(greeting_wave)
	sync_area()

func sync_area() -> void:
	visible = not departed and game.world == 2 and game.current_region() == home_region and not game.underground and game.flight == 0 and not game.earth_transition and game.fog.is_revealed(game.area_id(),position)

func pages() -> Array[String]: return game.ember_story.pages(role)
func final_action() -> String: return game.ember_story.action(role)
func conversation_started() -> void: game.ember_story.begin(role)
func conversation_finished(completed: bool) -> void:
	if completed: introduced = true
	game.ember_story.finish(role,completed)
func quest_finished() -> bool: return game.ember_story.done(role)
func greeting_text() -> String:
	return {"sol":"Welcome to Ember Dunes! Let's cool things down.","luma":"The oasis has a cure for scorpion venom.","brasa":"A Sunforge core can power your next tools!","orin":"An ancient star map waits beneath cooled lava."}[role]
