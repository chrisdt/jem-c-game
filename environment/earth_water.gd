extends RefCounted

# Traced in the paintings' 1500 × 1050 space. Masks are tiny and cached;
# scenery textures and animals remain owned by the active streamed district.
const EARTH = preload("res://earth_regions.gd")
const FISH: PackedScene = preload("res://environment/pond.tscn")
const DUCK: PackedScene = preload("res://environment/duck.tscn")
const WATER: Shader = preload("res://shaders/pond_water.gdshader")
const MASK_SIZE := Vector2i(256,180)
static var masks: Dictionary = {}
static var outlines := {
	"willow":[
		PackedVector2Array([Vector2(865,230),Vector2(915,188),Vector2(1025,160),Vector2(1110,185),Vector2(1185,225),Vector2(1215,265),Vector2(1160,300),Vector2(1080,325),Vector2(970,300),Vector2(900,280)]),
		PackedVector2Array([Vector2(275,595),Vector2(330,550),Vector2(470,527),Vector2(565,550),Vector2(650,585),Vector2(700,620),Vector2(755,665),Vector2(720,715),Vector2(635,749),Vector2(510,760),Vector2(430,740),Vector2(355,720),Vector2(290,700),Vector2(290,650)]),
		# Two stream reaches stop at the bridge, keeping its deck still.
		PackedVector2Array([Vector2(1100,317),Vector2(1135,350),Vector2(1110,390),Vector2(1065,420),Vector2(1050,451),Vector2(1000,447),Vector2(1030,403),Vector2(1090,365)]),
		PackedVector2Array([Vector2(968,520),Vector2(1048,518),Vector2(1045,558),Vector2(1010,590),Vector2(1023,630),Vector2(1010,670),Vector2(938,700),Vector2(800,715),Vector2(750,707),Vector2(768,674),Vector2(895,677),Vector2(968,651),Vector2(978,620),Vector2(948,580)])
	],
	"quarry":[PackedVector2Array([Vector2(198,748),Vector2(265,710),Vector2(300,665),Vector2(440,647),Vector2(530,675),Vector2(555,705),Vector2(620,730),Vector2(680,780),Vector2(627,817),Vector2(535,845),Vector2(405,837),Vector2(330,810),Vector2(250,795),Vector2(205,775)])],
	"moss":[PackedVector2Array([Vector2(610,640),Vector2(668,611),Vector2(720,585),Vector2(765,603),Vector2(826,620),Vector2(854,654),Vector2(861,679),Vector2(807,701),Vector2(723,709),Vector2(668,683),Vector2(628,662)])],
	"crystal_depths":[PackedVector2Array([Vector2(900,725),Vector2(970,691),Vector2(1050,660),Vector2(1130,668),Vector2(1210,699),Vector2(1280,731),Vector2(1340,762),Vector2(1380,800),Vector2(1340,846),Vector2(1280,866),Vector2(1200,853),Vector2(1185,828),Vector2(1170,805),Vector2(1140,792),Vector2(1090,790),Vector2(1050,788),Vector2(1000,784),Vector2(955,780),Vector2(919,755)])],
}
const ISLANDS := {
	"moss":[Vector4(713,657,20,14),Vector4(782,696,27,17),Vector4(827,681,28,22)],
	"crystal_depths":[Vector4(996,738,24,16),Vector4(1085,775,30,20),Vector4(1160,716,28,17),Vector4(1225,774,24,20),Vector4(1285,808,27,17),Vector4(1205,810,21,15),Vector4(1238,835,20,12)],
}
# x/y = centre, z/w = safe interior radii, all in art coordinates.
# Separate routes and independent random clocks prevent fish moving in unison.
const FISH_POOLS := {
	"willow":[{"area":Vector4(1055,246,142,50),"count":2},{"area":Vector4(500,645,185,69),"count":3}],
	"quarry":[{"area":Vector4(442,749,160,61),"count":3}],
	"moss":[{"area":Vector4(756,628,80,19),"count":1}],
	"crystal_depths":[{"area":Vector4(1068,713,68,22),"count":1},{"area":Vector4(1195,743,90,16),"count":1},{"area":Vector4(1125,746,55,13),"count":1}],
}
# Dry, connected shoreline patches. A floor check also guards every footstep.
const DUCK_BANKS := {
	"willow":[Rect2(225,770,78,48),Rect2(785,750,80,52),Rect2(1255,295,78,58)],
	"quarry":[Rect2(730,805,85,58),Rect2(710,873,95,45)],
}

