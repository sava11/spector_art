extends Node

signal key_changed(uid: String, state: Dictionary)
signal key_timer_finished(uid: String)

# uid -> { "activated": bool, "blocked": bool }
var keys: Dictionary = {}

# uid -> KeyTimer
var timers: Dictionary = {}

# KeyTimer structure
class KeyTimer:
	var time_left: float = 0.0
	var target_uid: String = ""
	var result: bool = false

# Set (or update) the state of the key and notify listeners
func set_key(uid: String, activated: bool, blocked: bool) -> void:
	keys[uid] = {
		"activated": bool(activated),
		"blocked": bool(blocked)
	}
	key_changed.emit(uid, keys[uid])

# Start a timer that will assign result to the uid key when it finishes
func start_key_timer(uid: String, duration: float, result: bool) -> void:
	var t = KeyTimer.new()
	t.time_left = float(duration)
	t.target_uid = uid
	t.result = bool(result)
	timers[uid] = t

# Stop the timer (if needed)
func stop_key_timer(uid:String) -> void:
	if timers.has(uid):
		timers.erase(uid)

# Handling timers
func _physics_process(delta: float) -> void:
	if timers.is_empty():
		return
	var to_remove := []
	for uid in timers.keys():
		var t:KeyTimer = timers[uid]
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
