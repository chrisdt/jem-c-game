extends RefCounted

# A temporary CPU mask uses the area's existing painting; it adds no scenery
# downloads and is discarded once its flowers have been placed.
var grass: Image
var world_size: Vector2
var floor_check: Callable
var placed: Array[Vector2] = []

func _init(painting: Texture2D, size: Vector2, terrain: Callable) -> void:
	world_size = size
	floor_check = terrain
	grass = painting.get_image()
	if grass.is_compressed(): grass.decompress()
	grass.resize(384,269,Image.INTERPOLATE_TRILINEAR)

func fits(point: Vector2, flower_scale: float) -> bool:
	# Check the patch's width and a little space around its roots, rather than
	# accepting one green pixel on the edge of a dirt path or rocky bank.
	var radius := Vector2(maxf(14,210*flower_scale),maxf(11,130*flower_scale))
	for sample in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2(-0.7,-0.7),Vector2(0.7,-0.7),Vector2(-0.7,0.7),Vector2(0.7,0.7)]:
		var ground: Vector2 = point+sample*radius
		if not Rect2(Vector2.ZERO,world_size).has_point(ground): return false
		var pixel := Vector2i(ground/world_size*Vector2(grass.get_size())).clamp(Vector2i.ZERO,grass.get_size()-Vector2i.ONE)
		var colour := grass.get_pixelv(pixel)
		if colour.g <= colour.r+0.035 or colour.g <= colour.b*1.3: return false
		if floor_check.is_valid() and not floor_check.call(ground): return false
	return true

func available(point: Vector2, flower_scale: float) -> bool:
	if not fits(point,flower_scale): return false
	for previous in placed:
		if previous.distance_to(point) < 30: return false
	return true

func place(preferred: Vector2, flower_scale: float) -> Vector2:
	if available(preferred,flower_scale):
		placed.append(preferred)
		return preferred
	for ring in range(1,16):
		for ray in 24:
			var point := preferred+Vector2.from_angle(ray*TAU/24)*ring*12
			if available(point,flower_scale):
				placed.append(point)
				return point
	# A missing patch is preferable to putting flowers back on a path/water.
	return Vector2.INF
