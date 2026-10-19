extends RefCounted

const ANCHORS = preload("res://assets/trial/anchors.gd")
const JAB: Texture2D = preload("res://assets/trial/miner_jab.png")
const SNAKE: Texture2D = preload("res://assets/trial/snake.png")
const PLANTS: Texture2D = preload("res://assets/trial/food_plants.png")
const ICONS: Texture2D = preload("res://assets/trial/icons.png")
const WOOD: Texture2D = preload("res://assets/trial/wood.png")
const JAB_ROWS := [Vector2(0,345),Vector2(345,316),Vector2(661,363)]
const SNAKE_ROWS := [Vector2(0,300),Vector2(320,325),Vector2(650,374)]
const SNAKE_COLS := [0,269,517,769,1027,1280,1536]
const SNAKE_HEADS := [
	[Vector2(223,244),Vector2(472,244),Vector2(729,244),Vector2(981,245),Vector2(1230,245),Vector2(1486,245)],
	[Vector2(145,605),Vector2(394,606),Vector2(651,608),Vector2(908,606),Vector2(1160,606),Vector2(1409,606)],
	[Vector2(125,766),Vector2(380,766),Vector2(635,767),Vector2(890,766),Vector2(1145,766),Vector2(1402,766)],
]
static var textures: Dictionary = {}
static var jab_frames: SpriteFrames

static func region(key: String, sheet: Texture2D, bounds: Rect2) -> AtlasTexture:
	if not textures.has(key):
		var part := AtlasTexture.new()
		part.atlas = sheet
		part.region = bounds
		part.filter_clip = true
		textures[key] = part
	return textures[key]

static func icon(index: int) -> Texture2D:
	var bounds: Rect2 = [Rect2(130,20,265,670),Rect2(567,180,485,422),Rect2(1108,179,488,423),Rect2(1648,179,484,422)][index]
	return region("icon%d" % index,ICONS,bounds)

static func plant(apple: bool, picked: bool) -> Texture2D:
	var bounds := Rect2(50 if not picked else 805,0,690,655) if apple else Rect2(170 if not picked else 900,660,540,364)
	return region("plant%s%s" % [apple,picked],PLANTS,bounds)

static func plant_anchor(apple: bool, picked: bool) -> Vector2:
	return Vector2(365 if not picked else 345,642) if apple else Vector2(265 if not picked else 260,337)

static func wood(index := 3) -> Texture2D:
	var bounds: Rect2 = [Rect2(76,180,535,350),Rect2(736,166,456,382),Rect2(87,748,502,370),Rect2(720,752,470,378)][index]
	return region("wood%d" % index,WOOD,bounds)

static func snake_pose(row: int, frame: int) -> Dictionary:
	var bounds := Rect2(SNAKE_COLS[frame],SNAKE_ROWS[row].x,SNAKE_COLS[frame+1]-SNAKE_COLS[frame],SNAKE_ROWS[row].y)
	return {"texture":region("snake%d/%d" % [row,frame],SNAKE,bounds),"anchor":SNAKE_HEADS[row][frame]-bounds.position}

static func make_jab_frames() -> SpriteFrames:
	if jab_frames != null: return jab_frames
	jab_frames = SpriteFrames.new()
	jab_frames.remove_animation(&"default")
	for row in 3:
		var direction: StringName = [&"side",&"down",&"up"][row]
		var animation := StringName("jab_"+str(direction))
		jab_frames.add_animation(animation)
		jab_frames.set_animation_loop(animation,false)
		for col in 4:
			var bounds := Rect2(col*384,JAB_ROWS[row].x,384,JAB_ROWS[row].y)
			jab_frames.add_frame(animation,region("jab%d/%d" % [row,col],JAB,bounds))
	return jab_frames

static func fit_jab(sprite: AnimatedSprite2D, direction: StringName, frame: int) -> void:
	var row: int = {&"side":0,&"down":1,&"up":2}[direction]
	var size := Vector2(384,JAB_ROWS[row].y)
	var anchor: Vector2 = ANCHORS.JAB_ANCHORS[row][frame]
	var scale: float = ANCHORS.JAB_SCALES[row]
	sprite.scale = Vector2.ONE*scale
	sprite.offset = size*0.5-anchor+Vector2(0,20.0/scale)
	if sprite.flip_h: sprite.offset.x = -sprite.offset.x
