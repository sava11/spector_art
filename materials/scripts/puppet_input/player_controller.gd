extends BaseController
class_name PlayerController

@export var camera_rotation:=0.0

func input_control():
	var t := Vector2(
		int(Input.is_action_pressed("move_right")) -
		int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_down")) -
		int(Input.is_action_pressed("move_up"))
		)
	if not t.is_zero_approx():
		input_direction=FNC.move(FNC.angle(t) - camera_rotation)
	else:
		input_direction=Vector2.ZERO
	jump_held = Input.is_action_pressed("jump")
