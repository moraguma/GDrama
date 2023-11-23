@tool
extends EditorImportPlugin
class_name GDramaImportPlugin


signal compiled_resource(resource: Resource)


var editor_plugin


func _get_importer_name() -> String:
	return "gdrama_importer"


func _get_visible_name() -> String:
	return "GDrama"


func _get_import_order() -> int:
	return 0


func _get_priority() -> float:
	return 1.0


func _get_resource_type():
	return "Resource"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gdrama"])


func _get_save_extension():
	return "tres"


func _get_preset_count() -> int:
	return 0


func _get_preset_name(preset_index: int) -> String:
	return "Undefined"


func _get_import_options(path: String, preset_index: int) -> Array:
	# When the options array is empty there is a misleading error on export
	# that actually means nothing so let's just have an invisible option.
	#return [{
	#	name = "defaults",
	#	default_value = true
	#}]
	
	return []


func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return false


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	# Get the raw file contents
	if not FileAccess.file_exists(source_file): return ERR_FILE_NOT_FOUND
	
	# Parse the text
	var parser: GDramaParser = GDramaParser.new()
	var err = parser.parse(source_file)
	var result: GDramaResource = parser.get_result()
	var errors: Array[Dictionary] = parser.get_errors()

	if err != OK:
		printerr("%d errors found in %s" % [len(errors), source_file])
		for error in errors:
			printerr("%s @ %d:%d" % [error["error"], error["line_number"], error["column_number"]])
		return err
	else:
		print("Successfully imported GDrama @ %s" % [source_file])
	
	err = ResourceSaver.save(result, "%s.%s" % [save_path, _get_save_extension()])
	compiled_resource.emit(result)
	return err
