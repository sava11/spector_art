extends BaseController
class_name PlayerController

func input_control():
	input_direction = Vector2(
				int(Input.is_action_pressed("move_right")) -
				int(Input.is_action_pressed("move_left")),
				int(Input.is_action_pressed("move_down")) -
				int(Input.is_action_pressed("move_up"))
			)
	jump_held = Input.is_action_pressed("jump")
