## DrawOnUI3D - Screen-space visual direction indicator for 3D navigation.
##
## This component creates a visual waypoint that shows direction to its parent position in 3D space.
## The waypoint is always visible on screen - either at its world position (if on screen) or on the screen edge
## pointing toward its direction (if off screen). Uses CanvasItem-based visualization with multiple nodes support.
## Automatically updates position calculations for smooth 3D navigation guidance.
## [br][br]
## [codeblock]
## # Basic usage:
## var draw_ui = DrawOnUI3D.new()
## draw_ui.screen_offset = Vector2(0, -30)
## draw_ui.screen_margin = 40.0
##
## # Add visual nodes (Sprite2D, Label, etc.) as children
## var icon = Sprite2D.new()
## icon.texture = preload("res://icon.png")
## draw_ui.add_child(icon)
##
## # Attach to a Node3D parent
## some_node_3d.add_child(draw_ui)
##
## # Connect to signals
## draw_ui.became_visible.connect(_on_waypoint_visible)
## draw_ui.became_hidden.connect(_on_waypoint_hidden)
## draw_ui.out_of_bounds.connect(_on_waypoint_out_of_bounds)
## [/codeblock]

class_name DrawOnUI3D
extends CanvasLayer

## Emitted when waypoint becomes visible on screen.
signal became_visible

## Emitted when waypoint becomes hidden (off screen or out of range).
signal became_hidden

## Emitted when waypoint is positioned outside screen bounds (on edge).
signal out_of_bounds

## Emitted when waypoint position changes.
## [param new_position] New screen position of the waypoint
signal position_changed(new_position: Vector2)

## Vertical offset for the waypoint when target is on screen.
## Positive values move waypoint up, negative down. Applied only when target is visible on screen.
@export var screen_offset: Vector2 = Vector2(0, -50)

## Screen margin for off-screen waypoints (pixels from screen edge).
## When target is off screen, waypoint is positioned this many pixels from the screen edge.
@export var screen_margin: float = 50.0

## Maximum distance at which the waypoint is visible.
## Set to 0 for unlimited range. Waypoint will be hidden if target is beyond this distance.
@export var max_distance: float = 0.0

## Minimum distance before waypoint becomes fully opaque.
## Creates a fade-in effect as target approaches. Waypoint opacity increases as distance decreases.
@export var fade_distance: float = 50.0

## Array of visual CanvasItem nodes for positioning.
## All CanvasItem children are automatically collected and positioned together.
var _nodes: Array[CanvasItem]

## Initial positions of visual nodes relative to this node.
## Used to maintain relative positioning when updating waypoint position.
var _nodes_initial_position: Array[Vector2]

## Current camera for screen space calculations.
## Cached reference to avoid repeated lookups. Updated automatically when camera changes.
var _camera: Camera3D

## Previous visibility state for signal emission.
## Used to detect visibility changes and emit appropriate signals.
var _was_visible: bool = false

## Previous on-screen state for signal emission.
## Used to detect when waypoint moves from on-screen to off-screen edge positioning.
var _was_on_screen: bool = false

## Initialize the 3D waypoint system and collect visual components.
## This method sets up the waypoint's screen-space visual elements and finds the active camera.
## [br][br]
## Critical initialization steps:
## - Finds the active Camera3D for screen space calculations
## - Collects all CanvasItem children for positioning
## - Stores initial positions of visual elements
## - Initializes visibility state tracking
func _ready() -> void:
	# Validate parent is Node3D
	if not (get_parent() is Node3D):
		push_error("DrawOnUI3D must have a Node3D parent")
		return
	
	# Look for Camera3D in the scene
	_camera = get_viewport().get_camera_3d()
	
	if _camera == null:
		push_warning("DrawOnUI3D: No Camera3D found in viewport")
	
	# Collect visual nodes
	for child in get_children():
		if child is CanvasItem:
			_nodes_initial_position.append(child.position)
			_nodes.append(child)
	
	# Initialize visibility state
	# Start as false to ensure proper signal emission on first update
	_was_visible = false
	_was_on_screen = false

## Calculate distance to target from camera position.
## Returns the distance in world units. Used for distance-based visibility and fading.
## Uses Vector3 distance calculation for accurate 3D space measurements.
## [br][br]
## Critical distance calculation:
## - Calculates Vector3 distance between camera and target global positions
## - Returns 0.0 if camera or parent is invalid or not Node3D
## [br][br]
## [return] Distance to target in world units, or 0.0 if calculation fails
func _get_distance_to_target() -> float:
	if _camera == null or get_parent() == null:
		return 0.0
	
	if not (get_parent() is Node3D):
		return 0.0
	
	var camera_pos = _camera.global_position
	var target_pos = (get_parent() as Node3D).global_position
	
	return camera_pos.distance_to(target_pos)

