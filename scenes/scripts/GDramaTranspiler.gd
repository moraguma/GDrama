class_name GDramaTranspiler


const CLOSERS = {"\"": "\"", "{": "}", "<": ">", "\'": "\'"}
const EMPTY = [" "]


static func remove_from_string(s: String, pos: int) -> String:
	return s.substr(0, pos) + s.substr(pos + 1)


# Parses a call String of the form "func arg1 arg2..." into an array R of
# strings such that R[0] = func and R[1:] = [arg1, arg2, ...]
static func parse_call(call_string: String, pos: int) -> Array[String]:
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
	
	while s[pos] != x:
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


static func check_arg_count(l: Array, total_args: int):
	if len(l) - 1 != total_args:
		push_error(str(total_args) + " arguments expected in " + l[0] + " function. " + str(len(l) - 1) + "provided") 


# If not currently in beat, pushes error
static func check_beat(call: String, current_beat):
	if current_beat == null:
		push_error("Attempted to make call \"" + call + "\" outside of beat!")


# Given a string, returns it with any empty spaces in the borders removed
static func remove_empty_borders(s: String) -> String:
	for i in [[0, 1], [-1, -1]]:
		var pos = i[0]
		var mod = i[1]
		
		while s[pos] in EMPTY:
			s = remove_from_string(s, pos)
			pos += mod
	return s


# Given a line, returns an array [actor, line]. If there's no actor, actor is ""
static func get_line_info(s: String) -> Array[String]:
	var pos = 0
	while pos < len(s):
		if s[pos] == ":":
			return [remove_empty_borders(s.substr(0, pos)), remove_empty_borders(s.substr(pos + 1))]
		if s[pos] == "\\":
			s = remove_from_string(s, pos)
		pos += 1
	return ["", remove_empty_borders(s)]


# Given a GDrama code, returns its resulting JSON dictionary
static func getJSON(code: String) -> Dictionary:
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
					check_arg_count(call, 1)
					consts[call[0]] = call[1]
					pos = advance_until(code, pos, ">") + 1
				"import":
					# TODO: Implement constant importing
					check_arg_count(call, 1)
					pos = advance_until(code, pos, ">") + 1
					pass
				"beat":
					check_arg_count(call, 1)
					if current_beat != null:
						result["beats"][current_beat]["next"] = call[1]
					
					current_beat = call[1]
					
					if result["start"] == null:
						result["start"] = current_beat
					
					result["beats"][current_beat] = {"steps": {}, "next": ""}
					current_step = 0
					
					pos = advance_until(code, pos, ">") + 1
				"call":
					check_arg_count(call, 1)
					check_beat(" ".join(call), current_beat)
					
					result["beats"][current_beat]["steps"][str(current_step)] = {"type": "CALL", "call": call[1]}
					current_step += 1
					
					pos = advance_until(code, pos, ">") + 1
				"jump":
					check_arg_count(call, 1)
					check_beat(" ".join(call), current_beat)
					
					result["beats"][current_beat]["steps"][str(current_step)] = {"type": "CALL", "call": "{jump " + call[1] + "}"}
					current_step += 1
					
					pos = advance_until(code, pos, ">") + 1
				"choice":
					check_beat(" ".join(call), current_beat)
					
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
					check_arg_count(call, 1)
					check_beat(" ".join(call), current_beat)
					
					result["beats"][current_beat]["steps"][str(current_step)] = {"type": "END", "info": call[1]}
					current_step += 1
					
					pos = advance_until(code, pos, ">") + 1
		else:
			var new_pos = advance_until_enter(code, pos)
			var line = code.substr(pos, new_pos - pos)
			var line_info = get_line_info(line)
			
			check_beat(line, current_beat)
			
			result["beats"][current_beat]["steps"][str(current_step)] = {"type": "DIRECTION", "actor": line_info[0], "direction": line_info[1]}
			current_step += 1
			
			pos = new_pos
		pos = advance_empty_spaces(code, pos)
	return result
