@tool
extends EditorExportPlugin

const FOLDERS := ["earth","frost","ember"]
var web := false
var output := ""

func _get_name() -> String:
	return "PlanetSceneryStreaming"

func _export_begin(features: PackedStringArray, _debug: bool, path: String, _flags: int) -> void:
	web = features.has("web")
	output = path.get_base_dir()

func _export_file(path: String, _type: String, features: PackedStringArray) -> void:
	if not features.has("web"): return
	for folder in FOLDERS:
		if path.begins_with("res://assets/"+folder+"/"):
			skip()
			return

func _export_end() -> void:
	if not web: return
	for folder in FOLDERS:
		var target := output.path_join(folder+"_chunks")
		var destination := ProjectSettings.globalize_path(target if target.is_absolute_path() else "res://"+target)
		DirAccess.make_dir_recursive_absolute(destination)
		for file in DirAccess.get_files_at("res://assets/"+folder):
			if file.get_extension() != "png": continue
			# Keep opaque scenery out of the initial pack. Native uses lossless
			# imports; Web streams smaller, faster-decoding high-quality JPEGs.
			var painting := Image.new()
			var error := painting.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/"+folder+"/"+file))
			if error == OK:
				error = painting.save_jpg(destination.path_join(file.get_basename()+".jpg"),0.92)
			if error != OK: push_error("Unable to export streamed scenery: "+folder+"/"+file)
