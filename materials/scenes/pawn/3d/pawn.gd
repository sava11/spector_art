## 3D pawn character with physics-based movement and action system.
##
## This class implements a complete 3D character controller with input processing,
## physics-based movement, jumping, dashing, and combat capabilities. It integrates
## with the action system for modular behavior and supports both player and enemy pawns.
## [br][br]
## [b]Key Features:[/b]
## - Physics-based 3D movement with CharacterBody3D
## - Input-driven actions (jump, dash, attack)
## - Automatic physics parameter calculation
## - Collision layer management for player/enemy interactions
## - Modular action system integration
## [br][br]
## [codeblock]
## # Basic pawn setup:
## var pawn = Pawn3D.new()
## pawn.input_direction = Vector2(1, 0)  # Move right
## pawn.want_jump = true
## add_child(pawn)
## [/codeblock]

class_name Pawn3D
extends CharacterBody3D


## Whether this pawn is an enemy (affects collision layers and interactions).
## When true, changes collision masks to interact with players instead of other enemies.
@export var enemy: bool = false: set = set_enemy

# ====================================================================================
# Input Variables - External Control Interface
# ====================================================================================

@export_group("input")

## Current movement input direction (normalized 2D vector).
## Controls horizontal movement: (1,0) = right, (-1,0) = left, (0,1) = forward, etc.
@export var input_direction: Vector2 = Vector2.ZERO

## Current look direction for aiming/rotation (screen space coordinates).
## Used for determining attack direction and character facing.
@export var look_direction: Vector3 = Vector3.FORWARD

## Whether the jump button is currently held down.
@export var jump_held: bool = false

## Whether the dash button is currently held down.
@export var dash_held: bool = false

## Whether the zip button is currently held down.
## Used for zip point selection and teleportation mechanics.
@export var zip_held: bool = false

## Whether the pawn wants to perform an attack action.
@export var want_attack: bool = false

@export_group("etc")

@export var hitboxes:Array[HitBox3D]

## Setter for enemy property that updates collision layers and masks.
## CRITICAL: Configures collision detection for player vs enemy interactions:
## - Players detect layer 3 (allies), enemies detect layer 4 (players)
## - Hurt boxes use opposite layers for damage detection
func set_enemy(value: bool) -> void:
	enemy = value
	# Configure hurt box collision detection
	var hurt_box = $hb
	hurt_box.set_collision_mask_value(3, !enemy)  # Detect allies when player
	hurt_box.set_collision_mask_value(4, enemy)   # Detect players when enemy
	hurt_box.flags = 1 + 4 * int(!enemy) + 8 * int(enemy)

	# Configure hit box collision layers (what this pawn can hit)
	for hit_box in hitboxes:
		hit_box.set_collision_layer_value(3, enemy)   # Hit allies when enemy
		hit_box.set_collision_layer_value(4, !enemy)  # Hit players when player

# ====================================================================================
# Internal State Variables
# ====================================================================================

## Last non-zero input direction (used for maintaining facing direction).
var last_input_direction: Vector2

## Whether the pawn wants to initiate a jump (true on jump button press).
var want_jump: bool = false

## Whether the jump button was just released.
var jump_released: bool = false

## Previous frame's jump_held state for edge detection.
var _last_jump_held: bool = false

## Whether the pawn is currently on the ground.
var _on_ground: bool = false

## Whether the pawn wants to initiate a dash (true on dash button press).
var want_dash: bool = false

## Whether the dash button was just released.
var dash_released: bool = false

## Previous frame's dash_held state for edge detection.
var _last_dash_held: bool = false

## Whether the pawn wants to initiate a dash (true on dash button press).
var want_zip: bool = false

## Whether the dash button was just released.
var zip_released: bool = false

## Previous frame's dash_held state for edge detection.
var _last_zip_held: bool = false

## Initialize the 3D pawn and calculate physics parameters.
## CRITICAL: Performs automatic physics parameter calculation based on jump action settings.
## This ensures consistent movement, jumping, and gravity that match the designed jump arc.
##
## Physics calculations:
## - Gravity acceleration for jump apex and fall
## - Jump velocity based on height and time to apex
## - Maximum movement speed based on jump distance and timing
func _ready() -> void:
	# Get references to action components
	var jump_action = $state/JumpAction3D
	var gravity_action = $state/GravityAction3D
	var move_action = $state/MoveAction3D

	# Calculate gravity acceleration for jump apex (rising)
	gravity_action.apex = (2 * jump_action.height) / pow(jump_action.time_to_apex, 2)

	# Calculate gravity acceleration for fall (descending)
	gravity_action.fall = (2 * jump_action.height) / pow(jump_action.time_to_land, 2)

	# Calculate jump velocity based on gravity and time to apex
	jump_action.jump_velocity = gravity_action.apex * jump_action.time_to_apex

	# Calculate maximum movement speed based on jump distance
	move_action.max_speed = jump_action.distance / (jump_action.time_to_apex + jump_action.time_to_land)
	set_enemy(enemy)

## Main physics process for pawn movement and state updates.
## CRITICAL: Handles input processing, state management, and physics integration.
## This method coordinates all pawn behavior each physics frame.
##
## [param delta] Time elapsed since the last physics frame in seconds
func _physics_process(_delta: float) -> void:

	# Process zip input with edge detection (detect button press/release)
	want_zip = !_last_zip_held and zip_held  # True on press
	zip_released = _last_zip_held and !zip_held  # True on release
	_last_zip_held = zip_held  # Store for next frame comparison

	# Process dash input with edge detection (detect button press/release)
	want_dash = !_last_dash_held and dash_held  # True on press
	dash_released = _last_dash_held and !dash_held  # True on release
	_last_dash_held = dash_held  # Store for next frame comparison

	# Process jump input with edge detection (detect button press/release)
	want_jump = !_last_jump_held and jump_held  # True on press
	jump_released = _last_jump_held and !jump_held  # True on release
	_last_jump_held = jump_held  # Store for next frame comparison

	# Update last movement direction for facing/orientation
	if not input_direction.is_zero_approx():
		last_input_direction = input_direction.normalized()

	#var angle = look_direction.angle()
	$hits.look_at(look_direction+Vector3(0,0.15,0),Vector3(0,1,0),true)

	# Update ground state and timers
	update_ground_and_timers()

	# Execute physics movement
	move_and_slide()

## Update ground contact state.
func update_ground_and_timers() -> void:
	_on_ground = is_on_floor()


func _on_attack_on_start(id: int, time: float) -> void:
	match id:
		0: $hits/sword/ap.play("attack")


func _vec3_to_angle(vec:Vector3)->Vector3:
	var up = vec.normalized()
	var forward = Vector3.FORWARD  # Or your desired forward
	var right = up.cross(forward).normalized()
	forward = right.cross(up).normalized()  # Orthogonalize
	var _basis = Basis(right, up, -forward)  # -forward for typical +Z forward
	
	# Get Euler angles in radians (X, Y, Z order)
	var euler = _basis.get_euler()
	
	# Convert to degrees if needed
	var euler_deg = Vector3(
		rad_to_deg(euler.x),
		rad_to_deg(euler.y),
		rad_to_deg(euler.z)
	)
	return euler_deg


func _on_health_changed(value: float, _delta: float) -> void:
	$hb/Node3D/DrawOnUI/pb.value=value


func _on_max_health_changed(value: float, _delta: float) -> void:
	$hb/Node3D/DrawOnUI/pb.max_value=value
