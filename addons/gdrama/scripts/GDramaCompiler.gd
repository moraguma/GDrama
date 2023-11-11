extends Resource
class_name GDramaCompiler


const CALL_ESCAPABLES: Array[String] = ["\"", "\'", "<", ">"]
const STRING_ESCAPABLES: Array[String]= ["\"", "\'"]
const CALL_CLOSERS = {"<": ">"}
const STRING_CLOSERS = {"\"": "\"", "\'": "\'"}
var SPACE = PackedByteArray([0])
var TAB = PackedByteArray([0])
var ENTER = PackedByteArray([0])

var consts: Dictionary = {}
var beats: Array = []
var line: int = 0
var column: int = 0
var pos: int = 0
var code: String

var errors: Array = []
var result: GDramaResource = GDramaResource.new()


func _init():
	SPACE.encode_u8(0, 32) # Space
	TAB.encode_u8(0, 13) # Carriage return
	ENTER.encode_u8(0, 10) # Line feed


# ------------------------------------------------------------------------------
# PARSING
# ------------------------------------------------------------------------------


func compile(path: String):
	code = FileAccess.open(path, FileAccess.READ).get_as_text()
	read_beats()
	pass


## Fills the beats array with all beats present in code
func read_beats() -> void:
	go_to_start()
	while pos < len(code):
		if is_character_in_pos("<"):
			var call = parse_call()
			if call[0] == "beat":
				check_arg_count(call, 1)
				beats.append(call[1])
		advance_until("<")


## Parses a string starting in pos. Returns the full string
func parse_string() -> String:
	assert(is_any_character_in_pos(STRING_CLOSERS.keys()), "Called parse_string outside string start")
	var closer = STRING_CLOSERS[code[pos]]
	
	advance_pos()
	var start_pos = pos
	
	while not is_character_in_pos(closer):
		add_error(code[pos].to_utf8_buffer() == ENTER, "Unterminated string")
		advance_pos()
	
	var result = remove_escapes(code.substr(start_pos, pos - start_pos), ["\"", "\'"])
	advance_pos()
	return result


## Parses a call String of the form "func arg1 arg2..." into an array R of
## strings such that R[0] = func and R[1:] = [arg1, arg2, ...]. Note that an
## arg can also be a call enveloped by {}; in that case, that args will also 
## be a string
func parse_call(subcalled: bool = false) -> Array:
	assert(code[pos] in CALL_CLOSERS, "Called parse_call outside call start")
	var closer = CALL_CLOSERS[code[pos]]
	
	advance_pos()
	var element_pos = pos
	var result = []
	var append_and_advance = func(to_append): # Adds to result
		result.append(to_append)
		advance_empty_spaces()
		return pos
	
	# While call isn't over
	while not is_character_in_pos(closer):
		var old_element_pos = element_pos
		add_error(code[pos].to_utf8_buffer() == ENTER, "Command missing closer \"" + closer + "\"")
		
		# Check for subcall
		if is_character_in_pos("<"):
			if element_pos < pos:
				element_pos = append_and_advance.call(remove_escapes(code.substr(element_pos, pos - element_pos), CALL_ESCAPABLES))
			
			if subcalled:
				add_error(true, "Subcall found within a subcall")
				return result
			else:
				element_pos = append_and_advance.call(parse_call(true))
		
		# Check for string
		if is_any_character_in_pos(STRING_CLOSERS.keys()):
			if element_pos < pos:
				element_pos = append_and_advance.call(remove_escapes(code.substr(element_pos, pos - element_pos), STRING_ESCAPABLES))
			element_pos = append_and_advance.call(parse_string())
		
		# Check for end of arg
		if is_empty_space():
			element_pos = append_and_advance.call(remove_escapes(code.substr(element_pos, pos - element_pos), CALL_ESCAPABLES))
		
		# Advance if nothing happened
		if element_pos == old_element_pos:
			advance_pos()
	
	if element_pos < pos:
		element_pos = append_and_advance.call(remove_escapes(code.substr(element_pos, pos - element_pos), CALL_ESCAPABLES))
	
	advance_pos()
	return result


## Sets pos, column and pos to start of file
func go_to_start():
	line = 0
	column = 0
	pos = 0


func is_empty_space() -> bool:
	return code[pos].to_utf8_buffer() in [SPACE, TAB, ENTER]


## Advances empty spaces in s starting from pos until pos is at a non-empty
## character
func advance_empty_spaces() -> void:
	if pos >= len(code):
		return
	
	while is_empty_space():
		advance_pos()
		if pos >= len(code):
			break


## Advances pos, column and line
func advance_pos() -> void:
	pos += 1
	column += 1
	if code[pos - 1].to_utf8_buffer() == ENTER:
		line += 1
		column = 0


## Advances spaces until pos is at x
func advance_until(x: String) -> void:
	if pos >= len(code):
		return
	
	while not is_character_in_pos(x):
		advance_pos()
		if pos >= len(code):
			break


func add_error(condition: bool, error: String) -> void:
	if condition:
		errors.append({
			"line_number": line,
			"column_number": column,
			"error": error
		})


## Checks if a specific character is in a position, ignoring it in the case it 
## is escaped
func is_character_in_pos(char: String) -> bool:
	var escape_escaped = false
	if pos - 2 >= 0:
		escape_escaped = code[pos - 2] == "\\"
	return code[pos] == char and code[max(0, pos - 1)] != "\\" or escape_escaped


## If one of the characters is in the specified position, returns that character.
## Otherwise, returns false. Ignores escaped characters
func is_any_character_in_pos(chars: Array):
	var escape_escaped = false
	if pos - 2 >= 0:
		escape_escaped = code[pos - 2] == "\\"
	
	for char in chars:
		if code[pos] == char and code[max(0, pos - 1)] != "\\" or escape_escaped:
			return char
	return false


# If the argument array passed contains a different number of arguments than
# expected, pushes an error message
func check_arg_count(l: Array, total_args: int):
	add_error(len(l) - 1 != total_args, str(total_args) + " arguments expected in " + l[0] + " function. " + str(len(l) - 1) + "provided")


## Removes escape characters from string as long as they are escaping a character
## given in escapables
static func remove_escapes(s: String, escapables: Array[String]) -> String:
	var pos = 0
	while pos < len(s):
		var escaping = false
		if pos + 1 < len(s):
			escaping = s[pos + 1] in escapables
		
		var escape_escaped = false
		if pos - 2 >= 0:
			escape_escaped = s[pos - 2] == "\\"
		var in_pos = s[pos] == "\\" and s[max(0, pos - 1)] != "\\" or escape_escaped
		
		if in_pos and escaping:
			s = remove_from_string(s, pos)
		else:
			pos += 1
	return s


# Returns the string s with the character at the given position removed
static func remove_from_string(s: String, pos: int) -> String:
	return s.substr(0, pos) + s.substr(pos + 1)


## Given a GDrama code, returns its resulting JSON dictionary
"""
func get_json(code: String) -> Dictionary:
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


# ------------------------------------------------------------------------------
# STRING UTILS
# ------------------------------------------------------------------------------


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
"""
