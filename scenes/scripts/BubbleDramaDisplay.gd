extends DramaDisplay2D
class_name BubbleDramaDisplay


const LOWER_VERTICES = [3, 4, 5, 6, 7, 8, 9, 10, 11]
const LINE_SIZE = 54
const SCALING_WEIGHT = 0.15


@export var actor_name: String


var showing = false
var active = false
var base_lower_vertice_pos = []
var current_choice_values
var current_choice_data
var current_choice


@onready var base_pos = position
@onready var bubble: Polygon2D = $Bubble
@onready var text: RichTextLabel = $Text
@onready var actor: RichTextLabel = $Actor

@onready var next: Polygon2D = $Next
@onready var next_base_pos = next.position

@onready var left: Polygon2D = $Left
@onready var left_base_pos = left.position
@onready var right: Polygon2D = $Right
@onready var right_base_pos = right.position


func _ready():
	scale = Vector2(1, 0)
	
	for i in LOWER_VERTICES:
		base_lower_vertice_pos.append(bubble.polygon[i])


func _process(delta):
	scale = lerp(scale, Vector2(1, 1 if showing else 0), SCALING_WEIGHT)


func _physics_process(delta):
	if active:
		if current_choice_data != null:
			if Input.is_action_just_pressed("left") and current_choice > 0:
				current_choice -= 1
				display_choice()
				display(current_choice_data[current_choice], "", false)
			elif Input.is_action_just_pressed("right") and current_choice < len(current_choice_data) - 1:
				current_choice += 1
				display_choice()
				display(current_choice_data[current_choice], "", false)
			elif Input.is_action_just_pressed("talk"):
				drama_player.make_choice(current_choice_values[current_choice])
				current_choice_data = null
		elif Input.is_action_just_pressed("talk"):
				drama_player.next_or_skip()


## Finishes typing
func _skipped():
	text.visible_ratio = 1.0


## Displays next icon
func _direction_ended():
	next.show()


## Displays text if is current actor
func _set_raw_text(raw_text: String):
	if active:
		display(raw_text, actor_name if actor_name != "You" else "")


## Advance letter if char done
func _spoke(letter: String):
	if active:
		text.visible_characters += 1


## Will be emited when the GDrama expects a choice to be made. Should display
## the available options to the player and, once one has been chosen, pass that
## choice to the DramaPlayer through the make_choice() method
##
## Line will be of the form 
## {
## "type": "CHOICE", 
## "choices": ["Choice 1 text", "Choice 2 text", ...],
## "results": ["Choice 1 result", "Choice 2 result", ...],
## "conditions": [true, false, ...]
## }
func _ask_for_choice(line: Dictionary):
	if actor_name == "You":
		activate()
		
		current_choice_data = []
		current_choice_values = []
		for i in range(len(line["choices"])):
			if line["conditions"][i]:
				current_choice_data.append(line["choices"][i])
				current_choice_values.append(i)
		
		if len(current_choice_data) == 0:
			push_error("No choices available")
		current_choice = 0
		display_choice()
	else:
		deactivate()

## Sets active if is actor
func _set_actor(actor: String):
	if actor == actor_name:
		activate()
	else:
		deactivate()
	
	next.hide()

## Deactivates regardless of state once drama has ended
func _ended_drama(info: String):
	deactivate()


# --------------------------------------------------------------------------------------------------
# METHODS
# --------------------------------------------------------------------------------------------------
func activate():
	active = true
	showing = true


func deactivate():
	active = false
	showing = false


func display_choice():
	update_choice_handles()
	display(current_choice_data[current_choice], "", false)
	next.hide()


func display(t: String, actor_name: String = "", start_invisible: bool = true):
	text.text = "[center]" + t
	var height_dif = Vector2(0, text.theme.get_default_font().get_multiline_string_size(erase_bbcode(t), HORIZONTAL_ALIGNMENT_CENTER, text.size[0], text.theme.get_default_font_size())[1] - text.custom_minimum_size[1])
	
	position = base_pos - height_dif
	next.position = next_base_pos + height_dif
	left.position = left_base_pos + height_dif / 2
	right.position = right_base_pos + height_dif / 2
	for i in range(len(LOWER_VERTICES)):
		bubble.polygon[LOWER_VERTICES[i]] = base_lower_vertice_pos[i] + height_dif
	
	actor.text = "[center]" + actor_name
	
	if start_invisible:
		text.visible_characters = 0


func update_choice_handles():
	if current_choice_data != null:
		if current_choice == 0:
			left.hide()
		else:
			left.show()
		
		if current_choice == len(current_choice_data) - 1:
			right.hide()
		else: 
			right.show()
	else:
		left.hide()
		right.hide()


func erase_bbcode(t: String):
	var pos = 0
	while pos < len(t):
		if t[pos] == "[":
			var end_pos = pos + 1
			while t[end_pos] != "]":
				end_pos += 1
			t = t.substr(0, pos) + t.substr(end_pos + 1)
		else:
			pos += 1
	return t
