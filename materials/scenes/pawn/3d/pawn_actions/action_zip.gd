## ZipPawnAction3D - 3D teleportation action for pawn character.
##
## This action handles zip point detection, selection, and teleportation in 3D space.
## Integrates with ZipZone3D and ZipPoint3D to provide smooth teleportation mechanics
## with visual feedback, slow-motion effects, and camera following during zip mode.
## [br][br]
## [b]Key Features:[/b]
## - Zip mode: Slow-motion selection of available zip points
## - Zipping: Smooth movement towards selected zip point
## - Zipped: Arrival state at zip point
## - Input device awareness (mouse for keyboard, directional input for gamepad)
## - Automatic camera target switching during zip mode
## - Time scale manipulation for dramatic effect
## [br][br]
## [codeblock]
## # Basic usage in pawn scene:
## var zip_action = ZipPawnAction3D.new()
## zip_action.zip_zone_path = NodePath("../ZipZone3D")
## zip_action.zip_speed = 1024.0
## zip_action.zip_accel = 65536.0
## add_child(zip_action)
## [/codeblock]

extends PawnAction
class_name ZipPawnAction3D

## Reference to the ZipZone3D node that detects available zip points.
## Should be set to the path of the ZipZone3D in the pawn scene.
@export var zip_zone_path: NodePath = NodePath("")

## Whether zip functionality is currently enabled.
## When disabled, zip mode and teleportation are completely disabled.
@export var zip_enabled: bool = true:
	set(v):
		zip_enabled = v
		if is_instance_valid(_zip_zone):
			_zip_zone.set_collision_layer_value(9, v)
			_zip_zone.set_collision_mask_value(9, v)

## Speed at which the pawn moves towards the zip point during teleportation.
## Higher values result in faster teleportation. Should be significantly higher than normal movement speed.
@export var zip_speed: float = pow(2, 10)  # 1024.0

## Acceleration rate when moving towards zip point.
## Controls how quickly the pawn reaches zip_speed. Higher values = faster acceleration.
@export var zip_accel: float = pow(2, 16)  # 65536.0

## Time scale multiplier when in zip mode (selecting a point).
## Lower values create slow-motion effect. 0.05 = 5% normal speed.
@export var zip_mode_time_scale: float = 0.05

## Whether the pawn is currently in zip mode (selecting a point).
## In zip mode, time slows down and available points are highlighted.
var in_zip_mode: bool = false

## Whether the pawn is currently teleporting to a zip point.
## During zipping, the pawn moves towards the selected point at zip_speed.
var zipping: bool = false

## Whether the pawn has arrived at a zip point.
## In this state, the pawn is stationary at the zip point until cleared.
var zipped: bool = false

## Currently selected zip point for teleportation.
## Set during zip mode, used during zipping, cleared when zipped state ends.
var zip_node: ZipPoint3D = null

## Whether the pawn wants to enter zip mode (from input).
## Derived from pawn's zip_held state, checked each frame to enter zip mode.
var want_zip: bool = false

## Internal reference to the ZipZone3D node.
## Cached reference for performance, updated in _ready().
var _zip_zone: ZipZone3D = null

## World camera reference for follow target switching.
## Used to switch camera follow target between base and zip markers.
var _world_cam: Node = null

## Initialize the zip action when entering the scene tree.
## Sets up references to zip zone, markers, and camera system.
## [br][br]
## Critical initialization steps:
## - Resolves zip_zone_path to get ZipZone3D reference
## - Finds zip and base markers for camera following
## - Locates world camera for follow target switching
## - Configures collision layers if zip_enabled is set
func _ready() -> void:
	super._ready()
	
	# Resolve zip zone reference
	if not zip_zone_path.is_empty():
		_zip_zone = get_node_or_null(zip_zone_path) as ZipZone3D
		if not _zip_zone:
			push_warning("ZipPawnAction3D: ZipZone3D not found at path: %s" % zip_zone_path)

	# Find world camera (usually in scene tree as autoload or scene root)
	_world_cam = get_tree().current_scene.get_node_or_null("%world_cam")
	if not _world_cam:
		# Try alternative common paths
		_world_cam = get_tree().current_scene.get_node_or_null("world_cam")
	
	# Configure collision layers if zip is enabled
	if is_instance_valid(_zip_zone) and zip_enabled:
		_zip_zone.set_collision_layer_value(9, true)
		_zip_zone.set_collision_mask_value(9, true)

