extends "res://environment/human_npc.gd"

const EARTH = preload("res://earth_regions.gd")
const FOOT := EARTH.BEA_FOOT

func _ready() -> void:
	name = "Bea"
	home_region = 1
	position = FOOT
	# Keep Bea beside her landmark when an annotated walking boundary excludes
	# the log itself. Her quest remains reachable from the surrounding grass.
	if not EARTH.can_walk(home_region,false,position):
		for ring in range(1,21):
			var found := false
			for ray in 24:
				var candidate := FOOT+Vector2.from_angle(ray*TAU/24)*ring*10
				if EARTH.can_walk(home_region,false,candidate):
					position = candidate
					found = true
					break
			if found: break
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
