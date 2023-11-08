extends Node
class_name DramaAnimator


# ------------------------------------------------------------------------------
# SIGNALS
# ------------------------------------------------------------------------------
signal done # Emitted when dialogue finishes naturally
signal spoke # Emitted when a letter is turned visible

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------
var is_typing = false
var time_per_char: float = 0.015

# ------------------------------------------------------------------------------
# NODES
# ------------------------------------------------------------------------------
@export var label: RichTextLabel
var text_timer: Timer
var animation_timer: Timer


func _ready():
	text_timer = Timer.new()
	add_child(text_timer)
	animation_timer = Timer.new()
	add_child(animation_timer)


# Animates the given string. Uses the label to display text if it's available
func animate(s: String):
	is_typing = true
	
	# Generates steps as a list of texts and calls
	var steps = []
	var raw_text = s
	var pos = 0
	
	while pos < len(raw_text):
		if raw_text[pos] == "(" and raw_text[max(pos - 1, 0)] != "\\":
			var call = GoDramaTranspiler.parse_call(raw_text, pos)
			steps.append({"type": "CALL", "call": call})
			
			if len(steps) >= 2: # Removes empty text if present
				if steps[-2]["type"] == "TEXT":
					if steps[-2]["size"] == 0:
						steps.remove_at(len(steps) - 2)
			
			raw_text = raw_text.substr(0, pos) + raw_text.substr(GoDramaTranspiler.advance_until(raw_text, pos, ")") + 1)
		
		var new_pos = GoDramaTranspiler.advance_until(raw_text, pos, "(")
		steps.append({"type": "TEXT", "size": new_pos - pos})
		pos = new_pos
	
	if label != null:
		label.text = raw_text
		label.visible_characters = 0
	
	# Animates calls and texts
	var step_pos = 0
	var current_step = 0
	while current_step < len(steps):
		match steps[current_step]["type"]:
			"CALL":
				await callv(steps[current_step]["call"][0], steps[current_step]["call"].slice(1))
			"TEXT":
				if is_typing:
					var text_pos = 0
					while text_pos < steps[current_step]["size"]:
						if label != null:
							label.visible_characters += 1
						
						text_timer.start(time_per_char)
						await text_timer.timeout
						if not is_typing:
							break
						
						text_pos += 1
		current_step += 1
	
	is_typing = false
	done.emit()

# ------------------------------------------------------------------------------
# GODRAMA METHODS
# ------------------------------------------------------------------------------

# Sets time_per_char. Effectively, changes the talking speed
func speed(time: String) -> void:
	time_per_char = float(time)


# Creates a pause in the animation
func wait(time: String) -> void:
	if is_typing:
		text_timer.start(float(time))
		await text_timer.timeout
