extends Resource
class_name GDramaParser

# --------------------------------------------------------------------------------------------------
# CONSTANTS
# --------------------------------------------------------------------------------------------------
const REGULAR_COLOR = Color("#cdcfd2")
const KEYWORD_COLOR = Color("#ff7085")
const ACTOR_COLOR = Color("#a3a3f5")
const CALL_COLOR = Color("#ff8ccc")
const CONST_COLOR = Color("#63c259")

const DIRECTION_ESCAPABLES: Array[String] = ["$", ":", "<", ">"]
const CALL_ESCAPABLES: Array[String] = ["\"", "\'", "<", ">", "$"]
const STRING_ESCAPABLES: Array[String]= ["\"", "\'", "$"]
const CALL_CLOSERS = {"<": ">"}
const STRING_CLOSERS = {"\"": "\"", "\'": "\'"}
var SPACE = PackedByteArray([0])
var TAB = PackedByteArray([0])
var ENTER = PackedByteArray([0])
var CHAR_TAB = PackedByteArray([0])

# --------------------------------------------------------------------------------------------------
# VARIABLES
# --------------------------------------------------------------------------------------------------
var line_colors = null
var line_column_modifiers = {}

var line: int = 0
var column: int = 0
var pos: int = 0
var code: String
var current_file: String

var current_beat: String
var consts: Dictionary = {}
var imported: Array[String] = []

var errors: Array[Dictionary] = []
var result: GDramaResource = GDramaResource.new()


func _init():
	SPACE.encode_u8(0, 32) # Space
	TAB.encode_u8(0, 13) # Carriage return
	CHAR_TAB.encode_u8(0, 9) # Character tabulation
	ENTER.encode_u8(0, 10) # Line feed 


# ------------------------------------------------------------------------------
# PARSING
# ------------------------------------------------------------------------------
## Creates a corresponding GDramaResource from the file in the given path. 
## The result of this process can be acessed through get_result
func parse(path: String) -> Error:
	assert(FileAccess.file_exists(path), "Attempted to parse inexistent file")
	
	current_file = path
	code = FileAccess.open(path, FileAccess.READ).get_as_text()
	
	replace_consts()
	read_beats()
	
	go_to_start()
	
	advance_empty_spaces()
	while pos < len(code):
		# Handle call
		var call_handled = false
		if is_character_in_pos("<"):
			var old_values = get_parsing_values()
			call_handled = true
			
			var call = parse_call()
			match call[0]:
				"const": # Already parsed
					pass
				"import": # Already parsed
					pass
				"beat":
					if current_beat != "":
						result.beats[current_beat]["next"] = call[1]
					
					current_beat = call[1]
				"choice":
					if not is_inside_beat("choice"):
						return FAILED
					
					var choice = {"type": GDramaResource.CHOICE, "choices": [], "results": [], "conditions": []}
					while true:
						if len(call) == 3:
							call.append(["get_true"])
						check_arg_count(call, 3)
						choice["choices"].append(call[1])
						choice["results"].append(call[2])
						choice["conditions"].append(call[3])
						
						old_values = get_parsing_values()
						advance_empty_spaces()
						if is_character_in_pos("<"):
							call = parse_call()
							if not call[0] == "choice":
								set_parsing_values(old_values)
								break
						else:
							break
					result.beats[current_beat]["lines"].append(choice)
				"end":
					if not is_inside_beat("end"):
						return FAILED
					
					if len(call) == 1:
						call.append("")
					check_arg_count(call, 2)
					result.beats[current_beat]["lines"].append({"type": GDramaResource.END, "info": call[1]})
				_:
					set_parsing_values(old_values)
					call_handled = false
		
		# Parse direction
		if not call_handled: 
			if not is_inside_beat("direction"):
				return FAILED
			
			var direction = {"type": GDramaResource.DIRECTION, "actor": [], "specification": []}
			var dir = parse_direction()
			if is_character_in_pos(":"): # Actor definition
				direction["actor"] = dir
				advance_pos()
				direction["specification"] = parse_direction(true)
			else:
				direction["specification"] = dir
			result.beats[current_beat]["lines"].append(direction)
		
		advance_empty_spaces()
	return OK


## Fills the beats array with all beats present in code
func read_beats() -> void:
	go_to_start()
	while pos < len(code):
		if is_character_in_pos("<"):
			var call = parse_call()
			if call[0] == "beat":
				check_arg_count(call, 1)
				if result.start == "":
					result.start = call[1]
				result.beats[call[1]] = {"lines": [], "next": ""}
		advance_until("<")


