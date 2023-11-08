@icon("res://addons/gdrama/icons/DramaPlayer.png")
@tool
extends DramaAnimator
class_name DramaPlayer


@export var gdrama_path: String:
	set(value):
		gdrama_path = value
		update_configuration_warnings()


@onready var drama_reader: DramaReader = DramaReader.new()


func _get_configuration_warnings():
	if gdrama_path == "":
		return ["GDrama file not set"]
	elif not FileAccess.file_exists(gdrama_path):
		return ["Unable to locate GDrama at " + gdrama_path]
	return []


# Called when the node enters the scene tree for the first time.
func _ready():
	drama_reader.load_gdrama(gdrama_path)
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
		animate(line["direction"])
