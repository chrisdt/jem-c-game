extends RefCounted

const PANEL: Texture2D = preload("res://assets/ui/panel.png")
# The generator leaves a few nearly transparent pixels outside the painted
# frame. Exclude that empty padding when sizing the reusable nine-slice.
const PANEL_REGION := Rect2i(20,244,1948,292)
const HEADING: Font = preload("res://assets/ui/heading.ttf")
const BODY: Font = preload("res://assets/ui/body.ttf")
const TOUCH_BUTTON = preload("res://ui/touch_button.gd")
const CREAM := Color("fff0cc")
const MUTED := Color("c6ccb7")
const GOLD := Color("d6ad58")
static var panel_texture: Texture2D

static func panel_style(tint := Color.WHITE) -> StyleBoxTexture:
	if panel_texture == null:
		var original := PANEL.get_image()
		var pixels := original.get_region(PANEL_REGION)
		# Prepare the painted frame at its actual UI height once, so nine-slice
		# corners and rivets retain their proportions on every panel size.
		pixels.resize(roundi(pixels.get_width() * 54.0 / pixels.get_height()),54,Image.INTERPOLATE_LANCZOS)
		panel_texture = ImageTexture.create_from_image(pixels)
	var style := StyleBoxTexture.new()
	style.texture = panel_texture
	var height := panel_texture.get_height()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, height * 0.32)
	style.modulate_color = tint
	style.set_content_margin_all(12)
	return style

static func panel(parent: Node, at: Vector2, dimensions: Vector2) -> Panel:
	var node := Panel.new()
	node.position = at
	node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", panel_style())
	parent.add_child(node)
	return node

static func label(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size := 16, heading := false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = at
	node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font", HEADING if heading else BODY)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", CREAM)
	node.add_theme_color_override("font_shadow_color", Color(0,0,0,0.7))
	node.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(node)
	return node

static func icon(parent: Node, texture: Texture2D, at: Vector2, dimensions: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.texture = texture
	node.position = at
	node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size := 16) -> Button:
	var node := TOUCH_BUTTON.new()
	node.text = text
	node.position = at
	node.size = dimensions
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", HEADING)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", CREAM)
	node.add_theme_color_override("font_hover_color", Color("fff9e8"))
	node.add_theme_color_override("font_disabled_color", MUTED)
	for entry in [["normal",Color.WHITE],["hover",Color(1.2,1.15,1.05)],["pressed",Color(0.8,0.87,0.85)],["disabled",Color(0.65,0.73,0.71)]]:
		if dimensions.x <= 44:
			# Rivets belong on the larger panels; tiny close/help buttons need
			# clear symbols and enough room for a comfortable click target.
			var small := StyleBoxFlat.new()
			small.bg_color = Color("123536") * entry[1]
			small.border_color = GOLD
			small.set_border_width_all(1)
			small.set_corner_radius_all(8)
			small.set_content_margin_all(4)
			node.add_theme_stylebox_override(entry[0],small)
			continue
		var box := panel_style(entry[1])
		box.set_content_margin(SIDE_TOP,4)
		box.set_content_margin(SIDE_BOTTOM,4)
		node.add_theme_stylebox_override(entry[0],box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("ffe4a0")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(10)
	node.add_theme_stylebox_override("focus", focus)
	parent.add_child(node)
	return node