## Replaces consts in current file
func replace_consts() -> void:
	go_to_start()
	while pos < len(code):
		process_const_line()
		if is_character_in_pos("$"):
			var start = pos
			var start_column = column
			var name
			advance_pos()
			
			# Get constant name
			if is_any_character_in_pos(STRING_CLOSERS.keys()): # Is string
				name = parse_string()
			else: # Is name
				var name_start = pos
				while not is_empty_space() and not is_any_character_in_pos(CALL_ESCAPABLES):
					advance_pos()
				
				if pos == name_start:
					add_error("Found empty constant")
				else:
					name = code.substr(name_start, pos - name_start)
			
			# Replace constant
			if not name in consts:
				add_error("Unrecognized constant " + name)
			else:
				code = code.substr(0, start) + consts[name] + code.substr(pos)
				
				if not line in line_column_modifiers: # Create modifier
					line_column_modifiers[line] = {}
				if not column in line_column_modifiers[line]:
					line_column_modifiers[line][start_column + len(consts[name])] = 0
				line_column_modifiers[line][start_column + len(consts[name])] += column - start_column - len(consts[name])
		advance_pos()


## Imports consts from given GDrama file
func import_consts(path: String) -> void:
	if not FileAccess.file_exists(path):
		add_error("Import file doesn't exist")
		return
	
	var old_values = get_parsing_values()
	imported.append(path)
	current_file = path
	code = FileAccess.open(path, FileAccess.READ).get_as_text()
	go_to_start()
	while pos < len(code):
		process_const_line()
		advance_until("<")
	set_parsing_values(old_values)


## Processes const and import calls, adding their results to consts
func process_const_line():
	if is_character_in_pos("<"):
			var call = parse_call()
			match call[0]:
				"import":
					check_arg_count(call, 1)
					if call[1] in imported:
						add_error("Attempted cyclical import")
					else:
						import_consts(call[1])
				"const":
					check_arg_count(call, 2)
					if call[1] in consts:
						add_error("Constant " + call[1] + " already defined")
					else:
						consts[call[1]] = call[2]


## Returns the line divided into strings and calls
func parse_direction(actor_defined: bool = false) -> Array:
	# Skip empty spaces
	while code[pos].to_utf8_buffer() in [SPACE, TAB, CHAR_TAB]:
		advance_pos()
	
	var element_pos = pos
	var direction: Array = []
	while code[pos].to_utf8_buffer() != ENTER and pos < len(code) and (not is_character_in_pos(":") or actor_defined):
		if is_character_in_pos("<"): # Add call
			if pos > element_pos: # Add past string
				var all_white_spaces = true # Only adds if string has at least one non empty space
				for i in range(element_pos, pos):
					if not code[i].to_utf8_buffer() in [SPACE, TAB, CHAR_TAB]:
						all_white_spaces = false
						break
				
				if not all_white_spaces:
					direction.append(remove_escapes(code.substr(element_pos, pos - element_pos), DIRECTION_ESCAPABLES))
					element_pos = pos
			direction.append(parse_call(true))
			element_pos = pos
		else:
			advance_pos()
	
	if pos > element_pos: # Add past string
		direction.append(remove_escapes(code.substr(element_pos, pos - element_pos), DIRECTION_ESCAPABLES))
	
	return direction


## Parses a string starting in pos. Returns the full string. Ends at last "
func parse_string() -> String:
	assert(is_any_character_in_pos(STRING_CLOSERS.keys()), "Called parse_string outside string start")
	var closer = STRING_CLOSERS[code[pos]]
	
	advance_pos()
	var start_pos = pos
	
	while not is_character_in_pos(closer):
		if code[pos].to_utf8_buffer() == ENTER:
			add_error("Unterminated string")
			return ""
		advance_pos()
	
	var result = remove_escapes(code.substr(start_pos, pos - start_pos), ["\"", "\'"])
	advance_pos()
	return result


## Parses a call of the form <call arg1 arg2...>. Note that args can be strings
## or subcalls, which are the same as calls except they cannot contain subcalls
## of their own
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
	while pos < len(code) and not is_character_in_pos(closer):
		var old_element_pos = element_pos
		if code[pos].to_utf8_buffer() == ENTER:
			add_error("Command missing closer \"" + closer + "\"")
			return result
		
		# Check for subcall
		if is_character_in_pos("<"):
			if element_pos < pos:
				element_pos = append_and_advance.call(remove_escapes(code.substr(element_pos, pos - element_pos), CALL_ESCAPABLES))
			
			if subcalled:
				add_error("Subcall found within a subcall")
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


## Gets the current parsing values. This result should be used to restore a
## state through set_parsing_values()
func get_parsing_values():
	return [code, pos, line, column, current_file]


## Restores a state from values gotten previously from get_parsing_values()
func set_parsing_values(values: Array):
	self.code = values[0]
	self.pos = values[1]
	self.line = values[2]
	self.column = values[3]
	self.current_file = values[4]


## Returns whether the current pos is at a space, tab or enter
func is_empty_space() -> bool:
	if pos >= len(code):
		return false
	
	return code[pos].to_utf8_buffer() in [SPACE, TAB, CHAR_TAB, ENTER]


