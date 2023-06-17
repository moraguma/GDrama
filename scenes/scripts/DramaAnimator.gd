extends Resource
class_name DramaAnimator


var label: RichTextLabel
var to_call: Object
var animation_player: AnimationPlayer

var time_per_char: float = 0.015


func _init(label: RichTextLabel, to_call: Object, animation_player: AnimationPlayer):
	self.label = label
	self.to_call = to_call
	self.animation_player = animation_player


# Returns an animation created from the given string
func create_animation(s: String) -> Animation:
	# Text processing 
	var raw_text = s
	var pos = 0
	
	while pos + 1 < len(raw_text):
		if raw_text[pos] == "(" and raw_text[max(pos - 1, 0)] != "\\":
			var new_pos = GDramaTranspiler.advance_until(raw_text, pos, ")")
			
			raw_text = raw_text.substr(0, pos) + raw_text.substr(new_pos + 1)
		pos = GDramaTranspiler.advance_until(raw_text, pos, "(")
	
	# Object setup
	var animation = Animation.new()
	
	var value_idx = animation.add_track(Animation.TYPE_VALUE)
	
	
	var method_idx = animation.add_track(Animation.TYPE_METHOD)
	
	
	animation.track_set_path(value_idx, label.get_path())
	
	return animation


# Sets time_per_char
func speed(time_per_char) -> float:
	self.time_per_char = float(time_per_char)
