extends Node
class_name SaveLoader

## Automatic save/load manager for individual nodes.
##
## This component should be attached as a child node to the object whose properties need to be saved.
## It automatically tracks changes to specified properties and saves them to the global save system.
## The parent node = get_parent().
## [br][br]
## [codeblock]
## # Example usage:
## # 1. Attach SaveLoader as child to a node with properties to save
## # 2. Set properties array to ["health", "position", "inventory"]
## # 3. Disable auto_update for manual saving
## [/codeblock]

## Emitted after loading data into the parent node.
signal loaded

## Emitted after automatically pushing changes to the save system.
signal changed_and_pushed(path, changed_keys)

## List of parent node properties to track and save.
## Only these properties will be monitored for changes and included in save data.
@export var properties: Array[String] = []

## Enable periodic checking for property changes.
## When enabled, automatically detects and saves changes at regular intervals.
@export var auto_update: bool = true

## Time interval in seconds between change checks when auto_update is enabled.
@export var update_interval: float = 0.2

# Internal variables
## Reference to the parent node being tracked.
var _owner: Node = null

## String path of the parent node for save data identification.
var _owner_path: String = ""

## Cache of serialized property values for change detection.
## Stores {property_name: PackedByteArray} for comparison.
var _last_bytes: Dictionary = {}

## Accumulator for update timing.
var _t_acc: float = 0.0

## Initialize the save loader when entering the scene tree.
## Registers the parent node with the global save system and attempts to load existing save data.
func _enter_tree() -> void:
	# Ensure parent is ready
	_owner = get_parent()
	if not _owner:
		printerr("SLDLoader: parent not found")
		return

	_owner_path = str(_owner.get_path())

	SLD.register_node(_owner, properties)

	# Attempt to load existing save data if available
	if SLD.saved_data.has(_owner_path):
		# Load only properties specified in our properties array
		var stored :Dictionary= SLD.saved_data[_owner_path]
		# stored should be a Dictionary by contract
		if typeof(stored) == TYPE_DICTIONARY:
			for prop in properties:
				if stored.has(prop):
					# Set the value on parent (assuming it's already in readable format)
					_owner.set(prop, stored[prop])
			# Update byte cache after loading
			_update_last_bytes_from_owner()
			emit_signal("loaded")
	else:
		# No saved data exists - initialize entry in SLD.saved_data if needed
		# so other modules can see current values
		if SLD.saved_data.get(_owner_path, null) == null:
			_save_current_to_global()

	# Enable processing if auto_update is enabled
	set_process(auto_update)


## Process function for automatic update checking.
## Periodically checks for property changes when auto_update is enabled.
func _process(delta: float) -> void:
	if not auto_update or not is_inside_tree() or is_queued_for_deletion():
		return
	_t_acc += delta
	if _t_acc < update_interval:
		return
	_t_acc = 0.0
	_check_and_push_changes()

## Check for property changes and push them to the global save system.
## Compares current property values with cached values and saves any changes.
func _check_and_push_changes() -> void:
	if not _owner:
		return
	var changed_keys: Array = []
	for prop in properties:
		# Safely get value - returns null if property doesn't exist
		var val = _owner.get(prop)
		var bytes: PackedByteArray
		# Serialize value to bytes with objects
		bytes = var_to_bytes_with_objects(val)
		var last = _last_bytes.get(prop, null)
		# If no previous value, consider it changed
		var changed :bool= (last == null) or (last != bytes)
		if changed:
			changed_keys.append(prop)
			_last_bytes[prop] = bytes
	# If there are changes - update global SLD.saved_data (only changed fields)
	if changed_keys.size() > 0:
		_save_current_to_global(changed_keys)
		emit_signal("changed_and_pushed", _owner_path, changed_keys)

## Save current parent node values to global SLD.saved_data.
## [param changed_keys] If provided, only update these fields; otherwise update all properties.
func _save_current_to_global(changed_keys: Array = []) -> void:
	# Ensure dictionary exists
	if not SLD.saved_data.has(_owner_path):
		SLD.saved_data[_owner_path] = {}
	var node_dict :Dictionary= SLD.saved_data[_owner_path]
	# Select keys to update
	var keys_to_update = changed_keys if not changed_keys.is_empty() else properties.duplicate()
	for prop in keys_to_update:
		# Get current value from parent
		var val = _owner.get(prop)
		# Save live value (SLD.make_save() will serialize to bytes when writing to file)
		node_dict[prop] = val
	SLD.saved_data[_owner_path] = node_dict
	# Don't call SLD.make_save() here - leave file writing responsibility to SLD
	# (if needed, can add a flag or signal that SLD listens to and saves)
	# Example: SLD can subscribe to changed_and_pushed signal and do file save as needed.

## Update the _last_bytes cache based on current owner state (all properties).
func _update_last_bytes_from_owner() -> void:
	_last_bytes.clear()
	for prop in properties:
		var val = _owner.get(prop)
		_last_bytes[prop] = var_to_bytes_with_objects(val)

## Public API: Force push all properties to global save data.
## Updates the cache and saves current values to the global save system.
func force_push() -> void:
	_update_last_bytes_from_owner()
	_save_current_to_global()

## Public API: Remove entry from global save data.
## Completely erases the save data for this node from the global save system.
func force_erase_global() -> void:
	SLD.saved_data.erase(_owner_path)
