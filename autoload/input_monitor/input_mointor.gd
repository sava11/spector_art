extends Node

# ====================================================================================
# Input Visualizer - System for displaying input device-specific button names
# ====================================================================================
# This system automatically detects the current input device (keyboard/mouse or gamepad)
# and provides localized button names for different gamepad brands (xBox, PlayStation, Nintendo).
# Used by UI systems to show context-sensitive control hints to players.

signal input_changed()

# ====================================================================================
# Device State
# ====================================================================================
# 0 = keyboard/mouse, >0 = gamepad device ID (supports multiple gamepads)
var device_id: int = 0
var device_name: String = "Keyboard"  # "xBox", "PlayStation", "Nintendo", "Unknown"

# ====================================================================================
# Gamepad Button Name Mappings
# ====================================================================================
# Maps SDL button indices to platform-specific button data for different gamepad brands.
# Each button entry contains both display text and image path for visual button prompts.
# These mappings ensure that button prompts show correct labels and images
# (A/B/X/Y vs Cross/Circle/Square/Triangle, etc.)
# Integration note: Used by UI systems that need to display control hints, similar to how
const BUTTON_NAMES := {
	"xBox": {
		0: {"text": "A", "image": "res://autoload/input_monitor/xBox/a.svg"},
		1: {"text": "B", "image": "res://autoload/input_monitor/xBox/b.svg"},
		2: {"text": "X", "image": "res://autoload/input_monitor/xBox/x.svg"},
		3: {"text": "Y", "image": "res://autoload/input_monitor/xBox/y.svg"},
		4: {"text": "Back", "image": "res://autoload/input_monitor/xBox/back.svg"},
		5: {"text": "Guide", "image": "res://autoload/input_monitor/xBox/guide.svg"},
		6: {"text": "Start", "image": "res://autoload/input_monitor/xBox/start.svg"},
		7: {"text": "L3", "image": "res://autoload/input_monitor/xBox/l3.svg"},
		8: {"text": "R3", "image": "res://autoload/input_monitor/xBox/r3.svg"},
		9: {"text": "LB", "image": "res://autoload/input_monitor/xBox/lb.svg"},
		10: {"text": "RB", "image": "res://autoload/input_monitor/xBox/rb.svg"},
		11: {"text": "Up", "image": "res://autoload/input_monitor/xBox/up.svg"},
		12: {"text": "Down", "image": "res://autoload/input_monitor/xBox/down.svg"},
		13: {"text": "Left", "image": "res://autoload/input_monitor/xBox/left.svg"},
		14: {"text": "Right", "image": "res://autoload/input_monitor/xBox/right.svg"}
	},
	"PlayStation": {
		0: {"text": "Cross", "image": "res://autoload/input_monitor/PlayStatinon/cross.svg"},
		1: {"text": "Circle", "image": "res://autoload/input_monitor/PlayStatinon/circle.svg"},
		2: {"text": "Square", "image": "res://autoload/input_monitor/PlayStatinon/square.svg"},
		3: {"text": "Triangle", "image": "res://autoload/input_monitor/PlayStatinon/triangle.svg"},
		4: {"text": "Share", "image": "res://autoload/input_monitor/PlayStatinon/share.svg"},
		5: {"text": "PS", "image": "res://autoload/input_monitor/PlayStatinon/ps.svg"},
		6: {"text": "Options", "image": "res://autoload/input_monitor/PlayStatinon/options.svg"},
		7: {"text": "L3", "image": "res://autoload/input_monitor/PlayStatinon/l3.svg"},
		8: {"text": "R3", "image": "res://autoload/input_monitor/PlayStatinon/r3.svg"},
		9: {"text": "L1", "image": "res://autoload/input_monitor/PlayStatinon/l1.svg"},
		10: {"text": "R1", "image": "res://autoload/input_monitor/PlayStatinon/r1.svg"},
		11: {"text": "Up", "image": "res://autoload/input_monitor/PlayStatinon/up.svg"},
		12: {"text": "Down", "image": "res://autoload/input_monitor/PlayStatinon/down.svg"},
		13: {"text": "Left", "image": "res://autoload/input_monitor/PlayStatinon/left.svg"},
		14: {"text": "Right", "image": "res://autoload/input_monitor/PlayStatinon/right.svg"}
	},
	"Nintendo": {
		0: {"text": "B", "image": "res://autoload/input_monitor/Nintendo/b.svg"},
		1: {"text": "A", "image": "res://autoload/input_monitor/Nintendo/a.svg"},
		2: {"text": "Y", "image": "res://autoload/input_monitor/Nintendo/y.svg"},
		3: {"text": "X", "image": "res://autoload/input_monitor/Nintendo/x.svg"},
		4: {"text": "-", "image": "res://autoload/input_monitor/Nintendo/minus.svg"},
		5: {"text": "Home", "image": "res://autoload/input_monitor/Nintendo/home.svg"},
		6: {"text": "+", "image": "res://autoload/input_monitor/Nintendo/plus.svg"},
		7: {"text": "LStick", "image": "res://autoload/input_monitor/Nintendo/lstick.svg"},
		8: {"text": "RStick", "image": "res://autoload/input_monitor/Nintendo/rstick.svg"},
		9: {"text": "L", "image": "res://autoload/input_monitor/Nintendo/l.svg"},
		10: {"text": "R", "image": "res://autoload/input_monitor/Nintendo/r.svg"},
		11: {"text": "Up", "image": "res://autoload/input_monitor/Nintendo/up.svg"},
		12: {"text": "Down", "image": "res://autoload/input_monitor/Nintendo/down.svg"},
		13: {"text": "Left", "image": "res://autoload/input_monitor/Nintendo/left.svg"},
		14: {"text": "Right", "image": "res://autoload/input_monitor/Nintendo/right.svg"}
	},
	"Unknown": {}  # Fallback - uses raw SDL numbering
}


