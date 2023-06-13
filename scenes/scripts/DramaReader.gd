extends Object
class_name DramaReader

const CLOSERS = {"\"": "\"", "{": "}", "<": ">", "\'": "\'"}

var drama: Dictionary
var beat: String
var pointer: String
var to_call: Object

func _init(to_call: Object = self):
	self.to_call = to_call


# Loads and parses a .drama file. If successful, the drama and pointer variables
# are updated 
func load_drama(path: String) -> void:
	pass


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
	pass


# Returns true if the drama is loaded. If it's not, returns false and pushes an
# error message
func check_drama() -> bool:
	if drama != null:
		return true
	push_error("No drama loaded!")
	return false


func remove_from_string(s: String, pos: int) -> String:
	return s.substr(0, pos) + s.substr(pos + 1)


func advance_empty_spaces(s: String, pos: int) -> int:
	while s[pos] == " ":
		pos += 1
	return pos


# Parses a call String of the form "func arg1 arg2..." into an array R of
# strings such that R[0] = func and R[1:] = [arg1, arg2, ...]
func parse_call(call_string: String, pos: int) -> Array[String]:
	var new_call = String(call_string)
	
	if new_call[pos] in CLOSERS:
		var enveloper = new_call[pos]
		var subenveloper
		var result: Array[String]
		result = []
		
		pos += 1
		var size = 0
		
		while new_call[pos + size] != CLOSERS[enveloper]:
			if new_call[pos + size] == "\\":
				new_call = remove_from_string(new_call, pos + size)
				size += 1
			elif subenveloper != null:
				if new_call[pos + size] == CLOSERS[subenveloper]:
					if subenveloper != "{":
						result.append(new_call.substr(pos, size))
					else: 
						result.append(new_call.substr(pos, size + 1))
					pos = advance_empty_spaces(new_call, pos + size + 1)
					size = 0
					subenveloper = null
				else:
					size += 1
			elif new_call[pos + size] in CLOSERS and size == 0:
				subenveloper = new_call[pos + size]
				if subenveloper != "{":
					pos += 1
			elif new_call[pos + size] == " ":
				result.append(new_call.substr(pos, size))
				pos = advance_empty_spaces(new_call, pos + size + 1)
				size = 0
			else:
				size += 1
		
		if size != 0:
			result.append(new_call.substr(pos, size))
			size = 0
		
		return result
	else:
		push_error("Invalid call \"" + new_call + "\" at position " + str(pos))
	
	return []


# Jumps beat and pointer to the start of the specified beat
func jump(target_beat: String) -> void:
	beat = target_beat
	pointer = "0"


# If the pointer is on a choice, makes the specified choice
func make_choice(choice: int) -> void:
	if check_drama():
		var line = drama[beat]["steps"][pointer]
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
			if not pointer in drama[beat]["steps"]:
				if drama[beat]["next"] == "":
					return {"type": "END", "info": ""}
				jump(drama[beat]["next"])
			
			var line = drama[beat]["steps"][pointer]
			
			match line["type"]:
				"DIRECTION":
					pointer = str(int(pointer) + 1)
					result = line
				"CHOICE":
					result = line
				"END":
					result = line
				"CALL":
					var call = parse_call(line["call"], 0)
					callv(call[0], call.slice(1))
		return result
	return {}
