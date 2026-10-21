extends "res://environment/human_npc.gd"

const ART = preload("res://environment/frost_art.gd")
const GRID = preload("res://environment/wind_mesh.gd")
var role := "pip"

func _ready() -> void:
	name = role.capitalize()
	var spec: Dictionary = game.frost_story.PEOPLE[role]
	home_region = spec.region
	position = game.frost_story.fit_floor(spec.foot,home_region,false)
	fit_sprite(ART.PEOPLE,ART.person_cell(role,false))
	var cell: Rect2i = ART.person_cell(role,true)
	var image := ART.PEOPLE.get_image().get_region(cell)
	var bounds := visible_bounds(image)
	var region := Rect2(bounds.position+cell.position,bounds.size)
	var art_scale := height/region.size.y
	greeting_wave = MeshInstance2D.new()
	greeting_wave.texture = ART.PEOPLE
	greeting_wave.mesh = GRID.make(region.size)
	greeting_wave.scale = Vector2.ONE*art_scale
	greeting_wave.position = Vector2(-(ground_centre(image,bounds)-bounds.position.x),-region.size.y)*art_scale
	var material := ShaderMaterial.new()
	material.shader = GREETING.WAVE
	material.set_shader_parameter("atlas_origin",region.position/ART.PEOPLE.get_size())
	material.set_shader_parameter("atlas_size",region.size/ART.PEOPLE.get_size())
	material.set_shader_parameter("cell_size",region.size)
	material.set_shader_parameter("elbow",Vector2(0.82,0.55))
	material.set_shader_parameter("palm",Vector2(0.85,0.40))
	greeting_wave.material = material
	greeting_wave.hide()
	add_child(greeting_wave)
	sync_area()

func sync_area() -> void:
	visible = not departed and game.world == 1 and game.current_region() == home_region and not game.underground and game.flight == 0 and not game.earth_transition and game.fog.is_revealed(game.area_id(),position)

func pages() -> Array[String]: return game.frost_story.pages(role)
func final_action() -> String: return game.frost_story.action(role)
func conversation_started() -> void: game.frost_story.begin(role)
func conversation_finished(completed: bool) -> void:
	if completed: introduced = true
	game.frost_story.finish(role,completed)
func quest_finished() -> bool: return game.frost_story.done(role)
func greeting_text() -> String:
	return {"pip":"Hello, traveller! Our aurora beacons need a little help.","nix":"Your next sword could sparkle with frost crystal!","tavi":"A crystal drill can uncover the oldest ice.","eira":"A lost expedition left a secret in Glacier Crown."}[role]
