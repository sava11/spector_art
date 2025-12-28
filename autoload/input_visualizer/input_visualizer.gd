extends Node

## Input Visualizer - System for displaying input device-specific button names and images.
##
## This system automatically detects the current input device (keyboard/mouse or gamepad)
## and provides localized button names and images for different gamepad brands
## (xBox, PlayStation, Nintendo, PC). Used by UI systems to show context-sensitive
## control hints to players with proper platform-specific labels and visual prompts.
##
## [codeblock]
## # Basic usage:
## InputMonitor.action_to_key("jump")  # Returns "A" on xBox, "Cross" on PlayStation
## InputMonitor.action_to_button_image("jump")  # Returns SVG path for visual prompts
##
## # Connect to device changes for UI updates
## InputMonitor.connect("input_changed", Callable(self, "_update_hints"))
## [/codeblock]

## Emitted when the input device changes (keyboard ↔ gamepad).
signal input_changed

## Current input device ID. 0 = keyboard/mouse, >0 = gamepad device ID.
var device_id: int = 0

## Current device platform name ("Keyboard", "xBox", "PlayStation", "Nintendo", "Unknown").
var device_name: String = "Keyboard"

## Platform-specific button mappings with display names and image paths.
## Maps SDL button indices to localized names and SVG image paths for different platforms.
## Ensures correct button labels (A/B/X/Y vs Cross/Circle/Square/Triangle) and provides
## visual button prompts for rich UI experiences.
const BUTTON_NAMES := {
	"xBox": {
		0: {"text": "A", "image": "res://autoload/input_visualizer/xBox/a.svg"},
		1: {"text": "B", "image": "res://autoload/input_visualizer/xBox/b.svg"},
		2: {"text": "X", "image": "res://autoload/input_visualizer/xBox/x.svg"},
		3: {"text": "Y", "image": "res://autoload/input_visualizer/xBox/y.svg"},
		4: {"text": "Back", "image": "res://autoload/input_visualizer/xBox/back.svg"},
		5: {"text": "Guide", "image": "res://autoload/input_visualizer/xBox/guide.svg"},
		6: {"text": "Start", "image": "res://autoload/input_visualizer/xBox/start.svg"},
		7: {"text": "L3", "image": "res://autoload/input_visualizer/xBox/l3.svg"},
		8: {"text": "R3", "image": "res://autoload/input_visualizer/xBox/r3.svg"},
		9: {"text": "LB", "image": "res://autoload/input_visualizer/xBox/lb.svg"},
		10: {"text": "RB", "image": "res://autoload/input_visualizer/xBox/rb.svg"},
		11: {"text": "Up", "image": "res://autoload/input_visualizer/xBox/up.svg"},
		12: {"text": "Down", "image": "res://autoload/input_visualizer/xBox/down.svg"},
		13: {"text": "Left", "image": "res://autoload/input_visualizer/xBox/left.svg"},
		14: {"text": "Right", "image": "res://autoload/input_visualizer/xBox/right.svg"}
	},
	"PlayStation": {
		0: {"text": "Cross", "image": "res://autoload/input_visualizer/PlayStation/cross.svg"},
		1: {"text": "Circle", "image": "res://autoload/input_visualizer/PlayStation/circle.svg"},
		2: {"text": "Square", "image": "res://autoload/input_visualizer/PlayStation/square.svg"},
		3: {"text": "Triangle", "image": "res://autoload/input_visualizer/PlayStation/triangle.svg"},
		4: {"text": "Share", "image": "res://autoload/input_visualizer/PlayStation/share.svg"},
		5: {"text": "PS", "image": "res://autoload/input_visualizer/PlayStation/ps.svg"},
		6: {"text": "Options", "image": "res://autoload/input_visualizer/PlayStation/options.svg"},
		7: {"text": "L3", "image": "res://autoload/input_visualizer/PlayStation/l3.svg"},
		8: {"text": "R3", "image": "res://autoload/input_visualizer/PlayStation/r3.svg"},
		9: {"text": "L1", "image": "res://autoload/input_visualizer/PlayStation/l1.svg"},
		10: {"text": "R1", "image": "res://autoload/input_visualizer/PlayStation/r1.svg"},
		11: {"text": "Up", "image": "res://autoload/input_visualizer/PlayStation/up.svg"},
		12: {"text": "Down", "image": "res://autoload/input_visualizer/PlayStation/down.svg"},
		13: {"text": "Left", "image": "res://autoload/input_visualizer/PlayStation/left.svg"},
		14: {"text": "Right", "image": "res://autoload/input_visualizer/PlayStation/right.svg"}
	},
	"Nintendo": {
		0: {"text": "B", "image": "res://autoload/input_visualizer/Nintendo/b.svg"},
		1: {"text": "A", "image": "res://autoload/input_visualizer/Nintendo/a.svg"},
		2: {"text": "Y", "image": "res://autoload/input_visualizer/Nintendo/y.svg"},
		3: {"text": "X", "image": "res://autoload/input_visualizer/Nintendo/x.svg"},
		4: {"text": "-", "image": "res://autoload/input_visualizer/Nintendo/minus.svg"},
		5: {"text": "Home", "image": "res://autoload/input_visualizer/Nintendo/home.svg"},
		6: {"text": "+", "image": "res://autoload/input_visualizer/Nintendo/plus.svg"},
		7: {"text": "LStick", "image": "res://autoload/input_visualizer/Nintendo/lstick.svg"},
		8: {"text": "RStick", "image": "res://autoload/input_visualizer/Nintendo/rstick.svg"},
		9: {"text": "L", "image": "res://autoload/input_visualizer/Nintendo/l.svg"},
		10: {"text": "R", "image": "res://autoload/input_visualizer/Nintendo/r.svg"},
		11: {"text": "Up", "image": "res://autoload/input_visualizer/Nintendo/up.svg"},
		12: {"text": "Down", "image": "res://autoload/input_visualizer/Nintendo/down.svg"},
		13: {"text": "Left", "image": "res://autoload/input_visualizer/Nintendo/left.svg"},
		14: {"text": "Right", "image": "res://autoload/input_visualizer/Nintendo/right.svg"}
	},
	"Unknown": {}  # Fallback - uses raw SDL numbering
}


