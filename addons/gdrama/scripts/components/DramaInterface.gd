@icon("res://addons/gdrama/icons/DramaInterface.png")
@tool
extends Node
class_name DramaInterface


@export var drama_displays: Array[Node]:
	set(value):
		drama_displays = value
		update_configuration_warnings()
@export var gdrama_path: String:
	set(value):
		gdrama_path = value
		update_configuration_warnings()



var drama_player: DramaPlayer


var playing = false


func _get_configuration_warnings():
	var warnings = []
	
	if gdrama_path == "":
		warnings.append("No GDrama path given")
	elif not FileAccess.file_exists(gdrama_path):
		warnings.append("Unable to find GDrama at " + gdrama_path)
	
	if len(drama_displays) == 0:
		warnings.append("No DramaDisplays have been specified")


func _ready():
	drama_player = _get_drama_player()
	add_child(drama_player)
	
	drama_player.load_gdrama(gdrama_path)
	for display in drama_displays:
		drama_player.connect_display(display)


func play_drama():
	playing = true
	
	drama_player.start_drama.call_deferred()
	await drama_player.ended_drama
	
	playing = false


## Returns the log being kept by this nodes DramaReader
func get_log():
	return drama_player.drama_reader.log


## Can be overriden in scripts that inherit from this one to return a custom
## DramaPlayer implementation
func _get_drama_player() -> DramaPlayer:
	return DramaPlayer.new()
