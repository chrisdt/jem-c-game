extends "res://environment/human_npc.gd"

const EARTH = preload("res://earth_regions.gd")
const PORTRAIT: Texture2D = preload("res://assets/npcs/bea.png")
const FOOT := EARTH.BEA_FOOT

func _ready() -> void:
	name = "Bea"
	home_region = 1
	position = FOOT
	fit_sprite(PORTRAIT)
	sync_area()

func greeting_text() -> String:
	return "Could you lend a hand with some lost supplies?"

func pages() -> Array[String]:
	if not game.trial.sword_owned: return ["There's a snake near my supply box. Rowan at camp can help you prepare a copper sword: 3 copper and 2 fallen wood."]
	return game.story.pages("bea")

func final_action() -> String:
	return game.story.action("bea")

func conversation_started() -> void:
	game.story.begin("bea")

func conversation_finished(completed: bool) -> void:
	if completed: introduced = true
	game.story.finish("bea",completed)
