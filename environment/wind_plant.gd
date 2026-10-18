@tool
extends Node2D

const PARTS: Texture2D = preload("res://assets/pond_life.png")
const WIND: Shader = preload("res://shaders/plant_wind.gdshader")
const WIND_MESH = preload("res://environment/wind_mesh.gd")

@export_enum("White daisies", "Yellow wildflowers", "Pink flowers", "Green reeds", "Cattails", "Blue flowers") var plant_style := 0:
	set(value):
		plant_style = value
		refresh_preview()
@export_range(0.0, 25.0) var wind_strength := 9.0:
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
	var cell := PARTS.get_size() / Vector2(4, 2)
	var stems := MeshInstance2D.new()
	stems.name = "MovingStems"
	stems.texture = PARTS
	stems.mesh = WIND_MESH.make(cell)
	stems.position = Vector2(-cell.x * 0.5, -cell.y * (0.96 if plant_style < 4 else 0.89))
	var wind := ShaderMaterial.new()
	wind.shader = WIND
	wind.set_shader_parameter("atlas_origin", Vector2((plant_style % 4) / 4.0, floorf(plant_style / 4.0) / 2.0))
	wind.set_shader_parameter("wind_strength", wind_strength)
	wind.set_shader_parameter("wind_speed", wind_speed)
	wind.set_shader_parameter("wind_phase", wind_phase)
	stems.material = wind
	add_child(stems)
