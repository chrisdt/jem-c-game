extends RefCounted

# Coordinates are traced against the paintings in their common 1500 × 1050
# art space. They deliberately do not use the walk-through trigger positions:
# a trail mouth and the wooden sign beside it are different objects.
const ART_SCALE := Vector2(2000.0 / 1500.0, 1400.0 / 1050.0)
const FONT: Font = preload("res://assets/ui/heading.ttf")
const WOOD: Texture2D = preload("res://assets/scenery/wood_sign.png")
const BOARD_REGION := Rect2(40.0/1536.0, 160.0/1024.0, 1474.0/1536.0, 426.0/1024.0)
const INK := Color("f1dfb2")
const ENGRAVING := Color("503119")
# The heading font's OS/2 cap height is 714/1000 em. Signs use capitals only;
# fitting their ink rather than full ascender/descender metrics keeps them
# readable without wasting the plank on space reserved for lowercase tails.
const CAP_HEIGHT := 0.714
const LINE_SPACING := 1.16
static var letter_layouts: Dictionary = {}

# x/y = plank centre, z = angle in radians. A slightly larger wooden face
# sits over each painted arrow board while retaining its original post.
const TRAILS := [
	[
		{"east":Vector3(1408,376,-0.09), "south":Vector3(623,953,-0.08)},
		{"west":Vector3(80,445,-0.12), "east":Vector3(1417,450,-0.10), "south":Vector3(830,936,-0.15)},
		{"north":Vector3(679,45,-0.08), "east":Vector3(1438,413,-0.08)},
		{"north":Vector3(695,20,0), "west":Vector3(71,419,0)},
		{"west":Vector3(193,389,0.10)},
	],
	[
		{"west":Vector3(64,426,-0.18), "east":Vector3(1451,267,0.22)},
		{"east":Vector3(1427,423,0.16), "south":Vector3(751,885,-0.12)},
		{"west":Vector3(90,394,0.25), "east":Vector3(1380,423,-0.19), "south":Vector3(738,934,0.16)},
		{"north_west":Vector3(310,49,-0.10), "north_east":Vector3(1188,49,0.10)},
		{"west":Vector3(71,445,-0.16)},
	],
	[
		{"west":Vector3(74,321,0.12), "south":Vector3(922,883,0.15)},
		{"east":Vector3(1431,334,-0.06), "south":Vector3(679,962,0.03)},
		{"north":Vector3(777,50,0.20), "west":Vector3(70,330,0.13), "east":Vector3(1439,384,-0.15)},
		{"north":Vector3(701,45,0.18), "east":Vector3(1436,450,0.15)},
		{"west":Vector3(71,338,0.18)},
	],
]

# Beam centres, usable front-face widths/heights, and their painted slopes.
# Keep lettering between the posts, clear of rope, lanterns and iron bands.
const ENTRANCES := [
	{0:Vector4(1110,167,102,16), 1:Vector4(1087,144,87,17), 4:Vector4(1090,135,98,15)},
	{0:Vector4(1218,119,78,13), 1:Vector4(429,128,78,12), 4:Vector4(1220,119,78,13)},
	{0:Vector4(296,113,80,14), 1:Vector4(304,94,69,13), 4:Vector4(1177,115,73,13)},
]
const ENTRANCE_ANGLES := [
	{0:0.0, 1:0.0, 4:0.10},
	{0:0.14, 1:-0.14, 4:0.12},
	{0:-0.04, 1:0.0, 4:0.11},
]
const EXITS := [
	{0:Vector4(121,355,92,15), 1:Vector4(757,824,94,15), 4:Vector4(141,748,90,15)},
	{0:Vector4(735,860,49,16), 1:Vector4(739,835,58,18)},
	{0:Vector4(268,857,74,18), 1:Vector4(750,820,82,18), 4:Vector4(253,855,74,18)},
]
const EXIT_ANGLES := [
	{0:0.34, 1:0.0, 4:-0.39},
	{0:0.0, 1:0.0},
	{0:0.0, 1:0.0, 4:0.0},
]
const BASE_SIGNS := [
	{"camp":Vector2(485,280), "rocket":Vector2(235,345)},
	{"camp":Vector2(535,710), "rocket":Vector2(300,830)},
	{"camp":Vector2(1160,785), "rocket":Vector2(1390,830)},
]
# Base labels sit beside the props; keep these smaller than trail wayfinding.
const BASE_SIGN_SCALE := 0.64
const DIRECTIONS := {
	"west":Vector2.LEFT, "east":Vector2.RIGHT, "north":Vector2.UP,
	"south":Vector2.DOWN, "north_west":Vector2(-0.70710678,-0.70710678),
	"north_east":Vector2(0.70710678,-0.70710678),
}