## Main action processing method called each physics frame.
## Handles zip mode, zipping, and zipped state transitions.
## [br][br]
## Critical processing logic:
## - Updates zip mode state based on input and conditions
## - Manages time scale for slow-motion effect
## - Handles zip point selection and visual feedback
## - Processes teleportation movement
## - Manages camera follow target switching
## [br][br]
## [param delta] Time elapsed since last physics frame in seconds
func _on_action(delta: float) -> void:
	# Update want_zip from pawn's zip_held state (if available)
	# Fallback to checking input directly if pawn doesn't have zip_held
	if pawn_node.zip_held:
		want_zip = pawn_node.zip_held and zip_enabled
	else:
		# Direct input check as fallback
		want_zip = Input.is_action_pressed("zip") and zip_enabled
	
	# Update zip mode state
	in_zip_mode = want_zip and not zipping and not zipped and \
		not pawn_node._on_ground and zip_enabled
	
	# Apply time scale for slow-motion effect during zip mode
	Engine.time_scale = zip_mode_time_scale + (1.0 - zip_mode_time_scale) * int(!in_zip_mode)
	
	# Update visual feedback and camera following
	if is_instance_valid(_zip_zone):
		_update_zip_visuals()
	
	# Process zip mode (point selection)
	if in_zip_mode:
		_process_zip_mode(delta)
	
	# Process teleportation to selected point
	if zip_node and not in_zip_mode:
		_process_zipping(delta)
	
	# Clear zip state when conditions are met
	if zipped and _should_clear_zip():
		clear_zip()

## Process zip mode: selecting a zip point based on input direction.
## Updates zip_node based on player's input direction (mouse or gamepad).
## [br][br]
## Critical selection logic:
## - Generates direction vector from input device (mouse position or gamepad input)
## - Queries zip zone for best matching point in that direction
## - Updates visual feedback on selected point
## - Updates zip marker position for camera following
## [br][br]
## [param delta] Time elapsed since last frame (unused but kept for signature)
func _process_zip_mode(_delta: float) -> void:
	if not is_instance_valid(_zip_zone):
		return
	
	# Generate direction based on input device
	var direction := _generate_direction()
	
	# Get best matching zip point in direction
	var new_zip_node = _zip_zone.get_available_zip_point(direction)
	
	# Update zip node and visual feedback
	if new_zip_node != zip_node:
		if zip_node:
			zip_node.img.hide()
		zip_node = new_zip_node
		if zip_node:
			zip_node.img.show()
			# Orient icon towards player
			var to_player = (pawn_node.global_position - zip_node.global_position).normalized()
			zip_node.img.look_at(zip_node.global_position + to_player, Vector3.UP, true)

## Process teleportation movement towards selected zip point.
## Moves the pawn smoothly towards the zip point using acceleration-based movement.
## [br][br]
## Critical movement logic:
## - Calculates direction from current position to zip point
## - Accelerates velocity towards zip point
## - Checks if close enough to snap to point position
## - Transitions to zipped state when arrived
## - Updates facing direction based on movement
## [br][br]
## [param delta] Time elapsed since last physics frame in seconds
func _process_zipping(delta: float) -> void:
	if not is_instance_valid(zip_node):
		clear_zip()
		return
	
	zipping = true
	
	var to: Vector3 = zip_node.global_position
	var from: Vector3 = pawn_node.global_position
	var direction = from.direction_to(to)
	
	# Accelerate towards zip point
	pawn_node.velocity = pawn_node.velocity.move_toward(
		direction * zip_speed,
		zip_accel * delta
	)
	
	# Check if close enough to snap to point
	var distance_squared = from.distance_squared_to(to)
	var snap_threshold = pow(zip_speed * delta, 2) * 1.5
	
	if distance_squared <= snap_threshold:
		# Arrived at zip point
		if zip_node:
			zip_node.img.hide()
		pawn_node.global_position = zip_node.global_position
		pawn_node.velocity = Vector3.ZERO
		
		# Update facing direction based on movement direction
		# Convert 3D direction to 2D for last_input_direction
		if abs(direction.x) > abs(direction.z):
			pawn_node.last_input_direction.x = sign(direction.x)
		elif direction.z != 0:
			pawn_node.last_input_direction.y = sign(direction.z)
		
		zipping = false
		zipped = true

