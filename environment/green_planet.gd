extends Node2D

const PLACEMENT = preload("res://environment/flower_placement.gd")
const PLANT = preload("res://environment/wind_plant.gd")
const TERRAIN = preload("res://ore_spawns.gd")

func _ready() -> void:
	var ground: Sprite2D = $Ground
	var placement := PLACEMENT.new(ground.texture,ground.texture.get_size()*ground.scale,TERRAIN.green_ground)
	for child in get_children():
		if child.get_script() != PLANT or child.plant_style in [3,4]: continue
		var point := placement.place(child.position,child.scale.x)
		if point.is_finite(): child.position = point
		else: child.hide()
