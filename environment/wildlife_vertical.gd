@tool
extends RefCounted

enum Species { DUCK, GOAT, FROSTLING, DUNE_SPRITE, RAT, BAT }

# Keep the original paintings intact. Each atlas region has its own ground
# anchor, and each view shares one scale across walking and feeding poses.
const DATA := [
	{
		"art": preload("res://assets/creatures/duck_vertical.png"),
		"columns": [0,550,980,1536],
		"rows": [Vector2(0,280),Vector2(280,220),Vector2(500,270),Vector2(770,245)],
		"anchors": [
			[Vector2(337,263),Vector2(767,263),Vector2(1199,263),Vector2(337,483),Vector2(767,483),Vector2(1199,483)],
			[Vector2(337,752),Vector2(767,752),Vector2(1199,752),Vector2(337,975),Vector2(767,975),Vector2(1199,975)]],
		"scales": [1.65,1.65]
	},
	{
		"art": preload("res://assets/creatures/goat_vertical.png"),
		"columns": [0,355,665,1024],
		"rows": [Vector2(20,365),Vector2(395,330),Vector2(735,390),Vector2(1140,365)],
		"anchors": [
			[Vector2(204,360),Vector2(513,360),Vector2(822,360),Vector2(204,699),Vector2(513,699),Vector2(822,699)],
			[Vector2(204,1104),Vector2(513,1104),Vector2(822,1104),Vector2(204,1470),Vector2(513,1470),Vector2(822,1470)]],
		"scales": [1.35,1.22]
	},
	{
		"art": preload("res://assets/creatures/aliens_vertical.png"),
		"columns": [0,313,627,941,1254],
		"rows": [Vector2(25,305),Vector2(335,305)],
		"anchors": [
			[Vector2(168,308),Vector2(483,308),Vector2(786,308),Vector2(1098,308)],
			[Vector2(168,621),Vector2(483,621),Vector2(786,621),Vector2(1098,621)]],
		"scales": [0.98,0.98]
	},
	{
		"art": preload("res://assets/creatures/aliens_vertical.png"),
		"columns": [0,313,627,941,1254],
		"rows": [Vector2(645,285),Vector2(935,295)],
		"anchors": [
			[Vector2(168,909),Vector2(483,909),Vector2(786,909),Vector2(1098,909)],
			[Vector2(168,1205),Vector2(483,1205),Vector2(786,1205),Vector2(1098,1205)]],
		"scales": [1.06,1.02]
	},
	{
		"art": preload("res://assets/creatures/cave_vertical.png"),
		"columns": [0,313,627,947,1254],
		"rows": [Vector2(20,330),Vector2(350,330)],
		"anchors": [
			[Vector2(165,331),Vector2(485,331),Vector2(790,331),Vector2(1098,331)],
			[Vector2(165,653),Vector2(485,653),Vector2(790,653),Vector2(1098,653)]],
		"scales": [0.65,0.65]
	},
	{
		"art": preload("res://assets/creatures/cave_vertical.png"),
		"columns": [0,313,627,947,1254],
		"rows": [Vector2(690,255),Vector2(945,255)],
		"anchors": [
			[Vector2(165,887),Vector2(480,882),Vector2(790,887),Vector2(1100,883)],
			[Vector2(165,1133),Vector2(480,1130),Vector2(790,1138),Vector2(1100,1133)]],
		"scales": [0.94,0.94]
	},
]

static var textures: Dictionary = {}

static func apply(sprite: Sprite2D, species: int, facing: Vector2, pose: int, body_scale: float) -> void:
	var view := int(facing.y < 0)
	var data: Dictionary = DATA[species]
	var feeding := species <= Species.GOAT
	var row := view * 2 + int(pose >= 3) if feeding else view
	var column := pose % 3 if feeding else pose % 4
	var key := Vector3i(species, view, pose)
	if not textures.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = data.art
		texture.region = Rect2(data.columns[column],data.rows[row].x,data.columns[column+1]-data.columns[column],data.rows[row].y)
		texture.filter_clip = true
		textures[key] = texture
	var frame: AtlasTexture = textures[key]
	var anchor: Vector2 = data.anchors[view][pose]
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.texture = frame
	sprite.offset = frame.region.size * 0.5 - (anchor - frame.region.position)
	sprite.flip_h = false
	sprite.scale = Vector2.ONE * body_scale * data.scales[view]
