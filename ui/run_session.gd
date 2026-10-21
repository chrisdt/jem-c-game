extends Node

signal changed
signal adventure_completed
signal start_resolved
const CAMPAIGN := "three-worlds-story-v1"
const STORY_IDS := ["rowan","bea","otis","mara","iris","finn","frost_pip","frost_nix","frost_tavi","frost_eira","ember_sol","ember_luma","ember_brasa","ember_orin"]
var timed := false
var running := false
var finished := false
var started_ms := 0
var duration_ms := 0
var enemies := 0
var recoveries := 0
var completed_ids: Array[String] = []
var token := ""
var start_pending := false
var verified := false
var submitting := false
var submitted := false
var rank := 0
var nickname := ""
var notice := ""
var generation := 0
var endpoint_override := ""

func _ready() -> void: process_mode = Node.PROCESS_MODE_ALWAYS
func menu() -> void:
	generation += 1
	timed = false
	running = false
	finished = false
	start_pending = false
	start_resolved.emit()
func choose(is_timed: bool) -> void: timed = is_timed
func begin_world() -> void:
	generation += 1
	var id := generation
	running = false
	finished = false
	started_ms = Time.get_ticks_msec()
	duration_ms = 0
	enemies = 0
	recoveries = 0
	completed_ids.clear()
	token = ""
	verified = false
	submitting = false
	submitted = false
	rank = 0
	nickname = "Scout-%02d" % randi_range(10,99)
	notice = ""
	start_pending = false
	if OS.has_feature("web"):
		# The first world draw compiles shaders and uploads its textures. A
		# request created before that draw can time out before fetch is polled.
		# Start both clocks after the world has painted, before play advances.
		await get_tree().process_frame
		await get_tree().process_frame
		if id != generation: return
	started_ms = Time.get_ticks_msec()
	running = true
	if timed: register_run(id)
func elapsed_ms() -> int:
	return maxi(0,Time.get_ticks_msec()-started_ms) if running else duration_ms
static func format_time(milliseconds: int, precise := false) -> String:
	var total := maxi(0,milliseconds)/1000
	var text := "%d:%02d:%02d" % [total/3600,(total/60)%60,total%60] if total >= 3600 else "%d:%02d" % [total/60,total%60]
	return text+(".%02d" % ((maxi(0,milliseconds)%1000)/10) if precise else "")
func record_enemy() -> void:
	if running: enemies += 1
func record_recovery() -> void:
	if running: recoveries += 1
func observe(game: Node) -> void:
	if not running: return
	# Read small quest flags; never format three journals or load other maps
	# every frame merely to update the run counter.
	completed_ids.clear()
	for role in ["rowan","bea","otis","mara","iris","finn"]:
		if game.story.done(role): completed_ids.append(role)
	for role in game.frost_story.ORDER:
		if game.frost_story.done(role): completed_ids.append("frost_"+role)
	for role in game.ember_story.ORDER:
		if game.ember_story.done(role): completed_ids.append("ember_"+role)
	if completed_ids.size() == STORY_IDS.size():
		duration_ms = elapsed_ms()
		running = false
		finished = true
		adventure_completed.emit.call_deferred()
		if timed: verify_finish(generation)
func endpoint() -> String:
	if not endpoint_override.is_empty(): return endpoint_override
	if not OS.has_feature("web"): return ""
	# Use the page URL, not document.baseURI: versioned releases use a base
	# tag for scenery, but scores must live outside replaceable releases.
	return str(JavaScriptBridge.eval("(()=>{const p=new URL(location.href);const n=p.pathname.indexOf('/releases/');return new URL(n<0?'api/leaderboard.php':p.pathname.slice(0,n+1)+'api/leaderboard.php',p).href})()"))
func api(action: String, data := {}) -> Dictionary:
	var url := endpoint()
	if url.is_empty(): return {"error":"Shared scores work on the hosted PHP website. You can still finish this adventure."}
	var request := HTTPRequest.new()
	request.timeout = 10
	request.use_threads = not OS.has_feature("web")
	request.body_size_limit = 131072
	add_child(request)
	var payload: Dictionary = data.duplicate()
	payload.action = action
	var method := HTTPClient.METHOD_GET if action == "board" else HTTPClient.METHOD_POST
	if method == HTTPClient.METHOD_GET: url += "?fresh="+str(Time.get_ticks_msec())
	var error := request.request(url,["Content-Type: application/json","Accept: application/json"],method,"" if method == HTTPClient.METHOD_GET else JSON.stringify(payload))
	if error != OK:
		request.queue_free()
		return {"error":"Couldn't reach shared scores. Your adventure still works."}
	var response: Array = await request.request_completed
	request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS: return {"error":"Shared scores couldn't connect. Please try again."}
	var parsed = JSON.parse_string(response[3].get_string_from_utf8())
	if not parsed is Dictionary: return {"error":"Shared scores need the PHP scoreboard installed on this website."}
	if response[1] != 200 and not parsed.has("error"): return {"error":"Shared scores are unavailable. Please try again."}
	return parsed
func register_run(id: int) -> void:
	start_pending = true
	var reply := await api("start",{"campaign":CAMPAIGN})
	if id != generation: return
	start_pending = false
	token = reply.get("token","")
	if token.is_empty(): notice = reply.get("error","This run will finish without a shared time.")
	changed.emit()
	start_resolved.emit()
func verify_finish(id: int) -> void:
	if start_pending: await start_resolved
	if id != generation: return
	if token.is_empty():
		if notice.is_empty(): notice = "Finished! This run couldn't connect to the shared board."
		changed.emit()
		return
	notice = "Checking your official finish time…"
	changed.emit()
	var reply := await api("complete",{"token":token,"quests":completed_ids,"enemies":enemies,"recoveries":recoveries})
	if id != generation: return
	verified = reply.has("result")
	if verified:
		duration_ms = int(reply.result.duration_ms)
		notice = "Official time ready. Choose a nickname to post it."
	else: notice = reply.get("error","Your finish is complete, but shared scores couldn't be checked.")
	changed.emit()
func submit(value: String) -> void:
	if not finished or not verified or submitted or submitting: return
	var expression := RegEx.new()
	expression.compile("^[A-Za-z0-9][A-Za-z0-9 _-]{1,15}$")
	if value != value.strip_edges() or expression.search(value) == null:
		notice = "Use a nickname of 2–16 letters, numbers, spaces, - or _."
		changed.emit()
		return
	var id := generation
	submitting = true
	notice = "Posting your time…"
	changed.emit()
	var reply := await api("submit",{"token":token,"nickname":value})
	if id != generation: return
	submitting = false
	if reply.has("scores"):
		submitted = true
		nickname = reply.get("nickname",value)
		rank = int(reply.get("rank",0)) if reply.get("rank") != null else 0
		notice = "Posted! Your best time is #%d." % rank if rank > 0 else "Posted! The board keeps the 50 fastest nicknames."
	else: notice = reply.get("error","Couldn't post. Try again when connected.")
	changed.emit()
