## Multichecker - Interactive multi-choice menu system with conditional options.
##
## This class creates interactive menus where players can select from multiple options,
## with each option potentially locked or unlocked based on game state. Integrates deeply
## with the Key-Lock system for conditional availability and supports dynamic expressions
## for complex game logic. Includes save/load functionality for menu state persistence.
## [br][br]
## [codeblock]
## # Basic usage:
## var menu = Multichecker.new()
## menu.items = [item1, item2, item3]  # MulticheckerItem resources
## menu.showed = true  # Display the menu
## menu.current_id_changed.connect(_on_selection_changed)
## add_child(menu)
##
## func _on_selection_changed(selected: bool, id: int):
##     print("Option ", id, " was selected: ", selected)
## [/codeblock]

extends Node2D
class_name Multichecker

## Emitted when the current selection changes.
## [br][br]
## [param result] Whether the selection was successful (true) or failed (false)
## [param id] The index of the selected option
signal current_id_changed(result: bool, id: int)

# =========================================================
# Configuration
# =========================================================

## Spacing constant used for UI layout calculations.
const SPACE := 4

## Master enable/disable switch for the entire multichecker.
@export var enabled: bool = true: set = set_enabled

## External blocking state - when true, prevents all interactions.
@export var blocked: bool = false: set = set_blocked

## Menu visibility state - controls whether the menu is displayed.
@export var showed: bool = false: set = set_showed

## Whether to pause game time when the menu is shown.
@export var time_stop: bool = true

## Whether to automatically hide the menu after making a selection.
@export var close_after_choice: bool = false

## Array of available menu options (MulticheckerItem resources).
@export var items: Array[MulticheckerItem]

## Currently selected option index (-1 for no selection).
@export var current_id: int

## Input action name used for menu confirmation/selection.
@export var prompt_action: String = "ui_accept"

## Translation key for the prompt description text.
@export var prompt_desc: String = "description"

# =========================================================
# UI Components
# =========================================================

## Help prompt panel showing current key binding and description.
var prompt: PanelContainer

## Label displaying the current key binding for the prompt action.
var prompt_label: Label

## Label displaying the translated description text.
var prompt_desc_label: Label

## Container node holding all KLKey instances for menu options.
var keys_root: Node

## Horizontal container holding all menu option buttons.
var button_container: HBoxContainer

## Main menu panel containing the button container.
var collection: PanelContainer

## Master lock for external blocking control of the entire multichecker.
var lock: KLLock

# =========================================================
# Input handling
# =========================================================

# Updates displayed key binding when input device changes
func _changed_device():
	prompt_label.text = IM.action_to_key(prompt_action)
	#$collection/mc/vbc/choice.text = tr("UI_ACCEPT") + ": " \
		#+ (IM.action_to_key("ui_accept") 
			#if button_container.get_child_count()>1 
			#else IM.action_to_key(prompt_action))
	#$collection/mc/vbc/exit.text = tr("UI_EXIT") + ": " \
		#+ IM.action_to_key(exit_action_name)

## Returns true if multichecker is active and not blocked
func is_activated()->bool:
	return enabled and not blocked

# =========================================================
# Lifecycle
# =========================================================

func _enter_tree() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	# Create container for key-lock system
	keys_root=Node.new()
	keys_root.name="keys"
	add_child(keys_root)
	
	# Setup save/load for current selection
	var sl:=SaveLoader.new()
	sl.name="save_loader"
	sl.properties=["current_id"]
	add_child(sl)

	# Create master lock for external blocking
	lock=KLLock.new()
	lock.name="lock"
	lock.activated.connect(set_blocked)
	add_child(lock)
	
	# Build help prompt UI
	#region prompt
	prompt=PanelContainer.new()
	prompt.name="prompt"
	var mc:=MarginContainer.new()
	mc.name="mc"
	mc.set("theme_override_constants/margin_top",SPACE)
	mc.set("theme_override_constants/margin_left",SPACE)
	mc.set("theme_override_constants/margin_right",SPACE)
	mc.set("theme_override_constants/margin_bottom",SPACE)
	prompt.add_child(mc)
	var hbc:=HBoxContainer.new()
	hbc.name="hbc"
	hbc.set("theme_override_constants/separation",SPACE)
	mc.add_child(hbc)
	var txtr:=TextureRect.new()
	txtr.name="img"
	txtr.hide()
	hbc.add_child(txtr)
	prompt_label=Label.new()
	prompt_label.name="key"
	hbc.add_child(prompt_label)
	prompt_desc_label=Label.new()
	prompt_desc_label.name="desc"
	prompt_desc_label.text=tr(prompt_desc)
	hbc.add_child(prompt_desc_label)
	add_child(prompt)
	prompt.position=-prompt.size/2
	#endregion
	
	# Build main menu collection UI
	#region collection
	collection=PanelContainer.new()
	collection.name="collection"
	var mc1:=MarginContainer.new()
	mc1.name="mc"
	#mc1.set("theme_override_constants/margin_top",SPACE)
	#mc1.set("theme_override_constants/margin_left",SPACE)
	#mc1.set("theme_override_constants/margin_right",SPACE)
	#mc1.set("theme_override_constants/margin_bottom",SPACE)
	collection.add_child(mc1)
	var sc:=ScrollContainer.new()
	sc.custom_minimum_size=Vector2(196,32)
	sc.draw_focus_border=true
	sc.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	mc1.add_child(sc)
	button_container=HBoxContainer.new()
	button_container.name="button_container"
	button_container.set("theme_override_constants/separation",SPACE)
	_build_buttons()
	sc.add_child(button_container)
	add_child(collection)
	collection.position=-collection.size/2
	#endregion
	
	# polishing
	set_showed(showed)
	_visual()
	_changed_device()
	IM.input_changed.connect(_changed_device)
	button_container.get_child(get_nearest_visible_button_id(current_id)).grab_focus()

