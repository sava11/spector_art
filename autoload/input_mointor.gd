extends Node

# ====================================================================================
# Input Visualizer - System for displaying input device-specific button names
# ====================================================================================
# This system automatically detects the current input device (keyboard/mouse or gamepad)
# and provides localized button names for different gamepad brands (Xbox, PlayStation, Nintendo).
# Used by UI systems to show context-sensitive control hints to players.

signal input_changed()

# ====================================================================================
# Device State
# ====================================================================================
# 0 = keyboard/mouse, >0 = gamepad device ID (supports multiple gamepads)
var device_id: int = 0
var device_name: String = "Keyboard"  # "Xbox", "PlayStation", "Nintendo", "Unknown"

# ====================================================================================
# Gamepad Button Name Mappings
# ====================================================================================
# Maps SDL button indices to platform-specific button names for different gamepad brands.
# These mappings ensure that button prompts show correct labels (A/B/X/Y vs Cross/Circle/Square/Triangle, etc.)
# Integration note: Used by UI systems that need to display control hints, similar to how
# the key-lock system uses unique identifiers for game state management.
const BUTTON_NAMES := {
	"Xbox": {
		0: "A", 1: "B", 2: "X", 3: "Y",
		4: "Back", 5: "Guide", 6: "Start",
		7: "L3", 8: "R3", 9: "LB", 10: "RB",
		11: "Up", 12: "Down", 13: "Left", 14: "Right"
	},
	"PlayStation": {
		0: "Cross", 1: "Circle", 2: "Square", 3: "Triangle",
		4: "Share", 5: "PS", 6: "Options",
		7: "L3", 8: "R3", 9: "L1", 10: "R1",
		11: "Up", 12: "Down", 13: "Left", 14: "Right"
	},
	"Nintendo": {
		0: "B", 1: "A", 2: "Y", 3: "X",
		4: "-", 5: "Home", 6: "+",
		7: "LStick", 8: "RStick", 9: "L", 10: "R",
		11: "Up", 12: "Down", 13: "Left", 14: "Right"
	},
	"Unknown": {}  # Fallback - uses raw SDL numbering
}


# ====================================================================================
# Input Event Processing
# ====================================================================================
# Monitors all input events to automatically detect the most recently used input device.
# This enables dynamic UI updates for control hints and ensures players see relevant button prompts.
# Critical integration: Similar to how HurtBox monitors HitBox collisions in the boxes system,
# this method monitors input events to maintain accurate device state.
func _input(event: InputEvent) -> void:
	var prev_device := device_id

	# Detect gamepad input (supports multiple gamepads via device property)
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		device_id = event.device + 1  # Convert to 1-based indexing (0 = keyboard)
		_detect_device_type(event.device)
	# Detect keyboard/mouse input
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		device_id = 0
		device_name = "Keyboard"
	else:
		return

	# Emit signal only when device actually changes (prevents unnecessary UI updates)
	if device_id != prev_device:
		input_changed.emit()  # Connected UI elements will update control hints

# ====================================================================================
# Gamepad Type Detection
# ====================================================================================
# Analyzes the gamepad's GUID (Globally Unique Identifier) to determine the platform/brand.
# This ensures button names are displayed correctly for different gamepad types.
# Critical: Must be called with the actual device index (0-based), not the display device_id.
# Integration note: Similar to how KLLock evaluates key expressions, this method evaluates
# string patterns to categorize gamepads, ensuring proper UI localization.
func _detect_device_type(device_index: int) -> void:
	# Validate device index to prevent crashes
	if device_index < 0 or device_index >= Input.get_connected_joypads().size():
		device_name = "Unknown"
		return

	var guid := Input.get_joy_guid(device_index).to_lower()

	# Platform detection based on GUID patterns (most specific matches first)
	if guid.contains("xbox") or guid.contains("xinput"):
		device_name = "Xbox"
	elif guid.contains("playstation") or guid.contains("ps4") or guid.contains("ps5") or guid.contains("dualshock"):
		device_name = "PlayStation"
	elif guid.contains("nintendo") or guid.contains("pro_controller") or guid.contains("joycon"):
		device_name = "Nintendo"
	else:
		device_name = "Unknown"

