## MulticheckerUI - User interface controller for multichecker menu display and interaction.
##
## This class manages the visual presentation and user interaction for Multichecker instances.
## Handles dynamic UI generation, input device detection, focus management, and menu visibility.
## Supports both keyboard and controller navigation with automatic device adaptation.
## [br][br]
## [b]Key Features:[/b]
## - Dynamic button generation from MulticheckerItem configurations
## - Real-time lock state visualization (enabled/disabled buttons)
## - Input device detection and visual feedback (keyboard/gamepad icons)
## - Focus management for keyboard/controller navigation
## - Pause state integration with game time control
## - Toggle and single-action button support

extends PanelContainer

## UI layout spacing constant used throughout the interface.
const SPACE := 4

signal multichecker_changed(to:Multichecker)

## Input action name used for menu activation.
const prompt_action: String = "ui_accept"

## Input action name used for menu deactivation.
const menu_exit: String = "ui_cancel"

## Menu visibility state - controls whether the menu is displayed.
var showed: bool = false : set = set_showed

var main_container: MarginContainer

## Help prompt panel showing current key binding and description.
var prompt: HBoxContainer

## Main menu panel containing the button container.
var collection: ScrollContainer

## Texture displaying the current key binding for the prompt action.
var prompt_key_image: TextureRect

## Label displaying the current key binding for the prompt action.
var prompt_label: Label

## Label displaying the translated description text.
var prompt_desc_label: Label

## Horizontal container holding all menu option buttons.
var button_container: HBoxContainer

## Current multichecker instance being displayed.
var current_multichecker: Multichecker = null : set = set_multichecker

func _enter_tree() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_physics_process(false)

## Initialize the UI components when entering the scene tree.
## CRITICAL: Builds the complete UI structure for menu display and input visualization.
## Creates the help prompt (showing current input binding) and main menu container.
## Sets up input device change detection for dynamic visual feedback.
func _ready() -> void:
	# Build the help prompt UI (shows current key binding and description)
	#region prompt
	main_container = MarginContainer.new()
	main_container.name = "mc"
	main_container.set("theme_override_constants/margin_top", SPACE*int(!showed))
	main_container.set("theme_override_constants/margin_left", SPACE*int(!showed))
	main_container.set("theme_override_constants/margin_right", SPACE*int(!showed))
	main_container.set("theme_override_constants/margin_bottom", SPACE*int(!showed))
	# Apply consistent spacing margins around the entire interface
	add_child(main_container)

	prompt = HBoxContainer.new()
	prompt.name = "prompt"
	prompt.set("theme_override_constants/separation", SPACE)
	main_container.add_child(prompt)

	# Icon display for gamepad buttons
	prompt_key_image = TextureRect.new()
	prompt_key_image.name = "img"
	prompt_key_image.hide()  # Initially hidden, shown when gamepad detected
	prompt.add_child(prompt_key_image)

	# Text display for keyboard keys
	prompt_label = Label.new()
	prompt_label.name = "key"
	prompt.add_child(prompt_label)

	# Description text (translated help text)
	prompt_desc_label = Label.new()
	prompt_desc_label.name = "desc"
	prompt.add_child(prompt_desc_label)

	prompt.hide()  # Initially hidden until multichecker is assigned
	#endregion

	# Build the main menu collection UI (scrollable button container)
	#region collection
	collection = ScrollContainer.new()
	collection.name = "collection"
	collection.custom_minimum_size = Vector2(196, 32)  # Minimum display size
	collection.draw_focus_border = true  # Visual focus indicator
	collection.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED  # Horizontal only
	main_container.add_child(collection)

	button_container = HBoxContainer.new()
	button_container.name = "button_container"
	button_container.set("theme_override_constants/separation", SPACE)
	collection.add_child(button_container)

	collection.hide()  # Initially hidden until menu is shown
	#endregion

	# Setup input device detection and visual feedback
	_changed_device()  # Initial device detection
	IV.input_changed.connect(_changed_device)  # Monitor device changes
	hide()
	set_physics_process(current_multichecker!=null)
	ready.connect(func():get_parent().move_child.call_deferred(self,get_parent().get_child_count()-1))

func _is_available() -> bool:
	return current_multichecker != null and current_multichecker.is_activated()

