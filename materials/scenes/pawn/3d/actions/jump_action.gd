extends Action
class_name JumpAction3D

signal jump_count_max_changed(jump_count: int)

@export var jump_count_max: int = 1:
	set(v):
		jump_count_max = v
		jump_count_max_changed.emit(v)
@export var height: float = 0.5
@export var distance: float = 1
@export_range(0.001, 2, 0.001, "or_greater") var time_to_apex: float = 0.35
@export_range(0.001, 2, 0.001, "or_greater") var time_to_land: float = 0.35

var buffer := Buffer.new(0.1, 0.1)
var jump_velocity: float
var jump_count:int=0
var is_jumping: bool = false
var want_jump: bool = false
var released: bool = false
var input_direction: Vector2 = Vector2.ZERO
var velocity:Vector3
var _on_ground:bool=false

func _action(_delta:float) -> void:
	if buffer.should_run_action():
		is_jumping = true
		_on_ground = false
		jump_count += 1
		velocity.x = input_direction.x * abs(velocity.x)
		velocity.z = input_direction.y * abs(velocity.z)
		velocity.y = jump_velocity
	elif not is_jumping and not _on_ground and jump_count == 0:
		jump_count += 1

	if released and velocity.y > 0:
		velocity.y *= 0.5

func _addition(delta:float) -> void:
	buffer.update(want_jump, jump_count < jump_count_max, delta)
