extends Polygon2D
class_name DialogueBubble


const LOWER_VERTICES = [3, 4, 5, 6, 7, 8, 9, 10, 11]
const LINE_SIZE = 54


var base_lower_vertice_pos = []
@onready var base_pos = position


@onready var text: RichTextLabel = $Text
@onready var actor: RichTextLabel = $Actor
@onready var next: Polygon2D = $Next
@onready var next_base_pos = next.position


func _ready():
	for i in LOWER_VERTICES:
		base_lower_vertice_pos.append(polygon[i])
	hide()


func display(t: String, actor_name: String = "", start_invisible: bool = true):
	text.text = "[center]" + t
	var height_dif = Vector2(0, text.get_line_count() * LINE_SIZE - text.custom_minimum_size[1])
	
	position = base_pos - height_dif
	next.position = next_base_pos + height_dif
	for i in range(len(LOWER_VERTICES)):
		polygon[LOWER_VERTICES[i]] = base_lower_vertice_pos[i] + height_dif
	
	actor.text = "[center]" + actor_name
	
	if start_invisible:
		text.visible_characters = 0


func appear():
	show()


func disappear():
	hide()


func show_next():
	next.show()


func hide_next():
	next.hide()


func advance_char():
	text.visible_characters += 1


func advance_all_chars():
	text.visible_ratio = 1.0
