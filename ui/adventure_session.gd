extends Node

signal changed
signal checkpoint_saved
signal checkpoint_started
signal checkpoint_finished(kept: bool, online: bool)
const SNAPSHOT = preload("res://ui/adventure_snapshot.gd")
const FILE := "user://explore_checkpoint.json"
const WEB_KEY := "sunny-scout-explore-checkpoint-v1"
const ENDPOINT := "https://playsunnyscout.com/index.php?rest_route=/sunny-scout/v1/adventure"
var storage_path := FILE
var endpoint_override := ""
var saved: Dictionary = {}
var staged: Dictionary = {}
var code := ""
var revision := 0
var busy := false
var status := "Visit a glowing totem to save your Explore adventure."
var conflict := false
var device_saved := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_device()

func load_device() -> void:
	var text := ""
	if OS.has_feature("web"):
		text = str(JavaScriptBridge.eval("(()=>{try{return localStorage.getItem("+JSON.stringify(WEB_KEY)+")||''}catch(_){return ''}})()"))
	if text.is_empty() and FileAccess.file_exists(storage_path): text = FileAccess.get_file_as_string(storage_path)
	if text.length() > 550000: return
	var parser := JSON.new()
	if parser.parse(text) != OK: return
	var parsed = parser.data
	if not parsed is Dictionary: return
	if valid_code(str(parsed.get("code",""))) and parsed.get("snapshot") is Dictionary and SNAPSHOT.number(parsed.get("revision")) and parsed.get("checkpoint") is String:
		saved = parsed
		device_saved = true

static func valid_code(value: String) -> bool:
	if value.length() != 32: return false
	for letter in value:
		if not letter in "0123456789abcdef": return false
	return true

static func normalize(value: String) -> String:
	return value.strip_edges().to_lower().replace("-","").replace(" ","").replace("\n","").replace("\r","")

func recovery_code() -> String:
	var value: String = saved.get("code",code)
	var parts := PackedStringArray()
	for i in range(0,value.length(),4): parts.append(value.substr(i,4))
	return "-".join(parts)

func has_save() -> bool: return not saved.is_empty()

func new_adventure() -> void:
	# Keep the old checkpoint recoverable until the new adventure actually
	# reaches a totem. Merely starting a game must not erase the previous save.
	code = ""
	revision = 0
	staged = {}
	conflict = false
	status = "Visit a glowing totem to save your Explore adventure."
	changed.emit()

func persist(record: Dictionary) -> bool:
	var text := JSON.stringify(record)
	var stored := false
	if OS.has_feature("web"):
		stored = bool(JavaScriptBridge.eval("(()=>{try{localStorage.setItem("+JSON.stringify(WEB_KEY)+","+JSON.stringify(text)+");return true}catch(_){return false}})()"))
	if not stored:
		var file := FileAccess.open(storage_path+".tmp",FileAccess.WRITE)
		if file != null:
			file.store_string(text)
			file.flush()
			var error := file.get_error()
			file.close()
			stored = error == OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(storage_path+".tmp"),ProjectSettings.globalize_path(storage_path)) == OK
	if stored:
		saved = record.duplicate(true)
		device_saved = true
	return stored

func checkpoint(game: Node) -> bool:
	if busy or game.run_session.timed or game.underground or game.earth_transition or game.flight != 0 or game.trial.health <= 0: return false
	if conflict: return false
	checkpoint_started.emit()
	if code.is_empty(): code = Crypto.new().generate_random_bytes(16).hex_encode()
	var snapshot := SNAPSHOT.capture(game)
	var record := {"code":code,"revision":revision,"checkpoint":Crypto.new().generate_random_bytes(12).hex_encode(),"snapshot":snapshot,"pending":true,"place":game.PLANET_NAMES[game.world]+" · "+game.regions().NAMES[game.current_region()]}
	# Remember uncertain writes, not copies of their entire snapshots. If a
	# response was lost we may rebase only over one of our own checkpoints.
	var ancestors: Array = saved.get("ancestors",[]).duplicate() if saved.get("code","") == code else []
	if saved.get("code","") == code and saved.get("pending",false): ancestors.append(saved.checkpoint)
	while ancestors.size() > 128: ancestors.pop_front()
	record["ancestors"] = ancestors
	if JSON.stringify(record).length() > 524288:
		status = "This adventure is too large to save. Your previous checkpoint is kept."
		changed.emit()
		checkpoint_finished.emit(false,false)
		return false
	var local_ok := persist(record)
	device_saved = local_ok
	status = "Checkpoint saved on this device. Saving online…" if local_ok else "Saving checkpoint online…"
	changed.emit()
	# If local storage is unavailable, still attempt the online copy. Retain it
	# in memory so a successful save gives the player their recovery code.
	if not local_ok: saved = record
	var online_ok := await upload()
	var kept := local_ok or online_ok
	if kept: checkpoint_saved.emit()
	checkpoint_finished.emit(kept,online_ok)
	return kept

func endpoint() -> String:
	if not endpoint_override.is_empty(): return endpoint_override
	if not OS.has_feature("web"): return ENDPOINT
	return str(JavaScriptBridge.eval("(()=>{if(typeof window.scoutAdventureEndpoint==='string'){const u=new URL(window.scoutAdventureEndpoint,location.href);if(u.origin===location.origin)return u.href}return ''})()"))

