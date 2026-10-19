extends RefCounted

const BACKDROP_PATH := "res://assets/ui/title_landscape.png"
const LOGO_PATH := "res://assets/ui/sunny_scout_logo.png"
# Keep the title and its illustrated subtitle together in both startup screens.
const LOGO_REGION := Rect2i(0,55,2171,616)

static func logo_texture() -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(LOGO_PATH)
	texture.region = Rect2(LOGO_REGION)
	return texture
