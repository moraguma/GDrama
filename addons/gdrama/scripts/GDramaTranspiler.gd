extends Resource
class_name GDramaTranspiler


const CLOSERS = {"\"": "\"", "{": "}", "<": ">",  "(": ")"}
const EMPTY = [" "]


var consts: Dictionary = {}
var beats: Array = []
var line: int = 0
var column: int = 0

var errors: Array = []


# ------------------------------------------------------------------------------
# PARSING
# ------------------------------------------------------------------------------
## Given a GDrama code, returns its resulting JSON dictionary
static func get_json(code: String) -> Dictionary:
	var result = {"start": null, "beats": {}}
	var consts = {}
	
	var current_beat = null
	var current_step: int = 0
	var pos = advance_empty_spaces(code, 0)
	while pos < len(code):
		if code[pos] == "<":
			var call = parse_call(code, pos)
			match call[0]:
				"const":
					pos = check_and_advance_pos(call, 2, code, pos)
					consts[call[1]] = call[2]
				"import":
					pos = check_and_advance_pos(call, 1, code, pos)
					consts.merge(import_consts(call[1]), true)
				"beat":
					pos = check_and_advance_pos(call, 1, code, pos)
					if current_beat != null:
						result["beats"][current_beat]["next"] = call[1]
					current_beat = call[1]
					result["beats"][current_beat] = {"steps": {}, "next": ""}
					
					if result["start"] == null:
						result["start"] = current_beat
					
					current_step = 0
				"jump":
					pos = check_and_advance_pos(call, 1, code, pos)
					result["beats"][current_beat]["steps"][str(current_step)] = check_and_get_call(call, current_beat)
					current_step += 1
				"flag":
					pos = check_and_advance_pos(call, 1, code, pos)
					result["beats"][current_beat]["steps"][str(current_step)] = check_and_get_call(call, current_beat)
					current_step += 1
				"unflag":
					pos = check_and_advance_pos(call, 1, code, pos)
					result["beats"][current_beat]["steps"][str(current_step)] = check_and_get_call(call, current_beat)
					current_step += 1
				"branch":
					pos = check_and_advance_pos(call, 2, code, pos)
					result["beats"][current_beat]["steps"][str(current_step)] = check_and_get_call(call, current_beat)
					current_step += 1
				"choice":
					check_beat_call(call, current_beat)
					
					var choices = [call]
					pos = advance_until(code, pos, ">") + 1
					pos = advance_empty_spaces(code, pos)
					while code[pos] == "<":
						var new_call = parse_call(code, pos)
						
						if new_call[0] != "choice":
							break
						
						choices.append(new_call)
						pos = advance_until(code, pos, ">") + 1
						pos = advance_empty_spaces(code, pos)
					
					var choice_dict = {"type": "CHOICE", "choices": [], "results": [], "conditions": []}
					
					for choice in choices:
						if len(choice) == 3:
							choice.append("{get_true}")
						check_arg_count(choice, 3)
						
						choice_dict["choices"].append(choice[1])
						choice_dict["results"].append(choice[2])
						choice_dict["conditions"].append(choice[3])
					
					result["beats"][current_beat]["steps"][str(current_step)] = choice_dict
					current_step += 1
				"end":
					if len(call) == 1:
						call.append("")
					
					pos = check_and_advance_pos(call, 1, code, pos)
					check_beat_call(call, current_beat)
					result["beats"][current_beat]["steps"][str(current_step)] = {"type": "END", "info": call[1]}
					current_step += 1
				_:
					push_error("Unrecognized command " + call[0])
					return {}
		else:
			var new_pos = advance_until_enter(code, pos)
			var line = replace_consts(code.substr(pos, new_pos - pos), consts)
			var line_info = get_line_info(line)
			
			check_beat(line, current_beat)
			
			result["beats"][current_beat]["steps"][str(current_step)] = {"type": "DIRECTION", "actor": line_info[0], "direction": line_info[1]}
			current_step += 1
			
			pos = new_pos
		pos = advance_empty_spaces(code, pos)
	return result


## Fills the beats array with all beats present in code
func read_beats(code: String) -> void:
	var pos = 0
	while pos < len(code):
		if is_character_in_pos(code, "<", pos):
			var call = parse_call(code, pos, ["{"])
			if call[0] == "beat":
				check_beat()


