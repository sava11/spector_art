extends CharacterBody2D
class_name Pawn2D

signal dash_count_max_changed(count: int)

## Input variables for external control
@export var input_direction: Vector2 = Vector2.ZERO
@export var jump_held: bool = false

## Movement parameters
@export_group("Movement", "move_")
@export var move_max_speed: float=1200
@export var move_accel: float = 1200.0
@export var move_decel: float = 1400.0
@export var move_turn_accel: float = 800

@export_group("dash", "dash")
@export var dash_speed:float=2000
@export var dash_count_max: int = 1:
	set(v):
		dash_count_max = v
		dash_count_max_changed.emit(v)
@export var dash_distance := 200.0
@export var dash_cooldown := 0.5

## Internal variables
var last_input_direction:Vector2

var dash_buffer := Buffer.new(0.2, 0.2)
var dashing: bool = false
var dash_tween: Tween
var dash_cooldown_timer: float = 0
var dash_timer: float = 0
var dash_duration:float=0

var want_jump:=false
var jump_released:=false
var _last_jump_held:=false

func _ready() -> void:
	dash_duration=dash_distance/dash_speed
	print(dash_duration)

func _physics_process(delta: float) -> void:

	want_jump = !_last_jump_held and jump_held
	jump_released = _last_jump_held and !jump_held
	_last_jump_held=jump_held
	if not input_direction.is_zero_approx():
		last_input_direction=input_direction.normalized()

	# Process horizontal movement
	process_move(delta)

	# Process jumping
	process_dash(delta)

	update_ground_and_timers(delta)

	# Move the character
	move_and_slide()

## Process movement based on input direction
func process_move(delta: float) -> void:
	var target_speed = input_direction * move_max_speed

	# Handle movement
	var rate: float = move_accel if (snapped(velocity.angle(),PI/6) == snapped(target_speed.angle(),PI/6) or target_speed.length() == 0) else move_turn_accel
	if not target_speed.is_zero_approx() and (snapped(abs(velocity.length()), 0.1) <= snapped(abs(target_speed.length()), 0.1)):
		velocity = velocity.move_toward(target_speed, rate * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_decel * delta)


func process_dash(delta: float) -> void:
	if dash_buffer.should_run_action():
		dashing = true
		dash_cooldown_timer += dash_cooldown
		var vec := last_input_direction * dash_speed
		velocity = vec
		dash_tween = get_tree().create_tween()
		dash_tween.tween_property(self, "velocity", 
			velocity - vec, dash_duration)
		return
	if dashing:
		dash_timer += delta
		if dash_timer > dash_duration:
			dashing = false
			dash_timer = 0

func update_ground_and_timers(delta: float) -> void:
	dash_buffer.update(want_jump, dash_cooldown_timer + dash_cooldown <= \
		dash_count_max * dash_cooldown and not dashing, delta)
	if not dashing:
		dash_cooldown_timer = max(0, dash_cooldown_timer - delta)
