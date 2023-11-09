extends Node2D
class_name ExampleDramaDisplayInterface


@onready var drama_display: ExampleDramaDisplay = $DramaDisplay


func get_drama_display() -> ExampleDramaDisplay:
	return drama_display
