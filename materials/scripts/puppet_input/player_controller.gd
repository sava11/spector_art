extends BaseController
class_name PlayerController

@export var camera_rotation:=0.0

func input_control():
	var t := Vector2(
		int(Input.is_action_pressed("move_right")) -
		int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_down")) -
		int(Input.is_action_pressed("move_up")))
	if not t.is_zero_approx():
		input_direction=FNC.move(FNC.angle(t) - camera_rotation)
	else:
		input_direction=Vector2.ZERO
	if get_parent() is Node2D:
		look_direction=get_parent().get_global_mouse_position() - get_parent().global_position
	elif get_parent() is Node3D:
		look_direction= Vector2(get_viewport().get_mouse_position()) - \
			get_viewport().get_camera_3d().unproject_position(
			get_parent().global_position)
	want_attack=Input.is_action_just_pressed("attack")
	dash_held = Input.is_action_pressed("dash")
	jump_held = Input.is_action_pressed("jump")