## Processes input events to automatically detect the current input device.
## Monitors all input events and updates device tracking when keyboard or gamepad input is detected.
## Only emits [signal input_changed] when the device actually changes to prevent UI update spam.
##
## This enables dynamic UI updates for control hints and ensures players see relevant,
## platform-specific button prompts throughout the game.
##
## [param event] InputEvent from Godot's input system
func _input(event: InputEvent) -> void:
	var prev_device := device_id

	# CRITICAL: Gamepad detection with multi-device support
	# Device ID conversion: Godot uses 0-based, we use 1-based (0 = keyboard)
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		device_id = event.device + 1
		_detect_device_type(event.device)  # Platform-specific detection
	# Keyboard/Mouse detection - most common input type
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		device_id = 0
		device_name = "Keyboard"
	else:
		return  # Ignore other input types (touch, custom events, etc.)

	# SIGNAL EMISSION: Only when device changes to prevent UI update spam
	# Integration: Connected to UI systems that display control hints
	if device_id != prev_device:
		input_changed.emit()  # Triggers UI updates across the game

## Detects the platform type of a connected gamepad using its GUID.
## Analyzes the gamepad's Globally Unique Identifier to determine if it's xBox, PlayStation,
## Nintendo, or unknown. This ensures proper button localization and correct labels for players.
##
## [br][br]
## [b]Supported Platforms:[/b]
## - xBox: Microsoft controllers (including third-party)
## - PlayStation: Sony DualSense, DualShock, etc.
## - Nintendo: Switch Pro Controller, Joy-Con, etc.
##
## [param device_index] Raw Godot device index (0-based, from Input.get_connected_joypads())
func _detect_device_type(device_index: int) -> void:
	# CRITICAL: Bounds checking prevents crashes with invalid device indices
	if device_index < 0 or device_index >= Input.get_connected_joypads().size():
		device_name = "Unknown"
		return

	var guid := Input.get_joy_guid(device_index).to_lower()

	# PATTERN MATCHING: Platform detection with specificity priority
	# Order matters: More specific patterns checked before generic ones
	if guid.contains("xBox") or guid.contains("xinput"):
		device_name = "xBox"  # Microsoft ecosystem
	elif guid.contains("playstation") or guid.contains("ps4") or guid.contains("ps5") or guid.contains("dualshock"):
		device_name = "PlayStation"  # Sony ecosystem
	elif guid.contains("Nintendo") or guid.contains("pro_controller") or guid.contains("joycon"):
		device_name = "Nintendo"  # Nintendo ecosystem
	else:
		device_name = "Unknown"  # Fallback for unsupported controllers