## Advances empty spaces in s starting from pos until pos is at a non-empty
## character
func advance_empty_spaces() -> void:
	if pos >= len(code):
		return
	
	while is_empty_space():
		advance_pos()
		if pos >= len(code):
			break


func advance_until_enter() -> void:
	if pos >= len(code):
		return
	
	while code[pos].to_utf8_buffer() != ENTER:
		advance_pos()
		if pos >= len(code):
			break


## Checks if a specific character is in a position, ignoring it in the case it 
## is escaped
func is_character_in_pos(char: String) -> bool:
	if pos >= len(code):
		return false
	
	var escape_escaped = false
	if pos - 2 >= 0:
		escape_escaped = code[pos - 2] == "\\"
	return code[pos] == char and (code[max(0, pos - 1)] != "\\" or escape_escaped)


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


## Advances spaces until pos is at x
func advance_until(x: String) -> void:
	if pos >= len(code):
		return
	
	while not is_character_in_pos(x):
		advance_pos()
		if pos >= len(code):
			break


## Advances pos, column and line
func advance_pos() -> void:
	if pos < len(code):
		pos += 1
		column += 1
		if code[pos - 1].to_utf8_buffer() == ENTER:
			line += 1
			column = 0

# --------------------------------------------------------------------------------------------------
# ERRORS
# --------------------------------------------------------------------------------------------------
## Gets the current column, modified by the defined constant modifiers
func get_modified_column() -> int:
	var modified_column = column
	if line in line_column_modifiers:
		for line_column in line_column_modifiers[line]:
			if column > line_column:
				modified_column += line_column_modifiers[line][line_column]
	return modified_column


## Adds the specified error, including line and column number
func add_error(error: String) -> void:
	errors.append({
		"line_number": line,
		"column_number": get_modified_column(),
		"error": error
	})


func get_errors() -> Array[Dictionary]:
	return errors


func get_result() -> GDramaResource:
	return result


func is_inside_beat(type: String) -> bool:
	if current_beat == "":
		add_error("Attempted to create " + type + " outside beat")
		return false
	return true


## If the argument array passed contains a different number of arguments than
## expected, pushes an error message
func check_arg_count(l: Array, total_args: int):
	if len(l) - 1 != total_args:
		add_error(str(total_args) + " arguments expected in " + l[0] + " function. " + str(len(l) - 1) + "provided")

# --------------------------------------------------------------------------------------------------
# COLORS
# --------------------------------------------------------------------------------------------------
func get_highlight(text: String):
	var found_actor = false
	var color = {0: {"color": REGULAR_COLOR if found_actor else ACTOR_COLOR}}
	code = text
	go_to_start()
	
	advance_empty_spaces()
	while pos < len(code):
		if is_character_in_pos("<"):
			var old_values = get_parsing_values()
			var call = parse_call()
			
			if len(call) == 0: # Initial call
				call.append("invalid")
			var keyword_call = call[0] in ["beat", "const", "import", "choice", "end"]
			set_parsing_values(old_values)
			color[pos] = {"color": KEYWORD_COLOR if keyword_call else CALL_COLOR}
			
			advance_pos()
			
			if pos < len(code):
				var opener_count = 1
				while opener_count > 0:
					if is_character_in_pos("<"):
						opener_count += 1
						color[pos] = {"color": CALL_COLOR}
					elif is_character_in_pos(">"):
						opener_count -= 1
						if opener_count == 1 and keyword_call:
							color[pos + 1] = {"color": KEYWORD_COLOR}
					advance_pos()
					if pos >= len(code):
						break
				color[pos] = {"color": REGULAR_COLOR if found_actor else ACTOR_COLOR}
		elif is_character_in_pos("$"):
			color[pos] = {"color": CONST_COLOR}
			advance_pos()
			
			if pos < len(code):
				if is_any_character_in_pos(STRING_CLOSERS.keys()):
					parse_string()
				else:
					while not code[pos].to_utf8_buffer() in [SPACE, ENTER, TAB, CHAR_TAB]:
						advance_pos()
						if pos >= len(code):
							break
				color[pos] = {"color": REGULAR_COLOR if found_actor else ACTOR_COLOR}
		else:
			if is_character_in_pos(":"):
				found_actor = true
				advance_pos()
				if pos < len(code):
					color[pos] = {"color": REGULAR_COLOR}
			else:
				advance_pos()
	
	if not found_actor:
		for pos in color:
			if color[pos]["color"] == ACTOR_COLOR:
				color[pos]["color"] = REGULAR_COLOR
	
	return color


# --------------------------------------------------------------------------------------------------
# UTILS
# --------------------------------------------------------------------------------------------------
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


## Returns the string s with the character at the given position removed
static func remove_from_string(s: String, pos: int) -> String:
	return s.substr(0, pos) + s.substr(pos + 1)
