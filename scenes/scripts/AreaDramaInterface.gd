extends DramaInterface2D
class_name AreaDramaInterface

@onready var standing_pos: Vector2 = position + $StandingPos.position

@export var intro_drama_display: BubbleDramaDisplay
@export var look_left = false


func display_trigger():
	intro_drama_display.showing = true
	intro_drama_display.display("E", "", false)
	intro_drama_display.next.hide()


func hide_trigger():
	intro_drama_display.showing = false


func play_drama():
	await super.play_drama()
	display_trigger()
