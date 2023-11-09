@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("DramaPlayer", "Node", preload("res://addons/gdrama/scripts/DramaPlayer.gd"), preload("res://addons/gdrama/icons/DramaPlayer.png"))
	add_custom_type("DramaDisplay", "Node", preload("res://addons/gdrama/scripts/DramaDisplay.gd"), preload("res://addons/gdrama/icons/DramaDisplay.png"))


func _exit_tree():
	remove_custom_type("DramaPlayer")
	remove_custom_type("DramaDisplay")
