## DrawOnUI - Unified screen-space visual direction indicator for 2D and 3D navigation.
##
## This component creates a visual waypoint that shows direction to its parent position in 2D or 3D space.
## The waypoint is always visible on screen - either at its world position (if on screen) or on the screen edge
## pointing toward its direction (if off screen). Uses CanvasItem-based visualization with multiple nodes support.
## Automatically detects 2D/3D mode and updates position calculations for smooth navigation guidance.
## [br][br]
## [codeblock]
## # Basic usage:
## var draw_ui = DrawOnUI.new()
## draw_ui.screen_offset = Vector2(0, -30)
## draw_ui.screen_margin = 40.0
## draw_ui.max_distance = 1000.0
## draw_ui.fade_distance = 100.0
##
## # Add visual nodes (Sprite2D, Label, etc.) as children
## var icon = Sprite2D.new()
## icon.texture = preload("res://icon.png")
## draw_ui.add_child(icon)
##
## # Attach to a Node2D or Node3D parent
## some_node_2d.add_child(draw_ui)  # or some_node_3d.add_child(draw_ui)
##
## # Connect to signals
## draw_ui.became_visible.connect(_on_waypoint_visible)
## draw_ui.became_hidden.connect(_on_waypoint_hidden)
## draw_ui.out_of_bounds.connect(_on_waypoint_out_of_bounds)
## [/codeblock]

class_name DrawOnUI
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

@export var enabled:bool

## Maximum distance at which the waypoint is visible.
## Set to 0 for unlimited range. Waypoint will be hidden if target is beyond this distance.
@export var max_distance: float = 0.0

## Minimum distance before waypoint becomes fully opaque.
## Creates a fade-in effect as target approaches. Waypoint opacity increases as distance decreases.
@export var fade_distance: float = 50.0

## Vertical offset for the waypoint when target is on screen.
## Positive values move waypoint up, negative down. Applied only when target is visible on screen.
@export var screen_offset: Vector2 = Vector2(0, 0)

## Screen margin for off-screen waypoints (pixels from screen edge).
## When target is off screen, waypoint is positioned this many pixels from the screen edge.
@export var screen_margin: float = 0.0

## Force specific mode (2D or 3D). If AUTO, detects based on parent.
## AUTO mode automatically detects 2D/3D based on parent node type.
@export_enum("AUTO", "2D", "3D") var mode: String = "AUTO"

## Array of visual CanvasItem nodes for positioning.
## All CanvasItem children are automatically collected and positioned together.
var _nodes: Array[CanvasItem]

## Initial positions of visual nodes relative to this node.
## Used to maintain relative positioning when updating waypoint position.
var _nodes_initial_position: Array[Vector2]

## Current camera for screen space calculations (Camera2D or Camera3D).
## Cached reference to avoid repeated lookups. Updated automatically when camera changes.
var _camera: Node

## Cached mode detection result.
## True if operating in 3D mode, false for 2D mode.
var _is_3d: bool = false

## Cached parent reference for performance.
## Parent node whose position is being tracked.
var _parent: Node

## Previous visibility state for signal emission.
## Used to detect visibility changes and emit appropriate signals.
var _was_visible: bool = false

## Previous on-screen state for signal emission.
## Used to detect when waypoint moves from on-screen to off-screen edge positioning.
var _was_on_screen: bool = false

## Initialize the waypoint system and collect visual components.
## This method sets up the waypoint's screen-space visual elements, detects 2D/3D mode,
## and finds the active camera for screen space calculations.
## [br][br]
## Critical initialization steps:
## - Detects 2D/3D mode based on parent type or forced mode setting
## - Finds the appropriate camera (Camera2D or Camera3D)
## - Collects all CanvasItem children for positioning
## - Stores initial positions of visual elements
## - Initializes visibility state tracking
func _ready() -> void:
	_parent = get_parent()
	
	if _parent == null:
		push_error("DrawOnUI must have a parent node (Node2D or Node3D)")
		return

	# Detect mode if set to AUTO
	if mode == "AUTO":
		_is_3d = _parent is Node3D
	else:
		_is_3d = mode == "3D"

	# Find appropriate camera
	_update_camera()

	# Collect visual nodes
	for child in get_children():
		if child is CanvasItem:
			_nodes_initial_position.append(child.position)
			_nodes.append(child)
	
	# Initialize visibility state
	# Start as false to ensure proper signal emission on first update
	_was_visible = false
	_was_on_screen = false

## Update camera reference based on current mode.
## This method finds and caches the appropriate camera for screen calculations.
## Should be called when camera might have changed (e.g., scene transitions).
func _update_camera() -> void:
	if _is_3d:
		_camera = get_viewport().get_camera_3d()
	else:
		_camera = get_viewport().get_camera_2d()

