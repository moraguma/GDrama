extends CharacterBody2D
class_name Character

# --------------------------------------------------------------------------------------------------
# SIGNALS
# --------------------------------------------------------------------------------------------------
signal finished_move_h
signal landed

# --------------------------------------------------------------------------------------------------
# CONSTANTS
# --------------------------------------------------------------------------------------------------
# Movement ---------------------------------------------------------------------
const H_MOVE_TOLERANCE = 10.0

const SPEED = 450.0
const JUMP_SPEED = 1000.0
const TERMINAL_FALL_SPEED = 1800.0

const AIR_ACCEL = 0.05
const GROUND_ACCEL = 0.1
const GROUND_DECEL = 0.2
const GRAVITY_WEIGHT = 0.03

# Animation --------------------------------------------------------------------
const MOVE_ANIM_TOLERANCE = 50.0
const MAX_ANGLE = 0.1

# --------------------------------------------------------------------------------------------------
# VARIABLES
# --------------------------------------------------------------------------------------------------
@export var texture_path: String
@export var actor_name: String

# Movement ---------------------------------------------------------------------
var dir: Vector2 = Vector2(0, 0)
var aim_h
var on_floor = true

var effective_gravity = GRAVITY_WEIGHT

# --------------------------------------------------------------------------------------------------
# NODES
# --------------------------------------------------------------------------------------------------
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite
@onready var drama_display: BubbleDramaDisplay = $BubbleDramaDisplay

# --------------------------------------------------------------------------------------------------
# BUILT-INS
# --------------------------------------------------------------------------------------------------
func _ready():
	drama_display.actor_name = actor_name
	
	sprite.texture = load(texture_path)


func _physics_process(delta):
	_movement_process(delta)
	_animation_process()


func _movement_process(delta):
	# Horizontal velocity
	var h_accel
	if is_on_floor():
		if not on_floor:
			landed.emit()
			on_floor = true
		
		if dir.dot(velocity) > 0:
			h_accel = GROUND_ACCEL
		else:
			h_accel = GROUND_DECEL
	else:
		on_floor = false
		h_accel = AIR_ACCEL
	
	velocity[0] = lerp(velocity[0], dir[0] * SPEED, h_accel)
	
	# Vertical velocity
	var gravity_weight
	if velocity[1] < 0:
		gravity_weight = effective_gravity
	else:
		gravity_weight = GRAVITY_WEIGHT
	velocity[1] = lerp(velocity[1], TERMINAL_FALL_SPEED, gravity_weight)
	
	move_and_slide()
	
	# Move H logic
	if aim_h != null:
		if abs(position[0] - aim_h) < H_MOVE_TOLERANCE or dir.dot(Vector2(aim_h, 0) - position) < 0:
			aim_h = null
			dir = Vector2(0, 0)
			finished_move_h.emit()


func _animation_process():
	# Decides on animation
	if velocity.length() > MOVE_ANIM_TOLERANCE:
		animation_player.play("move")
	else:
		animation_player.play("idle")
	
	# Flips sprite depending on direction
	if velocity[0] > 0:
		sprite.flip_h = false
	elif velocity[0] < 0:
		sprite.flip_h = true
	
	# Creates angle
	var angle = clamp(MAX_ANGLE * velocity[0] / SPEED, -MAX_ANGLE, MAX_ANGLE)
	sprite.rotation = angle
	
	# Corrects offset so sprite is stepping on floor
	var height = Vector2(0, sprite.texture.get_height() / 2)
	sprite.offset = height - height.rotated(-angle)

# --------------------------------------------------------------------------------------------------
# DRAMA CALLS
# --------------------------------------------------------------------------------------------------
func move_h(movement: float):
	if movement != 0.0:
		aim_h = position[0] + movement
		dir = Vector2(movement / abs(movement), 0)
		await finished_move_h


func jump():
	if is_on_floor():
		velocity += Vector2(0, -1) * JUMP_SPEED
		await landed
