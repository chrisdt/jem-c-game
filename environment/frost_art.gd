extends RefCounted

const PEOPLE: Texture2D = preload("res://assets/frozen/snow_sprites.png")
const BEACON_FRAGMENT: Texture2D = preload("res://assets/frozen/beacon_fragment.png")
const ITEMS: Texture2D = preload("res://assets/frozen/items.png")
const YETI: Texture2D = preload("res://assets/frozen/yeti.png")
const MINER_JAB: Texture2D = preload("res://assets/frozen/frost_jab.png")
const SPACE_JAB: Texture2D = preload("res://assets/frozen/space_jab.png")
const EQUIPMENT_SHADER: Shader = preload("res://shaders/frost_equipment.gdshader")
static var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/frozen/atlas.json"))
static var textures: Dictionary = {}
static var frames: Dictionary = {}
static var materials: Dictionary = {}

static func rect(values: Array) -> Rect2:
	return Rect2(values[0],values[1],values[2],values[3])
static func texture(sheet: Texture2D, key: String, row: int, col: int) -> Texture2D:
	var id := "%s/%d/%d" % [key,row,col]
	if not textures.has(id):
		var part := AtlasTexture.new()
		part.atlas = sheet
		part.region = rect(metadata[key][row][col].region)
		part.filter_clip = true
		textures[id] = part
	return textures[id]
static func person_cell(role: String, waving: bool) -> Rect2i:
	return Rect2i(rect(metadata.snow_sprites[int(waving)][["pip","nix","tavi","eira"].find(role)].region))
static func item(index: int) -> Texture2D:
	if index == 2:
		if not textures.has("beacon_fragment"):
			var part := AtlasTexture.new()
			part.atlas = BEACON_FRAGMENT
			# Trim the dedicated illustration's transparent padding. Coordinates
			# scale with the import size; no neighbouring sheet cells can bleed in.
			var source_size := Vector2(1308,1203)
			var scale := BEACON_FRAGMENT.get_size()/source_size
			part.region = Rect2(Vector2(344,154)*scale,Vector2(652,904)*scale)
			part.filter_clip = true
			textures["beacon_fragment"] = part
		return textures["beacon_fragment"]
	return texture(ITEMS,"items",index/4,index%4)
static func yeti_pose(row: int, frame: int) -> Dictionary:
	var record: Dictionary = metadata.yeti[row][frame]
	return {"texture":texture(YETI,"yeti",row,frame),"anchor":Vector2(record.anchor[0],record.anchor[1]),"scale":112.0/metadata.yeti[row][0].region[3]}
static func make_jab_frames(space: bool) -> SpriteFrames:
	if frames.has(space): return frames[space]
	var source: Texture2D = SPACE_JAB if space else MINER_JAB
	var key := "space_jab" if space else "frost_jab"
	var result := SpriteFrames.new()
	result.remove_animation(&"default")
	for row in 3:
		var animation: StringName = StringName("jab_"+["side","down","up"][row])
		result.add_animation(animation)
		result.set_animation_loop(animation,false)
		for col in 4: result.add_frame(animation,texture(source,key,row,col))
	frames[space] = result
	return result
static func fit_jab(sprite: AnimatedSprite2D, space: bool, direction: StringName, frame: int, copper: bool) -> void:
	var row: int = {&"side":0,&"down":1,&"up":2}[direction]
	var key := "space_jab" if space else "frost_jab"
	var record: Dictionary = metadata[key][row][frame]
	var anchor := Vector2(record.anchor[0],record.anchor[1])
	var scale: float = 87.45/metadata[key][row][0].region[3]
	sprite.scale = Vector2.ONE*scale
	sprite.offset = sprite.sprite_frames.get_frame_texture(sprite.animation,frame).get_size()*0.5-anchor+Vector2(0,20.0/scale)
	if sprite.flip_h: sprite.offset.x = -sprite.offset.x
	if copper and frame > 0:
		var material := material_for("copper_"+str(direction))
		material.set_shader_parameter("copper_blade",true)
		material.set_shader_parameter("tool_bounds",{&"side":Vector4(0.62,0.20,1.0,0.70),&"down":Vector4(0.30,0.48,0.72,0.92),&"up":Vector4(0.65,0.0,1.0,0.68)}[direction])
		configure_atlas(material,sprite.sprite_frames.get_frame_texture(sprite.animation,frame))
		sprite.material = material
static func material_for(key: String) -> ShaderMaterial:
	if not materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = EQUIPMENT_SHADER
		materials[key] = material
	return materials[key]
static func configure_atlas(material: ShaderMaterial, source: Texture2D) -> void:
	var atlas := source as AtlasTexture
	material.set_shader_parameter("atlas_origin",atlas.region.position/atlas.atlas.get_size() if atlas != null else Vector2.ZERO)
	material.set_shader_parameter("atlas_size",atlas.region.size/atlas.atlas.get_size() if atlas != null else Vector2.ONE)
static func fit_drill(sprite: AnimatedSprite2D, direction: StringName) -> void:
	var material := material_for("drill_"+str(direction))
	material.set_shader_parameter("copper_blade",false)
	configure_atlas(material,sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame))
	var bounds: Vector4 = {&"side":Vector4(0.67,0.32,1.0,0.79),&"down":Vector4(0.37,0.43,0.70,0.83),&"up":Vector4(0.66,0.28,1.0,0.70)}[direction]
	material.set_shader_parameter("tool_bounds",bounds)
	sprite.material = material
