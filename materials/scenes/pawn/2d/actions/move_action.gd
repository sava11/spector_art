extends Action
class_name MoveAction2D

## Movement parameters
@export var move_max_speed: float=300
@export var move_accel: float = 600.0
@export var move_decel: float = 600.0
@export var move_turn_accel: float = 400

var input_direction: Vector2 = Vector2.ZERO
var velocity:Vector2

func _action(delta:float):
	var target_speed = input_direction * move_max_speed
	var rate: float = move_accel if (snapped(velocity.angle(),PI/6) == \
		snapped(target_speed.angle(),PI/6) or target_speed.length() == 0) \
		else move_turn_accel
	if not target_speed.is_zero_approx() and (snapped(abs(velocity.length()), 0.1) <= snapped(abs(target_speed.length()), 0.1)):
		velocity = velocity.move_toward(target_speed, rate * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_decel * delta)

func _not_action(delta:float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, move_decel * delta)
