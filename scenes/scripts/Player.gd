extends Character
class_name Player


const FLOATY_GRAVITY_WEIGHT = 0.015


var controllable = true
var cutscene: CutsceneTrigger = null


func _physics_process(delta):
	if controllable:
		_input_process()
	super._physics_process(delta)


func _input_process():
	dir = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"), 0)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity += Vector2(0, -1 * JUMP_SPEED)
	
	if Input.is_action_pressed("jump"):
		effective_gravity = FLOATY_GRAVITY_WEIGHT
	else:
		effective_gravity = GRAVITY_WEIGHT
	
	if Input.is_action_just_pressed("talk") and cutscene != null:
		take_control()
		cutscene.play_cutscene(self)


func take_control():
	controllable = false
	dir = Vector2(0, 0)
	effective_gravity = GRAVITY_WEIGHT


func return_control():
	controllable = true


func enter_cutscene_area(area):
	cutscene = area.get_cutscene_trigger()
	cutscene.display_trigger()


func exit_cutscene_area(area):
	cutscene.hide_trigger()
	cutscene = null
