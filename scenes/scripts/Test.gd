extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var drama_reader = DramaReader.new()
	#var x = TokeTy
	var t = drama_reader.parse_call("<jump \"arg1\" {arg 2}>", 0)
	
	var a = [1, 2, 3]
	t = a[-1]
	
	drama_reader.load_json("res://resources/example.json")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