## Parses a call String of the form "func arg1 arg2..." into an array R of
## strings such that R[0] = func and R[1:] = [arg1, arg2, ...]. The given 
## joiners are the subcalls we should watch out for (unless they are escaped)
func parse_call(s: String, pos: int, joiners: Array[String]) -> Array[String]:
	var enter = PackedByteArray([0])
	enter.encode_u8(0, 10)
	
	assert(s[pos] in CLOSERS, "Called parse_call outside call start")
	var closer = CLOSERS[s[pos]]
	
	var escapables = joiners.duplicate()
	for joiner in joiners:
		assert(joiner in CLOSERS, "Joiner not in CLOSERS")
		escapables.append(CLOSERS[joiner])
	
	pos += 1
	var element_pos = pos
	var result = []
	
	# While call isn't over
	while not is_character_in_pos(s, ">", pos):
		add_error(s[pos].to_utf8_buffer() == enter, "Command missing closer \">\"")
		var added_element = false 
		
		# Has subcall started
		var joiner = is_any_character_in_pos(s, joiners, pos)
		if joiner != false:
			if element_pos < pos: # Adds previous element if not whitespace
				result.append(remove_escapes(s.substr(element_pos, pos - element_pos), escapables))
				element_pos = pos
			
			pos = advance_until(s, pos, CLOSERS[joiner]) # Closes subcall
			added_element = true
			break
		
		# Finishes regular call if empty space
		if not added_element and is_empty_space(s, pos):
			added_element = true
		
		if added_element: # Adds element to result and advances pos
			result.append(remove_escapes(s.substr(element_pos, pos - element_pos), escapables))
			pos = advance_empty_spaces(s, pos)
			element_pos = pos
		else: # Element still being processed
			pos += 1
			column += 1
	
	return result


## Removes escape characters from string as long as they are escaping a character
## given in escapables
func remove_escapes(s: String, escapables: Array[String]) -> String:
	var pos = 0
	while pos < len(s):
		var escaping = false
		if pos + 1 < len(s):
			escaping = s[pos + 1] in escapables
		if is_character_in_pos(s, "\\", pos) and escaping:
			s = remove_from_string(s, pos)
		else:
			pos += 1
	return s


func add_error(condition: bool, error: String) -> void:
	if condition:
		errors.append({
			"line_number": line,
			"column_number": column,
			"error": error
		})


static func check_and_advance_pos(call: Array, total_args: int, code: String, pos: int) -> int:
	check_arg_count(call, total_args)
	return advance_until(code, pos, ">") + 1


static func check_and_get_call(call: Array, current_beat: String) -> Dictionary:
	check_beat_call(call, current_beat)
	return {"type": "CALL", "call": "{" + call[0] + " " + " ".join(call.slice(1)) + "}"}



## If not currently in beat, pushes error
static func check_beat_call(call: Array, current_beat):
	if current_beat == null:
		push_error("Attempted to make call \"" + " ".join(call) + "\" outside of beat!")


## If not currently in beat, pushes error
static func check_beat(line: String, current_beat):
	if current_beat == null:
		push_error("Attempted to display line \"" + line + "\" outside of beat!")


# Given a path to a GDrama code, returns a dictionary containing its consts
static func import_consts(path: String) -> Dictionary:
	var code = FileAccess.open(path, FileAccess.READ).get_as_text()
	
	var consts = {}
	var pos = 0
	
	while pos < len(code):
		if code[pos] == "\\":
			pos += 1
		elif code[pos] == "<":
			var call = parse_call(code, pos)
			if call[0] == "const":
				check_arg_count(call, 2)
				consts[call[1]] = call[2]
		
		pos += 1
	
	return consts


# --------------------------------------------------------------------------------------------------
# ERRORS
# --------------------------------------------------------------------------------------------------
# If the argument array passed contains a different number of arguments than
# expected, pushes an error message
func check_arg_count(l: Array, total_args: int):
	add_error(len(l) - 1 != total_args, str(total_args) + " arguments expected in " + l[0] + " function. " + str(len(l) - 1) + "provided")


# ------------------------------------------------------------------------------
# STRING UTILS
# ------------------------------------------------------------------------------


