extends Object
class_name DramaReader

var drama = {}
var pointer
var to_call


func _init(to_call: Object = self):
	self.to_call = to_call


# Loads and parses a .drama file. If successful, the drama and pointer variables
# are updated 
func load_drama(path: String) -> void:
	pass


# Loads a .json file obtained from parsing a .drama file. If successful, the
# drama and pointer variables are updated
func load_json(path: String) -> void:
	pass


# Saves the loaded drama file as a json in the specified path
func save_json(path: String) -> void:
	pass


# Returns the next line and advances the pointer by one. The return is given in
# the format
#
# {
# 	"type": String -> Can be either DIRECTION or CHOICE
# 	"content": String or Array[String] -> Direction string or array of choice 
# 	strings, depending on the type
# }
func next_line() -> Dictionary:
	return {}
