extends Node
class_name DramaAnimator


# --------------------------------------------------------------------------------------------------
# SIGNALS
# --------------------------------------------------------------------------------------------------

## Emitted when dialogue finishes
signal direction_ended

## Emitted when dialogue is skipped
signal skipped

## Emits the raw text of a direction when it has been processed
signal set_raw_text(raw_text: String)

## Emitted when a letter is meant to have been turned visible
signal spoke(letter: String)

## Emitted when a drama call is made, regardless of whether or not it has been
## handled by this node
signal drama_call(method_name: String, args: Array)


# --------------------------------------------------------------------------------------------------
# VARIABLES
# --------------------------------------------------------------------------------------------------
var is_typing = false
var time_per_char: float = 0.015

# ------------------------------------------------------------------------------
# NODES
# ------------------------------------------------------------------------------
var text_timer: Timer


func _ready():
	text_timer = Timer.new()
	add_child(text_timer)


## Animates the given direction. Returns true if any text was processed or false
## otherwise
func animate(steps: Array):
	is_typing = true
	
	# Define raw_text
	var raw_text = ""
	for step in steps:
		if not step is Array:
			raw_text += step
	set_raw_text.emit(raw_text)
	
	# Animation
	var text_processed = false
	for step in steps:
		if step is Array: # Call processing
			var method_name = step[0]
			var args = step.slice(1)
			
			drama_call.emit(method_name, args)
			if has_method(method_name):
				if is_typing:
					await callv(method_name, args)
				else:
					callv(method_name, args)
		elif is_typing: # Text processing
			text_processed = true
			
			step = remove_bbcode(step)
			var pos = 0
			while pos < len(step):
				# Ignore bbcode
				pos = advance_bbcode(step, pos)
				if pos >= len(step):
					break
				
				# Wait for time_per_char
				spoke.emit(step[pos])
				if time_per_char > 0:
					text_timer.start(time_per_char)
					await text_timer.timeout
					if not is_typing:
						break
				
				pos += 1
	
	is_typing = false
	direction_ended.emit()
	return text_processed


func skip_animation():
	if is_typing:
		skipped.emit()
		is_typing = false
		
		text_timer.timeout.emit()
		text_timer.stop()


## Returns the given string with bbcode removed
func remove_bbcode(s: String):
	var pos = 0
	while pos < len(s):
		if is_character_in_pos(s, pos, "["):
			var start_pos = pos
			while not is_character_in_pos(s, pos, "]"):
				pos += 1
				if pos >= len(s):
					break
			if is_character_in_pos(s, pos, "]"):
				s = s.substr(0, start_pos) + s.substr(pos + 1)
		pos += 1
	return s

func advance_bbcode(s: String, pos: int):
	if is_character_in_pos(s, pos, "["):
		while not is_character_in_pos(s, pos, "]"):
			pos += 1
			if pos >= len(s):
				break
	return pos


func is_character_in_pos(s: String, pos: int, char: String):
	if pos >= len(s):
		return false
	
	var escape_escaped = false
	if pos - 2 >= 0:
		escape_escaped = s[pos - 2] == "\\"
	return s[pos] == char and (s[max(0, pos - 1)] != "\\" or escape_escaped)
# ------------------------------------------------------------------------------
# GDRAMA METHODS
# ------------------------------------------------------------------------------

# Sets time_per_char. Effectively, changes the talking speed
func speed(time: String) -> void:
	time_per_char = float(time)


# Creates a pause in the animation
func wait(time: String) -> void:
	if is_typing:
		text_timer.start(float(time))
		await text_timer.timeout
