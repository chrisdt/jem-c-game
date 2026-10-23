extends RefCounted

# Four native wild plants, with matching ripe/picked rows and shared root anchors.
const SHEET: Texture2D = preload("res://assets/food/wild_plants.png")
const NAMES := ["Frozen berries","Aurora pods","Emberfruit","Sunspine bulbs"]
const HEARTS := [1,2,1,2]
const HEIGHTS := [80.0,112.0,95.0,90.0]
const MESSAGES := ["Frozen berries restore one heart.","Aurora pods restore two hearts.","Emberfruit restores one heart.","Sunspine bulbs restore two hearts."]
static var frames: Dictionary = {}

static func frame(kind: int, picked: bool) -> AtlasTexture:
	var key := kind+int(picked)*4
	if not frames.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		var cell := SHEET.get_size()/Vector2(4,2)
		texture.region = Rect2(Vector2(kind,int(picked))*cell,cell)
		texture.filter_clip = true
		frames[key] = texture
	return frames[key]

static func anchor() -> Vector2:
	return SHEET.get_size()/Vector2(4,2)*Vector2(0.5,239.0/256.0)
