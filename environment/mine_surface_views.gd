extends RefCounted

# Small painted surface vistas are clipped to each exit's existing aperture.
# The original frame, lanterns, floor and walk-through trigger stay in place.
const ART: Texture2D = preload("res://assets/scenery/mine_surface_views.png")
const SCALE := Vector2(2000.0/1500.0,1400.0/1050.0)
const REGIONS := [0,1,4]
static var OPENINGS := [
	{
		0:PackedVector2Array([Vector2(94,361),Vector2(150,386),Vector2(170,412),Vector2(81,439),Vector2(80,389)]),
		1:PackedVector2Array([Vector2(719,839),Vector2(792,839),Vector2(818,869),Vector2(818,895),Vector2(690,895),Vector2(690,870)]),
		4:PackedVector2Array([Vector2(119,780),Vector2(176,754),Vector2(176,797),Vector2(114,826)]),
	},
	{
		0:PackedVector2Array([Vector2(719,872),Vector2(756,872),Vector2(772,891),Vector2(778,918),Vector2(773,934),Vector2(701,934),Vector2(698,915),Vector2(710,890)]),
		1:PackedVector2Array([Vector2(723,850),Vector2(773,850),Vector2(797,874),Vector2(797,906),Vector2(686,906),Vector2(686,875)]),
		4:PackedVector2Array([Vector2(245,760),Vector2(262,775),Vector2(282,793),Vector2(287,816),Vector2(282,847),Vector2(208,848),Vector2(207,800),Vector2(219,785)]),
	},
	{
		0:PackedVector2Array([Vector2(249,881),Vector2(283,881),Vector2(320,915),Vector2(320,935),Vector2(215,935),Vector2(215,916)]),
		1:PackedVector2Array([Vector2(720,836),Vector2(780,836),Vector2(813,869),Vector2(813,899),Vector2(684,899),Vector2(684,870)]),
		4:PackedVector2Array([Vector2(234,878),Vector2(277,878),Vector2(308,908),Vector2(308,938),Vector2(201,938),Vector2(201,914)]),
	},
]
const GROUND_EDGES := [
	{0:[2,3],1:[3,4],4:[2,3]},
	{0:[4,5],1:[3,4],4:[4,5]},
	{0:[3,4],1:[3,4],4:[3,4]},
]
static var meshes: Dictionary = {}

static func bounds(points: PackedVector2Array) -> Rect2:
	var result := Rect2(points[0],Vector2.ZERO)
	for point in points: result = result.expand(point)
	return result

static func source_rect(world: int, region: int) -> Rect2:
	# Inset the UVs to keep adjacent atlas panels out of filtered edge pixels.
	var cell := Vector2(1.0/3.0,1.0/3.0)
	var margin := Vector2.ONE*0.004
	return Rect2(Vector2(REGIONS.find(region),world)*cell+margin,cell-margin*2)

static func mesh(world: int, region: int) -> ArrayMesh:
	var key := "%d/%d" % [world,region]
	if meshes.has(key): return meshes[key]
	var outer: PackedVector2Array = OPENINGS[world][region]
	var area := bounds(outer)
	var source := source_rect(world,region)
	var inner := PackedVector2Array()
	for i in outer.size():
		# A wider feather at the threshold blends the outside path into the
		# painted mine floor, instead of ending the vista at a straight edge.
		var inset := 12.0 if GROUND_EDGES[world][region].has(i) else 1.5
		inner.append(outer[i].move_toward(area.get_center(),inset))
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for ring in [inner,outer]:
		for point in ring:
			var at: Vector2 = point*SCALE
			vertices.append(Vector3(at.x,at.y,0))
			uvs.append(source.position+(point-area.position)/area.size*source.size)
			colors.append(Color.WHITE if ring == inner else Color(1,1,1,0))
	var indices := Geometry2D.triangulate_polygon(inner)
	var count := outer.size()
	for i in count:
		var next := (i+1)%count
		indices.append_array(PackedInt32Array([i,next,count+next,i,count+next,count+i]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	meshes[key] = result
	return result

static func draw(canvas: Node2D, world: int, region: int) -> void:
	if not OPENINGS[world].has(region): return
	canvas.draw_mesh(mesh(world,region),ART)
