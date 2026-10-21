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
	fit_person(role)
	sync_area()

func sync_area() -> void:
	super.sync_area()
	if role == "nova": visible = visible and game.story.available("nova")

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

func quest_finished() -> bool:
	return is_instance_valid(game.story) and game.story.done(role)