# ====================================================================================
# Input Event Processing - Core Device Detection Engine
# ====================================================================================
# Monitors all input events to automatically detect the most recently used input device.
# This enables dynamic UI updates for control hints and ensures players see relevant button prompts.
#
# PERFORMANCE CONSIDERATIONS:
# - Only emits signal when device actually changes (prevents UI spam)
# - Processes all input events, but returns early for non-device-changing events
# - Critical path: Must be efficient as it runs for every input event
#
# @param event: InputEvent from Godot's input system
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

# ====================================================================================
# Gamepad Type Detection - Platform Recognition Engine
# ====================================================================================
# Analyzes gamepad's GUID (Globally Unique Identifier) to determine platform/brand.
# This is CRITICAL for proper button localization and ensures players see correct labels.
#
# CRITICAL REQUIREMENTS:
# - Must be called with actual device index (0-based), not display device_id
# - Handles multiple connected gamepads correctly
# - Robust fallback to "Unknown" for unsupported devices
#
# PATTERN MATCHING: Platform detection with specificity priority
# Order matters: More specific patterns checked before generic ones
#
# DETECTION PRIORITY: Most specific patterns checked first to avoid false positives
# Example: "xBox" checked before generic "xinput" to ensure correct categorization
#
# SUPPORTED PLATFORMS:
# - xBox: Microsoft controllers (including third-party)
# - PlayStation: Sony DualSense, DualShock, etc.
# - Nintendo: Switch Pro Controller, Joy-Con, etc.
#
# @param device_index: Raw Godot device index (0-based, from Input.get_connected_joypads())
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

# ====================================================================================
# Action to Button Name Conversion - Primary API Method
# ====================================================================================
# Converts an input action name to a human-readable button/key name based on current device.
# This is the PRIMARY API METHOD used by UI systems to display control hints throughout the game.
#
# ALGORITHM: Two-pass lookup system for robust device matching
# 1. Primary pass: Find exact device type match (keyboard vs gamepad)
# 2. Fallback pass: Return first available event if no exact match
#
# ERROR HANDLING: Graceful degradation with warnings for debugging
# Returns "Undefined" for invalid actions instead of crashing
#
# @param action_name: Input action name from Project Settings -> Input Map
# @return: Localized button/key name, or "Undefined" if action not found
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

