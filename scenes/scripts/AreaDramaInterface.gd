extends DramaInterface2D
class_name AreaDramaInterface


@export var intro_drama_display: BubbleDramaDisplay


func _physics_process(delta):
	if Input.is_action_just_pressed("talk") and playing:
		drama_player.next_or_skip()


func display_trigger():
	intro_drama_display.appear()
	intro_drama_display.display("E", "", false)


func hide_trigger():
	intro_drama_display.disappear()
