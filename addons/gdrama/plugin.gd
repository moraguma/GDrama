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


func _enter_tree():
	import_plugin = GDramaImportPlugin.new()
	import_plugin.editor_plugin = self
	add_import_plugin(import_plugin)
	
	for i in range(len(TYPE_NAMES)):
		add_custom_type(TYPE_NAMES[i], TYPE_BASES[i], TYPE_SCRIPTS[i], TYPE_ICONS[i])


func _exit_tree():
	remove_import_plugin(import_plugin)
	for name in TYPE_NAMES:
		remove_custom_type(name)
