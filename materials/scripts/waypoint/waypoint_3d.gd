## Waypoint3D - Screen-space visual direction indicator for 3D navigation.
##
## This component creates a visual waypoint that shows direction to its own position in 3D space.
## The waypoint is always visible on screen - either at its world position (if on screen) or on the screen edge
## pointing toward its direction (if off screen). Uses icon-based visualization.
## Automatically updates position calculations for smooth 3D navigation guidance.
## [br][br]
## [codeblock]
## # Basic usage:
## var waypoint = Waypoint3D.new()
## waypoint.icon_color = Color.CYAN
## waypoint.icon_texture = preload("res://objective_3d_icon.png")
## waypoint.position = Vector3(10, 5, 20)  # World position of the waypoint
## add_child(waypoint)
## [/codeblock]

class_name WayPoint3D
extends Node3D

## Color of the waypoint icon.
@export var icon_color: Color = Color.WHITE:
	set(value):
		icon_color = value
		_update_visual()

## Size multiplier for the waypoint icon.
@export var size: float = 1.0:
	set(value):
		size = value
		_update_visual()

## Maximum distance at which the waypoint is visible.
## Set to 0 for unlimited range.
@export var max_distance: float = 0.0

## Minimum distance before waypoint becomes fully opaque.
## Creates a fade-in effect as target approaches.
@export var fade_distance: float = 0.0

## Vertical offset for the waypoint when target is on screen.
## Positive values move waypoint up, negative down.
@export var screen_offset: Vector2 = Vector2(0, 0):
	set(value):
		screen_offset = value
		_update_visual()

## Custom texture for the waypoint icon.
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_update_visual()

## Screen margin for off-screen waypoints (pixels from screen edge).
@export var screen_margin: float = 32.0


## CanvasLayer for screen-space rendering.
var _canvas_layer: CanvasLayer

## Icon sprite node for the waypoint.
var _icon: Sprite2D

## Current camera for screen space calculations.
var _camera: Camera3D

## Initialize the 3D waypoint system and create visual components.
## This method sets up the waypoint's screen-space icon visual element.
## [br][br]
## Critical initialization steps:
## - Creates CanvasLayer with Sprite2D for screen-space rendering
## - Finds the active camera for screen space calculations
## - Sets up initial visual properties and colors
func _ready() -> void:
	_create_visual_elements()
	_update_visual()
	# Look for Camera3D in the scene
	_camera = get_viewport().get_camera_3d()

## Main update loop for waypoint screen-space positioning and visual updates.
## This method calculates target position in screen space, determines if target is in camera frustum,
## and positions waypoint accordingly (above target or on screen edge pointing toward target).
## [br][br]
## Critical update operations:
## - Calculates distance to target and screen space position using 3D camera projection
## - Uses camera frustum checking for accurate visibility determination
## - Positions waypoint on screen edge or above target
## - Handles visibility fading based on distance settings
##
## [param delta] Time elapsed since last frame (unused but kept for _process signature)
func _process(_delta: float) -> void:
	if _camera == null or _icon == null:
		if _canvas_layer:
			_canvas_layer.visible = false
		return

	# Update camera reference if needed
	if _camera == null or not is_instance_valid(_camera):
		# Look for Camera3D in the scene
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			if _canvas_layer:
				_canvas_layer.visible = false
			return

	var waypoint_pos = global_position
	var camera_pos = _camera.global_position
	var distance = (waypoint_pos - camera_pos).length()

	# Check visibility based on max_distance
	var should_be_visible = max_distance <= 0.0 or distance <= max_distance
	if _canvas_layer:
		_canvas_layer.visible = should_be_visible

	if not should_be_visible:
		return

	# Project 3D position to screen space
	var viewport = get_viewport()
	if viewport == null:
		return

	var screen_pos_2d = _camera.unproject_position(waypoint_pos)
	var viewport_size = viewport.get_visible_rect().size

	# Check if waypoint is in camera frustum (visible area)
	var is_in_frustum = _camera.is_position_in_frustum(waypoint_pos)
	var is_on_screen = (is_in_frustum and
					   screen_pos_2d.x >= 0 and screen_pos_2d.x <= viewport_size.x and
					   screen_pos_2d.y >= 0 and screen_pos_2d.y <= viewport_size.y)

	var final_pos: Vector2

	if is_on_screen:
		# Position at the waypoint location with offset
		final_pos = screen_pos_2d + screen_offset
		_icon.rotation = 0  # No rotation when on screen
	else:
		# Position on screen edge pointing toward waypoint
		var center = viewport_size / 2

		# For off-screen waypoints, calculate direction from center to screen position
		var direction: Vector2
		if is_in_frustum:
			# Object is in frustum but off-screen
			direction = (screen_pos_2d - center).normalized()
		else:
			# Object is outside frustum, calculate direction in camera space
			var to_waypoint = waypoint_pos - camera_pos

			# Transform direction to camera local space (X=right, Y=up, Z=forward)
			var camera_transform = _camera.global_transform
			var local_direction = camera_transform.basis.inverse() * to_waypoint

			# Use X and Y components for screen direction
			# Keep 3D coordinates for now, will handle screen inversion in rotation
			var screen_dir = Vector2(local_direction.x, local_direction.y)
			if screen_dir.length() > 0:
				direction = screen_dir.normalized()*Vector2(1,-1)
			else:
				# Fallback if waypoint is exactly at camera position
				direction = Vector2.UP

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

		final_pos = edge_pos

		# Rotate icon to point toward waypoint
		# Invert Y for screen coordinates (screen has Y growing downward)
		var angle = -atan2(direction.y, -direction.x)
		_icon.rotation = angle+PI/2.0

	# Apply final position
	_icon.position = final_pos

	# Handle fade-in effect
	var alpha = 1.0
	if fade_distance > 0.0 and distance < fade_distance:
		alpha = distance / fade_distance
	_icon.modulate.a = alpha

## Create the visual elements for the waypoint icon.
## This method initializes CanvasLayer with Sprite2D for screen-space waypoint visualization.
## [br][br]
## Critical visual element creation:
## - Creates CanvasLayer for screen-space rendering
## - Creates icon sprite with proper setup for 2D screen display
## - Sets initial color and size
func _create_visual_elements() -> void:
	# Create CanvasLayer for screen-space rendering
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "CanvasLayer"
	add_child(_canvas_layer)

	# Create icon visual as Sprite2D
	_icon = Sprite2D.new()
	_icon.name = "Icon"
	_icon.centered = true  # Center the sprite for proper rotation
	_canvas_layer.add_child(_icon)


## Update visual elements based on current properties.
## This method refreshes the icon visual component with current settings.
## [br][br]
## Critical visual updates:
## - Applies color, size, and texture settings to icon
## - Updates icon modulation for proper rendering
func _update_visual() -> void:
	if _icon == null: return

	# Apply color, size and texture
	_icon.texture = icon_texture
	_icon.scale = Vector2(size, size)
	_icon.modulate = icon_color
