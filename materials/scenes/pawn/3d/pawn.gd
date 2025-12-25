extends CharacterBody3D
class_name Pawn3D

signal jump_count_max_changed(count: int)

## Input variables for external control
@export var input_direction: Vector2 = Vector2.ZERO
@export var jump_held: bool = false

## Movement parameters
@export_group("Movement", "move_")
@export var move_ground_accel: float = 5.0
@export var move_ground_decel: float = 5.0
@export var move_ground_turn_accel: float = 10
@export var move_air_accel: float = 3.0
@export var move_air_decel: float = 3.0
@export var move_air_turn_accel: float = 5.0

@export_group("Jump", "jump_")
@export var jump_count_max: int = 1:
	set(v):
		jump_count_max = v
		jump_count_max_changed.emit(v)
@export var jump_height: float = 0.5
@export var jump_distance: float = 1
@export_range(0.001, 2, 0.001) var jump_time_to_apex: float = 0.35
@export var jump_time_to_land: float = 0.35

## Internal variables
var jump_buffer := Buffer.new(0.2, 0.2)
var gravity_apex: float
var gravity_fall: float
var jump_velocity: float
var max_speed: float

var want_jump:=false
var jump_released:=false
var _last_jump_held:=false
var jump_count:int=0
var is_jumping: bool = false
var _on_ground: bool = false

func _ready() -> void:
	# Calculate movement parameters based on jump physics
	gravity_apex = (2 * jump_height) / pow(jump_time_to_apex, 2)
	gravity_fall = (2 * jump_height) / pow(jump_time_to_land, 2)
	jump_velocity = gravity_apex * jump_time_to_apex
	max_speed = jump_distance / (jump_time_to_apex + jump_time_to_land)

func _physics_process(delta: float) -> void:
	# Update ground state
	_on_ground = is_on_floor()
	want_jump = !_last_jump_held and jump_held
	jump_released = _last_jump_held and !jump_held
	_last_jump_held=jump_held

	# Process horizontal movement
	process_horizontal(delta)

	# Process jumping
	process_jumping()

	# Apply gravity
	apply_gravity(delta)

	update_ground_and_timers(delta)

	# Move the character
	move_and_slide()

#var target_speed = input_dir.x * max_speed

#var accel = ground_accel if _on_ground else air_accel
#var decel = ground_decel if _on_ground else air_decel
#var turn_accel = ground_turn_accel if _on_ground else air_turn_accel

#var rate: float = accel if (sign(velocity.x) == sign(target_speed) or target_speed == 0) else turn_accel
#if target_speed != 0 and can_move and not _climb and (snapped(abs(velocity.x), 0.1) <= snapped(abs(target_speed), 0.1)):
	#velocity.x = move_toward(velocity.x, target_speed, rate * delta)
#else:
	#if _on_ground: velocity.x = move_toward(velocity.x, 0, decel * delta)

## Process horizontal movement based on input direction
func process_horizontal(delta: float) -> void:
	var target_speed_x = input_direction.x * max_speed
	var target_speed_z = input_direction.y * max_speed  # Y input becomes Z movement in 3D

	var accel = move_ground_accel if _on_ground else move_air_accel
	var decel = move_ground_decel if _on_ground else move_air_decel
	var turn_accel = move_ground_turn_accel if _on_ground else move_air_turn_accel

	# Handle X axis movement
	var rate_x: float = accel if (sign(velocity.x) == sign(target_speed_x) or target_speed_x == 0) else turn_accel
	if target_speed_x != 0.0 and (snapped(abs(velocity.x), 0.1) <= snapped(abs(target_speed_x), 0.1)):
		velocity.x = move_toward(velocity.x, target_speed_x, rate_x * delta)
	else:
		if _on_ground: velocity.x = move_toward(velocity.x, 0, decel * delta)

	# Handle Z axis movement
	var rate_z: float = accel if (sign(velocity.z) == sign(target_speed_z) or target_speed_z == 0) else turn_accel
	if target_speed_z != 0.0 and snapped(abs(velocity.z), 0.1) <= snapped(abs(target_speed_z), 0.1):
		velocity.z = move_toward(velocity.z, target_speed_z, rate_z * delta)
	else:
		if _on_ground: velocity.z = move_toward(velocity.z, 0, decel * delta)

## Process jumping based on jump_pressed input
func process_jumping() -> void:
	if jump_buffer.should_run_action():
		is_jumping = true
		_on_ground = false
		jump_count += 1
		velocity.x = input_direction.x * abs(velocity.x)
		velocity.z = input_direction.y * abs(velocity.z)
		velocity.y = jump_velocity
	elif not is_jumping and not _on_ground and jump_count == 0:
		jump_count += 1

	if jump_released and velocity.y > 0:
		velocity.y *= 0.5

## Apply gravity to the character
func apply_gravity(delta: float) -> void:
	if is_jumping and velocity.y < 0:
		velocity.y -= gravity_apex * delta
	else:
		velocity.y -= gravity_fall * delta

func update_ground_and_timers(delta: float) -> void:
	if is_on_floor():
		_on_ground = true
		jump_count = 0
		is_jumping = false
	else:
		_on_ground = false

	jump_buffer.update(want_jump, jump_count < jump_count_max, delta)
