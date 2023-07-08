@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("DramaAnimationPlayer", "AnimationPlayer", preload("res://addons/gdrama/scripts/DramaAnimationPlayer.gd"), preload("res://addons/gdrama/icons/DramaAnimationPlayer.png"))


func _exit_tree():
	remove_custom_type("DramaAnimationPlayer")
