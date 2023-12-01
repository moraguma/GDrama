extends Node2D
class_name Game


const UNCHOSEN_COLOR = "#9c9c9c"


var logs_visible = false
var logs_active = false
var current_drama_reader: DramaReader


@onready var logs_button = $Player/Camera2D/LogsButton
@onready var logs = $Player/Camera2D/Logs
@onready var logs_container = $Player/Camera2D/Logs/LogScroll/LogContainer


func _physics_process(delta):
	if logs_active and Input.is_action_just_pressed("logs"):
		if logs_visible:
			logs.hide()
		else:
			logs.show()
		logs_visible = not logs_visible


func connect_logs(drama_reader: DramaReader):
	logs_active = true
	current_drama_reader = drama_reader
	
	drama_reader.added_to_log.connect(add_log)
	logs_button.show()


func add_log(log):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	match log.type:
		GDramaResource.DIRECTION:
			if log["actor"] != "You":
				label.text = log["actor"] + ": "
			label.text += log["specification"]
		GDramaResource.CHOICE:
			for i in len(log["choices"]):
				if log["conditions"][i]:
					if log["selection"] == i:
						label.text += log["choices"][i] + "\n"
					else:
						label.text += "[color=" + UNCHOSEN_COLOR + "]" + log["choices"][i] + "[/color]\n"
		GDramaResource.END:
			label.text = "[center]End of conversation"
			if log["info"] != "":
				label.text += " - " + log["info"]
	
	logs_container.add_child(label)


func reset_logs():
	current_drama_reader.added_to_log.disconnect(add_log)
	
	for log in logs_container.get_children():
		log.queue_free()
	
	logs_button.hide()
	logs.hide()
	
	logs_active = false
	logs_visible = false
