extends Node2D
class_name CutsceneTrigger


@export var gdrama_path: String
@export var characters: Array[Character]


@onready var bubble: DialogueBubble = $Bubble
@onready var drama_player: DramaPlayer = $DramaPlayer


var playing = false


func _ready():
	drama_player.load_gdrama(gdrama_path)
	call_deferred("_create_display_connections")


func _create_display_connections():
	for character in characters:
		drama_player.connect_display(character.drama_display)


func _physics_process(delta):
	if Input.is_action_just_pressed("talk") and playing:
		drama_player.next_or_skip()


func display_trigger():
	bubble.appear()
	bubble.display("E", "", false)


func hide_trigger():
	bubble.disappear()


func play_cutscene(player: Player):
	playing = true
	
	drama_player.connect_display(player.drama_display)
	drama_player.start_drama()
	
	await drama_player.ended_drama
	
	drama_player.disconnect_display(player.drama_display)
	
	playing = false
