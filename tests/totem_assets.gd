extends SceneTree

# Run in an isolated project copy whose three totem .ctex files were removed.
# The previous preloads failed to compile in precisely this state.
const TOTEM = preload("res://environment/save_totem.gd")
const PERSON = preload("res://environment/human_npc.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)
func run() -> void:
	for world in [0,1,2]:
		var import_config := ConfigFile.new()
		check(import_config.load(TOTEM.ART[world]+".import")==OK,"Original import settings are missing")
		var generated: String = import_config.get_value("remap","path","")
		check(not FileAccess.file_exists(generated),"Test did not remove the generated totem texture")
		var texture: Texture2D = TOTEM.texture_for(world)
		check(texture != null and texture.get_width()<=256,"Missing cache prevented loading shipped PNG")
		if texture == null: continue
		var bounds := PERSON.visible_bounds(texture.get_image())
		check(bounds.has_area() and bounds.end.y<texture.get_height(),"Totem base still includes transparent bottom padding")
		check(TOTEM.texture_for(world)==texture,"Native totem texture was not cached")
	if failures==0: print("PASS: scripts compile and all three totems load without generated .ctex files; faint bottom padding excluded from foot anchors")
	quit(1 if failures else 0)
