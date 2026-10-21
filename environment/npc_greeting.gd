extends RefCounted

# One shared painted greeting atlas. Only the raised forearm bends; the head,
# torso and boots stay fixed. The existing idle portrait remains the rest pose.
const ART: Texture2D = preload("res://assets/npcs/earth_greeting_people.png")
const WAVE: Shader = preload("res://shaders/npc_wave.gdshader")
const GRID = preload("res://environment/wind_mesh.gd")
const ROLES := ["rowan","otis","bea","mara","iris","finn","nova"]
static var frames: Dictionary = {}

static func make(person: Node2D, role: String) -> MeshInstance2D:
	if not frames.has(role):
		var index: int = ROLES.find(role)
		var cell := Rect2i((index%4)*384,0 if index < 4 else 530,384,531 if index < 4 else 494)
		var image := ART.get_image().get_region(cell)
		var bounds: Rect2i = person.visible_bounds(image)
		var anchor: float = person.ground_centre(image,bounds)-bounds.position.x
		frames[role] = {"region":Rect2(bounds.position+cell.position,bounds.size),"anchor":anchor}
	var frame: Dictionary = frames[role]
	var region: Rect2 = frame.region
	var scale: float = person.height/region.size.y
	var sprite := MeshInstance2D.new()
	sprite.name = "GreetingWave"
	sprite.texture = ART
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.mesh = GRID.make(region.size)
	sprite.scale = Vector2.ONE*scale
	sprite.position = Vector2(-frame.anchor,-region.size.y)*scale
	var material := ShaderMaterial.new()
	material.shader = WAVE
	material.set_shader_parameter("atlas_origin",region.position/ART.get_size())
	material.set_shader_parameter("atlas_size",region.size/ART.get_size())
	material.set_shader_parameter("cell_size",region.size)
	material.set_shader_parameter("palm",Vector2(0.115,0.35 if role in ["finn","nova"] else 0.31))
	sprite.material = material
	sprite.hide()
	person.add_child(sprite)
	return sprite