func _update_focus() -> void:
	if button_container and button_container.get_child_count() > 0 and collection and collection.visible:
		var nearest_button_id = get_nearest_visible_button_id(current_id)
		if nearest_button_id >= 0:
			button_container.get_child(nearest_button_id).grab_focus()

# =========================================================
# Button Management
# =========================================================

## Build UI buttons from the MulticheckerItem array.
## CRITICAL: Creates KLKey instances for each item with lock integration and handles save/load for toggle buttons.
## This method is the heart of the multichecker system - it transforms data into interactive UI elements.
func _build_buttons() -> void:
	# Clear existing buttons
	for b in button_container.get_children():
		b.queue_free()

	# Create button for each item
	for i in items.size():
		var data = items[i]
		var btn = Button.new()
		btn.name = "Button_%s" % [data.name.replace(" ","_")]
		btn.text = tr(data.name)
		btn.custom_minimum_size.y=32
		btn.toggle_mode = data.toggled
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Connect visibility changes
		data.visible_changed.connect(func(value):
			btn.visible = value
			#_update_focus()
		)
		btn.visible = data.visible
		button_container.add_child(btn)

		# Setup save/load for toggle buttons
		if data.toggled:
			var sl:=SaveLoader.new()
			sl.name="sl"
			sl.properties=["button_pressed"]
			btn.add_child(sl)

		# CRITICAL: Create and configure KLKey for lock system integration
		var key = KLKey.new()
		key.uid=data.uid
		key.timer=data.timer
		key.name = "Key_%s" % [data.name.replace(" ","_")]
		key.lock_keys = data.lock_keys
		key.lock_expression=data.lock_expression
		key.active.connect(_on_key_active.bind(data, i))
		keys_root.add_child(key)

		# Connect lock state to button disability
		key._lock.activated.connect(func(b): btn.disabled = b)

		# Handle button press - trigger key if activated
		btn.pressed.connect(func():
			if is_activated():
				key.trigger()
				return
			btn.button_pressed=false)

## Handle key activation from the KLKey system.
## CRITICAL: Executes dynamic expressions and manages menu visibility based on selection results.
## This is where the multichecker's core interaction logic happens.
## [br][br]
## [param result] Whether the key activation was successful
## [param data] The MulticheckerItem that was activated
## [param index] The index of the activated item
func _on_key_active(result: bool, data: MulticheckerItem, index: int) -> void:
	if not is_activated(): return

	# Update current selection
	current_id = index
	current_id_changed.emit(result, index)

	#_update_focus()

	# Execute appropriate callables based on toggle state and result
	var call_list = data.callables_on_released if not result and data.toggled else data.callables_on_pressed
	for cd in call_list:
		if cd: cd.execute(self)

	# Manage UI visibility for multi-choice menus
	if items.size() > 1:
		collection.visible = not close_after_choice
		prompt.visible = close_after_choice

	# Auto-close behavior
	if close_after_choice:
		FNC.set_pause(false)

## Finds nearest visible button to given index. Used for focus management in menu navigation
func get_nearest_visible_button_id(id:int=0) -> int:
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

# =========================================================
# State Management
# =========================================================

# Controls menu visibility and pause state
func set_showed(value: bool):
	showed=value
	if is_node_ready():
		if time_stop:
			FNC.set_pause(value)
		if prompt:
			prompt.visible=not value
		if collection:
			collection.visible=value and is_activated()
			_update_focus()

# External blocking control (connected to master KLLock)
func set_blocked(value: bool) -> void:
	blocked = value
	_visual()

# Master enable/disable control
func set_enabled(value: bool) -> void:
	enabled = value
	_visual()

# Updates UI visibility based on current state
func _visual():
	if prompt:
		prompt.visible=is_activated() and not showed
	if collection:
		collection.visible=showed and is_activated()
		if collection.visible:
			_update_focus()
