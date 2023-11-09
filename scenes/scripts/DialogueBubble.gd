extends Polygon2D
class_name DialogueBubble


const LOWER_VERTICES = [3, 4, 5, 6, 7, 8, 9, 10, 11]


var base_lower_vertice_pos = []
@onready var base_pos = position


@onready var text: RichTextLabel = $Text


func _ready():
	for i in LOWER_VERTICES:
		base_lower_vertice_pos.append(polygon[i])
	hide()


func display(t: String, start_invisible: bool = true):
	text.text = "[center]" + t
	var height_dif = Vector2(0, text.get_content_height() - text.custom_minimum_size[1])
	
	position = base_pos - height_dif
	for i in range(len(LOWER_VERTICES)):
		polygon[LOWER_VERTICES[i]] = base_lower_vertice_pos[i] - height_dif
	
	if start_invisible:
		text.visible_characters = 0


func appear():
	show()


func disappear():
	hide()


func advance_char():
	text.visible_characters += 1
