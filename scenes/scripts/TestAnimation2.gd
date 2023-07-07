extends Node


@onready var animation_player = $Node/AnimationPlayer
@onready var rich_text_label = $Node/RichTextLabel


func _ready():
	animation_player.play("test")
	var anim: Animation = animation_player.get_animation("test")
	
	var d = {}
	for track in range(anim.get_track_count()):
		d[track] = anim.track_get_path(track)
	
	print("Node - " + str(d))


func test():
	print("Test successful!")
