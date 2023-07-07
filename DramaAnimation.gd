extends Animation
class_name DramaAnimation


var value_idx: int
var method_idx: int
var raw_text: String


var current_pos = 0
var current_time = 0


var time_per_char: float = 0.015


# ------------------------------------------------------------------------------
# Animation
# ------------------------------------------------------------------------------


func _init():
	value_idx = add_track(Animation.TYPE_VALUE)
	method_idx = add_track(Animation.TYPE_METHOD)
	
	track_insert_key(value_idx, 0, 0)


# Adds a keyframe to the value track so it shows characters up to the specified
# pos in a time according time_per_char
func add_text_keyframe(pos: int) -> void:
	current_time += time_per_char * (pos - current_pos)
	current_pos = pos
	
	track_insert_key(value_idx, current_time, pos)


# Calls a method. If the method is present in this class, call it now,
# otherwise, adds the call to the method track
func add_method_keyframe(call: Array) -> void:
	if has_method(call[0]):
		callv(call[0], call.slice(1))
	else:
		track_insert_key(method_idx, current_time, {"method": call[0], "args": call.slice(1)})


# Assigns the given paths to the value and method tracks
func assign_paths(value_path: NodePath, method_path: NodePath) -> void:
	track_set_path(value_idx, value_path)
	track_set_path(method_idx, method_path)


# ------------------------------------------------------------------------------
# GDrama Commands
# ------------------------------------------------------------------------------


# Sets time_per_char. Effectively, changes the talking speed
func speed(time: String) -> void:
	time_per_char = float(time)


# Adds to the current_time. Effectively, creates a pause in the animation
func wait(time: String) -> void:
	current_time += float(time)
	add_text_keyframe(current_pos)