## Generate direction vector for zip point selection.
## Returns normalized direction based on current input device (mouse or gamepad).
## [br][br]
## Critical input handling:
## - Keyboard/Mouse (device_id 0): Uses mouse position projected to 3D space
## - Gamepad (device_id > 0): Uses directional input vector
## - Falls back to look_direction if available
## [br][br]
## [return] Normalized Vector3 direction for zip point selection
func _generate_direction() -> Vector3:
	var direction := Vector3.ZERO

	match IV.device_id:
		0:  # Keyboard/Mouse
			# Project mouse position to 3D space
			var cam = get_viewport().get_camera_3d()
			if cam:
				var mouse_pos = get_viewport().get_mouse_position()
				var origin = cam.project_ray_origin(mouse_pos)
				var normal = cam.project_ray_normal(mouse_pos)
				var target_pos = origin + normal * 100.0  # Arbitrary distance
				
				if is_instance_valid(_zip_zone):
					direction = (target_pos - _zip_zone.global_position).normalized()
				else:
					direction = normal
			else:
				# Fallback to look_direction if camera not available
				if not pawn_node.look_direction.is_zero_approx():
					direction = (pawn_node.look_direction - pawn_node.global_position).normalized()
		1:  # Gamepad (or other device)
			# Use input direction from pawn
			if not pawn_node.input_direction.is_zero_approx():
				var input_3d = Vector3(pawn_node.input_direction.x, 0, pawn_node.input_direction.y)
				direction = input_3d.normalized()
			else:
				# Fallback to look_direction
				if not pawn_node.look_direction.is_zero_approx():
					direction = (pawn_node.look_direction - pawn_node.global_position).normalized()
		_:
			# Default: use look_direction or input_direction
			if not pawn_node.look_direction.is_zero_approx():
				direction = (pawn_node.look_direction - pawn_node.global_position).normalized()
			elif not pawn_node.input_direction.is_zero_approx():
				var input_3d = Vector3(pawn_node.input_direction.x, 0, pawn_node.input_direction.y)
				direction = input_3d.normalized()
	
	# Ensure direction is not zero
	if direction.is_zero_approx():
		direction = Vector3.FORWARD
	
	return direction.normalized()

## Update visual feedback for zip zone and available points.
## Shows/hides zip zone visual and updates shader parameters.
## [br][br]
## [param delta] Time elapsed since last frame (unused but kept for signature)
func _update_zip_visuals() -> void:
	if not is_instance_valid(_zip_zone):
		return
	
	# Show/hide zip zone visual based on zip mode
	var visual = _zip_zone.get_node_or_null("visual")
	if visual:
		visual.visible = in_zip_mode

## Check if zip state should be cleared.
## Returns true when pawn should exit zipped state (ground contact, jump, dash, etc.).
## [br][br]
## Critical state management:
## - Clears when pawn touches ground
## - Clears when jump is initiated
## - Clears when dash is initiated
## - Allows external systems to trigger clear via conditions
## [br][br]
## [return] True if zip state should be cleared, false otherwise
func _should_clear_zip() -> bool:
	# Get jump and dash actions to check their buffers
	var jump_action = pawn_node.get_node_or_null("state/JumpAction3D") as JumpPawnAction3D
	var dash_action = pawn_node.get_node_or_null("state/DashAction3D") as DashPawnAction3D
	
	# Clear on ground contact
	if pawn_node._on_ground:
		return true
	
	# Clear on jump input - check if pawn wants to jump
	if pawn_node.want_jump:
		return true
	
	# Clear on dash input - check if pawn wants to dash
	if pawn_node.want_dash:
		return true
	
	# Alternative: check action buffers if available (using get() for safety)
	if jump_action:
		var jump_buffer = jump_action.get("buffer")
		if jump_buffer is Buffer and jump_buffer.should_run_action():
			return true
	
	if dash_action:
		var dash_buffer = dash_action.get("buffer")
		if dash_buffer is Buffer and dash_buffer.should_run_action():
			return true
	
	return false

## Clear zip state and reset all zip-related variables.
## Hides visual feedback, resets state flags, and clears zip node reference.
## [br][br]
## Critical cleanup:
## - Hides zip point visual indicator
## - Resets all state flags (zipping, zipped, in_zip_mode)
## - Clears zip node reference
## - Should be called when exiting zip state
func clear_zip() -> void:
	if is_instance_valid(zip_node):
		zip_node.img.hide()
	zip_node = null
	zipping = false
	zipped = false
	in_zip_mode = false

## Additional processing called every frame regardless of action state.
## Handles zip state clearing when zip is disabled or conditions change.
## [br][br]
## [param delta] Time elapsed since last frame
func _additional(delta: float) -> void:
	# Clear zip if disabled or on ground when not in zip mode
	if not zip_enabled or (pawn_node._on_ground and not in_zip_mode):
		clear_zip()
