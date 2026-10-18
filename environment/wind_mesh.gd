extends RefCounted

# Trees, flowers, reeds and fish share a small textured grid. The shader can
# bend individual parts of the artwork without sliding its pixels around.
const GRID := 16
static var meshes: Dictionary = {}

static func make(cell: Vector2) -> ArrayMesh:
	if meshes.has(cell):
		return meshes[cell]
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for y in range(GRID + 1):
		for x in range(GRID + 1):
			var uv := Vector2(x, y) / GRID
			vertices.append(uv * cell)
			uvs.append(uv)
	for y in GRID:
		for x in GRID:
			var corner := y * (GRID + 1) + x
			indices.append_array(PackedInt32Array([corner, corner + 1, corner + GRID + 1, corner + 1, corner + GRID + 2, corner + GRID + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	meshes[cell] = mesh
	return mesh
