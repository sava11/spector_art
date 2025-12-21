# ====================================================================================
# Input Visualizer Example Usage
# ====================================================================================
# This example demonstrates how to use the InputVisualizer system
# to display both text and image-based input prompts.
#
# To use this in your game:
# 1. Ensure InputVisualizer is autoloaded as a singleton
# 2. Call InputVisualizer.action_to_key("your_action") for text prompts
# 3. Call InputVisualizer.action_to_button_image("your_action") for image paths
# 4. Load the returned image path using load() or ResourceLoader
# ====================================================================================

extends Node

# Example of displaying input hints in UI
func show_jump_hint():
	var text_hint = "Press " + InputVisualizer.action_to_key("jump") + " to jump"
	var image_path = InputVisualizer.action_to_button_image("jump")

	print("Text hint: ", text_hint)
	print("Image path: ", image_path)

	# Example of loading and using the image in a TextureRect
	if image_path != "":
		var texture = load(image_path)
		if texture:
			# In real usage, assign to your UI element:
			# $ButtonIcon.texture = texture
			print("Image loaded successfully!")
		else:
			print("Failed to load image")

# Example of getting current device info
func print_current_device():
	var device_type = "Keyboard" if InputVisualizer.is_keyboard_input() else "Gamepad"
	var device_name = InputVisualizer.device_name

	print("Current device: ", device_type, " (", device_name, ")")

# Example of handling device changes
func _ready():
	# Connect to device change signal
	InputVisualizer.connect("input_changed", Callable(self, "_on_input_device_changed"))

	print_current_device()

func _on_input_device_changed():
	print("Input device changed!")
	print_current_device()

	# Update all UI elements that show input hints
	show_jump_hint()
