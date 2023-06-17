extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	#var p = PackedByteArray([0])
	#p.encode_u8(0, 0x22)
	#print("!".to_utf8_buffer() == p)
	
	var e = FileAccess.open("res://resources/empties.gdrama", FileAccess.READ).get_as_text()
	var pos = 0
	while pos < len(e):
		var i = -1
		var p = PackedByteArray([0])
		var s = e[pos].to_utf8_buffer()
		while s != p:
			i += 1
			p.encode_u8(0, i)
		print("Char at pos " + str(pos) + " is equal to " + str(i))
		pos += 1
	
	var drama_reader = DramaReader.new()
	
	drama_reader.load_json("res://resources/example.json")
	
	var line = drama_reader.next_line()
	while line["type"] != "END":
		if line["type"] == "CHOICE":
			drama_reader.make_choice(0)
		line = drama_reader.next_line()
	
	var f = FileAccess.open("res://resources/example.gdrama", FileAccess.READ).get_as_text()
	print(f)
	var r = GDramaTranspiler.getJSON(f)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
