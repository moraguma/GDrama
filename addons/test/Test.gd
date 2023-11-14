extends CodeEdit


func _ready():
	var t = GDramaParser.new()
	t.parse("res://resources/dramas/example.gdrama")
