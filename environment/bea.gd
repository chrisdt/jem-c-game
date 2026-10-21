extends "res://environment/human_npc.gd"

const EARTH = preload("res://earth_regions.gd")
const FOOT := EARTH.BEA_FOOT

func _ready() -> void:
	name = "Bea"
	home_region = 1
	position = FOOT
	fit_person("bea")
	sync_area()

func greeting_text() -> String:
	return "Could you lend a hand with some lost supplies?"

func pages() -> Array[String]:
	return game.story.pages("bea")

func final_action() -> String:
	return game.story.action("bea")

func conversation_started() -> void:
	game.story.begin("bea")

func conversation_finished(completed: bool) -> void:
	if completed: introduced = true
	game.story.finish("bea",completed)

func quest_finished() -> bool:
	return is_instance_valid(game.story) and game.story.done("bea")
