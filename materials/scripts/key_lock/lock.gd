## KLLock - Logical lock that evaluates key states using boolean expressions.
##
## This class represents a lock that monitors multiple KLKey states and evaluates
## a boolean expression to determine if the lock should be "activated" (unlocked).
## Supports complex logical operations between keys using expressions like "(0 || 1) & !2".
## [br][br]
## [codeblock]
## # Basic usage:
## var lock = KLLock.new()
## lock.keys = ["door_key", "master_key"]
## lock.expression = "0 || 1"  # Unlock if either key is active
## lock.activated.connect(_on_lock_opened)
## add_child(lock)
## [/codeblock]

extends Node
class_name KLLock

## Emitted when the lock's activated state changes.
## [br][br]
## [param active] True if the lock is activated (unlocked), false if deactivated (locked)
signal activated(active: bool)

## Boolean expression defining the lock condition.
## Uses indices to reference keys array: "0" = keys[0], "1" = keys[1], etc.
## Supports logical operators: & (and), | (or), ! (not), &&, ||.
@export var expression: String

## Array of key UIDs that this lock monitors.
## Expression uses indices to reference these keys (0 = keys[0], 1 = keys[1], etc.).
@export var keys: Array[String]

## Internal cache of the last evaluated state to detect changes.
var last_state := false

## Initialize the lock when entering the scene tree.
## Connects to key change signals and performs initial evaluation.
func _ready():
	KLD.key_changed.connect(_on_key_changed)
	_check()

## Get the effective state of a key at the specified index.
## Returns true only if the key exists, is activated, and not blocked.
## [br][br]
## [param index] Index in the keys array
## [return] True if the key is active and unblocked
func _key_value(index: int) -> bool:
	if index < 0 or index >= keys.size():
		return false
	var data = KLD.keys.get(keys[index])
	return data != null and data.activated and not data.blocked

## Evaluate the boolean expression and return the result.
## Converts the expression from symbolic notation to GDScript syntax and executes it.
## [br][br]
## [return] True if the expression evaluates to true (lock is activated)
func evaluate() -> bool:
	var expr := expression

	for i in keys.size():
		expr = expr.replace(
			str(i),
			str(_key_value(i)).to_lower()
		)

	expr = expr.replace("!", " not ")
	expr = expr.replace("&", " and ")
	expr = expr.replace("&&", " and ")
	expr = expr.replace("|", " or ")
	expr = expr.replace("||", " or ")

	var expr_obj := Expression.new()
	return expr_obj.parse(expr) == OK \
		and expr_obj.execute()

## Handle key state changes from the global key registry.
## Reevaluates the lock condition when any monitored key changes.
## [br][br]
## [param _uid] The UID of the changed key (unused)
## [param _state] The new state of the key (unused)
func _on_key_changed(_uid, _state):
	_check()

## Evaluate the current state and emit activated signal if it changed.
## Internal method that performs the actual state evaluation and change detection.
func _check():
	var current = evaluate()
	if current != last_state:
		last_state = current
		activated.emit(current)
