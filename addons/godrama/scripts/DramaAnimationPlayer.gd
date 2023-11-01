extends AnimationPlayer
class_name DramaAnimationPlayer


var drama_animator: DramaAnimator
var label: RichTextLabel


# Creates and plays an animation based on the drama string provided
func play_drama(drama: String) -> String:
	if is_playing():
		advance(current_animation_length - current_animation_position)
	
	if drama_animator == null:
		update_drama_animator()
	
	var anim = drama_animator.create_drama_animation(drama)
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("drama", anim)
	
	if has_animation_library("DRAMA"):
		remove_animation_library("DRAMA")
	add_animation_library("DRAMA", anim_library)
	play("DRAMA/drama")
	
	return anim.raw_text


# Updates the drama animator used to generate animations. If no label has been
# provided, a dummy label will be used
func update_drama_animator():
	drama_animator = DramaAnimator.new(self, label if label != null else RichTextLabel.new(), self)
