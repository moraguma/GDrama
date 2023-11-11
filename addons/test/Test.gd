extends Node


func _ready():
	var t = GDramaCompiler.new()
	t.compile("res://resources/dramas/example.gdrama")
