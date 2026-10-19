extends RefCounted

const BACKDROP_PATH := "res://assets/ui/title_landscape.png"
const LOGO_PATH := "res://assets/ui/sunny_scout_logo.png"
# Reuse the same visible wordmark in the engine and the HTML loader.
const LOGO_REGION := Rect2i(0,90,2172,550)

static func logo_texture() -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(LOGO_PATH)
	texture.region = Rect2(LOGO_REGION)
	return texture
