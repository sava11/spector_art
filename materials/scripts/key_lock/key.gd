@tool
extends Node
class_name KLKey

# =========================================================
# Signals
# =========================================================
signal activated_changed(active: bool)
signal blocked_changed(blocked: bool)
signal enabled()
signal disabled()
signal error()

# =========================================================
# Exported
# =========================================================
@export var uid: String = "@path" : set = _set_uid
@export var activate_on_ready:bool=false
@export var timer: float = 0.0

@export_group("reset")
@export var reset_when_blocked: bool = false
@export var reset_value: bool = false

@export_group("lock")
@export var lock_expression: String = ""      # "(0 || 1) & !2"
@export var lock_keys: Array[String] = []     # key uids

# =========================================================
# Internal state
# =========================================================
var activated: bool = false:set=_set_activated
var blocked: bool = false
enum status{OK, BLOCKED}
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

	# Создаём lock при необходимости
	if lock_expression.strip_edges() != "":
		_lock = KLLock.new()
		_lock.expression = lock_expression
		_lock.keys = lock_keys
		_lock.activated.connect(_set_blocked)
		add_child(_lock)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if activate_on_ready:
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
	activated_changed.emit(activated)
	_emit_signal()

func _set_blocked(v: bool) -> void:
	if blocked == v:
		return
	blocked = v

	if blocked and reset_when_blocked:
		activated = reset_value

	KLD.set_key(uid, activated, blocked)
	blocked_changed.emit(blocked)
	activated_changed.emit(activated)
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
