extends Node2D
class_name CutsceneTrigger


@export var gdrama_path: String
@export var displays: Array[DramaDisplay]


@onready var bubble: DialogueBubble = $Bubble
@onready var drama_player: DramaPlayer = $DramaPlayer


func _ready():
	drama_player.load_gdrama(gdrama_path)
	for display in displays:
		drama_player.connect_display(display)


func display_trigger():
	bubble.appear()
	bubble.display("E", false)


func hide_trigger():
	bubble.disappear()


func play_cutscene(player: Player):
	print("This has yet to be implemented!")