## Calculate distance to target from camera position.
## Returns the distance in world units. Used for distance-based visibility and fading.
## [br][br]
## [return] Distance to target in world units, or 0.0 if calculation fails
func _get_distance_to_target() -> float:
	if _camera == null or _parent == null:
		return 0.0
	
	var camera_pos: Vector3
	var target_pos: Vector3
	
	if _is_3d:
		if _camera is Camera3D:
			camera_pos = _camera.global_position
		target_pos = _parent.global_position
	else:
		if _parent is Node2D and _camera is Camera2D:
			var cam_2d = _camera as Camera2D
			var target_2d = _parent as Node2D
			camera_pos = Vector3(cam_2d.global_position.x, cam_2d.global_position.y, 0)
			target_pos = Vector3(target_2d.global_position.x, target_2d.global_position.y, 0)
	
	return camera_pos.distance_to(target_pos)

## Calculate opacity based on distance and fade settings.
## Returns a value between 0.0 and 1.0 based on distance to target and fade_distance setting.
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
## [br][br]
## [param screen_pos] Screen position of target (may be outside viewport)
## [param viewport_size] Size of the viewport
## [return] Position on screen edge with margin applied
func _calculate_edge_position(screen_pos: Vector2, viewport_size: Vector2) -> Vector2:
	var center = viewport_size / 2.0
	var direction = (screen_pos - center).normalized()
# Calculate position on screen edge
	var edge_pos = center
	var half_width = viewport_size.x / 2 - screen_margin
	var half_height = viewport_size.y / 2 - screen_margin

	# Find intersection with screen edges
	var abs_x = abs(direction.x)
	var abs_y = abs(direction.y)

	if abs_x > 0.001 and abs_y > 0.001:  # Avoid division by zero
		# Calculate scale factors to reach each edge
		var scale_x = half_width / abs_x
		var scale_y = half_height / abs_y
		var _scale = min(scale_x, scale_y)

		# Position on the edge that would be hit first
		edge_pos = center + direction * _scale
	else:
		# Handle edge cases where direction is aligned with axes
		if abs_x > abs_y:
			edge_pos.x = center.x + half_width * sign(direction.x)
			edge_pos.y = center.y
		else:
			edge_pos.x = center.x
			edge_pos.y = center.y + half_height * sign(direction.y)

	# Clamp to screen margins
	edge_pos.x = clamp(edge_pos.x, screen_margin, viewport_size.x - screen_margin)
	edge_pos.y = clamp(edge_pos.y, screen_margin, viewport_size.y - screen_margin)
	return edge_pos

## Calculate rotation angle for off-screen waypoint pointing toward target.
## Returns angle in radians for rotating waypoint to point toward off-screen target.
## [br][br]
## [param screen_pos] Screen position of target
## [param edge_pos] Position of waypoint on screen edge
## [return] Rotation angle in radians
func _calculate_rotation_angle(screen_pos: Vector2, edge_pos: Vector2) -> float:
	var direction = (screen_pos - edge_pos).normalized()
	return direction.angle()

## Main update loop for waypoint screen-space positioning and visual updates.
## This method calculates target position in screen space, determines if target is visible,
## and positions waypoint accordingly (above target or on screen edge pointing toward target).
## Automatically handles both 2D and 3D modes with appropriate calculations.
## [br][br]
## Critical update operations:
## - Updates camera reference if needed
## - Calculates distance to target and checks max_distance limit
## - Calculates screen space position using appropriate projection
## - Determines visibility based on distance, screen bounds, and frustum (3D)
## - Positions waypoint on screen edge or above target for off-screen objects
## - Calculates rotation for off-screen waypoints
## - Applies opacity based on distance and fade settings
## - Handles visibility state changes and emits appropriate signals
## - Updates all visual nodes with proper positioning, rotation, and opacity
##
## [param delta] Time elapsed since last frame (unused but kept for _process signature)
func _process(_delta: float) -> void:
	if not enabled or _camera == null or _nodes.is_empty() or _parent == null:
		if visible:
			visible = false
			_was_visible = false
			became_hidden.emit()
		return

	# Update camera reference if needed
	if not is_instance_valid(_camera):
		_update_camera()
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

	var waypoint_pos: Vector3

	if _is_3d:
		if not (_parent is Node3D):
			return
		waypoint_pos = _parent.global_position
		if not (_camera is Camera3D):
			return
	else:
		if not (_parent is Node2D):
			return
		var wp_2d = (_parent as Node2D).global_position
		waypoint_pos = Vector3(wp_2d.x, wp_2d.y, 0)

	# Calculate screen position based on mode
	var screen_pos_2d: Vector2
	var viewport_size = get_viewport().get_visible_rect().size

	if _is_3d:
		screen_pos_2d = (_camera as Camera3D).unproject_position(waypoint_pos)
	else:
		# For 2D, convert world position to screen space
		var wp_2d = (_parent as Node2D).global_position
		var cp_2d = (_camera as Camera2D).global_position
		screen_pos_2d = (wp_2d - cp_2d) * (_camera as Camera2D).zoom + viewport_size / 2

	# Check if waypoint is on screen
	var is_in_frustum = true
	if _is_3d:
		is_in_frustum = (_camera as Camera3D).is_position_in_frustum(waypoint_pos)

	var is_on_screen = (is_in_frustum and
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
		rotation_angle = _calculate_rotation_angle(screen_pos_2d, final_pos)-PI/2.0
		
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
			node.modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, opacity)