# ====================================================================================
# Gamepad Button Name Resolution - Platform Localization Engine
# ====================================================================================
# Converts raw SDL button index to platform-specific button name using current device type.
# This is CRITICAL for proper localization - ensures players see correct labels:
# - xBox: A, B, X, Y, LB, RB, etc.
# - PlayStation: Cross, Circle, Square, Triangle, L1, R1, etc.
# - Nintendo: A, B, X, Y, L, R, etc.
#
# CRITICAL BUG FIX HISTORY:
# Previous implementation created InputEventJoypadButton without setting button_index,
# causing all buttons to return default "Button 0" text instead of actual names.
# This broke gamepad UI prompts completely.
#
# DATA STRUCTURE: BUTTON_NAMES dictionary provides platform-specific mappings
# Each button entry contains both display text and image path for rich UI
#
# @param button_idx: SDL button index (0-14 typically, matches standard gamepad layout)
# @return: Localized button name or fallback SDL description if unmapped
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
	fallback_event.button_index = button_idx  # This was the critical bug - missing assignment
	return fallback_event.as_text()  # Returns "Button 0", "Button 1", etc.

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
# Button Image Methods - Visual Input Prompt System
# ====================================================================================
# Methods for retrieving button images to create rich, visual input prompts.
# Enables both text and image-based UI hints for enhanced user experience.
#
# CRITICAL INTEGRATION:
# - Works alongside action_to_key() for hybrid text+image displays
# - Used by UI systems that need visual button representations
# - Similar to how key-lock system provides state feedback, this provides visual feedback
#
# IMAGE SYSTEM ARCHITECTURE:
# - Platform-specific subdirectories: xBox/, PlayStation/, Nintendo/, PC/
# - SVG format for crisp scaling at any UI size
# - File naming matches button names (a.svg, cross.svg, space.svg, etc.)
# - Graceful fallback to empty string if images unavailable
#
# USAGE PATTERNS:
# - Load images: var texture = load(InputMonitor.action_to_button_image("jump"))
# - UI Integration: Assign to TextureRect, Sprite, or custom UI components
# - Fallback: Combine with text if images fail to load

# Converts an input action name to a button image path based on current device.
# This is the VISUAL COUNTERPART to action_to_key() - returns image paths instead of text.
#
# CRITICAL INTEGRATION POINTS:
# - BOXES SYSTEM: Creates visual combat tutorials with button images
# - KEY-LOCK SYSTEM: Shows visual hints for key activation requirements
# - MULTICHECKER: Displays navigation button images in menus
#
# ALGORITHM: Mirrors action_to_key() but returns image paths for visual UI
# Same two-pass lookup system ensures device-specific image selection
#
# IMAGE LOADING: Use with load() or ResourceLoader for Texture creation
# Example: var texture = load(InputMonitor.action_to_button_image("jump"))
#
# ERROR HANDLING: Returns empty string for graceful degradation
# UI systems should fallback to text-only prompts if images unavailable
#
# @param action_name: Input action name from Project Settings -> Input Map
# @return: Full image path string, or empty string if unavailable
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

# Converts SDL button index to platform-specific button image path.
# This ensures players see correct button images (A/B/X/Y vs Cross/Circle/Square/Triangle).
#
# @param button_idx: SDL button index (0-14 typically)
# @return: Image path string or empty string if no image available
func joy_button_image(button_idx: int) -> String:
	return _joy_button_image(button_idx)