## Converts an input action name to a localized button/key name based on current device.
## This is the primary API method for displaying control hints in UI systems.
## Returns platform-specific button names (A/B/X/Y vs Cross/Circle/Square/Triangle).
##
## Uses a two-pass lookup system: first tries device-specific events, then falls back
## to any available event. Returns "Undefined" for invalid actions instead of crashing.
##
## [br][br]
## [codeblock]
## # Examples:
## action_to_key("jump")  # Returns "A" on xBox, "Cross" on PlayStation, "Space" on keyboard
## action_to_key("attack") # Returns "X" on xBox, "Square" on PlayStation
## [/codeblock]
##
## [param action_name] Input action name from Project Settings -> Input Map
## [return] Localized button/key name, or "Undefined" if action not found
func action_to_key(action_name: String) -> String:
	var events := InputMap.action_get_events(action_name)

	# CRITICAL: Input validation prevents crashes from invalid action names
	if events.is_empty():
		push_warning("InputMonitor: Action '%s' not found in InputMap" % action_name)
		return "Undefined"

	# PRIMARY PASS: Device-specific lookup for optimal user experience
	if device_id == 0:  # Keyboard/Mouse mode
		for event in events:
			if event is InputEventKey:
				return _get_key_display_name(event)  # Clean key formatting
	else:  # Gamepad mode - use platform-specific button names
		for event in events:
			if event is InputEventJoypadButton:
				return _joy_button_name(event.button_index)  # Localized button names

	# FALLBACK PASS: Ensure we always return something usable
	# Critical for mixed input configurations (keyboard + gamepad actions)
	for event in events:
		if device_id == 0 and event is InputEventKey:
			return _get_key_display_name(event)
		elif device_id != 0 and event is InputEventJoypadButton:
			return _joy_button_name(event.button_index)

	return "Undefined"

## Converts raw SDL button index to platform-specific button name.
## Returns localized button names ensuring players see correct labels for their platform:
## xBox (A, B, X, Y, LB, RB), PlayStation (Cross, Circle, Square, Triangle, L1, R1),
## Nintendo (A, B, X, Y, L, R), etc.
##
## Falls back to SDL-standard description ("Button 0", "Button 1", etc.) for unmapped buttons.
##
## [param button_idx] SDL button index (0-14 typically, matches standard gamepad layout)
## [return] Localized button name or fallback SDL description if unmapped
func _joy_button_name(button_idx: int) -> String:
	var names_dict = BUTTON_NAMES.get(device_name, {})

	# PRIMARY PATH: Check for platform-specific mapped name
	if names_dict.has(button_idx):
		var button_data = names_dict[button_idx]
		if button_data is Dictionary and button_data.has("text"):
			return button_data["text"]  # Localized button name (A, B, Cross, Circle, etc.)
		# LEGACY: Support old string-only format during migration
		return str(button_data)

	# FALLBACK PATH: Generate SDL-standard description for unmapped buttons
	# CRITICAL: Must set button_index before calling as_text() to get correct name
	var fallback_event := InputEventJoypadButton.new()
	return fallback_event.as_text()  # Returns "Button 0", "Button 1", etc.

## Formats keyboard key names for clean UI display.
## Removes unnecessary suffixes like "(Physical)" and "(Unicode)" to ensure
## readable key names in UI prompts (e.g., "Space" instead of "Space (Physical)").
##
## [param key_event] InputEventKey to format
## [return] Clean key name suitable for UI display
func _get_key_display_name(key_event: InputEventKey) -> String:
	var full_text := key_event.as_text()
	# Remove common suffixes that clutter the display
	var suffixes_to_remove := [" (Physical)", " (Unicode)"]
	for suffix in suffixes_to_remove:
		if full_text.ends_with(suffix):
			return full_text.substr(0, full_text.length() - suffix.length())
	return full_text

