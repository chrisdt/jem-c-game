extends RefCounted

# Only the bright surface exit is a real doorway in each Earth mine. The other
# painted timber openings are closed workings, not additional level entrances.
# Rectangles use the original 1500 x 1050 paintings and fit the dark opening
# between its posts, clear of the surrounding floor and real surface exits.
const WOOD: Texture2D = preload("res://assets/scenery/wood_sign.png")
const WORLD_SCALE := Vector2(2000.0/1500.0,1400.0/1050.0)
const DOORS := {
	0:[
		Rect2(280,146,47,54),Rect2(412,101,43,64),
		Rect2(629,298,49,64),Rect2(774,99,48,51),
		Rect2(969,247,39,56),Rect2(1321,147,57,67),
		Rect2(1393,379,54,66),Rect2(1262,752,76,63),
		Rect2(612,845,60,60),Rect2(284,669,66,61),
	],
	1:[
		Rect2(135,133,62,65),Rect2(347,178,47,55),
		Rect2(711,34,80,58),Rect2(1143,132,60,59),
		Rect2(1277,132,67,65),Rect2(608,246,34,54),
		Rect2(860,246,31,54),Rect2(140,510,79,59),
		Rect2(427,533,44,54),Rect2(645,548,29,45),
		Rect2(831,547,29,45),Rect2(1095,527,75,59),
		Rect2(1387,541,48,55),
	],
	4:[
		Rect2(331,116,61,64),Rect2(754,47,57,61),
		Rect2(1088,123,32,49),Rect2(1322,98,57,60),
		Rect2(100,325,85,61),Rect2(609,308,61,56),
		Rect2(1381,450,49,62),Rect2(1331,671,52,62),
		Rect2(607,600,45,49),
	],
}
static var plank: AtlasTexture

static func doors_for(world: int, region: int, cave: bool) -> Array:
	return DOORS.get(region,[]) if world == 0 and cave else []

static func draw_map(canvas: Node2D, world: int, region: int, cave: bool) -> void:
	var doors := doors_for(world,region,cave)
	if doors.is_empty(): return
	if plank == null:
		plank = AtlasTexture.new()
		plank.atlas = WOOD
		# A single grain strip from the existing blank sign; no painted post,
		# lettering or transparent glow is stretched across the doorway.
		plank.region = Rect2(85,219,1360,126)
	for opening: Rect2 in doors:
		var centre := opening.get_center()*WORLD_SCALE
		var size := opening.size*WORLD_SCALE
		var strip := size.y*0.19
		for row in 3:
			var angle: float = [-0.025,0.018,-0.012][row]
			var at := centre+Vector2(0,(row-1)*size.y*0.31)
			draw_plank(canvas,at,Vector2(size.x,strip),angle,Color("ac9674"))
		var brace_length := Vector2(size.x*0.97,size.y*0.81).length()
		var brace_angle := atan2(size.y*0.81,size.x*0.97)
		for direction in [-1,1]:
			draw_plank(canvas,centre,Vector2(brace_length,strip*0.8),brace_angle*direction,Color("c5ad85"))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_plank(canvas: Node2D, centre: Vector2, size: Vector2, angle: float, tint: Color) -> void:
	canvas.draw_set_transform(centre,angle)
	canvas.draw_texture_rect(plank,Rect2(-size*0.5,size),false,tint)
	for side in [-1,1]:
		var nail := Vector2(side*size.x*0.43,0)
		canvas.draw_circle(nail+Vector2(0,0.6),1.65,Color("3d3024"))
		canvas.draw_circle(nail,1.15,Color("847e69"))
		canvas.draw_circle(nail+Vector2(-0.3,-0.3),0.4,Color("c0b99b"))