## Checks if a specific character is in a position, ignoring it in the case it 
## is escaped
static func is_character_in_pos(s: String, char: String, pos: int) -> bool:
	var escape_escaped = false
	if pos - 2 >= 0:
		escape_escaped = s[pos - 2] == "\\"
	return s[pos] == char and s[max(0, pos - 1)] != "\\" or escape_escaped


## If one of the characters is in the specified position, returns that character.
## Otherwise, returns false. Ignores escaped characters
static func is_any_character_in_pos(s: String, chars: Array[String], pos: int):
	var escape_escaped = false
	if pos - 2 >= 0:
		escape_escaped = s[pos - 2] == "\\"
	
	for char in chars:
		if s[pos] == char and s[max(0, pos - 1)] != "\\" or escape_escaped:
			return char
	return false


# Returns the string s with the character at the given position removed
static func remove_from_string(s: String, pos: int) -> String:
	return s.substr(0, pos) + s.substr(pos + 1)


## Check if space is a space, carriage return or line feed
static func is_empty_space(s: String, pos: int) -> bool:
	var empty = [PackedByteArray([0]), PackedByteArray([0]), PackedByteArray([0])]
	empty[0].encode_u8(0, 32) # Space
	empty[1].encode_u8(0, 13) # Carriage return
	empty[2].encode_u8(0, 10) # Line feed
	
	return s[pos].to_utf8_buffer() in empty


# Advances empty spaces in s starting from pos until pos is at a non-empty
# character
static func advance_empty_spaces(s: String, pos: int) -> int:
	if pos >= len(s):
		return pos
	
	var empty = [PackedByteArray([0]), PackedByteArray([0]), PackedByteArray([0])]
	empty[0].encode_u8(0, 32) # Space
	empty[1].encode_u8(0, 13) # Carriage return
	empty[2].encode_u8(0, 10) # Line feed
	
	while s[pos].to_utf8_buffer() in empty:
		pos += 1
		if pos >= len(s):
			break
	return pos


# Advances spaces in s starting from pos until pos is at x
static func advance_until(s: String, pos: int, x: String) -> int:
	if pos >= len(s):
		return pos
	
	while not is_character_in_pos(s, x, pos):
		pos += 1
		if pos >= len(s):
			break
	return pos


# Advances spaces in s starting from pos until pos is at \n
static func advance_until_enter(s: String, pos: int) -> int:
	if pos >= len(s):
		return pos
	
	var enter = PackedByteArray([0])
	enter.encode_u8(0, 10)
	
	while s[pos].to_utf8_buffer() != enter:
		pos += 1
		if pos >= len(s):
			break
	return pos


# Given a string, returns it with any empty spaces in the borders removed
static func remove_empty_borders(s: String) -> String:
	for pos in [0, -1]:
		while s[pos] in EMPTY:
			s = remove_from_string(s, pos)
	return s


# Given a line, returns an array [actor, line]. If there's no actor, actor is ""
static func get_line_info(s: String) -> Array[String]:
	var pos = 0
	while pos < len(s):
		if s[pos] == ":":
			return [remove_empty_borders(s.substr(0, pos)), remove_empty_borders(s.substr(pos + 1))]
		if s[pos] == "\\" and s[min(len(s) - 1, pos + 1)] == ":":
			s = remove_from_string(s, pos)
		pos += 1
	return ["", remove_empty_borders(s)]


# Given a string and a replacement dict, returns the string with its $values
# replaced by the ones in the dict
static func replace_consts(s: String, consts: Dictionary) -> String:
	var pos = 0
	while pos < len(s):
		if s[pos] == "$":
			var initial_pos = pos
			var stopping_char = " "
			if s[pos + 1] == "\"":
				stopping_char = "\""
				pos += 1
			pos += 1
			
			var new_pos = advance_until(s, pos, stopping_char)
			if new_pos >= len(s):
				new_pos -= 1
			
			var key = s.substr(pos, new_pos - pos)
			var replacement = "UNDEFINED"
			if key in consts:
				replacement = consts[key]
			
			s = s.substr(0, initial_pos) + replacement + s.substr(new_pos if stopping_char == " " else new_pos + 1)
			pos = initial_pos + len(replacement)
		else:
			if s[pos] == "\\" and s[min(pos + 1, len(s) + 1)] in ESCAPABLES:
				s = remove_from_string(s, pos)
			pos += 1
	return s