## Assign a new multichecker instance to this UI controller.
## CRITICAL: Handles the complete setup for displaying a specific multichecker's menu.
## Rebuilds the UI for the new multichecker and manages visibility states.
## Called automatically when multichecker instances are enabled/disabled.
## [br][br]
## [param multichecker] The Multichecker instance to display, or null to clear
func set_multichecker(multichecker: Multichecker) -> void:
	current_multichecker = multichecker
	multichecker_changed.emit(current_multichecker)

	# Clean up existing button instances efficiently
	if button_container:
		for child in button_container.get_children():
			child.queue_free()

	if multichecker:
		# Setup UI for the new multichecker
		_build_buttons(current_multichecker.items)  # Create buttons for each item
		_set_prompt_desc(multichecker.prompt_desc)  # Set help text
		collection.hide()  # Start with menu hidden
		prompt.show()  # Show input help
		show()  # Make UI visible
	else:
		# Clear multichecker - hide everything
		showed = false
		hide()
	set_physics_process(multichecker!=null)

# Updates displayed key binding when input device changes
func _changed_device():
	_set_prompt_action()

func _set_prompt_action():
	var img_path:=IV.action_to_button_image(prompt_action)
	if ResourceLoader.exists(img_path):
		prompt_key_image.texture = load(img_path)
		prompt_key_image.show()
		prompt_label.hide()
	else:
		prompt_label.text=IV.action_to_key(prompt_action)
		prompt_label.show()
		prompt_key_image.hide()

func _set_prompt_desc(desc: String) -> void:
	prompt_desc_label.text = tr(desc)

## Build interactive buttons for each menu item with full Key-Lock integration.
## CRITICAL: Creates the UI representation of menu options with real-time state synchronization.
## Each button is connected to its corresponding KLKey for lock state and activation handling.
## Handles both toggle and single-action button behaviors with proper state management.
## [br][br]
## [param items] Array of MulticheckerItem configurations to create buttons for
func _build_buttons(items: Array[MulticheckerItem]) -> void:
	# Safety checks for required components
	if not current_multichecker:
		push_error("Cannot build buttons: current_multichecker is null")
		return

	if not button_container:
		push_error("Cannot build buttons: button_container is null")
		return

	# Create one button for each menu item
	for data in items:
		if not data:
			push_warning("Skipping null MulticheckerItem")
			continue

		# Find the corresponding KLKey instance
		var key_name := "Key_%s" % [data.name.replace(" ", "_")]
		var key: KLKey = current_multichecker.keys_root.get_node_or_null(key_name)

		if not key:
			push_warning("KLKey '%s' not found for MulticheckerItem '%s'" % [key_name, data.name])
			continue

		# Create and configure the button
		var btn := Button.new()
		btn.name = "Button_%s" % [data.name.replace(" ", "_")]
		btn.text = tr(data.name)  # Translated display text
		btn.custom_minimum_size.y = 32  # Consistent button height
		btn.toggle_mode = data.toggled  # Toggle behavior for persistent options
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Controller-only interaction

		# Connect visibility changes from item configuration
		data.visible_changed.connect(func(value: bool) -> void: btn.visible = value)
		btn.visible = data.visible
		button_container.add_child(btn)

		# Special handling for toggle buttons - synchronize with key state
		if data.toggled:
			btn.button_pressed = key.activated  # Initial state sync
			# Keep button state synchronized with key activation
			key.active.connect(func(activated: bool) -> void:
				if data.toggled:
					btn.button_pressed = activated
			)

		# CRITICAL: Connect key activation to UI update handler
		var bound_callable := _on_ui_key_active.bind(items)

		# Handle multichecker changes - clean up old connections
		multichecker_changed.connect(
			func(_to: Multichecker) -> void:
				if key.active.is_connected(bound_callable):
					key.active.disconnect(bound_callable)
		)

		key.active.connect(bound_callable)

		# Connect lock state to button interactivity
		key.block.connect(func(blocked: bool) -> void: btn.disabled = blocked)

		# Handle direct button presses - trigger the corresponding key
		btn.pressed.connect(func() -> void:
			if current_multichecker and current_multichecker.is_activated():
				key.trigger()  # Activate through the Key-Lock system
			else:
				btn.button_pressed = false  # Reset on invalid state
		)

