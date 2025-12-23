## Multichecker - Interactive multi-choice menu system with conditional options and key-lock integration.
##
## This class creates dynamic interactive menus where players can select from multiple options,
## with each option potentially locked or unlocked based on complex game state conditions.
## Deeply integrates with the Key-Lock system for conditional option availability and supports
## dynamic expressions for executing complex game logic on selection. Includes automatic
## save/load functionality for menu state persistence across game sessions.
## [br][br]
## [b]Key Features:[/b]
## - Dynamic menu generation from MulticheckerItem resource configurations
## - Seamless Key-Lock system integration for conditional option access
## - Support for both toggle and single-action button behaviors
## - Automatic save/load of menu state and current selections
## - Integrated pause management during menu interaction
## - Keyboard/controller navigation with focus management
## - Real-time UI updates based on lock state changes
## [br][br]
## [codeblock]
## # Basic usage with conditional options:
## var menu = Multichecker.new()
## menu.items = [item1, item2, item3]  # MulticheckerItem resources
## menu.time_stop = true  # Pause game time during menu
## menu.showed = true  # Display the menu
## menu.current_id_changed.connect(_on_selection_changed)
## add_child(menu)
##
## func _on_selection_changed(selected: bool, id: int):
##     if selected:
##         print("Player selected option ", id)
##     else:
##         print("Option ", id, " was deselected")
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

## Check if the multichecker is currently active and available for interaction.
## This method combines the enabled and blocked states to determine overall availability.
## [br][br]
## [return] True if the multichecker is enabled and not externally blocked, false otherwise
func is_activated() -> bool:
	return enabled and not blocked

# =========================================================
# Lifecycle
# =========================================================

func _enter_tree() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS

## Initialize the multichecker when entering the scene tree.
## CRITICAL: Sets up the core infrastructure for key-lock integration and state persistence.
## This method performs essential initialization:
## - Creates the keys_root container for KLKey instances
## - Sets up automatic save/load for current_id persistence
## - Creates the master KLLock for external blocking control
## - Builds KLKey instances for each menu item
func _ready() -> void:
	# Create container node for KLKey instances (one per menu item)
	keys_root = Node.new()
	keys_root.name = "keys"
	add_child(keys_root)

	# Setup automatic save/load for menu state persistence
	var sl := SaveLoader.new()
	sl.name = "save_loader"
	sl.properties = ["current_id"]  # Save the currently selected option
	add_child(sl)

	# Create master lock for external blocking (e.g., cutscenes, game states)
	lock = KLLock.new()
	lock.name = "lock"
	lock.activated.connect(set_blocked)  # Connect to blocking state management
	add_child(lock)

	_build_keys()  # CRITICAL: Create KLKey instances for each menu item

## Build KLKey instances for each menu item with full lock system integration.
## CRITICAL: This method creates the core integration between menu items and the Key-Lock system.
## Each menu option gets its own KLKey that handles:
## - Lock condition evaluation based on lock_expression and lock_keys
## - Timer-based auto-reset functionality
## - State persistence through unique UIDs
## - Signal connections for menu interaction feedback
func _build_keys() -> void:
	# Clean up any existing KLKey instances (important for dynamic item changes)
	for k in keys_root.get_children():
		k.queue_free()

	# Create one KLKey instance for each menu item
	for i in items.size():
		var data = items[i]

		# CRITICAL: Configure KLKey with item's lock conditions and behaviors
		var key = KLKey.new()
		key.uid = data.uid  # Unique identifier for save/load and cross-scene references
		key.timer = data.timer  # Auto-reset timer duration
		key.name = "Key_%s" % [data.name.replace(" ", "_")]  # Human-readable name
		key.lock_keys = data.lock_keys  # Key UIDs referenced in lock expression
		key.lock_expression = data.lock_expression  # Boolean expression for availability
		key.active.connect(_on_key_active.bind(data, i))  # Connect to menu interaction handler
		keys_root.add_child(key)


## Handle key activation events from the KLKey system.
## CRITICAL: This is the core interaction handler where menu selections are processed.
## Manages selection state, executes dynamic expressions, and handles menu logic.
## Called whenever a player interacts with a menu option through the Key-Lock system.
## [br][br]
## [param result] True if the key activation succeeded, false if blocked/failed
## [param data] The MulticheckerItem configuration for the activated option
## [param index] The array index of the activated item (for current_id tracking)
func _on_key_active(result: bool, data: MulticheckerItem, index: int) -> void:
	if not is_activated():  # Safety check - ignore interactions when disabled/blocked
		return

	# Update the currently selected option index
	current_id = index
	current_id_changed.emit(result, index)  # Notify listeners of selection change

	# CRITICAL: Execute appropriate dynamic expressions based on selection type and result
	# For toggle buttons: use callables_on_released when deactivating, callables_on_pressed when activating
	# For regular buttons: always use callables_on_pressed
	var call_list = data.callables_on_released if not result and data.toggled else data.callables_on_pressed
	for cd in call_list:
		if cd:  # Safety check for null expressions
			cd.execute(self)  # Execute dynamic expression with multichecker as context

# =========================================================
# State Management
# =========================================================

## Set the external blocking state of the multichecker.
## When blocked, all menu interactions are disabled and the current multichecker reference is cleared.
## Connected to the master KLLock for automatic blocking based on game state conditions.
## [br][br]
## [param value] True to block the multichecker, false to unblock it
func set_blocked(value: bool) -> void:
	blocked = value
	if blocked:
		MUI.current_multichecker = null  # Clear global reference when blocked

## Set the master enable/disable state of the multichecker.
## Controls overall availability and manages the global multichecker reference in MUI.
## When disabled, the multichecker becomes inactive but retains its configuration.
## [br][br]
## [param value] True to enable the multichecker, false to disable it
func set_enabled(value: bool) -> void:
	if enabled != value:
		enabled = value
		# Update global multichecker reference for UI management
		MUI.current_multichecker = self if enabled else null