func api(payload: Dictionary) -> Dictionary:
	var url := endpoint()
	if url.is_empty(): return {"error":"Update the Sunny Scout WordPress plugin and use its Play link for online saves."}
	var request := HTTPRequest.new()
	request.timeout = 12
	request.body_size_limit = 550000
	request.use_threads = not OS.has_feature("web")
	add_child(request)
	var error := request.request(url,["Content-Type: application/json","Accept: application/json"],HTTPClient.METHOD_POST,JSON.stringify(payload))
	if error != OK:
		request.queue_free()
		return {"error":"Online saves couldn't connect. Try the totem again."}
	var response: Array = await request.request_completed
	request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS: return {"error":"Online saves couldn't connect. Try the totem again."}
	var parser := JSON.new()
	if parser.parse(response[3].get_string_from_utf8()) != OK: return {"error":"Online saves need the updated WordPress plugin."}
	var parsed = parser.data
	if not parsed is Dictionary: return {"error":"Online saves need the updated WordPress plugin."}
	if response[1] == 404 and parsed.get("code","") == "rest_no_route": return {"error":"Online saves need the updated WordPress plugin."}
	if response[1] != 200 and not parsed.has("error"): return {"error":"Online saves are unavailable. Try again."}
	parsed["http_status"] = response[1]
	return parsed

func upload() -> bool:
	if busy or saved.is_empty(): return false
	busy = true
	changed.emit()
	var record := saved.duplicate(true)
	var payload := {"action":"save","code":record.code,"revision":int(record.revision),"checkpoint":record.checkpoint,"snapshot":record.snapshot}
	var reply := await api(payload)
	if reply.get("conflict",false):
		var remote := await api({"action":"load","code":record.code})
		if not remote.has("error") and remote.get("checkpoint","") in record.get("ancestors",[]):
			payload.revision = int(remote.revision)
			reply = await api(payload)
	busy = false
	if reply.has("error"):
		conflict = reply.get("conflict",false)
		status = ("Saved on this device. " if device_saved else "Checkpoint could not be saved. ")+str(reply.error)
		changed.emit()
		return false
	if not reply.has("revision") or reply.get("checkpoint","") != record.checkpoint:
		status = ("Saved on this device. " if device_saved else "")+"Online save could not be confirmed."
		changed.emit()
		return false
	revision = int(reply.revision)
	record.revision = revision
	record.pending = false
	record["ancestors"] = []
	if not persist(record): saved = record
	status = "Checkpoint saved on this device and online." if device_saved else "Checkpoint saved online. Keep your recovery code."
	changed.emit()
	return true

func continue_adventure() -> bool:
	if busy or not has_save(): return false
	code = saved.code
	revision = int(saved.revision)
	conflict = false
	var candidate := saved.duplicate(true)
	# Prefer another device's newer checkpoint, but keep our own newer offline
	# work over an older server copy or one of our uncertain earlier writes.
	busy = true
	status = "Checking your latest checkpoint…"
	changed.emit()
	var reply := await api({"action":"load","code":code})
	busy = false
	var pending: bool = saved.get("pending",true)
	if not reply.has("error") and reply.get("snapshot") is Dictionary and int(reply.get("revision",0)) >= revision:
		var own_earlier: bool = reply.get("checkpoint","") in saved.get("ancestors",[])
		if not pending or (int(reply.revision) > revision and not own_earlier):
			candidate.snapshot = reply.snapshot
			candidate.revision = int(reply.revision)
			candidate.checkpoint = reply.checkpoint
			candidate.pending = false
			candidate["ancestors"] = []
			revision = int(reply.revision)
	staged = candidate.snapshot.duplicate(true)
	staged["_recovered"] = candidate
	changed.emit()
	return true

func recover(value: String) -> bool:
	if busy: return false
	var candidate := normalize(value)
	if not valid_code(candidate):
		status = "Enter all eight groups of your recovery code."
		changed.emit()
		return false
	busy = true
	status = "Finding your adventure…"
	changed.emit()
	var reply := await api({"action":"load","code":candidate})
	busy = false
	if reply.has("error") or not reply.get("snapshot") is Dictionary:
		status = str(reply.get("error","That adventure could not be opened."))
		changed.emit()
		return false
	code = candidate
	revision = int(reply.revision)
	conflict = false
	# Only replace the local checkpoint after the actual game validates and
	# restores the recovered payload. Bad data must not destroy a good save.
	staged = reply.snapshot.duplicate(true)
	staged["_recovered"] = {"code":code,"revision":revision,"checkpoint":reply.checkpoint,"snapshot":reply.snapshot,"pending":false,"place":"Recovered adventure"}
	changed.emit()
	return true

func restore(game: Node) -> bool:
	if staged.is_empty() or game.run_session.timed: return false
	var codec := SNAPSHOT.new()
	var data := codec.unpack(staged,game)
	if data.is_empty():
		staged = {}
		status = "This checkpoint couldn't be read. Your previous save is kept."
		changed.emit()
		return false
	SNAPSHOT.apply(data,game)
	game.save_totem.resume_checkpoint()
	if staged.has("_recovered"):
		var recovered: Dictionary = staged._recovered
		if not persist(recovered):
			saved = recovered
			device_saved = false
	staged = {}
	status = "Adventure continued. Visit a totem to save again."
	changed.emit()
	return true
