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
@onready var drama_reader: DramaReader = DramaReader.new()
var connected_displays: Array = []


# --------------------------------------------------------------------------------------------------
# METHODS
# --------------------------------------------------------------------------------------------------
func load_gdrama(path: String):
	drama_reader.load_gdrama(path)

## Connects the signals emitted by this node to the respective functions in the
## given DramaDisplay
func connect_display(display):
	if not display in connected_displays:
		connected_displays.append(display)
		
		skipped.connect(display._skipped)
		direction_ended.connect(display._direction_ended)
		set_raw_text.connect(display._set_raw_text)
		spoke.connect(display._spoke)
		drama_call.connect(display._drama_call)
		ask_for_choice.connect(display._ask_for_choice)
		set_actor.connect(display._set_actor)
		ended_drama.connect(display._ended_drama)
		
		display.drama_player = self


## Disconnects signal from given DramaDisplay
func disconnect_display(display):
	if display in connected_displays:
		connected_displays.erase(display)
		
		skipped.disconnect(display._skipped)
		direction_ended.disconnect(display._direction_ended)
		set_raw_text.disconnect(display._set_raw_text)
		spoke.disconnect(display._spoke)
		drama_call.disconnect(display._drama_call)
		ask_for_choice.disconnect(display._ask_for_choice)
		set_actor.disconnect(display._set_actor)
		ended_drama.disconnect(display._ended_drama)
		
		display.drama_player = null


## Disconnects all connected DramaDisplays. Can be called at the end of a scene
func disconnect_displays():
	while len(connected_displays) > 0:
		disconnect_display(connected_displays[0])


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