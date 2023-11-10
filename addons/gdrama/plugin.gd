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
	preload("res://addons/gdrama/scripts/DramaDisplay2D.gd"),
	preload("res://addons/gdrama/scripts/DramaDisplay3D.gd"),
	preload("res://addons/gdrama/scripts/DramaDisplayControl.gd"),
	preload("res://addons/gdrama/scripts/DramaInterface2D.gd"),
	preload("res://addons/gdrama/scripts/DramaInterface3D.gd"),
	preload("res://addons/gdrama/scripts/DramaInterface.gd")
]
const TYPE_ICONS = [
	preload("res://addons/gdrama/icons/DramaDisplay2D.png"),
	preload("res://addons/gdrama/icons/DramaDisplay3D.png"),
	preload("res://addons/gdrama/icons/DramaDisplayControl.png"),
	preload("res://addons/gdrama/icons/DramaInterface2D.png"),
	preload("res://addons/gdrama/icons/DramaInterface3D.png"),
	preload("res://addons/gdrama/icons/DramaInterface.png")
]


func _enter_tree():
	for i in range(len(TYPE_NAMES)):
		add_custom_type(TYPE_NAMES[i], TYPE_BASES[i], TYPE_SCRIPTS[i], TYPE_ICONS[i])


func _exit_tree():
	for name in TYPE_NAMES:
		remove_custom_type(name)
