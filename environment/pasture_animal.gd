extends "res://environment/ambient_creature.gd"

const PAINTING = preload("res://environment/earth_animal_art.gd")
var species: int = PAINTING.Species.SHEEP

func _ready() -> void:
	super._ready()
	speed = (19.0 if species == PAINTING.Species.SHEEP else 16.0) * rng.randf_range(0.9,1.1)
	state = "graze"
	update_pose()

func rest() -> void:
	super.rest()
	state = "graze" if rng.randf() < 0.85 else "rest"
	rest_seconds = rng.randf_range(2.5,5.5)

func update_pose() -> void:
	var frame: int = [0,1,0,2][int(walk_distance/9.0)%4] if state == "walk" else (3 if state == "graze" else 0)
	current_frame = frame
	PAINTING.apply(sprite,species,facing,frame,size_variation)
	sprite.position.y = -absf(sin(walk_distance/9.0*PI))*0.6 if state == "walk" else 0.0
	sprite.rotation = sin(state_time*2.5)*0.008 if state == "graze" else 0.0
	if state != "walk": sprite.scale.y *= 1.0+sin(elapsed*2.0+flight_phase)*0.008

func _draw() -> void:
	var width := 23.0 if species == PAINTING.Species.SHEEP else 31.0
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,width*size_variation,Color(0.08,0.14,0.06,0.14))
	draw_set_transform(Vector2.ZERO)
