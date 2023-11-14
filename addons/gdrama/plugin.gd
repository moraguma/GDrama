@tool
extends EditorPlugin


const TYPE_NAMES = [
	"DramaDisplay2D",
	"DramaDisplay3D",
	"DramaDisplayControl",
	"DramaInterface2D",
	"DramaInterface3D",
	"DramaInterface"
]
const TYPE_BASES = [
	"Node2D",
	"Node3D",
	"Control",
	"Node2D",
	"Node3D",
	"Node"
]
const TYPE_SCRIPTS = [
	preload("res://addons/gdrama/scripts/components/DramaDisplay2D.gd"),
	preload("res://addons/gdrama/scripts/components/DramaDisplay3D.gd"),
	preload("res://addons/gdrama/scripts/components/DramaDisplayControl.gd"),
	preload("res://addons/gdrama/scripts/components/DramaInterface2D.gd"),
	preload("res://addons/gdrama/scripts/components/DramaInterface3D.gd"),
	preload("res://addons/gdrama/scripts/components/DramaInterface.gd")
]
const TYPE_ICONS = [
	preload("res://addons/gdrama/icons/DramaDisplay2D.png"),
	preload("res://addons/gdrama/icons/DramaDisplay3D.png"),
	preload("res://addons/gdrama/icons/DramaDisplayControl.png"),
	preload("res://addons/gdrama/icons/DramaInterface2D.png"),
	preload("res://addons/gdrama/icons/DramaInterface3D.png"),
	preload("res://addons/gdrama/icons/DramaInterface.png")
]

var import_plugin
var og_textfile_extensions


func _enter_tree():
	if Engine.is_editor_hint():
		og_textfile_extensions = get_editor_interface().get_editor_settings().get_setting("docks/filesystem/textfile_extensions")
		get_editor_interface().get_editor_settings().set_setting("docks/filesystem/textfile_extensions", og_textfile_extensions + ",gdrama")
		
		var gdrama_syntax_highlighter: GDramaSyntaxHighlighter = GDramaSyntaxHighlighter.new()
		get_editor_interface().get_script_editor().register_syntax_highlighter(gdrama_syntax_highlighter)
		
		import_plugin = GDramaImportPlugin.new()
		import_plugin.editor_plugin = self
		add_import_plugin(import_plugin)
		
		for i in range(len(TYPE_NAMES)):
			add_custom_type(TYPE_NAMES[i], TYPE_BASES[i], TYPE_SCRIPTS[i], TYPE_ICONS[i])


func _exit_tree():
	if Engine.is_editor_hint():
		get_editor_interface().get_editor_settings().set_setting("docks/filesystem/textfile_extensions", og_textfile_extensions)
		
		remove_import_plugin(import_plugin)
		for name in TYPE_NAMES:
			remove_custom_type(name)
