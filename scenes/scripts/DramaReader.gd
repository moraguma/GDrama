extends Resource
class_name DramaReader


var drama: Dictionary
var beat: String
var pointer: String
var to_call: Object


func _init(to_call: Object = self):
	self.to_call = to_call


# ------------------------------------------------------------------------------
# Drama Handling
# ------------------------------------------------------------------------------


# Loads and parses a .drama file. If successful, the drama and pointer variables
# are updated 
func load_gdrama(path: String) -> void:
	drama = GDramaTranspiler.get_json(FileAccess.open(path, FileAccess.READ).get_as_text())
	jump(drama["start"])


# Loads a .json file obtained from parsing a .drama file. If successful, the
# drama and pointer variables are updated
func load_json(path: String) -> void:
	drama = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	if drama == null:
		push_error("Failed to load JSON at " + path)
	else:
		jump(drama["start"])


# Saves the loaded drama file as a json in the specified path
func save_json(path: String) -> void:
	if check_drama():
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(drama))
		file.close()


# Returns true if the drama is loaded. If it's not, returns false and pushes an
# error message
func check_drama() -> bool:
	if drama != null:
		return true
	push_error("No drama loaded!")
	return false


# If the pointer is on a choice, makes the specified choice
func make_choice(choice: int) -> void:
	if check_drama():
		var line = drama["beats"][beat]["steps"][pointer]
		if line["type"] == "CHOICE":
			if choice >= 0 and choice < len(line["results"]):
				jump(line["results"][choice])
			else:
				push_error("Invalid choice " + str(choice) + " at line " + JSON.stringify(line))
		else:
			push_error("Current line" + JSON.stringify(line) + "is not a choice!")


# Returns the next line and advances the pointer by one. The return is given in
# the format
func next_line() -> Dictionary:
	if check_drama():
		var result
		while result == null:
			if not pointer in drama["beats"][beat]["steps"]:
				if drama["beats"][beat]["next"] == "":
					return {"type": "END", "info": ""}
				jump(drama["beats"][beat]["next"])
			
			var line = drama["beats"][beat]["steps"][pointer]
			
			match line["type"]:
				"DIRECTION":
					pointer = str(int(pointer) + 1)
					
					result = replace_commands_in_fields(line, ["actor", "direction"])
					
				"CHOICE":
					result = line
					for i in range(len(result["choices"])):
						result["choices"][i] = replace_commands(result["choices"][i])
						
						var condition = GDramaTranspiler.parse_call(result["conditions"][i], 0)
						result["conditions"][i] = to_call.callv(condition[0], condition.slice(1))
				"END":
					result = line
					result["info"] = replace_commands(result["info"])
				"CALL":
					var call = GDramaTranspiler.parse_call(line["call"], 0)
					to_call.callv(call[0], call.slice(1))
		return result
	return {}


# Returns the string with all DramaReader level commands replaced
func replace_commands(s: String) -> String:
	var pos = 0
	
	while pos + 1 < len(s):
		if s[pos] == "{" and s[max(pos - 1, 0)] != "\\":
			var command = GDramaTranspiler.parse_call(s, pos)
			var new_pos = GDramaTranspiler.advance_until(s, pos, "}")
			
			s = s.substr(0, pos) + to_call.callv(command[0], command.slice(1)) + s.substr(new_pos + 1)
		pos = GDramaTranspiler.advance_until(s, pos, "{")
	
	return s


# Given a dict and a list of fields, replaces commands in all specified fields
func replace_commands_in_fields(d: Dictionary, fields: Array[String]) -> Dictionary:
	for field in fields:
		d[field] = replace_commands(d[field])
	
	return d


# ------------------------------------------------------------------------------
# GDrama Commands
# ------------------------------------------------------------------------------


# Jumps beat and pointer to the start of the specified beat
func jump(target_beat: String) -> void:
	beat = target_beat
	pointer = "0"


# Returns true
func get_true() -> bool:
	return true


func test(x):
	return "Test! " + x
