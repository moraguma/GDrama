@icon("res://addons/gdrama/icons/DramaDisplay.png")
@tool
extends Node
class_name DramaDisplay


# --------------------------------------------------------------------------------------------------
# VARIABLES
# --------------------------------------------------------------------------------------------------
## The DramaPlayer that this node should animate
@export var drama_player: DramaPlayer:
	set(value):
		drama_player = value
		update_configuration_warnings()


# --------------------------------------------------------------------------------------------------
# BUILT-INS
# --------------------------------------------------------------------------------------------------
func _get_configuration_warnings():
	if drama_player == null:
		return ["DramaPlayer not set"]
	return []


func _ready():
	drama_player.direction_ended.connect(_direction_ended)
	drama_player.set_raw_text.connect(_set_raw_text)
	drama_player.spoke.connect(_spoke)
	drama_player.drama_call.connect(_drama_call)
	drama_player.ask_for_choice.connect(_ask_for_choice)
	drama_player.set_actor.connect(_set_actor)
	drama_player.ended_drama.connect(_ended_drama)


# --------------------------------------------------------------------------------------------------
# INHERITABLES
# --------------------------------------------------------------------------------------------------
## Will be called when the current direction ends. It can be used, for instance,
## to add a visual indicator that the dialogue can be skipped
func _direction_ended():
	pass

## Will be called to signal that the given text should be displayed in the main
## label. Can, for instance, set this text to a RichTextLabel and update its
## visible_characters property to 0
func _set_raw_text(raw_text: String):
	pass

## Will be called to signal that the given letter has been displayed. Can, for
## instance, add one to the visible_characters property of the RichTextLabel 
## that's displaying the main text and play a randomized sound
func _spoke(letter: String):
	pass

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
func _set_actor(actor: String):
	pass

## Will be called to signal that the current scene has ended. Can be used, for
## instance, to close the current dialogue windows and free the player's
## movement
func _ended_drama(info: String):
	pass
