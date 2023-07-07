extends Node


@onready var animation_player = $AnimationPlayer
@onready var label = $RichTextLabel
var drama_reader: DramaReader
var drama_animator: DramaAnimator


# Called when the node enters the scene tree for the first time.
func _ready():
	drama_reader = DramaReader.new()
	drama_reader.load_gdrama("res://resources/example.gdrama")
	
	drama_animator = DramaAnimator.new(animation_player, label, self, self)
	
	next_line()


func next_line():
	if animation_player.is_playing():
		animation_player.advance(animation_player.current_animation_length - animation_player.current_animation_position)
	
	var line = drama_reader.next_line()
	while line["type"] == "CHOICE":
		drama_reader.make_choice(0)
	
	animation_player.remove_animation_library("t")
	var anim_lib = AnimationLibrary.new()
	var anim: DramaAnimation = drama_animator.create_drama_animation(line["direction"])
	anim_lib.add_animation("t1", anim)
	print(anim_lib.has_animation("t1"))
	animation_player.add_animation_library("t", anim_lib)
	
	label.text = "[center]" + anim.raw_text
	animation_player.play("t/t1")
	
	var a: Animation = animation_player.get_animation("t/t1")
	var d = {}
	for track in range(a.get_track_count()):
		d[track] = {"path": a.track_get_path(track), "keys": []}
		for key in range(a.track_get_key_count(track)):
			d[track]["keys"].append(anim.track_get_key_time(track, key))
	print(d)
