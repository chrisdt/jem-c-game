extends RefCounted

enum Species { SHEEP, COW, DOG }
const SHEETS := [preload("res://assets/creatures/sheep.png"),preload("res://assets/creatures/cow.png"),preload("res://assets/creatures/dog.png"),preload("res://assets/creatures/dog_sitting.png")]
const COLUMNS := [0,390,780,1160,1536]
const ROWS := [Vector2(0,350),Vector2(350,325),Vector2(675,349)]
# Per-pose hoof/paw anchors compensate for the paintings' different padding.
const ANCHORS := [
	[[Vector2(208,334),Vector2(583,330),Vector2(958,334),Vector2(1310,334)],
	 [Vector2(205,656),Vector2(582,658),Vector2(948,656),Vector2(1320,653)],
	 [Vector2(205,984),Vector2(582,989),Vector2(948,990),Vector2(1320,983)]],
	[[Vector2(185,316),Vector2(575,310),Vector2(963,312),Vector2(1330,315)],
	 [Vector2(193,648),Vector2(580,648),Vector2(969,648),Vector2(1364,648)],
	 [Vector2(193,973),Vector2(580,985),Vector2(960,983),Vector2(1355,981)]],
	[[Vector2(203,317),Vector2(587,311),Vector2(971,313),Vector2(1355,314)],
	 [Vector2(195,661),Vector2(580,662),Vector2(962,660),Vector2(1348,657)],
	 [Vector2(195,981),Vector2(580,982),Vector2(962,982),Vector2(1348,981)]],
	[[Vector2(255,328),Vector2(620,328),Vector2(1005,328),Vector2(1388,328)],
	 [Vector2(223,664),Vector2(590,664),Vector2(973,664),Vector2(1356,664)],
	 [Vector2(207,983),Vector2(590,983),Vector2(975,983),Vector2(1357,983)]],
]
const SCALES := [[0.17,0.18,0.17],[0.22,0.22,0.22],[0.145,0.17,0.14],[0.12,0.125,0.12]]
static var poses: Dictionary = {}

static func pose(species: int, facing: Vector2, frame: int, sitting := false) -> Dictionary:
	var sheet := 3 if sitting else species
	var row := 0 if facing.y == 0 else (1 if facing.y > 0 else 2)
	var key := Vector3i(sheet,row,frame)
	if not poses.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = SHEETS[sheet]
		texture.region = Rect2(COLUMNS[frame],ROWS[row].x,COLUMNS[frame+1]-COLUMNS[frame],ROWS[row].y)
		texture.filter_clip = true
		poses[key] = {"texture":texture,"anchor":ANCHORS[sheet][row][frame],"scale":SCALES[sheet][row],"row":row}
	return poses[key]

static func apply(sprite: Sprite2D, species: int, facing: Vector2, frame: int, variation: float) -> void:
	var art := pose(species,facing,frame)
	var texture: AtlasTexture = art.texture
	sprite.texture = texture
	sprite.offset = texture.region.size*0.5-(art.anchor-texture.region.position)
	sprite.flip_h = facing.x < 0
	if sprite.flip_h: sprite.offset.x = -sprite.offset.x
	sprite.scale = Vector2.ONE * art.scale * variation
