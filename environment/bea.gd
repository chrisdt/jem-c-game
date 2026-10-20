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
	return "Hello, explorer! Welcome to Pinewood Trail."

func pages() -> Array[String]:
	var result: Array[String] = []
	if not introduced:
		result.append("I'm Bea, the woodland ranger. I help keep Pinewood Trail safe.")
	if not game.trial.sword_owned:
		result.append("Rowan at camp can help you prepare a copper sword. You'll need 3 copper and 2 fallen wood.")
	elif game.upgraded:
		result.append("Your hand drill is ready for tough minerals. Keep your sword handy for the woodland trail.")
	else:
		result.append("Keep your sword ready out here. Watch for a snake's warning before it strikes.")
	return result
