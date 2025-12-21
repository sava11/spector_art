## KLKey - Interactive key component for the Key-Lock system.
##
## This class represents a key that can be activated/deactivated and blocked/unblocked.
## Keys are the interactive elements that players manipulate to unlock KLLock instances.
## Supports timers, blocking conditions, and dynamic expressions for complex game logic.
## [br][br]
## [codeblock]
## # Basic usage:
## var key = KLKey.new()
## key.uid = "red_key"
## key.timer = 10.0  # Auto-deactivate after 10 seconds
## # Can only activate if any_key_index_in_lock_keys is active
## key.lock_expression = "any_key_index_in_lock_keys"  
## key.active.connect(_on_key_activated)
## add_child(key)
##
## # Manual activation
## key.trigger()  # Toggle the key state
## [/codeblock]

extends Node
class_name KLKey

## Emitted when the key's activation state changes.
## [br][br]
## [param active] True if the key is activated, false if deactivated
signal active(activated: bool)

## Emitted when the key's blocked state changes.
## [br][br]
## [param blocked] True if the key is blocked, false if unblocked
signal block(blocked: bool)

## Emitted when the key becomes activated (convenience signal).
signal enabled()

## Emitted when the key becomes deactivated (convenience signal).
signal disabled()

## Emitted when the key is blocked or encounters an error (convenience signal).
signal error()

# =========================================================
# Exported
# =========================================================

## Unique identifier for this key in the global key registry.
## Use "@path" to automatically generate UID based on scene path.
@export var uid: String = "@path" : set = _set_uid

## Editor-only property to manually activate the key during development.
@export var activate: bool = false:
	set(v):
		if not Engine.is_editor_hint():
			trigger()
			activate = false
		else:
			activate = v

## Auto-deactivation timer duration in seconds.
## When > 0, the key will automatically deactivate after this many seconds.
@export var timer: float = 0.0

## Reset configuration group.
@export_group("reset")

## Whether to reset the key's activation state when it becomes blocked.
@export var reset_when_blocked: bool = false

## The activation state to reset to when blocked (if reset_when_blocked is true).
@export var reset_value: bool = false

## Lock configuration group - defines blocking conditions.
@export_group("lock")

## Boolean expression defining when this key should be blocked.
## Uses indices to reference lock_keys array: "0" = lock_keys[0], etc.
@export var lock_expression: String = ""

## Array of key UIDs that can block this key when the lock_expression evaluates true.
@export var lock_keys: Array[String] = []

# =========================================================
# Internal state
# =========================================================

## Current activation state of the key.
var activated: bool = false: set = _set_activated

## Current blocked state of the key (computed from lock_expression).
var blocked: bool = false

## Status enumeration for trigger() return values.
enum status {OK, BLOCKED}

## Internal KLLock instance that monitors blocking conditions.
var _lock: KLLock

# =========================================================
# UID
# =========================================================
func _set_uid(v: String) -> void:
	uid = v
	if Engine.is_editor_hint():
		if uid.is_empty():
			uid = _generate_uid()

func _resolve_uid() -> String:
	if uid == "@path":
		return "/root/" + str(get_tree().root.get_path_to(self))
	return uid

func _generate_uid() -> String:
	var bytes := PackedByteArray()
	for i in range(8):
		bytes.append(randi() % 256)
	return bytes.hex_encode()

# =========================================================
# Lifecycle
# =========================================================
func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return

	uid = _resolve_uid()

	# Register the key if it doesn't exist yet
	if not KLD.keys.has(uid):
		KLD.set_key(uid, false, false)

	# Подписываемся на изменения
	KLD.key_changed.connect(_on_key_changed)

	_lock = KLLock.new()
	_lock.name="lock"
	_lock.expression = lock_expression
	_lock.keys = lock_keys
	_lock.activated.connect(_set_blocked)
	add_child(_lock)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if activate:
		trigger()
	_sync_from_autoload()
	_emit_signal()

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	if KLD.key_changed.is_connected(_on_key_changed):
		KLD.key_changed.disconnect(_on_key_changed)

# =========================================================
# Public API
# =========================================================
func trigger() -> status:
	if blocked:
		return status.BLOCKED
	if timer > 0.0:
		KLD.start_key_timer(
			uid,
			timer,
			not activated
		)
	else:
		_set_activated(not activated)
	return status.OK

# =========================================================
# Internal logic
# =========================================================
func _set_activated(v: bool) -> void:
	if activated == v:
		return
	activated = v
	KLD.set_key(uid, activated, blocked)
	active.emit(activated)
	_emit_signal()

func _set_blocked(v: bool) -> void:
	if blocked == v:
		return
	blocked = v

	if blocked and reset_when_blocked:
		activated = reset_value

	KLD.set_key(uid, activated, blocked)
	block.emit(blocked)
	active.emit(activated)
	_emit_signal()

# =========================================================
# KLD callbacks
# =========================================================
func _on_key_changed(changed_uid: String, _data: Dictionary) -> void:
	if changed_uid != uid:
		return
	_sync_from_autoload()

func _sync_from_autoload() -> void:
	var data:Dictionary = KLD.keys.get(uid)
	if data == null:
		return
	activated = data.activated
	blocked = data.blocked

# =========================================================
# Visual
# =========================================================
func _emit_signal() -> void:
	if blocked:
		error.emit()
	elif activated:
		enabled.emit()
	else:
		disabled.emit()
