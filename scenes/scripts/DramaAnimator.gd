extends Resource
class_name DramaAnimator


var animation_player: AnimationPlayer
var label: RichTextLabel
var to_call: Object

var time_per_char = 0.015


func _init(animation_player: AnimationPlayer, label: RichTextLabel = null, to_call: Object = self):
	self.animation_player = animation_player
	self.label = label
	self.to_call = to_call


# Returns an animation created from the given string
func create_animation(s: String) -> Animation:
	# Text processing 
	
	# Object setup
	var animation = Animation.new()
	
	if label != null:
		var value_idx = animation.add_track(Animation.TYPE_VALUE)
	
	var method_idx = animation.add_track(Animation.TYPE_METHOD)
	
	
	animation.track_set_path(value_idx, label.get_path())
	
	return animation
