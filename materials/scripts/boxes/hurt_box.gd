## HurtBox - Damageable collision area that receives damage from HitBoxes.
##
## This class defines damageable collision areas that can receive damage from HitBox attacks.
## Manages health, invincibility frames, and various damage detection modes. Supports
## raycast verification, single-hit detection, and automatic invincibility timers.
## [br][br]
## [codeblock]
## # Basic usage:
## var hurt_box = HurtBox.new()
## hurt_box.max_health = 100.0
## hurt_box.tspeed = 0.5  # 0.5 second invincibility frames
## hurt_box.health_changed.connect(_on_health_changed)
## hurt_box.alive.connect(_on_alive_changed)
## add_child(hurt_box)
##
## func _on_health_changed(value: float, delta: float):
##     health_bar.value = value
## [/codeblock]

class_name HurtBox
extends Area2D

## Emitted when invincibility frames begin.
signal invi_started

## Emitted when invincibility frames end.
signal invi_ended

## Emitted when the entity's alive state changes.
## [br][br]
## [param alive] True if the entity is alive, false if dead
signal alive(alive: bool)

## Emitted when health value changes.
## [br][br]
## [param value] The new health value
## [param delta] The change in health (positive for healing, negative for damage)
signal health_changed(value: float, delta: float)

## Emitted when maximum health value changes.
## [br][br]
## [param value] The new maximum health value
## [param delta] The change in maximum health
signal max_health_changed(value: float, delta: float)

## Physics layer flags for raycast collision detection.
## Used when detect_by_ray is enabled on HitBoxes to determine what layers to check.
@export_flags_2d_physics() var flags: int = 0

## Array of HitBox exceptions that should be ignored for damage.
## Useful for preventing self-damage or friendly fire.
@export var exceptions: Array[HitBox]

## Default duration for invincibility frames in seconds.
@export var tspeed: float = 1.0

## Maximum health value. Setting this automatically scales current health proportionally.
@export var max_health: float = 1: set = set_max_health

## Internal timer for managing invincibility duration.
@onready var t: Timer = Timer.new()

## Whether the HurtBox is currently invincible and immune to damage.
var invincible: bool = false: set = set_invincible

## Current health value. Automatically clamped between 0 and max_health.
var health: float = max_health: set = set_health

## Internal alive state flag. True when health > 0.
var _alive: bool = false: set = set_alive

## Internal array storing currently colliding HitBoxes (for continuous damage).
var bs: Array = []

## Set the maximum health value and scale current health proportionally.
## Emits max_health_changed signal and adjusts current health to maintain the same percentage.
## [br][br]
## [param value] The new maximum health value
func set_max_health(value: float):
	emit_signal("max_health_changed", value, value - max_health)
	self.health = value * float(health) / float(max_health)
	max_health = value

## Set the current health value with automatic clamping and state management.
## Emits health_changed signal and manages alive/dead state transitions.
## [br][br]
## [param value] The new health value
func set_health(value: float):
	var delta := value - health
	emit_signal("health_changed", value, delta)
	if health <= 0 and delta > 0:
		_alive = true
	if is_node_ready():
		health = min(value, max_health)
	else:
		_alive = true
		health = value
	if health <= 0 and _alive:
		_alive = false
		health = 0

## Set the alive state and emit the alive signal.
## [br][br]
## [param value] The new alive state
func set_alive(value: bool):
	_alive = value
	alive.emit(_alive)

## Set the invincibility state and update collision monitoring.
## Disables collision detection while invincible to prevent damage.
## [br][br]
## [param v] The new invincibility state
func set_invincible(v):
	invincible = v
	self.set_deferred("monitorable", !v)
	self.set_deferred("monitoring", !v)
	if invincible:
		emit_signal("invi_started")
	else:
		emit_signal("invi_ended")

## Start invincibility frames for a specified duration.
## Automatically ends invincibility when the timer expires.
## [br][br]
## [param duration] Duration of invincibility in seconds (uses tspeed if not specified)
func start_invincible(duration: float = tspeed):
	if duration > 0:
		self.invincible = true
		t.start(duration)

