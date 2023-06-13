class_name Token
var lexeme: String
var line: int
var type: int
var literal

func _init(lexeme: String, line: int, type: int, literal):
	self.lexeme = lexeme
	self.line = line
	self.type = type
	self.literal = literal
	
