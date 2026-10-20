extends "res://environment/human_npc.gd"

var role := "otis"

func _ready() -> void:
	name = role.capitalize()
	home_region = game.story.PEOPLE[role].region
	position = game.story.PEOPLE[role].foot
	if not game.story.floor_at(position,home_region,false):
		for ring in range(1,16):
			var found := false
			for ray in 24:
				var candidate: Vector2 = game.story.PEOPLE[role].foot+Vector2.from_angle(ray*TAU/24)*ring*10
				if game.story.floor_at(candidate,home_region,false):
					position = candidate
					found = true
					break
			if found: break
	if role == "otis":
		fit_sprite(load("res://assets/npcs/earth_people_concept.png"),Rect2i(768,0,768,1024))
	else:
		var index: int = ["mara","iris","finn","nova"].find(role)
		fit_sprite(load("res://assets/npcs/earth_neighbours.png"),Rect2i((index%2)*768,(index/2)*512,768,512))
	sync_area()

func greeting_text() -> String:
	return {"otis":"Mind the rockfall! Come talk before heading to the quarry.","mara":"Looking for stronger tools? I can help.","iris":"There's a story hidden in these ruins.","finn":"Every explorer needs a well-sealed spacesuit.","nova":"One day this rocket will take us to other worlds!"}[role]

func pages() -> Array[String]:
	return game.story.pages(role)

func final_action() -> String:
	return game.story.action(role)

func conversation_started() -> void:
	game.story.begin(role)

func conversation_finished(completed: bool) -> void:
	if completed: introduced = true
	game.story.finish(role,completed)
