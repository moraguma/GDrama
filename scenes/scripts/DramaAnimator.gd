extends Resource
class_name DramaAnimator


var animation_player: AnimationPlayer
var label: RichTextLabel
var to_call: Object


func _init(animation_player: AnimationPlayer, label: RichTextLabel, to_call: Object):
	self.animation_player = animation_player
	self.label = label
	self.to_call = to_call


# Returns a DramaAnimation created from the given string
func create_drama_animation(s: String) -> DramaAnimation:
	# Text processing 
	#var raw_text = s
	#var pos = 0
	
	#while pos + 1 < len(raw_text):
	#	if raw_text[pos] == "(" and raw_text[max(pos - 1, 0)] != "\\":
	#		var new_pos = GDramaTranspiler.advance_until(raw_text, pos, ")")
	#		
	#		raw_text = raw_text.substr(0, pos) + raw_text.substr(new_pos + 1)
	#	pos = GDramaTranspiler.advance_until(raw_text, pos, "(")
	
	# Animation
	var drama_animation = get_new_drama_animation()
	
	var pos = 0
	var text_pos = 0
	
	var raw_text = s
	
	while pos < len(s):
		var old_pos = pos
		pos = GDramaTranspiler.advance_until(s, pos, "(")
		text_pos += pos - old_pos - 1
		
		drama_animation.add_text_keyframe(text_pos)
		
		if s[min(len(s) - 1, pos)] == "(" and s[max(0, pos - 1)] != "\\":
			var call = GDramaTranspiler.parse_call(s, pos)
			var new_pos = GDramaTranspiler.advance_until(s, pos, ")")
			
			raw_text = raw_text.substr(0, text_pos) + s.substr(new_pos + 1)
			
			drama_animation.add_method_keyframe(call)
			
			pos = new_pos + 1
	
	drama_animation.raw_text = raw_text
	
	assign_paths(drama_animation)
	
	return drama_animation


# Assigns paths to the provided DramaAnimation according to the label, to_call
# and animation_player nodes
func assign_paths(drama_animation: DramaAnimation) -> void:
	var value_path = ""
	var method_path = ""
	if animation_player != null:
		if label != null:
			value_path = str(animation_player.get_path_to(label)) + ":visible_characters"
		if to_call != null:
			method_path = str(animation_player.get_path_to(to_call))
	
	drama_animation.assign_paths(value_path, method_path)


# Returns a new DramaAnimation object. Can be overwritten in extended functions
# to return an object that inherits from DramaAnimation
func get_new_drama_animation() -> DramaAnimation:
	return DramaAnimation.new()
