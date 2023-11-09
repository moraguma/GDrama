extends Node


@onready var drama_animator: DramaAnimator = $DramaAnimator
@onready var label = $RichTextLabel
var drama_reader: DramaReader


# Called when the node enters the scene tree for the first time.
func _ready():
	drama_reader = DramaReader.new()
	drama_reader.load_gdrama("res://resources/example.gdrama")
	
	next_line()


func next_line():
	var line = drama_reader.next_line()
	while line["type"] == "CHOICE":
		drama_reader.make_choice(0)
		line = drama_reader.next_line()
	
	if line["type"] == "END":
		$Button.hide()
		$RichTextLabel.hide()
	else:
		drama_animator.animate(line["direction"])