## Converts an input action name to a button image path based on current device.
## This is the visual counterpart to [method action_to_key] - returns SVG image paths
## instead of text for rich, visual input prompts.
##
## Uses platform-specific subdirectories (xBox/, PlayStation/, Nintendo/, PC/) with
## SVG format for crisp scaling. File naming matches button names (a.svg, cross.svg, space.svg, etc.).
##
## [br][br]
## [codeblock]
## # Load and use button image:
## var image_path = InputMonitor.action_to_button_image("jump")
## if image_path:
##     var texture = load(image_path)
##     button_sprite.texture = texture
## [/codeblock]
##
## [param action_name] Input action name from Project Settings -> Input Map
## [return] Full image path string, or empty string if unavailable
func action_to_button_image(action_name: String) -> String:
	var events := InputMap.action_get_events(action_name)
	# CRITICAL: Input validation prevents crashes from invalid actions
	if events.is_empty():
		push_warning("InputMonitor: Action '%s' not found in InputMap" % action_name)
		return ""

	# PRIMARY PASS: Device-specific image lookup
	if device_id == 0:  # Keyboard/Mouse mode
		for event in events:
			if event is InputEventKey:
				return _get_key_image_path(event)  # PC key images
	else:  # Gamepad mode
		for event in events:
			if event is InputEventJoypadButton:
				return _joy_button_image(event.button_index)  # Platform-specific images

	# FALLBACK PASS: Ensure we return something usable for mixed configurations
	for event in events:
		if device_id == 0 and event is InputEventKey:
			return _get_key_image_path(event)
		elif device_id != 0 and event is InputEventJoypadButton:
			return _joy_button_image(event.button_index)
	return ""  # Graceful degradation - no image available

## Converts SDL button index to platform-specific button image path.
## Returns SVG image paths for visual button prompts.
##
## [param button_idx] SDL button index (0-14 typically)
## [return] Image path string or empty string if no image available
func joy_button_image(button_idx: int) -> String:
	return _joy_button_image(button_idx)

func _joy_button_image(button_idx: int) -> String:
	var names_dict = BUTTON_NAMES.get(device_name, {})

	# Check if we have image data for this button on current platform
	if names_dict.has(button_idx):
		var button_data = names_dict[button_idx]
		if button_data is Dictionary and button_data.has("image"):
			return button_data["image"]

	return ""

# Gets image path for keyboard key (PC platform)
func _get_key_image_path(key_event: InputEventKey) -> String:
	var key_name := _get_key_display_name(key_event).to_lower()
	# Map common key names to image files
	var key_mappings := {
		"space": "res://autoload/input_visualizer/PC/space.svg",
		"enter": "res://autoload/input_visualizer/PC/enter.svg",
		"escape": "res://autoload/input_visualizer/PC/escape.svg",
		"w": "res://autoload/input_visualizer/PC/w.svg",
		"a": "res://autoload/input_visualizer/PC/a.svg",
		"s": "res://autoload/input_visualizer/PC/s.svg",
		"d": "res://autoload/input_visualizer/PC/d.svg",
		"shift": "res://autoload/input_visualizer/PC/shift.svg",
		"ctrl": "res://autoload/input_visualizer/PC/ctrl.svg",
		"up": "res://autoload/input_visualizer/PC/up.svg",
		"down": "res://autoload/input_visualizer/PC/down.svg",
		"left": "res://autoload/input_visualizer/PC/left.svg",
		"right": "res://autoload/input_visualizer/PC/right.svg"
	}

	return key_mappings.get(key_name, "")

## Returns true if currently using keyboard/mouse input.
func is_keyboard_input() -> bool:
	return device_id == 0

## Returns true if currently using gamepad input.
func is_gamepad_input() -> bool:
	return device_id > 0

## Returns the actual device index (0-based) for gamepad operations.
## Useful when interfacing with other systems that need the raw device index.
func get_device_index() -> int:
	return device_id - 1 if device_id > 0 else -1

## Forces a specific device type for debugging or forced input modes.
## [param device_type] 0 for keyboard, >0 for gamepad device ID
func force_device(device_type: int) -> void:
	var prev_device := device_id
	device_id = device_type
	if device_type == 0:
		device_name = "Keyboard"
	else:
		_detect_device_type(device_type - 1)
	if device_id != prev_device:
		input_changed.emit()
