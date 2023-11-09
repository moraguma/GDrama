@icon("res://addons/gdrama/icons/DramaPlayer.png")
@tool
extends DramaAnimator
class_name DramaPlayer


# --------------------------------------------------------------------------------------------------
# SIGNALS
# --------------------------------------------------------------------------------------------------
## Asks for a choice, which should be given by calling the make_choice() method.
## Line will be of the form 
##
## {
## "type": "CHOICE", 
## "choices": ["Choice 1 text", "Choice 2 text", ...],
## "results": ["Choice 1 result", "Choice 2 result", ...],
## "conditions": [true, false, ...]
## }
signal ask_for_choice(line: Dictionary)

## Signals that the given actor is currently speaking
signal set_actor(actor: String)

## Signals that the drama has reached its end
signal ended_drama(info: String)

# --------------------------------------------------------------------------------------------------
# VARIABLES
# --------------------------------------------------------------------------------------------------
## Path of the GDrama that should be loaded
@export var gdrama_path: String:
	set(value):
		gdrama_path = value
		update_configuration_warnings()


@onready var drama_reader: DramaReader = DramaReader.new()


# --------------------------------------------------------------------------------------------------
# BUILT-INS
# --------------------------------------------------------------------------------------------------
func _get_configuration_warnings():
	if gdrama_path == "":
		return ["GDrama file not set"]
	elif not FileAccess.file_exists(gdrama_path):
		return ["Unable to locate GDrama at " + gdrama_path]
	return []


func _ready():
	drama_reader.load_gdrama(gdrama_path)


# --------------------------------------------------------------------------------------------------
# METHODS
# --------------------------------------------------------------------------------------------------

## Should be called when the drama is supposed to start playing
func start_drama():
	drama_reader.reset_drama()
	
	next_line()


## If dialogue is currently playing, skips it. Otherwise, goes to the next line
func next_or_skip():
	if is_typing:
		skip_animation()
	else:
		next_line()


## Goes to the next line of the dialogue
func next_line():
	var line = drama_reader.next_line()
	match line["type"]:
		"CHOICE":
			ask_for_choice.emit(line)
		"END":
			ended_drama.emit(line["info"])
		"DIRECTION":
			set_actor.emit(line["actor"])
			animate(line["direction"])


## Makes a choice. Should only be called after an ask_for_choice signal and
## before calling next_line again
func make_choice(choice: int):
	drama_reader.make_choice(choice)
	next_line()
