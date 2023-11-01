@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("DramaAnimator", "Node", preload("res://addons/godrama/scripts/DramaAnimator.gd"), preload("res://addons/godrama/icons/DramaAnimationPlayer.png"))


func _exit_tree():
	remove_custom_type("DramaAnimator")