static func mask_for(key: String) -> Dictionary:
	if masks.has(key): return masks[key]
	var image := Image.create(MASK_SIZE.x,MASK_SIZE.y,false,Image.FORMAT_R8)
	image.fill(Color.BLACK)
	var scale := Vector2(MASK_SIZE) / EARTH.ART_SIZE
	for polygon in outlines[key]:
		var bounds := Rect2(polygon[0],Vector2.ZERO)
		for point in polygon: bounds = bounds.expand(point)
		var start := Vector2i((bounds.position * scale).floor()).clamp(Vector2i.ZERO,MASK_SIZE)
		var end := Vector2i((bounds.end * scale).ceil()).clamp(Vector2i.ZERO,MASK_SIZE)
		for y in range(start.y,end.y):
			for x in range(start.x,end.x):
				var point := (Vector2(x,y)+Vector2.ONE*0.5) / scale
				if not Geometry2D.is_point_in_polygon(point,polygon): continue
				var island := false
				for stone in ISLANDS.get(key,[]):
					if ((point-Vector2(stone.x,stone.y))/Vector2(stone.z,stone.w)).length_squared() < 1: island = true
				if not island: image.set_pixel(x,y,Color.WHITE)
	var result := {"image":image,"texture":ImageTexture.create_from_image(image)}
	masks[key] = result
	return result

static func add_to(parent: Node2D, key: String, ground: Texture2D, water_z := -1) -> Node2D:
	if not outlines.has(key): return null
	var mask := mask_for(key)
	var habitat := Node2D.new()
	habitat.name = "PondHabitat"
	habitat.y_sort_enabled = true
	parent.add_child(habitat)
	var water := Sprite2D.new()
	water.name = "ShimmeringWater"
	water.texture = ground
	water.centered = false
	water.scale = EARTH.SIZE / ground.get_size()
	water.z_index = water_z
	water.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shimmer := ShaderMaterial.new()
	shimmer.shader = WATER
	shimmer.set_shader_parameter("water_mask",mask.texture)
	water.material = shimmer
	habitat.add_child(water)
	var index := 0
	for pool in FISH_POOLS[key]:
		var area: Vector4 = pool.area
		for i in pool.count:
			var fish := FISH.instantiate()
			fish.name = "PondFish%d" % index
			fish.position = EARTH.from_art(Vector2(area.x,area.y))
			fish.water_radius = EARTH.from_art(Vector2(area.z,area.w))
			fish.swim_radius = fish.water_radius * Vector2(0.65-i*0.07,0.42-i*0.04)
			fish.swim_offset = Vector2.ZERO
			fish.ground_texture = ground
			fish.water_mask = mask.texture
			fish.water_mask_image = mask.image
			fish.z_index = water_z
			habitat.add_child(fish)
			index += 1
	var region := 2 if key == "willow" else 4
	index = 0
	for bank in DUCK_BANKS.get(key,[]):
		var duck := DUCK.instantiate()
		duck.name = "ShoreDuck%d" % index
		duck.wander_area = Rect2(EARTH.from_art(bank.position),EARTH.from_art(bank.size))
		duck.position = duck.wander_area.get_center()
		duck.walk_speed = 18.0 + index * 2
		duck.shore_floor = func(point: Vector2) -> bool: return EARTH.floor_contains(region,false,point)
		habitat.add_child(duck)
		index += 1
	return habitat
