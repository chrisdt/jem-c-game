extends SceneTree

var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)

func rectangle(values: Array) -> Rect2i:
	return Rect2i(values[0],values[1],values[2],values[3])

func digest(image: Image) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(image.get_data())
	return hash.finish().hex_encode()

func run() -> void:
	# The closures are painted into the source backgrounds, not drawn at play
	# time. Preserve the original pixels everywhere outside the retouched areas.
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/support/mine_painting.json"))
	check(manifest.version == 1 and manifest.mines.size() == 3,"Missing mine-painting preservation manifest")
	var boards := 0
	var rubble := 0
	for mine in manifest.mines:
		var image := Image.load_from_file(mine.path)
		image.convert(Image.FORMAT_RGBA8)
		check(image.get_size() == Vector2i(mine.size[0],mine.size[1]),"Mine painting changed dimensions")
		var imported: Texture2D = load(mine.path)
		check(imported.get_size() == Vector2(image.get_size()),"Runtime painting import has different dimensions")
		var exit := rectangle(mine.exit)
		check(digest(image.get_region(exit)) == mine.exit_sha256,"Usable surface exit artwork changed")
		var protected: Image = image.duplicate()
		for edit in mine.edits:
			var bounds := rectangle(edit.bounds)
			var opening := rectangle(edit.opening)
			check(Rect2i(Vector2i.ZERO,image.get_size()).encloses(bounds),"Retouched doorway is outside its map")
			check(not bounds.intersects(exit),"Retouched doorway covers the real exit")
			check(digest(image.get_region(opening)) != edit.original_sha256,"A decorative opening still has the original open artwork")
			protected.fill_rect(bounds,Color(0,0,0,0))
			if edit.kind == "boards": boards += 1
			else: rubble += 1
		check(digest(protected) == mine.preserved_sha256,"Mine pixels changed outside the local doorway edits")
	check(boards == 32 and rubble == 5,"Missing painted doorway or natural rail closure")
	var game_script: Script = load("res://game.gd")
	check(not game_script.get_script_constant_map().has("BOARDED_PASSAGES"),"Runtime still loads the removed boarding overlay")
	check(not FileAccess.file_exists("res://environment/boarded_passages.gd"),"Old runtime boarding renderer remains")
	if failures == 0: print("PASS: 32 boarded openings and five rubble closures painted into three original-size backgrounds; all usable exits and every pixel outside local edit areas unchanged; runtime overlay removed")
	quit(1 if failures else 0)
