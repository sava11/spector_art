## Waypoint2D - Screen-space visual direction indicator for 2D navigation.
##
## This component creates a visual waypoint that shows direction to its own position in 2D space.
## The waypoint is always visible on screen - either at its world position (if on screen) or on the screen edge
## pointing toward its direction (if off screen). Uses icon-based visualization.
## Automatically updates position calculations for smooth navigation guidance.
## [br][br]
## [codeblock]
## # Basic usage:
## var waypoint = Waypoint2D.new()
## waypoint.icon_color = Color.YELLOW
## waypoint.icon_texture = preload("res://objective_icon.png")
## waypoint.position = Vector2(100, 200)  # World position of the waypoint
## add_child(waypoint)
## [/codeblock]

class_name WayPoint2D
extends Node2D

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
@export var fade_distance: float = 50.0

## Vertical offset for the waypoint when target is on screen.
## Positive values move waypoint up, negative down.
@export var screen_offset: Vector2 = Vector2(0, -50):
	set(value):
		screen_offset = value
		_update_visual()

## Custom texture for the waypoint icon.
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_update_visual()

## Screen margin for off-screen waypoints (pixels from screen edge).
@export var screen_margin: float = 50.0


## CanvasLayer for screen-space rendering.
var _canvas_layer: CanvasLayer

## Icon sprite node for the waypoint.
var _icon: Sprite2D

## Current camera for screen space calculations.
var _camera: Camera2D

## Initialize the 2D waypoint system and create visual components.
## This method sets up the waypoint's screen-space icon visual element.
## [br][br]
## Critical initialization steps:
## - Creates CanvasLayer with icon sprite
## - Finds the active camera for screen space calculations
## - Sets up initial visual properties and colors
func _ready() -> void:
	_create_visual_elements()
	_update_visual()
	_find_camera()

## Main update loop for waypoint screen-space positioning and visual updates.
## This method calculates target position in screen space, determines if target is on screen,
## and positions waypoint accordingly (above target or on screen edge pointing toward target).
## [br][br]
## Critical update operations:
## - Calculates distance to target and screen space position
## - Determines if target is visible on screen
## - Positions waypoint on screen edge or above target
## - Handles visibility fading based on distance settings
## - Emits signals for distance and screen visibility changes
##
## [param delta] Time elapsed since last frame (unused but kept for _process signature)
func _process(_delta: float) -> void:
	if _camera == null or _icon == null:
		if _canvas_layer:
			_canvas_layer.visible = false
		return

	# Update camera reference if needed
	if _camera == null or not is_instance_valid(_camera):
		_find_camera()
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

	# Convert waypoint world position to screen space
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_pos = (waypoint_pos - camera_pos) / _camera.zoom + viewport_size / 2

	# Check if waypoint is on screen (within viewport bounds)
	var is_on_screen = (screen_pos.x >= 0 and screen_pos.x <= viewport_size.x and
					   screen_pos.y >= 0 and screen_pos.y <= viewport_size.y)

	var final_pos: Vector2

	if is_on_screen:
		# Position at the waypoint location with offset
		final_pos = screen_pos + screen_offset
		_icon.rotation = 0  # No rotation when on screen
	else:
		# Position on screen edge pointing toward waypoint
		var center = viewport_size / 2
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

		# Clamp to screen margins
		edge_pos.x = clamp(edge_pos.x, screen_margin, viewport_size.x - screen_margin)
		edge_pos.y = clamp(edge_pos.y, screen_margin, viewport_size.y - screen_margin)

		final_pos = edge_pos

		# Rotate icon to point toward waypoint
		var angle = atan2(direction.y, direction.x)
		_icon.rotation = angle

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
## - Creates icon sprite with proper setup
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
	if _icon == null:
		return

	# Apply color, size and texture
	_icon.texture = icon_texture
	_icon.scale = Vector2(size, size)
	_icon.modulate = icon_color

## Find the active camera in the scene for screen space calculations.
## This method searches for Camera2D nodes in the scene tree to determine
## the current viewport and camera settings for accurate screen positioning.
func _find_camera() -> void:
	# Try to find camera in current scene
	var tree = get_tree()
	if tree == null:
		return

	# Look for Camera2D in the scene
	var cameras = tree.get_nodes_in_group("camera")
	if cameras.size() > 0:
		_camera = cameras[0]
		return

	# Fallback: find any Camera2D
	var root = tree.get_root()
	_camera = _find_camera_recursive(root)

## Recursively search for Camera2D in the scene tree.
## [param node] The node to start searching from
## [return] Camera2D node if found, null otherwise
func _find_camera_recursive(node: Node) -> Camera2D:
	# Check current node
	if node is Camera2D and node.is_current():
		return node

	# Check children
	for child in node.get_children():
		var camera = _find_camera_recursive(child)
		if camera != null:
			return camera

	return null
