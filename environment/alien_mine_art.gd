extends RefCounted

# Approved Frost/Ember alien designs, four illustrated poses per species.
# Source pixels are kept intact; atlas crops and foot anchors compensate for
# each pose's padding. Import may downscale the sheet without changing anchors.
const ATLAS: Texture2D = preload("res://assets/creatures/alien_mine_creatures.png")
const SOURCE_SIZE := Vector2(1536,1024)
const NAMES := [["Crystal Crawler","Icewing"],["Ash Crawler","Cinderwing"]]
const CROPS := [
	[Rect2(44,52,328,193),Rect2(428,53,334,189),Rect2(805,54,332,192),Rect2(1188,53,323,192)],
	[Rect2(61,269,274,254),Rect2(419,298,330,230),Rect2(773,352,379,176),Rect2(1174,370,313,157)],
	[Rect2(39,564,347,177),Rect2(420,552,344,191),Rect2(804,556,336,190),Rect2(1185,552,326,195)],
	[Rect2(29,745,329,249),Rect2(382,754,355,239),Rect2(763,812,437,178),Rect2(1173,823,334,171)],
]
const ANCHORS := [
	[Vector2(208,240),Vector2(595,238),Vector2(976,241),Vector2(1356,241)],
	[Vector2(240,519),Vector2(622,524),Vector2(1024,524),Vector2(1392,523)],
	[Vector2(211,736),Vector2(596,739),Vector2(974,742),Vector2(1350,743)],
	[Vector2(245,990),Vector2(622,989),Vector2(1031,986),Vector2(1395,990)],
]
# The two widest lava wing poses overlap their neighbours' rectangular bounds,
# while their silhouettes remain separate. Clip only the empty corner containing
# the neighbour's wing tip; retain the full intended wing in each pose.
const CLIP = preload("res://shaders/alien_atlas_clip.gdshader")
static var frames: Dictionary = {}
static var masks: Dictionary = {}

static func apply(sprite: Sprite2D, world: int, flying: bool, facing: Vector2, pose: int, variation: float) -> void:
	var row := (world-1)*2+int(flying)
	var key := row*4+pose
	var imported_scale := Vector2(ATLAS.get_size())/SOURCE_SIZE
	if not frames.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = Rect2(CROPS[row][pose].position*imported_scale,CROPS[row][pose].size*imported_scale)
		texture.filter_clip = true
		frames[key] = texture
	var texture: AtlasTexture = frames[key]
	sprite.texture = texture
	sprite.offset = Vector2(texture.get_size())*0.5-(ANCHORS[row][pose]-CROPS[row][pose].position)*imported_scale
	if facing.x != 0: sprite.flip_h = facing.x < 0
	if sprite.flip_h: sprite.offset.x = -sprite.offset.x
	var art_scale := (0.19 if flying else 0.16)*variation/imported_scale.x
	sprite.scale = Vector2(art_scale,art_scale*(0.94 if facing.y != 0 else 1.0))
	sprite.material = null
	if row == 3 and pose in [2,3]:
		if not masks.has(pose):
			var mask := ShaderMaterial.new()
			mask.shader = CLIP
			mask.set_shader_parameter("cut_rect",Vector4(1168,900,1210,1024) if pose == 2 else Vector4(1150,790,1210,900))
			masks[pose] = mask
		sprite.material = masks[pose]