# Internal method to get button image path
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
		"space": "res://autoload/input_monitor/PC/space.svg",
		"enter": "res://autoload/input_monitor/PC/enter.svg",
		"escape": "res://autoload/input_monitor/PC/escape.svg",
		"w": "res://autoload/input_monitor/PC/w.svg",
		"a": "res://autoload/input_monitor/PC/a.svg",
		"s": "res://autoload/input_monitor/PC/s.svg",
		"d": "res://autoload/input_monitor/PC/d.svg",
		"shift": "res://autoload/input_monitor/PC/shift.svg",
		"ctrl": "res://autoload/input_monitor/PC/ctrl.svg",
		"up": "res://autoload/input_monitor/PC/up.svg",
		"down": "res://autoload/input_monitor/PC/down.svg",
		"left": "res://autoload/input_monitor/PC/left.svg",
		"right": "res://autoload/input_monitor/PC/right.svg"
	}

	return key_mappings.get(key_name, "")

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
# Integration Notes with Gameplay Systems - Spector Art Architecture
# ====================================================================================
# InputMonitor is a CORE SYSTEM that enables device-aware UI across the entire game.
# It works alongside all major game systems to provide contextual, localized input hints.
#
# ================================================================================
# 1. MULTICHECKER SYSTEM INTEGRATION - Menu Navigation
# ================================================================================
# Enables device-aware menu systems with proper navigation hints:
#
# INTEGRATION PATTERNS:
# - Menu navigation: Show correct D-pad/analog stick hints
# - Selection confirmation: Device-specific confirm/cancel buttons
# - Conditional options: Button prompts that match multichecker logic
# - Dynamic expressions: Input hints that respond to game state changes
#
# ================================================================================
# 2. IMAGE-BASED UI INTEGRATION - Rich Visual Prompts
# ================================================================================
# Dual-mode system supporting both text and visual button representations:
#
# VISUAL SYSTEM ARCHITECTURE:
# - action_to_key(): Returns localized text labels
# - action_to_button_image(): Returns SVG image paths for visual prompts
# - Platform directories: xBox/, PlayStation/, Nintendo/, PC/
# - Hybrid displays: Combine text + images for maximum accessibility
#
# LOADING PATTERNS:
# ```gdscript
# # Text-only prompt
# var hint = "Press " + InputMonitor.action_to_key("jump")
#
# # Image prompt
# var image_path = InputMonitor.action_to_button_image("jump")
# var texture = load(image_path) if image_path else null
#
# # Hybrid prompt (recommended)
# var text_hint = InputMonitor.action_to_key("jump")
# var image_path = InputMonitor.action_to_button_image("jump")
# ```
#
# ================================================================================
# 3. SIGNAL CONNECTIONS - Event-Driven Architecture
# ================================================================================
# Follows Godot's signal pattern for loose coupling with other systems:
#
# PRIMARY SIGNAL: input_changed
# - Emitted only when device actually changes (prevents UI spam)
# - Connect to UI update methods across all systems
#
# CONNECTION EXAMPLES:
# ```gdscript
# # Connect in UI systems
# InputMonitor.connect("input_changed", Callable(self, "_update_control_hints"))
#
# func _update_control_hints():
#     hint_label.text = "Press " + InputMonitor.action_to_key("interact")
# ```
#
# ================================================================================
# 4. SUPPORTED PLATFORMS & LOCALIZATION
# ================================================================================
# Comprehensive platform support with accurate button mapping:
#
# XBOX ECOSYSTEM:
# - Face buttons: A, B, X, Y (not Cross, Circle, Square, Triangle)
# - Bumpers: LB, RB (not L1, R1)
# - Special: Back, Guide, Start
#
# PLAYSTATION ECOSYSTEM:
# - Face buttons: Cross, Circle, Square, Triangle (not A, B, X, Y)
# - Bumpers: L1, R1 (not LB, RB)
# - Special: Share, PS, Options
#
# NINTENDO ECOSYSTEM:
# - Face buttons: B, A, Y, X (inverted from xBox)
# - Bumpers: L, R
# - Special: -, Home, +
#
# PC ECOSYSTEM:
# - Standard keys: Space, Enter, Escape, WASD
# - Modifiers: Shift, Ctrl
# - Navigation: Arrow keys
#
# ================================================================================
# 5. IMAGE FILE SPECIFICATIONS
# ================================================================================
# Optimized for game UI with consistent quality across platforms:
#
# FORMAT: SVG (Scalable Vector Graphics)
# - Crisp scaling at any resolution
# - Small file sizes
# - Consistent visual quality
#
# ORGANIZATION: autoload/input_monitor/{platform}/
# - xBox/: Microsoft-style button icons
# - PlayStation/: Sony-style button icons
# - Nintendo/: Nintendo-style button icons
# - PC/: Keyboard key icons
#
# NAMING: Matches button text labels
# - Face buttons: a.svg, b.svg, x.svg, y.svg, cross.svg, circle.svg, etc.
# - Special buttons: start.svg, select.svg, guide.svg, ps.svg, home.svg
# - D-pad: up.svg, down.svg, left.svg, right.svg
#
# ================================================================================
# 6. PERFORMANCE & RELIABILITY CONSIDERATIONS
# ================================================================================
# Designed for high-performance, real-time operation:
#
# EFFICIENCY:
# - Minimal processing per input event
# - Lazy loading of button names (computed on demand)
# - Signal emission only on actual device changes
#
# RELIABILITY:
# - Graceful fallbacks for unmapped buttons
# - Warning system for debugging invalid actions
# - Platform detection with robust pattern matching
# - Bounds checking prevents crashes
#
# MEMORY MANAGEMENT:
# - Static BUTTON_NAMES dictionary (no dynamic allocation)
# - Image paths are strings (textures loaded on demand)
# - No persistent state beyond device tracking
