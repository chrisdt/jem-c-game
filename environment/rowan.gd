extends "res://environment/human_npc.gd"

# Feet share the same world plane as Scout's boots. Crop transparent atlas
# margins before fitting, so the source image size never sets character size.
const FOOT := Vector2(590,454)
const MISSION_TITLE := "Ready for the Trail"
enum Mission { NOT_STARTED, ACTIVE, COMPLETE }
const INTRO: Array[String] = [
	"Let's get you ready for the trail. Find 3 copper and 2 fallen wood.",
	"Bring them to this workbench to craft a sword. It'll help with the snakes along the trails.",
]
var mission := Mission.NOT_STARTED
var completion_seen := false
var accepting_mission := false
var acknowledging_completion := false

func _ready() -> void:
	name = "Rowan"
	position = FOOT
	fit_person("rowan")
	sync_area()

func greeting_text() -> String:
	return "Need a hand getting ready for the trail? Come talk to me."

func pages() -> Array[String]:
	if mission == Mission.COMPLETE or game.trial.sword_owned:
		var result: Array[String] = ["That's a fine sword! You're ready for the trail."]
		if not completion_seen:
			result.append("Bea looks after Pinewood Trail. She may have a job for an explorer.")
		return result
	if mission == Mission.NOT_STARTED: return INTRO.duplicate()
	if game.ore < game.trial.SWORD_COPPER:
		return ["You have %d / 3 copper. Mine copper along Earth's trails with your pick or drill. You'll also need 2 fallen wood." % game.ore]
	if game.trial.wood < game.trial.SWORD_WOOD:
		return ["You've found the copper! You have %d / 2 wood. Gather fallen branches and logs beside the trails." % game.trial.wood]
	return ["You have everything you need. Use this workbench to craft your copper sword."]

func final_action() -> String:
	if mission == Mission.NOT_STARTED:
		return "Complete mission" if game.trial.sword_owned else "Accept mission"
	return "Done"

func conversation_started() -> void:
	# Remember what this conversation offers. Escape, a hidden speaker or scene
	# teardown must never accept an offer or acknowledge an unread ending.
	accepting_mission = mission == Mission.NOT_STARTED
	acknowledging_completion = game.trial.sword_owned and not completion_seen

func conversation_finished(completed: bool) -> void:
	if completed:
		introduced = true
		if accepting_mission and mission == Mission.NOT_STARTED:
			mission = Mission.ACTIVE
			game.message = "Mission started: Ready for the Trail. Gather 3 copper and 2 fallen wood, then craft a sword at camp."
			sync_mission()
		if acknowledging_completion and mission == Mission.COMPLETE:
			completion_seen = true
	accepting_mission = false
	acknowledging_completion = false

func sync_mission() -> void:
	# Sword ownership survives spending ingredients, equipping the drill and
	# travelling. The quest never consumes materials or grants a second sword.
	if mission == Mission.ACTIVE and game.trial.sword_owned:
		mission = Mission.COMPLETE
		game.message = "Ready for the Trail complete! Your copper sword is ready. Find Bea on Pinewood Trail for your next quest."

func quest_finished() -> bool:
	return mission == Mission.COMPLETE

func progress_text() -> String:
	if mission == Mission.COMPLETE: return "Copper sword crafted"
	if game.ore >= game.trial.SWORD_COPPER and game.trial.wood >= game.trial.SWORD_WOOD:
		return "Materials ready · craft at camp"
	return "Copper %d/3 · Wood %d/2" % [mini(game.ore,game.trial.SWORD_COPPER),mini(game.trial.wood,game.trial.SWORD_WOOD)]
