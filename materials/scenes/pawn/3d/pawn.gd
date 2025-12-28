extends CharacterBody3D
class_name Pawn3D

## Input variables for external control
@export var input_direction: Vector2 = Vector2.ZERO
@export var look_direction: Vector2 = Vector2.ZERO
@export var jump_held: bool = false
@export var dash_held: bool = false
@export var want_attack: bool = false
@export var enemy: bool = false:set=set_enemy
func set_enemy(value:bool):
	enemy=value
	$hb.set_collision_mask_value(3,!enemy)
	$hb.set_collision_mask_value(4,enemy)
	$hb.flags=1+4*int(!enemy)+8*int(enemy)
	for e in $hits.get_children():
		e.set_collision_layer_value(3,enemy)
		e.set_collision_layer_value(4,!enemy)

## Internal variables
var last_input_direction:Vector2

var want_jump: bool =false
var jump_released: bool =false
var _last_jump_held: bool =false
var _on_ground: bool = false

var want_dash:=false
var dash_released:=false
var _last_dash_held:=false

var jump_count:int=0
var is_jumping:bool=false

func _ready() -> void:
	# Calculate movement parameters based on jump physics
	var jump:=$state/JumpAction3D
	var gravity:=$state/GravityAction3D
	var move:=$state/MoveAction3D
	gravity.apex = (2 * jump.height) / pow(jump.time_to_apex, 2)
	gravity.fall = (2 * jump.height) / pow(jump.time_to_land, 2)
	jump.jump_velocity = gravity.apex * jump.time_to_apex
	move.max_speed = jump.distance / (jump.time_to_apex + jump.time_to_land)

func _physics_process(delta: float) -> void:
	# Update ground state
	_on_ground = is_on_floor()
	
	want_dash = !_last_dash_held and dash_held
	dash_released = _last_dash_held and !dash_held
	_last_dash_held=dash_held
	
	want_jump = !_last_jump_held and jump_held
	jump_released = _last_jump_held and !jump_held
	_last_jump_held=jump_held
	
	if not input_direction.is_zero_approx():
		last_input_direction=input_direction.normalized()
	#var ang:=look_direction.angle() 
	#$hits.rotation=Vector3(sin(ang),0,cos(ang))

	update_ground_and_timers(delta)

	# Move the character
	move_and_slide()


func update_ground_and_timers(delta: float) -> void:
	if is_on_floor():
		_on_ground = true
		jump_count = 0
		is_jumping = false
	else:
		_on_ground = false
