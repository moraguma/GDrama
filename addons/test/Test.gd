extends CodeEdit


func _ready():
	var t = GDramaParser.new()
	t.compile("res://resources/dramas/example.gdrama")
