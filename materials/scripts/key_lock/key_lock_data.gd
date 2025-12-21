## KLData - Global key registry and timer management for the Key-Lock system.
##
## This singleton manages the global state of all KLKey instances and their timers.
## Provides centralized storage for key states and handles timed key activations.
## All KLKey and KLLock instances communicate through this central registry.
## [br][br]
## [codeblock]
## # Direct usage (usually handled by KLKey/KLLock):
## KLD.set_key("door_key", true, false)  # Activate key
## KLD.start_key_timer("temp_key", 5.0, false)  # Auto-deactivate after 5 seconds
## [/codeblock]

extends Node

## Emitted when any key's state changes.
## [br][br]
## [param uid] The unique identifier of the changed key
## [param state] Dictionary containing "activated" and "blocked" boolean values
signal key_changed(uid: String, state: Dictionary)

## Emitted when a key timer finishes and the key state is updated.
## [br][br]
## [param uid] The unique identifier of the key whose timer finished
signal key_timer_finished(uid: String)

## Global dictionary storing all key states.
## Format: uid -> {"activated": bool, "blocked": bool}
var keys: Dictionary = {}

## Dictionary storing active key timers.
## Format: uid -> KeyTimer instance
var timers: Dictionary = {}

## Internal structure for managing timed key state changes.
class KeyTimer:
	## Time remaining until the timer expires (in seconds).
	var time_left: float = 0.0

	## The UID of the key this timer will affect.
	var target_uid: String = ""

	## The activation state to set when the timer expires.
	var result: bool = false

## Set or update the state of a key and notify all listeners.
## This is the central method for changing key states in the Key-Lock system.
## [br][br]
## [param uid] Unique identifier for the key
## [param activated] Whether the key is activated (true) or deactivated (false)
## [param blocked] Whether the key is blocked (true) or unblocked (false)
func set_key(uid: String, activated: bool, blocked: bool) -> void:
	keys[uid] = {
		"activated": bool(activated),
		"blocked": bool(blocked)
	}
	key_changed.emit(uid, keys[uid])

## Start a timer that will automatically change a key's activation state.
## Useful for temporary keys, cooldowns, or timed events.
## [br][br]
## [param uid] Unique identifier for the key
## [param duration] Time in seconds until the timer expires
## [param result] The activation state to set when the timer expires
func start_key_timer(uid: String, duration: float, result: bool) -> void:
	var t = KeyTimer.new()
	t.time_left = float(duration)
	t.target_uid = uid
	t.result = bool(result)
	timers[uid] = t

## Stop and remove a key timer if it exists.
## [br][br]
## [param uid] Unique identifier of the key whose timer to stop
func stop_key_timer(uid: String) -> void:
	if timers.has(uid):
		timers.erase(uid)

## Process active key timers and update expired ones.
## Called every physics frame to decrement timer counters and trigger state changes.
## [br][br]
## [param delta] Time elapsed since the last physics frame
func _physics_process(delta: float) -> void:
	if timers.is_empty():
		return
	var to_remove := []
	for uid in timers.keys():
		var t: KeyTimer = timers[uid]
		if t.time_left <= 0.0:
			# save the current `blocked` (if the key exists), otherwise false
			var cur_blocked := false
			if keys.has(uid):
				cur_blocked = keys[uid].get("blocked", false)
			# assign a value without touching blocked (we only change activated)
			set_key(uid, t.result, cur_blocked)
			to_remove.append(uid)
			key_timer_finished.emit(uid)
		t.time_left -= delta
	# remove completed timers
	for uid in to_remove:
		timers.erase(uid)
