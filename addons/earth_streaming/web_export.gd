@tool
extends EditorExportPlugin

var web := false
var output := ""

func _get_name() -> String:
	return "EarthSceneryStreaming"

func _export_begin(features: PackedStringArray, _debug: bool, path: String, _flags: int) -> void:
	web = features.has("web")
	output = path.get_base_dir().path_join("earth_chunks")

func _export_file(path: String, _type: String, features: PackedStringArray) -> void:
	if features.has("web") and path.begins_with("res://assets/earth/"):
		skip()

func _export_end() -> void:
	if not web: return
	var destination := ProjectSettings.globalize_path(output if output.is_absolute_path() else "res://"+output)
	DirAccess.make_dir_recursive_absolute(destination)
	for file in DirAccess.get_files_at("res://assets/earth"):
		if file.get_extension() != "png": continue
		# These are opaque ground paintings. High-quality JPEG cuts download
		# size and main-thread browser decoding time; native keeps lossless PNG.
		var painting := Image.new()
		var error := painting.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/earth/"+file))
		if error == OK:
			error = painting.save_jpg(destination.path_join(file.get_basename()+".jpg"),0.92)
		if error != OK:
			push_error("Unable to export streamed Earth scenery: "+file)
