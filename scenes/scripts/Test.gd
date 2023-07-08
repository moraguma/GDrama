extends Node


@onready var drama_animation_player: DramaAnimationPlayer = $DramaAnimationPlayer
@onready var label = $RichTextLabel
var drama_reader: DramaReader


# Called when the node enters the scene tree for the first time.
func _ready():
	drama_reader = DramaReader.new()
	drama_reader.load_gdrama("res://resources/example.gdrama")
	
	drama_animation_player.label = label
	
	next_line()


func next_line():
	var line = drama_reader.next_line()
	while line["type"] == "CHOICE":
		drama_reader.make_choice(0)
		line = drama_reader.next_line()
	
	label.text = drama_animation_player.play_drama(line["direction"])
