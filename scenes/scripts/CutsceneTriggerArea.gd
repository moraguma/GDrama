extends Area2D
class_name CutsceneTriggerArea


@onready var cutscene_trigger: CutsceneTrigger = get_parent()


func get_cutscene_trigger() -> CutsceneTrigger:
	return cutscene_trigger
