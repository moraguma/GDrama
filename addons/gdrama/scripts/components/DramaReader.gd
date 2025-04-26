extends Resource
class_name DramaReader


const MAX_LOG_SIZE = 100


## Signals that this line has just been added to the log
signal added_to_log(line)


var drama: GDramaResource
var beat: String
var pointer: int
var to_call: Object
var flags: Dictionary = {}

var log: Array = []
var log_modifiers: Array[Callable] = []


func _init():
	pass


# --------------------------------------------------------------------------------------------------
# DRAMA HANDLING
# --------------------------------------------------------------------------------------------------
## Loads a .gdrama file. If successful, the drama and pointer variables are 
## updated 
func load_gdrama(path: String) -> void:
	assert(ResourceLoader.exists(path), "Attempted to load inexistent drama at " + path)
	
	drama = load(path)
	jump(drama.start)


## If the pointer is on a choice, makes the specified choice
func make_choice(choice: int) -> void:
	assert(drama != null, "Called make_choice with no drama loaded")
	
	var line = drama.beats[beat]["lines"][pointer]
	assert(line["type"] == GDramaResource.CHOICE, "Called make_choice on non choice line")
	assert(choice >= 0 and choice < len(line["results"]), "Invalid choice " + str(choice) + " at line " + JSON.stringify(line))
	jump(line["results"][choice])
	
	log[-1]["selection"] = choice
	added_to_log.emit(log[-1])


## Returns drama to first beat
func reset_drama():
	assert(drama != null, "Called reset_drama with no drama loaded")
	jump(drama["start"])
	log = []


## Returns the next line and advances the pointer by one. The return is a line
## in the form specified in GDramaResource
func next_line() -> Dictionary:
	assert(drama != null, "Called next_line with no drama loaded")
	
	var result
	var should_add_to_log = true
	while result == null:
		# If current line is invalid
		if pointer >= len(drama.beats[beat]["lines"]):
			if drama.beats[beat]["next"] == "":
				return {"type": GDramaResource.END, "info": ""}
			jump(drama.beats[beat]["next"])
		
		# Process line
		var line = drama.beats[beat]["lines"][pointer].duplicate(true)
		match line["type"]:
			GDramaResource.DIRECTION:
				pointer = pointer + 1
				
				for field in ["actor", "specification"]:
					process_calls(line[field])
				if len(line["specification"]) > 0: # If everything was processed, skips
					result = line
			GDramaResource.CHOICE:
				result = line
				for i in range(len(result["conditions"])):
					var call_result = get_call_result(result["conditions"][i])
					if not call_result is bool:
						push_warning("Result of call " + result["conditions"] + " is not bool. This may cause unexpected behavior")
					result["conditions"][i] = call_result
				should_add_to_log = false
			GDramaResource.END:
				result = line
	
	add_to_log(result, should_add_to_log)
	return result


## Given an array of strings and calls (represented by arrays), processes all
## calls it can
func process_calls(a: Array) -> void:
	var i = 0
	while i < len(a):
		if a[i] is Array:
			assert(len(a[i]) > 0, "Attempted to process empty call")
			if has_method(a[i][0]):
				var r = callv(a[i][0], a[i].slice(1))
				if r is String:
					a[i] = r
				else:
					a.remove_at(i)
					i -= 1
		i += 1


## Processes the call specified by this array and returns its result
func get_call_result(a: Array):
	assert(len(a) > 0, "Attempted to process empty call")
	if has_method(a[0]):
		return callv(a[0], a.slice(1))
	return null


## Passes this line through all modifiers set in log_modifiers before adding it
## to the log
func add_to_log(line: Dictionary, emit_signal: bool):
	line = line.duplicate(true)
	
	for modifier in log_modifiers:
		line = modifier.call(line)
	
	if len(log) >= MAX_LOG_SIZE:
		log.pop_at(0)
	log.append(line)
	
	if emit_signal:
		added_to_log.emit(line)


# ------------------------------------------------------------------------------
# COMMANDS
# ------------------------------------------------------------------------------
## Jumps beat and pointer to the start of the specified beat
func jump(target_beat: String) -> void:
	beat = target_beat
	pointer = 0


## Jumps to target beat if flag is true
func branch(target_beat: String, flag: String) -> void:
	if get_flag(flag):
		jump(target_beat)


## Returns the value of a flag
func get_flag(flag: String):
	if flag in flags:
		return flags[flag]
	return false


## Turns on a local flag
func flag(name: String) -> void:
	flags[name] = true


## Turns off a local flag
func unflag(name: String) -> void:
	flags[name] = false


## Returns true
func get_true() -> bool:
	return true
