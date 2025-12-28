extends CharacterBody2D
class_name Pawn2D

## Input variables for external control
@export var input_direction: Vector2 = Vector2.ZERO
@export var look_direction: Vector2 = Vector2.ZERO
@export var jump_held: bool = false
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

var want_jump:=false
var jump_released:=false
var _last_jump_held:=false

var want_attack := false

func _ready() -> void:
	set_enemy(enemy)

func _physics_process(_delta: float) -> void:

	want_jump = !_last_jump_held and jump_held
	jump_released = _last_jump_held and !jump_held
	_last_jump_held=jump_held
	
	if not input_direction.is_zero_approx():
		last_input_direction=input_direction.normalized()
	$hits.rotation=look_direction.angle()

	# Move the character
	move_and_slide()