## Handle UI updates when a key is activated through the Key-Lock system.
## Manages menu visibility states and pause behavior based on selection results.
## Called whenever a menu option is selected, either through UI or direct key activation.
## [br][br]
## [param _activated] Whether the key activation succeeded (unused in UI context)
## [param items] The array of menu items for visibility logic
func _on_ui_key_active(_activated: bool, items: Array[MulticheckerItem]) -> void:
	# Safety checks
	if not current_multichecker:
		push_error("Multichecker doesn't exist")
		return

	if not current_multichecker.is_activated():
		return

	if not items or items.size() == 0:
		push_warning("_on_ui_key_active called with empty items array")
		return

	# CRITICAL: Manage UI visibility based on menu configuration and item count
	if items.size() > 1:  # Multi-choice menu
		# Show collection if staying open after choice, otherwise hide it
		collection.visible = not current_multichecker.close_after_choice
		# Show prompt if auto-closing after choice, otherwise hide it
		prompt.visible = current_multichecker.close_after_choice

	# Auto-close behavior for single-action menus
	if current_multichecker.close_after_choice:
		FNC.set_pause(false)  # Resume game time when auto-closing

## Find the nearest visible button to a given index for focus management.
## Used during keyboard/controller navigation to ensure focus stays on interactive elements.
## Expands search radius until a visible button is found, prioritizing buttons to the right.
## [br][br]
## [param id] The target button index to search around
## [return] The index of the nearest visible button, or -1 if none found
func _get_nearest_visible_button_id(id: int = 0) -> int:
	var count := button_container.get_child_count()

	# Validate input and check if target button is visible
	if id < 0 or id >= count:
		return -1
	var btn_at_id := button_container.get_child(id) as Button
	if btn_at_id.visible:
		return id

	# Search in expanding radius around target index
	for step in range(1, count):
		# Check left side first
		var left_idx := id - step
		if left_idx >= 0:
			var btn_left := button_container.get_child(left_idx) as Button
			if btn_left.visible:
				return left_idx

		# Check right side
		var right_idx := id + step
		if right_idx < count:
			var btn_right := button_container.get_child(right_idx) as Button
			if btn_right.visible:
				return right_idx

	# No visible button found
	return -1

func _update_focus(current_id: int) -> void:
	if button_container and button_container.get_child_count() > 0 and collection and collection.visible:
		var nearest_button_id = _get_nearest_visible_button_id(current_id)
		if nearest_button_id >= 0:
			button_container.get_child(nearest_button_id).grab_focus()

## Control the visibility state of the multichecker menu.
## CRITICAL: Manages the complete menu display lifecycle including focus, pause state, and UI visibility.
## Integrates with the game's pause system and ensures proper focus management for navigation.
## [br][br]
## [param value] True to show the menu, false to hide it
func set_showed(value: bool) -> void:
	showed = value and current_multichecker != null  # Only show if multichecker exists

	if main_container:
		main_container.set("theme_override_constants/margin_top", SPACE*int(!showed))
		main_container.set("theme_override_constants/margin_left", SPACE*int(!showed))
		main_container.set("theme_override_constants/margin_right", SPACE*int(!showed))
		main_container.set("theme_override_constants/margin_bottom", SPACE*int(!showed))

	if is_node_ready():
		# Show/hide the main menu collection
		collection.visible = showed and _is_available()

		# Integrate with game's pause system
		if current_multichecker != null and current_multichecker.time_stop:
			FNC.set_pause(value)  # Pause/unpause game time

		size=Vector2.ZERO
		if showed:
			_update_position()
			# Set initial focus when showing menu
			_update_focus(current_multichecker.current_id)

		# Show help prompt when menu is hidden, hide it when menu is shown
		prompt.visible = not showed

func _physics_process(_delta: float) -> void:
	_update_position()
	if Input.is_action_just_pressed(menu_exit) and showed:
		showed=false
	if Input.is_action_just_pressed(prompt_action) and not showed:
		showed=true

func _update_position():
	var pn:=current_multichecker.get_parent()
	var pos:Vector2=get_viewport_rect().size/2
	if pn is Node3D:
		pos=get_viewport().get_camera_3d().unproject_position(pn.global_position)
	elif pn is Node2D:
		pos=pn.global_position - get_viewport().get_camera_2d().global_position
	position=pos-size/2
