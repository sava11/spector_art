## Player controller implementation that handles keyboard/mouse and gamepad input.
##
## This class extends BaseController to provide concrete input processing for player characters.
## It translates raw input actions into movement directions, look directions, and action states.
## Supports both 2D and 3D pawns with automatic camera-relative movement and mouse aiming.
## [br][br]
## [b]Key Features:[/b]
## - WASD/arrows movement input processing
## - Mouse aiming with automatic 2D/3D detection
## - Camera-relative movement for 3D games
## - Action button handling (attack, dash, jump)
## - Input action mapping through Godot's Input system
## [br][br]
## [codeblock]
## # Basic setup:
## var controller = PlayerController.new()
## controller.puppet_pawn = $PlayerPawn
## controller.camera_rotation = camera.rotation.y  # For 3D camera-relative movement
## add_child(controller)
## [/codeblock]

class_name PlayerController
extends BaseController

const RAY_LENGTH = 1000

## Camera rotation angle in radians for 3D camera-relative movement.
## This allows movement to be relative to camera orientation rather than world space.
## Set this to your camera's Y rotation for proper 3D movement.
@export var camera_rotation: float = 0.0

## Processes player input and updates controller state.
## CRITICAL: This method handles all player input translation into pawn control signals.
## Reads from Godot's Input system and converts raw inputs into usable control values.
##
## Movement processing:
## - Converts WASD/arrow keys into normalized direction vector
## - Applies camera rotation for 3D relative movement
##
## Look direction processing:
## - For 2D pawns: Uses mouse position relative to pawn
## - For 3D pawns: Projects 3D world position to screen space
##
## Action processing:
## - Attack: Just pressed (single action)
## - Dash/Jump: Currently pressed (held actions)
func input_control() -> void:
	# Process movement input from WASD or arrow keys
	var raw_input := Vector2(
		int(Input.is_action_pressed("move_right")) -
		int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_down")) -
		int(Input.is_action_pressed("move_up")))

	if not raw_input.is_zero_approx():
		# Convert directional input to angle, apply camera rotation, then back to vector
		input_direction = FNC.move(FNC.angle(raw_input) - camera_rotation)
	else:
		input_direction = Vector2.ZERO

	# Process look direction based on pawn type
	if get_parent() is Node2D:
		# 2D: Direct mouse position relative to pawn
		look_direction = get_parent().get_global_mouse_position() - get_parent().global_position
	elif get_parent() is Node3D:
		# 3D: Project pawn world position to screen space for mouse aiming
		var space_state = get_parent().get_world_3d().direct_space_state
		var cam = get_viewport().get_camera_3d()
		var mousepos = get_viewport().get_mouse_position()
		var origin = cam.project_ray_origin(mousepos)
		var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var result = space_state.intersect_ray(query)
		if result: look_direction=result.position

	# Process action inputs
	want_attack = Input.is_action_just_pressed("attack")  # Single press detection
	dash_held = Input.is_action_pressed("dash")          # Continuous hold detection
	jump_held = Input.is_action_pressed("jump")          # Continuous hold detection
