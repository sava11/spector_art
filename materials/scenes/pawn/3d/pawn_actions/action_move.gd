extends PawnAction
class_name MovePawnAction3D

@export var max_speed: float=3.0
@export var ground_accel: float = 5.0
@export var ground_decel: float = 5.0
@export var ground_turn_accel: float = 10
@export var air_accel: float = 3.0
@export var air_decel: float = 3.0
@export var air_turn_accel: float = 5.0

func _on_action(delta:float):
	var velocity:=Vector2(pawn_node.velocity.x,pawn_node.velocity.z)
	var target_speed: Vector2 = pawn_node.input_direction * max_speed

	var accel = ground_accel if pawn_node._on_ground else air_accel
	var decel = ground_decel if pawn_node._on_ground else air_decel
	var turn_accel = ground_turn_accel if pawn_node._on_ground else air_turn_accel

	var rate: float = accel if (snapped(velocity.angle(),PI/10) == \
		snapped(target_speed.angle(),PI/10) or target_speed.length() == 0) \
		else turn_accel

	if not target_speed.is_zero_approx() and (snapped(abs(velocity.length()), 0.1) <= snapped(abs(target_speed.length()), 0.1)):
		velocity = velocity.move_toward(target_speed, rate * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, decel * delta)

	pawn_node.velocity=Vector3(velocity.x, pawn_node.velocity.y, velocity.y)
