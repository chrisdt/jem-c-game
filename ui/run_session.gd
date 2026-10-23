extends Node

signal changed
signal adventure_completed
signal start_resolved
const SHARED_ENDPOINT := "https://playsunnyscout.com/play/api/leaderboard.php"
const SCORE_FILE := "user://speedrun_scores.json"
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
var verifying := false
var local_saved := false
var result_id := ""
var local_scores: Array = []
var last_result: Dictionary = {}
var storage_path := SCORE_FILE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_scores()

func load_scores() -> void:
	local_scores = []
	last_result = {}
	if not FileAccess.file_exists(storage_path): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
	if not data is Dictionary or data.get("campaign", "") != CAMPAIGN: return
	if data.get("scores") is Array: local_scores = data.scores
	if data.get("last_result") is Dictionary: last_result = data.last_result

func save_result() -> bool:
	if not finished or not timed: return false
	var result := {"id":result_id,"nickname":nickname,"duration_ms":duration_ms,
		"enemies":enemies,"recoveries":recoveries,"token":token,"verified":verified,
		"submitted":submitted,"rank":rank}
	var scores := local_scores.duplicate(true)
	for i in range(scores.size()-1,-1,-1):
		if scores[i].get("id", "") == result_id: scores.remove_at(i)
	# Private run tokens are only in the recoverable result, never board rows.
	var row := result.duplicate()
	for key in ["token", "submitted", "rank"]: row.erase(key)
	scores.push_front(row)
	scores.resize(mini(scores.size(),50))
	var path := storage_path+".tmp"
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"campaign":CAMPAIGN,"scores":scores,"last_result":result}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(storage_path)) != OK: return false
	local_scores = scores
	last_result = result
	local_saved = true
	return true

func restore_result() -> bool:
	if last_result.is_empty(): return false
	generation += 1
	timed = true
	running = false
	finished = true
	start_pending = false
	verifying = false
	submitting = false
	result_id = str(last_result.get("id", ""))
	nickname = str(last_result.get("nickname", "Scout"))
	duration_ms = int(last_result.get("duration_ms",0))
	enemies = int(last_result.get("enemies",0))
	recoveries = int(last_result.get("recoveries",0))
	token = str(last_result.get("token", ""))
	verified = bool(last_result.get("verified",false))
	submitted = bool(last_result.get("submitted",false))
	rank = int(last_result.get("rank",0))
	completed_ids.assign(STORY_IDS)
	local_saved = true
	notice = "Your completed time is saved on this device."
	changed.emit()
	return true

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
	verifying = false
	local_saved = false
	result_id = str(Time.get_unix_time_from_system())+"-"+str(randi())
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
		if timed:
			local_saved = save_result()
			verify_finish(generation)
func endpoint() -> String:
	if not endpoint_override.is_empty(): return endpoint_override
	if not OS.has_feature("web"): return SHARED_ENDPOINT
	# Use the page URL, not document.baseURI: versioned releases use a base
	# tag for scenery, but scores must live outside replaceable releases.
	return str(JavaScriptBridge.eval("(()=>{const p=new URL(location.href);if(!['http:','https:'].includes(p.protocol))return '';const n=p.pathname.indexOf('/releases/');return new URL(n<0?'api/leaderboard.php':p.pathname.slice(0,n+1)+'api/leaderboard.php',p).href})()"))
func api(action: String, data := {}) -> Dictionary:
	var url := endpoint()
	if url.is_empty(): return {"error":"Shared scores need an online PHP website. Your time can be saved on this device."}
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
	var parser := JSON.new()
	var parse_error := parser.parse(response[3].get_string_from_utf8())
	var parsed = parser.data
	if parse_error != OK or not parsed is Dictionary: return {"error":"Shared scores need the PHP scoreboard installed on this website."}
	parsed["http_status"] = response[1]
	if response[1] != 200 and not parsed.has("error"): return {"error":"Shared scores are unavailable. Please try again."}
	return parsed
func register_run(id: int) -> void:
	start_pending = true
	var reply := await api("start",{"campaign":CAMPAIGN})
	if id != generation: return
	start_pending = false
	token = reply.get("token","")
	if token.is_empty(): notice = "Shared scores could not register this run. Your finish can still be saved on this device."
	changed.emit()
	start_resolved.emit()
func verify_finish(id: int) -> void:
	if verifying: return
	verifying = true
	changed.emit()
	if start_pending: await start_resolved
	if id != generation: return
	if token.is_empty():
		verifying = false
		notice = "Shared posting wasn't connected at the start. " + ("Your time is saved on this device." if local_saved else "Choose Save on this device to keep it.")
		changed.emit()
		return
	notice = "Checking your official finish time…"
	changed.emit()
	var reply := await api("complete",{"token":token,"quests":completed_ids,"enemies":enemies,"recoveries":recoveries})
	if id != generation: return
	verifying = false
	verified = reply.has("result")
	if verified:
		duration_ms = int(reply.result.duration_ms)
		notice = "Official time ready. Choose a nickname to post it."
	else:
		if int(reply.get("http_status",0)) == 410: token = ""
		notice = str(reply.get("error","Your finish couldn't be checked."))+ (" Choose Retry and post." if not token.is_empty() else " Shared posting is unavailable for this run.")
	local_saved = save_result()
	if not verified and local_saved: notice += " Your time is saved on this device."
	changed.emit()
func submit(value: String) -> void:
	if not finished or submitted or submitting or verifying: return
	var expression := RegEx.new()
	expression.compile("^[A-Za-z0-9][A-Za-z0-9 _-]{1,15}$")
	if value != value.strip_edges() or expression.search(value) == null:
		notice = "Use a nickname of 2–16 letters, numbers, spaces, - or _."
		changed.emit()
		return
	var id := generation
	nickname = value
	local_saved = save_result()
	if token.is_empty():
		notice = "Saved on this device! View it under This device times." if local_saved else "Couldn't save on this device. Check available storage and try again."
		changed.emit()
		return
	if not verified:
		await verify_finish(id)
		if id != generation or not verified: return
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
	else:
		if int(reply.get("http_status",0)) == 410:
			token = ""
			verified = false
		notice = reply.get("error","Couldn't post. Try again when connected.")
	local_saved = save_result()
	if not submitted and local_saved: notice += " Your time is saved on this device."
	changed.emit()
