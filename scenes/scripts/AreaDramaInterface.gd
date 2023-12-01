extends DramaInterface2D
class_name AreaDramaInterface

@onready var standing_pos: Vector2 = position + $StandingPos.position
@onready var game: Game = get_parent()

@export var intro_drama_display: BubbleDramaDisplay
@export var look_left = false


func display_trigger():
	if not playing:
		intro_drama_display.showing = true
		intro_drama_display.display("E", "", false)
		intro_drama_display.next.hide()


func hide_trigger():
	if not playing:
		intro_drama_display.showing = false


func play_drama():
	print("Trying to connect logs")
	game.connect_logs(drama_player.drama_reader)
	print("Connected logs")
	
	await super.play_drama()
	
	game.reset_logs()