## Calculate opacity based on distance and fade settings.
## Returns a value between 0.0 and 1.0 based on distance to target and fade_distance setting.
## Creates smooth fade-in effect as target approaches camera.
## [br][br]
## Opacity calculation:
## - If fade_distance <= 0: Always returns 1.0 (fully opaque)
## - If distance >= fade_distance: Returns 1.0 (fully opaque)
## - Otherwise: Linear interpolation from 0.0 to 1.0 based on distance
## [br][br]
## [return] Opacity value from 0.0 (transparent) to 1.0 (opaque)
func _calculate_opacity() -> float:
	if fade_distance <= 0.0:
		return 1.0
	
	var distance = _get_distance_to_target()
	if distance >= fade_distance:
		return 1.0
	
	# Linear fade from 0 to 1 as distance decreases
	return distance / fade_distance

## Calculate position on screen edge pointing toward off-screen target.
## When target is off screen, positions waypoint on the nearest screen edge pointing toward target.
## Handles all camera angles including vertical orientations correctly.
## [br][br]
## Critical edge calculation:
## - Uses normalized direction from screen center to target screen position
## - Calculates intersection with screen edges using aspect ratio-aware scaling
## - Handles edge cases for horizontal/vertical alignment
## - Applies screen margin to keep waypoint visible
## [br][br]
## [param screen_pos] Screen position of target (may be outside viewport)
## [param viewport_size] Size of the viewport
## [return] Position on screen edge with margin applied
func _calculate_edge_position(screen_pos: Vector2, viewport_size: Vector2) -> Vector2:
	var center = viewport_size / 2.0
	var direction = (screen_pos - center)
	
	# Handle zero direction case
	if direction.length_squared() < 0.0001:
		return center
	
	direction = direction.normalized()
	
	# Calculate position on screen edge
	var edge_pos = center
	var half_width = viewport_size.x / 2.0 - screen_margin
	var half_height = viewport_size.y / 2.0 - screen_margin

	# Find intersection with screen edges using aspect ratio-aware calculation
	var abs_x = abs(direction.x)
	var abs_y = abs(direction.y)

	if abs_x > 0.0001 and abs_y > 0.0001:  # Avoid division by zero
		# Calculate scale factors to reach each edge
		# This handles vertical camera angles correctly
		var scale_x = half_width / abs_x
		var scale_y = half_height / abs_y
		var scale = min(scale_x, scale_y)

		# Position on the edge that would be hit first
		edge_pos = center + direction * scale
	else:
		# Handle edge cases where direction is aligned with axes
		if abs_x > abs_y:
			edge_pos.x = center.x + half_width * sign(direction.x)
			edge_pos.y = center.y
		else:
			edge_pos.x = center.x
			edge_pos.y = center.y + half_height * sign(direction.y)

	# Clamp to screen margins to ensure waypoint stays visible
	edge_pos.x = clamp(edge_pos.x, screen_margin, viewport_size.x - screen_margin)
	edge_pos.y = clamp(edge_pos.y, screen_margin, viewport_size.y - screen_margin)
	return edge_pos

## Calculate rotation angle for off-screen waypoint pointing toward target.
## Returns angle in radians for rotating waypoint to point toward off-screen target.
## Adjusts angle by -PI/2 to account for sprite orientation (pointing up by default).
## [br][br]
## [param screen_pos] Screen position of target
## [param edge_pos] Position of waypoint on screen edge
## [return] Rotation angle in radians (adjusted for sprite orientation)
func _calculate_rotation_angle(screen_pos: Vector2, edge_pos: Vector2) -> float:
	var direction = (screen_pos - edge_pos)
	if direction.length_squared() < 0.0001:
		return 0.0
	direction = direction.normalized()
	return direction.angle() - PI / 2.0

