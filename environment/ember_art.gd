extends RefCounted
const PEOPLE: Texture2D = preload("res://assets/sunforge/sunstone_folk.png")
const ITEMS: Texture2D = preload("res://assets/sunforge/items.png")
const SCORPION: Texture2D = preload("res://assets/sunforge/scorpion.png")
const FROST = preload("res://environment/frost_art.gd")
const SHADER = preload("res://shaders/sunforge_equipment.gdshader")
static var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sunforge/atlas.json"))
static var textures: Dictionary = {}
static var materials: Dictionary = {}
static func texture(sheet: Texture2D, key: String, row: int, col: int) -> Texture2D:
	var id := "%s/%d/%d" % [key,row,col]
	if not textures.has(id):
		var part := AtlasTexture.new()
		part.atlas = sheet
		part.region = FROST.rect(metadata[key][row][col].region)
		part.filter_clip = true
		textures[id] = part
	return textures[id]
static func person_cell(role: String, waving: bool) -> Rect2i:
	return Rect2i(FROST.rect(metadata.sunstone_folk[int(waving)][["sol","luma","brasa","orin"].find(role)].region))
static func item(index: int) -> Texture2D: return texture(ITEMS,"items",index/4,index%4)
static func scorpion_pose(row: int, frame: int) -> Dictionary:
	var record: Dictionary = metadata.scorpion[row][frame]
	return {"texture":texture(SCORPION,"scorpion",row,frame),"anchor":Vector2(record.anchor[0],record.anchor[1]),"scale":88.0/metadata.scorpion[row][0].region[3]}
static func material_for(key: String) -> ShaderMaterial:
	if not materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		materials[key] = material
	return materials[key]
static func fit_drill(sprite: AnimatedSprite2D, direction: StringName) -> void:
	var material := material_for("drill_"+str(direction))
	material.set_shader_parameter("blade",false)
	FROST.configure_atlas(material,sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame))
	material.set_shader_parameter("tool_bounds",{&"side":Vector4(0.67,0.32,1.0,0.79),&"down":Vector4(0.37,0.43,0.70,0.83),&"up":Vector4(0.66,0.28,1.0,0.70)}[direction])
	sprite.material = material
static func fit_jab(sprite: AnimatedSprite2D, space: bool, direction: StringName, frame: int) -> void:
	FROST.fit_jab(sprite,space,direction,frame,false)
	if frame == 0: return
	var material := material_for("blade_"+str(direction))
	material.set_shader_parameter("blade",true)
	material.set_shader_parameter("tool_bounds",{&"side":Vector4(0.62,0.20,1.0,0.70),&"down":Vector4(0.30,0.48,0.72,0.92),&"up":Vector4(0.65,0.0,1.0,0.68)}[direction])
	FROST.configure_atlas(material,sprite.sprite_frames.get_frame_texture(sprite.animation,frame))
	sprite.material = material
