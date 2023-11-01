extends Node2D


@onready var animation_player = $AnimationPlayer
@onready var rich_text_label = $RichTextLabel


func _ready():
	animation_player.play("test")
	var anim: Animation = animation_player.get_animation("test")
	
	var d = {}
	for track in range(anim.get_track_count()):
		d[track] = anim.track_get_path(track)
	
	print(d)
	print(self.get_path_to(self))


func test():
	print("Test successful!")