## Initialize the HurtBox when entering the scene tree.
## Sets up signal connections, initializes health values, and configures the invincibility timer.
func _ready():
	if not area_exited.is_connected(_on_area_shape_exited):
		area_shape_exited.connect(_on_area_shape_exited)
	if not area_shape_entered.is_connected(_on_area_shape_entered):
		area_shape_entered.connect(_on_area_shape_entered)

	emit_signal("max_health_changed", max_health, max_health)
	emit_signal("health_changed", health, health)
	t.name = "timer"
	add_child(t)
	t.timeout.connect(_on_timeout)
	if tspeed > 0:
		t.wait_time = tspeed

## Physics process for handling continuous damage from colliding HitBoxes.
## Cleans up invalid exceptions and applies damage from all active collisions.
## [br][br]
## [param delta] Time elapsed since the last physics frame
func _physics_process(delta: float) -> void:
	for i in exceptions.size():
		if exceptions[i] == null:
			exceptions.remove_at(i)
	for area_col in bs:
		_change_health_by_area(area_col, delta)

## Process damage from a specific HitBox collision, with optional raycast verification.
## Performs line-of-sight check if the HitBox requires raycast detection.
## [br][br]
## [param area_col] The CollisionShape2D that triggered the collision
## [param delta] Time delta for damage calculation
func _change_health_by_area(area_col, delta: float = 1.0):
	var area: HitBox = area_col.get_parent()
	if area.detect_by_ray:
		var length: float = 100
		var dir: Vector2 = area_col.global_position.direction_to(global_position)
		var space := get_world_2d().direct_space_state
		var from_pos: Vector2 = area_col.global_position - dir.normalized() * length
		var to_pos: Vector2 = from_pos + dir * length * 2
		var params = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
		params.exclude = [self.get_rid()]
		params.collision_mask = flags
		params.collide_with_areas = true
		var result = space.intersect_ray(params)
		if result.is_empty() or result.get("collider") == null or result.get("collider") is HitBox:
			_apply_dmg(area.damage, delta)
	else:
		_apply_dmg(area.damage, delta)

## Apply damage to the HurtBox and start invincibility frames.
## [br][br]
## [param damage] The amount of damage to apply
## [param delta] Time delta for scaling damage
func _apply_dmg(damage, delta):
	health -= damage * delta
	start_invincible()

## Handle HitBox exiting the collision area.
## Removes the HitBox from active collision tracking and manages single-detect exceptions.
## [br][br]
## [param _area_rid] The RID of the exiting area (unused)
## [param area] The HitBox that exited
## [param area_shape_index] The shape index of the exiting HitBox
## [param _local_shape_index] The local shape index (unused)
func _on_area_shape_exited(_area_rid: RID, area: HitBox, area_shape_index: int, _local_shape_index: int) -> void:
	if not is_instance_valid(area) and area == null:
		return
	if area in exceptions and area.single_detect and not invincible:
		exceptions.remove_at(exceptions.find(area))
	var other_shape_owner = area.shape_find_owner(area_shape_index)
	var area_col = area.shape_owner_get_owner(other_shape_owner)
	if bs.find(area_col) >= 0:
		bs.erase(area_col)

## Handle HitBox entering the collision area.
## Adds valid HitBoxes to collision tracking and applies immediate damage if needed.
## [br][br]
## [param _area_rid] The RID of the entering area (unused)
## [param area] The HitBox that entered
## [param area_shape_index] The shape index of the entering HitBox
## [param _local_shape_index] The local shape index (unused)
func _on_area_shape_entered(_area_rid: RID, area: HitBox, area_shape_index: int, _local_shape_index: int) -> void:
	if !(area in exceptions) and health > 0:
		var other_shape_owner = area.shape_find_owner(area_shape_index)
		var area_col = area.shape_owner_get_owner(other_shape_owner)
		if area.single_detect:
			if not area.stepped:
				exceptions.append(area)
			_change_health_by_area(area_col)
		else:
			bs.append(area_col)

## Handle invincibility timer timeout.
## Automatically ends invincibility frames when the timer expires.
func _on_timeout():
	self.invincible = false
