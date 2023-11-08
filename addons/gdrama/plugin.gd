@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("DramaAnimator", "Node", preload("res://addons/gdrama/scripts/DramaAnimator.gd"), preload("res://addons/gdrama/icons/DramaAnimator.png"))
	add_custom_type("DramaPlayer", "Node", preload("res://addons/gdrama/scripts/DramaPlayer.gd"), preload("res://addons/gdrama/icons/DramaPlayer.png"))


func _exit_tree():
	remove_custom_type("DramaAnimator")
	remove_custom_type("DramaPlayer")