# ====================================================================================
# Action to Button Name Conversion
# ====================================================================================
# Converts an input action name to a human-readable button/key name based on current device.
# This is the primary API method used by UI systems to display control hints.
# Returns localized button names for gamepads and clean key names for keyboard input.
#
# Integration note: Similar to how KLKey.trigger() changes key states, this method
# translates abstract action names into concrete, device-specific button labels.
#
# @param action_name: The input action name (as defined in Project Settings -> Input Map)
# @return: Human-readable button/key name, or "Undefined" if action not found
func action_to_key(action_name: String) -> String:
	var events := InputMap.action_get_events(action_name)

	# Validate input to prevent errors
	if events.is_empty():
		push_warning("InputVisualizer: Action '%s' not found in InputMap" % action_name)
		return "Undefined"

	# Primary pass: Look for events matching current device type
	if device_id == 0:  # Keyboard/Mouse
		for event in events:
			if event is InputEventKey:
				return _get_key_display_name(event)
	else:  # Gamepad
		for event in events:
			if event is InputEventJoypadButton:
				return _joy_button_name(event.button_index)

	# Fallback pass: Return first available event if no device-specific match found
	for event in events:
		if device_id == 0 and event is InputEventKey:
			return _get_key_display_name(event)
		elif device_id != 0 and event is InputEventJoypadButton:
			return _joy_button_name(event.button_index)

	return "Undefined"

# ====================================================================================
# Gamepad Button Name Resolution
# ====================================================================================
# Converts SDL button index to platform-specific button name using the current device type.
# This ensures players see correct button labels (A/B/X/Y vs Cross/Circle/Square/Triangle).
#
# Critical bug fix: Previous implementation created a new InputEventJoypadButton without
# setting button_index, which would always return default text instead of actual button name.
#
# Integration note: Similar to how HurtBox applies damage based on HitBox properties,
# this method maps raw button indices to meaningful, localized button names.
#
# @param button_idx: SDL button index (0-14 typically)
# @return: Platform-specific button name or fallback SDL description
func _joy_button_name(button_idx: int) -> String:
	var names_dict = BUTTON_NAMES.get(device_name, {})

	# Check if we have a mapped name for this button on current platform
	if names_dict.has(button_idx):
		return names_dict[button_idx]

	# Fallback: Generate SDL-standard description with proper button index
	# Bug fix: Must set button_index before calling as_text()
	var fallback_event := InputEventJoypadButton.new()
	fallback_event.button_index = button_idx
	return fallback_event.as_text()

# ====================================================================================
# Keyboard Key Name Formatting
# ====================================================================================
# Formats keyboard key names for display, removing unnecessary modifiers and extra text.
# Ensures clean, readable key names in UI prompts (e.g., "Space" instead of "Space (Physical)").
#
# Integration note: Like how KLKey provides clean state management, this method provides
# clean, user-friendly key names for UI display.
#
# @param key_event: InputEventKey to format
# @return: Clean key name suitable for UI display
func _get_key_display_name(key_event: InputEventKey) -> String:
	var full_text := key_event.as_text()
	# Remove common suffixes that clutter the display
	var suffixes_to_remove := [" (Physical)", " (Unicode)"]
	for suffix in suffixes_to_remove:
		if full_text.ends_with(suffix):
			return full_text.substr(0, full_text.length() - suffix.length())
	return full_text

# ====================================================================================
# Utility Methods for Gameplay Integration
# ====================================================================================

# Returns true if currently using keyboard/mouse input
func is_keyboard_input() -> bool:
	return device_id == 0

# Returns true if currently using gamepad input
func is_gamepad_input() -> bool:
	return device_id > 0

# Returns the actual device index (0-based) for gamepad operations
# Useful when interfacing with other systems that need the raw device index
func get_device_index() -> int:
	return device_id - 1 if device_id > 0 else -1

# Forces a specific device type (useful for debugging or forced input modes)
# @param device_type: 0 for keyboard, >0 for gamepad device ID
func force_device(device_type: int) -> void:
	var prev_device := device_id
	device_id = device_type
	if device_type == 0:
		device_name = "Keyboard"
	else:
		_detect_device_type(device_type - 1)
	if device_id != prev_device:
		input_changed.emit()

# ====================================================================================
# Integration Notes with Gameplay Systems
# ====================================================================================
# This InputVisualizer system works alongside other game systems:
#
# 1. KEY-LOCK SYSTEM INTEGRATION:
#    - Use action_to_key() in UI prompts when displaying key requirements
#    - Connect input_changed signal to update control hints when device switches
#    - Similar to how KLKey states change, input device changes trigger UI updates
#
# 2. BOXES SYSTEM INTEGRATION:
#    - Use in combat tutorials to show correct button prompts for attacks
#    - Display parry timing hints with device-specific button names
#    - Like HurtBox monitors HitBox collisions, InputVisualizer monitors input device changes
#
# 3. USAGE PATTERNS:
#    - UI Labels: "Press " + InputVisualizer.action_to_key("jump") + " to jump"
#    - Tutorials: Show device-specific control schemes
#    - Settings: Allow players to see current input device type
#
# 4. SIGNAL CONNECTIONS:
#    - input_changed -> UI update methods
#    - Can be used with KLD.key_changed for complex input-dependent mechanics
