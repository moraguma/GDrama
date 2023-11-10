extends DramaDisplay2D
class_name BubbleDramaDisplay


const LOWER_VERTICES = [3, 4, 5, 6, 7, 8, 9, 10, 11]
const LINE_SIZE = 54


@export var actor_name: String


var active = false
var base_lower_vertice_pos = []


@onready var base_pos = position
@onready var bubble: Polygon2D = $Bubble
@onready var text: RichTextLabel = $Text
@onready var actor: RichTextLabel = $Actor
@onready var next: Polygon2D = $Next
@onready var next_base_pos = next.position


func _ready():
	for i in LOWER_VERTICES:
		base_lower_vertice_pos.append(bubble.polygon[i])
	hide()


# --------------------------------------------------------------------------------------------------
# INHERITABLES
# --------------------------------------------------------------------------------------------------
## Will be called when the dialogue has been skipped. It can be used, for
## instance, for drawing all letters of the dialogue
func _skipped():
	advance_all_chars()


## Will be called when the current direction ends. It can be used, for instance,
## to add a visual indicator that the dialogue can be skipped
func _direction_ended():
	show_next()

## Will be called to signal that the given text should be displayed in the main
## label. Can, for instance, set this text to a RichTextLabel and update its
## visible_characters property to 0
func _set_raw_text(raw_text: String):
	if active:
		display(raw_text, actor_name)

## Will be called to signal that the given letter has been displayed. Can, for
## instance, add one to the visible_characters property of the RichTextLabel 
## that's displaying the main text and play a randomized sound
func _spoke(letter: String):
	advance_char()

## Will be emited when the GDrama calls for a function. Can be used to implement
## specific functions, such as changing a character's mood
func _drama_call(func_name: String, args: Array):
	pass

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
	pass

## Will be called to signal the current actor. Can be used, for instance, to
## display that actor's name and sprite
##
## Note that this is called before any functions related to text display, such
## as _set_raw_text and _spoke, so it may be used to determine which display
## to focus on out of many
func _set_actor(actor: String):
	var old_active = active
	active = actor == actor_name
	
	if active and not old_active: # Just activated
		appear()
	elif not active and old_active: # Just deactivated
		disappear()
	
	hide_next()

## Will be called to signal that the current scene has ended. Can be used, for
## instance, to close the current dialogue windows and free the player's
## movement
func _ended_drama(info: String):
	active = false
	disappear()


# --------------------------------------------------------------------------------------------------
# METHODS
# --------------------------------------------------------------------------------------------------
func display(t: String, actor_name: String = "", start_invisible: bool = true):
	text.text = "[center]" + t
	var height_dif = Vector2(0, text.theme.get_default_font().get_multiline_string_size(erase_bbcode(t), HORIZONTAL_ALIGNMENT_CENTER, text.size[0], text.theme.get_default_font_size())[1] - text.custom_minimum_size[1])
	
	position = base_pos - height_dif
	next.position = next_base_pos + height_dif
	for i in range(len(LOWER_VERTICES)):
		bubble.polygon[LOWER_VERTICES[i]] = base_lower_vertice_pos[i] + height_dif
	
	actor.text = "[center]" + actor_name
	
	if start_invisible:
		text.visible_characters = 0


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


func calculate_total_lines(dir: String):
	var font: Font = text.theme.get_default_font()


func appear():
	show()


func disappear():
	hide()


func show_next():
	next.show()


func hide_next():
	next.hide()


func advance_char():
	text.visible_characters += 1


func advance_all_chars():
	text.visible_ratio = 1.0
