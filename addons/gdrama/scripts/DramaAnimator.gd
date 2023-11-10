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


# Animates the given string. Uses the label to display text if it's available
func animate(s: String):
	is_typing = true
	
	# Generates steps as a list of texts and calls
	var steps = []
	var raw_text = s
	var pos = 0
	
	while pos < len(raw_text):
		if raw_text[pos] == "(" and raw_text[max(pos - 1, 0)] != "\\":
			var call = GDramaTranspiler.parse_call(raw_text, pos)
			steps.append({"type": "CALL", "call": call})
			
			if len(steps) >= 2: # Removes empty text if present
				if steps[-2]["type"] == "TEXT":
					if steps[-2]["size"] == 0:
						steps.remove_at(len(steps) - 2)
			
			raw_text = raw_text.substr(0, pos) + raw_text.substr(GDramaTranspiler.advance_until(raw_text, pos, ")") + 1)
		
		var new_pos = GDramaTranspiler.advance_until(raw_text, pos, "(")
		steps.append({"type": "TEXT", "size": new_pos - pos})
		pos = new_pos
	
	set_raw_text.emit(raw_text)
	
	# Animates calls and texts
	var total_pos = 0
	var step_pos = 0
	var current_step = 0
	while current_step < len(steps):
		match steps[current_step]["type"]:
			"CALL":
				var method_name = steps[current_step]["call"][0]
				var args = steps[current_step]["call"].slice(1)
				
				drama_call.emit(method_name, args)
				if has_method(method_name):
					if is_typing:
						await callv(method_name, args)
					else:
						callv(method_name, args)
			"TEXT":
				if is_typing:
					var text_pos = 0
					while text_pos < steps[current_step]["size"]:
						spoke.emit(raw_text[total_pos])
						
						if time_per_char > 0:
							text_timer.start(time_per_char)
							await text_timer.timeout
							if not is_typing:
								break
						
						text_pos += 1
						total_pos += 1
		current_step += 1
	
	is_typing = false
	direction_ended.emit()


func skip_animation():
	if is_typing:
		skipped.emit()
		is_typing = false
		
		text_timer.timeout.emit()
		text_timer.stop()

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
