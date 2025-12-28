extends Action
class_name MoveAction3D

## Movement parameters
@export var max_speed: float=3.0
@export var ground_accel: float = 5.0
@export var ground_decel: float = 5.0
@export var ground_turn_accel: float = 10
@export var air_accel: float = 3.0
@export var air_decel: float = 3.0
@export var air_turn_accel: float = 5.0

var input_direction: Vector2 = Vector2.ZERO
var velocity:Vector3
var _on_ground:bool=false

func _action(delta:float):
	var target_speed_x = input_direction.x * max_speed
	var target_speed_z = input_direction.y * max_speed

	var accel = ground_accel if _on_ground else air_accel
	var decel = ground_decel if _on_ground else air_decel
	var turn_accel = ground_turn_accel if _on_ground else air_turn_accel

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

func _not_action(delta:float) -> void:
	var decel = ground_decel if _on_ground else air_decel
	velocity = velocity.move_toward(Vector3.ZERO, decel * delta)
