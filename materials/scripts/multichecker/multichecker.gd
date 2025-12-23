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

extends Node
class_name Multichecker

## Emitted when the current selection changes.
## [br][br]
## [param result] Whether the selection was successful (true) or failed (false)
## [param id] The index of the selected option
signal current_id_changed(result: bool, id: int)

# =========================================================
# Configuration
# =========================================================

## Master enable/disable switch for the entire multichecker.
@export var enabled: bool = true: set = set_enabled

## External blocking state - when true, prevents all interactions.
@export var blocked: bool = false: set = set_blocked

## Whether to pause game time when the menu is shown.
@export var time_stop: bool = true

## Whether to automatically hide the menu after making a selection.
@export var close_after_choice: bool = false

## Array of available menu options (MulticheckerItem resources).
@export var items: Array[MulticheckerItem]

## Currently selected option index (-1 for no selection).
@export var current_id: int

## Translation key for the prompt description text.
@export var prompt_desc: String = "description"

# =========================================================
# UI Components
# =========================================================

## Container node holding all KLKey instances for menu options.
var keys_root: Node

## Master lock for external blocking control of the entire multichecker.
var lock: KLLock

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
	
	_build_keys()

## CRITICAL: Creates KLKey instances for each item with lock integration.
func _build_keys() -> void:
	# Clear existing keys
	for k in keys_root.get_children():
		k.queue_free()

	# Create button for each item
	for i in items.size():
		var data = items[i]
		
		# CRITICAL: Create and configure KLKey for lock system integration
		var key = KLKey.new()
		key.uid=data.uid
		key.timer=data.timer
		key.name = "Key_%s" % [data.name.replace(" ","_")]
		key.lock_keys = data.lock_keys
		key.lock_expression=data.lock_expression
		key.active.connect(_on_key_active.bind(data, i))
		keys_root.add_child(key)


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

	# Execute appropriate callables based on toggle state and result
	var call_list = data.callables_on_released if not result and data.toggled else data.callables_on_pressed
	for cd in call_list:
		if cd: cd.execute(self)

# =========================================================
# State Management
# =========================================================

# External blocking control (connected to master KLLock)
func set_blocked(value: bool) -> void:
	blocked = value
	MUI.current_multichecker=null

# Master enable/disable control
func set_enabled(value: bool) -> void:
	if enabled != value:
		enabled = value
		MUI.current_multichecker = self if enabled else null
