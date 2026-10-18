extends RefCounted

const NAMES := ["Earth", "Frost Canyon", "Ember Dunes"]
const DESCRIPTIONS := ["Five districts & three mines", "Five districts & three mines", "Five districts & three mines"]
const MATERIALS := [["Copper", "Blue crystal"], ["Frost ore", "Amethyst"], ["Gold", "Fire ruby"]]
const ORES := [
	[preload("res://assets/copper_ore.png"), preload("res://assets/blue_ore.png")],
	[preload("res://assets/blue_ore.png"), preload("res://assets/amethyst_ore.png")],
	[preload("res://assets/gold_ore.png"), preload("res://assets/ruby_ore.png")],
]
const PLANETS: Texture2D = preload("res://assets/ui/planets.png")
const TOOLS: Texture2D = preload("res://assets/ui/tools.png")
static var planet_icons: Array[AtlasTexture] = []
static var tool_icons: Array[AtlasTexture] = []

static func cell(texture: Texture2D, index: int, columns: int) -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = texture
	var width := texture.get_width() / float(columns)
	icon.region = Rect2(index * width, 0, width, texture.get_height())
	return icon

static func planet_icon(index: int) -> AtlasTexture:
	if planet_icons.is_empty():
		for i in 3:
			planet_icons.append(cell(PLANETS, i, 3))
	return planet_icons[index]

static func tool_icon(upgraded: bool) -> AtlasTexture:
	if tool_icons.is_empty():
		for i in 2:
			tool_icons.append(cell(TOOLS, i, 2))
	return tool_icons[int(upgraded)]
