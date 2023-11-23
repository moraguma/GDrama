extends Resource
class_name GDramaResource


const CHOICE = 0
const END = 1
const DIRECTION = 2



## The name of the beat the drama should start from
@export var start: String

## Each beat is includes two keys, being "next" (String) the beat that should be 
## played immediately after this one, and "lines" being an array of commands and
## directions. The available ones are:
##
## {"type": CHOICE, "choices": [], "results": [], "conditions": []} -> In order,
## we have the text associated with each choice, the resulting beat of each one
## and the conditions (call specifications) that have to be met for them to 
## appear
##
## {"type": END, "info": ""} -> Signals the end of a drama
##
## {"type": DIRECTION, "actor": [], "specification": []} -> A direction. Specifies
## an actor (which can be blank) and a specifications. Each element of these
## lists is either a string or a call specification (an array of strings) 
@export var beats: Dictionary = {}