static func draw_map(canvas: Node2D, world: int, region: int, cave: bool, catalog) -> void:
	if cave:
		if EXITS[world].has(region):
			inscribe_beam(canvas, EXITS[world][region], EXIT_ANGLES[world][region], "SURFACE")
		else:
			# Deep Prism's natural exit has no timber frame to write on.
			post(canvas, Vector2(305,930), "SURFACE", Vector2(-1,-1).normalized())
		return
	if region == 0:
		post(canvas, BASE_SIGNS[world].camp, "CAMP", Vector2.ZERO, BASE_SIGN_SCALE)
		post(canvas, BASE_SIGNS[world].rocket, "ROCKET", Vector2.ZERO, BASE_SIGN_SCALE)
	if catalog.has_mine(region):
		inscribe_beam(canvas, ENTRANCES[world][region], ENTRANCE_ANGLES[world][region], catalog.MINE_NAMES[region])
	for link in catalog.LINKS[region]:
		var placement: Vector3 = TRAILS[world][region][link.side]
		canvas.draw_set_transform(Vector2(placement.x,placement.y) * ART_SCALE, placement.z)
		var source := Rect2(BOARD_REGION.position * WOOD.get_size(), BOARD_REGION.size * WOOD.get_size())
		canvas.draw_texture_rect_region(WOOD, Rect2(-66,-21,132,42), source)
		var direction: Vector2 = DIRECTIONS[link.side]
		var arrow_x := -51.0 if direction.x < 0 else 51.0
		paint_arrow(canvas, Vector2(arrow_x,0), direction)
		lettering(canvas, Rect2(-43 if arrow_x > 0 else -39,-15,82,30), catalog.NAMES[link.target], 13, true)
		canvas.draw_set_transform(Vector2.ZERO)

static func inscribe_beam(canvas: Node2D, beam: Vector4, angle: float, text: String) -> void:
	canvas.draw_set_transform(Vector2(beam.x,beam.y) * ART_SCALE, angle)
	var size := Vector2(beam.z,beam.w) * ART_SCALE
	lettering(canvas, Rect2(-size * 0.5, size), text, 15)
	canvas.draw_set_transform(Vector2.ZERO)

static func post(canvas: Node2D, foot: Vector2, text: String, direction := Vector2.ZERO, size_scale := 1.0) -> void:
	canvas.draw_set_transform(foot * ART_SCALE)
	canvas.draw_texture_rect(WOOD, Rect2(Vector2(-72,-85) * size_scale, Vector2(144,96) * size_scale), false)
	var face := Rect2(Vector2(-52,-65) * size_scale, Vector2(104,29) * size_scale)
	if direction != Vector2.ZERO:
		paint_arrow(canvas, Vector2(-52,-50) * size_scale, direction)
		face = Rect2(Vector2(-35,-65) * size_scale, Vector2(82,29) * size_scale)
	lettering(canvas, face, text, 14, text.contains(" / "))
	canvas.draw_set_transform(Vector2.ZERO)

static func paint_arrow(canvas: Node2D, centre: Vector2, direction: Vector2) -> void:
	var tip := centre + direction * 6
	var tail := centre - direction * 6
	var wing := direction.orthogonal() * 4
	canvas.draw_line(tail, tip, INK, 1.5, true)
	canvas.draw_polyline(PackedVector2Array([tip-direction*5+wing,tip,tip-direction*5-wing]), INK, 1.5, true)

static func lettering(canvas: Node2D, face: Rect2, text: String, max_size: int, two_lines := false) -> void:
	var key := "%s|%s|%d|%s" % [text,face,max_size,two_lines]
	if not letter_layouts.has(key):
		letter_layouts[key] = fit_letters(face,text,max_size,two_lines)
	for letter in letter_layouts[key]:
		# A shallow offset in the grain gives the warm paint a carved edge.
		canvas.draw_string(FONT, letter.at + Vector2(0,-0.65), letter.text, HORIZONTAL_ALIGNMENT_LEFT,-1,letter.size, ENGRAVING)
		canvas.draw_string(FONT, letter.at, letter.text, HORIZONTAL_ALIGNMENT_LEFT,-1,letter.size, INK)

static func fit_letters(face: Rect2, text: String, max_size: int, two_lines: bool) -> Array[Dictionary]:
	var lines := PackedStringArray([text.to_upper()])
	if two_lines:
		# Balance multi-word place names so neither line escapes the wood.
		var words := text.replace(" / "," ").to_upper().split(" ", false)
		var best := INF
		for split in range(1,words.size()):
			var top := " ".join(words.slice(0,split))
			var bottom := " ".join(words.slice(split))
			var width := maxf(FONT.get_string_size(top,HORIZONTAL_ALIGNMENT_LEFT,-1,max_size).x, FONT.get_string_size(bottom,HORIZONTAL_ALIGNMENT_LEFT,-1,max_size).x)
			if width < best:
				best = width
				lines = PackedStringArray([top,bottom])
	var font_size := max_size
	while font_size > 1:
		var widest := 0.0
		for line in lines:
			widest = maxf(widest, FONT.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
		if widest <= face.size.x and font_size * (CAP_HEIGHT + LINE_SPACING * (lines.size()-1)) <= face.size.y:
			break
		font_size -= 1
	var line_height := font_size * LINE_SPACING
	var ink_height := font_size * CAP_HEIGHT
	var baseline := face.get_center().y - (ink_height + line_height * (lines.size()-1)) * 0.5 + ink_height
	var fitted: Array[Dictionary] = []
	for line in lines:
		var width := FONT.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var at := Vector2(face.get_center().x - width * 0.5, baseline)
		fitted.append({"at":at,"text":line,"size":font_size})
		baseline += line_height
	return fitted