## Main update loop for waypoint screen-space positioning and visual updates.
## This method calculates target position in screen space, determines if target is in camera frustum,
## and positions waypoint accordingly (above target or on screen edge pointing toward target).
## [br][br]
## Critical update operations:
## - Validates camera, nodes, and parent before processing
## - Updates camera reference if needed (handles camera changes dynamically)
## - Calculates distance to target and checks max_distance limit
## - Checks if target is in front of camera (prevents reverse display bug)
## - Calculates screen space position using 3D camera projection
## - Uses camera frustum checking for accurate visibility determination
## - Handles targets behind camera by calculating world-space direction projection
## - Positions waypoint on screen edge or above target for off-screen objects
## - Calculates rotation for off-screen waypoints pointing toward target
## - Applies opacity based on distance and fade settings
## - Handles visibility state changes and emits appropriate signals
## - Updates all visual nodes with proper positioning, rotation, and opacity
## [br][br]
## Fixes reverse display issue:
## - Detects when target is behind camera using dot product with camera forward
## - Projects world-space direction to screen space for correct edge positioning
## - Prevents waypoint from appearing on opposite side when target is far away
## [br][br]
## [param delta] Time elapsed since last frame (unused but kept for _process signature)
func _process(_delta: float) -> void:
	if _camera == null or _nodes.is_empty():
		if visible:
			visible = false
			_was_visible = false
			became_hidden.emit()
		return

	# Validate parent
	if not (get_parent() is Node3D):
		if visible:
			visible = false
			_was_visible = false
			became_hidden.emit()
		return

	# Update camera reference if needed
	if not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			if visible:
				visible = false
				_was_visible = false
				became_hidden.emit()
			return

	# Check distance limit
	if max_distance > 0.0:
		var distance = _get_distance_to_target()
		if distance > max_distance:
			if visible:
				visible = false
				_was_visible = false
				became_hidden.emit()
			return

	# Get waypoint position from parent Node3D
	var waypoint_pos = (get_parent() as Node3D).global_position

	# Project 3D position to screen space
	var viewport = get_viewport()
	if viewport == null:
		return

	var viewport_size = viewport.get_visible_rect().size
	
	# Check if target is in front of camera to prevent reverse display
	# This fixes the issue where objects behind camera appear on opposite side
	var camera_forward = -_camera.global_transform.basis.z
	var camera_to_target = (waypoint_pos - _camera.global_position).normalized()
	var dot_product = camera_forward.dot(camera_to_target)
	
	# Target is behind camera if dot product is negative
	var is_behind_camera = dot_product < 0.0
	
	var screen_pos_2d: Vector2
	if is_behind_camera:
		# Calculate direction from camera to target in world space
		# Project this direction onto screen to get correct edge position
		var world_direction = (waypoint_pos - _camera.global_position).normalized()
		var center_screen = viewport_size / 2.0
		
		# Calculate screen-space direction from world direction
		# Use camera's basis vectors to convert world direction to screen space
		var right_world = _camera.global_transform.basis.x
		var up_world = _camera.global_transform.basis.y
		var screen_dir_x = world_direction.dot(right_world)
		var screen_dir_y = -world_direction.dot(up_world)  # Negative because screen Y is inverted
		
		# Create screen position based on direction from center
		# Use max viewport dimension to ensure position is off-screen
		var max_dimension = max(viewport_size.x, viewport_size.y)
		screen_pos_2d = center_screen + Vector2(screen_dir_x, screen_dir_y) * max_dimension * 2.0
	else:
		screen_pos_2d = _camera.unproject_position(waypoint_pos)

	# Check if waypoint is in camera frustum (visible area)
	# If behind camera, always treat as off-screen
	var is_in_frustum = _camera.is_position_in_frustum(waypoint_pos)
	var is_on_screen = (not is_behind_camera and is_in_frustum and
						screen_pos_2d.x >= 0 and screen_pos_2d.x <= viewport_size.x and
						screen_pos_2d.y >= 0 and screen_pos_2d.y <= viewport_size.y)

	var final_pos: Vector2
	var rotation_angle: float = 0.0
	var opacity: float = 1.0

	if is_on_screen:
		# Position at the waypoint location with offset
		final_pos = screen_pos_2d + screen_offset
		rotation_angle = 0.0
		
		# Check if state changed from off-screen to on-screen
		if not _was_on_screen:
			_was_on_screen = true
	else:
		# Position on screen edge pointing toward target
		final_pos = _calculate_edge_position(screen_pos_2d, viewport_size)
		rotation_angle = _calculate_rotation_angle(screen_pos_2d, final_pos)
		
		# Check if state changed from on-screen to off-screen
		if _was_on_screen:
			_was_on_screen = false
			out_of_bounds.emit()

	# Calculate opacity based on distance
	opacity = _calculate_opacity()

	# Update visibility state and emit signals
	# Waypoint should be visible if we reached this point (all checks passed)
	if not visible:
		visible = true
		if not _was_visible:
			_was_visible = true
			became_visible.emit()

	# Emit position change signal
	if position_changed.get_connections().size() > 0:
		position_changed.emit(final_pos)

	# Apply final position, rotation, and opacity to all nodes
	for i in _nodes.size():
		var node := _nodes[i]
		if not is_instance_valid(node):
			continue
		
		node.position = final_pos + _nodes_initial_position[i]
		
		if node is Node2D:
			(node as Node2D).rotation = rotation_angle
		
		if node is CanvasItem:
			var base_modulate = node.modulate
			node.modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, base_modulate.a * opacity)
