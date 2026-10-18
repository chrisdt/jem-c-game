@tool
extends Node2D

const PARTS: Texture2D = preload("res://assets/tree_parts.png")
const LEAF_SHADER: Shader = preload("res://shaders/tree_leaves.gdshader")
const GRID := 16

@export_enum("Sunlit broadleaf", "Emerald broadleaf", "Pine") var tree_style := 0:
	set(value):
		tree_style = value
		refresh_preview()
@export_range(0.0, 8.0) var wind_strength := 3.5:
	set(value):
		wind_strength = value
		refresh_preview()
@export_range(0.1, 3.0) var wind_speed := 1.0:
	set(value):
		wind_speed = value
		refresh_preview()
@export_range(0.0, 6.283) var wind_phase := 0.0:
	set(value):
		wind_phase = value
		refresh_preview()

func refresh_preview() -> void:
	if is_inside_tree() and not is_queued_for_deletion():
		_rebuild.call_deferred()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.free()
	var cell := PARTS.get_size() / Vector2(3, 2)
	var trunk := Sprite2D.new()
	trunk.name = "FixedTrunk"
	var trunk_art := AtlasTexture.new()
	trunk_art.atlas = PARTS
	trunk_art.region = Rect2(Vector2(tree_style * cell.x, cell.y), cell)
	trunk.texture = trunk_art
	trunk.centered = false
	# Sprite roots are placed at the scene origin, which is also the sort point.
	trunk.position = Vector2(-cell.x * 0.5, -cell.y * 0.92)
	add_child(trunk)
	var leaves := MeshInstance2D.new()
	leaves.name = "MovingLeaves"
	leaves.texture = PARTS
	leaves.mesh = canopy_mesh(cell)
	leaves.position = Vector2(-cell.x * 0.5, -cell.y * 1.04)
	var wind := ShaderMaterial.new()
	wind.shader = LEAF_SHADER
	wind.set_shader_parameter("atlas_origin", Vector2(tree_style / 3.0, 0))
	wind.set_shader_parameter("wind_strength", wind_strength)
	wind.set_shader_parameter("wind_speed", wind_speed)
	wind.set_shader_parameter("wind_phase", wind_phase)
	leaves.material = wind
	add_child(leaves)
	queue_redraw()

func canopy_mesh(cell: Vector2) -> ArrayMesh:
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
	return mesh

func _draw() -> void:
	# A small fixed contact shadow grounds the tree without swaying its roots.
	draw_set_transform(Vector2(16, -2), 0, Vector2(1, 0.28))
	draw_circle(Vector2.ZERO, 70, Color(0.10, 0.18, 0.08, 0.10))
	draw_circle(Vector2(-8, 0), 40, Color(0.10, 0.18, 0.08, 0.12))
	draw_set_transform(Vector2.ZERO)
