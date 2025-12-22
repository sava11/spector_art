## HurtBox3D - Damageable collision area that receives damage from HitBox3D entities in 3D space.
##
## This class defines damageable collision areas that can receive damage from HitBox3D attacks.
## Manages health, invincibility frames, and various damage detection modes. Supports
## 3D raycast verification, single-hit detection, and automatic invincibility timers.
## Designed for 3D game environments with comprehensive health management.
## [br][br]
## [codeblock]
## # Basic usage:
## var hurt_box = HurtBox3D.new()
## hurt_box.max_health = 100.0
## hurt_box.tspeed = 0.5  # 0.5 second invincibility frames
## hurt_box.health_changed.connect(_on_health_changed)
## hurt_box.alive.connect(_on_alive_changed)
## add_child(hurt_box)
##
## func _on_health_changed(value: float, delta: float):
##     health_bar.value = value
## [/codeblock]

class_name HurtBox3D
extends Area3D

## Emitted when invincibility frames begin.
## Connect to this signal to handle invincibility start events.
signal invi_started

## Emitted when invincibility frames end.
## Connect to this signal to handle invincibility end events.
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

## Physics layer flags for 3D raycast collision detection.
## Used when detect_by_ray is enabled on HitBox3D instances to determine
## what layers to check during line-of-sight verification in 3D space.
@export_flags_3d_physics() var flags: int = 0

## Array of HitBox3D exceptions that should be ignored for damage.
## Useful for preventing self-damage or friendly fire scenarios.
## Add HitBox3D instances to this array to exclude them from damage calculations.
@export var exceptions: Array[HitBox3D]

## Default duration for invincibility frames in seconds.
## This value determines how long the HurtBox3D remains invincible after taking damage.
@export var tspeed: float = 1.0

## Maximum health value. Setting this automatically scales current health proportionally.
## This property controls the upper limit for health values and triggers health scaling.
@export var max_health: float = 1: set = set_max_health

## Internal timer for managing invincibility duration.
## Automatically created and configured during initialization.
@onready var t: Timer = Timer.new()

## Whether the HurtBox3D is currently invincible and immune to damage.
## This state automatically disables collision monitoring when active.
var invincible: bool = false: set = set_invincible

## Current health value. Automatically clamped between 0 and max_health.
## This value represents the entity's current vitality level.
var health: float = max_health: set = set_health

## Internal alive state flag. True when health > 0.
## This flag tracks whether the entity should be considered alive or dead.
var _alive: bool = false: set = set_alive

## Internal array storing currently colliding HitBox3D collision shapes.
## Used for continuous damage tracking from overlapping HitBox3D instances.
var bs: Array = []

## Set the maximum health value and scale current health proportionally.
## This method emits the max_health_changed signal and adjusts current health
## to maintain the same percentage ratio when maximum health changes.
## [br][br]
## Critical implementation details:
## - Emits max_health_changed signal with old and new values
## - Automatically scales current health to maintain health percentage
## - Ensures health never exceeds the new maximum
##
## [param value] The new maximum health value (must be positive)
func set_max_health(value: float):
	emit_signal("max_health_changed", value, value - max_health)
	self.health = value * float(health) / float(max_health)
	max_health = value

## Set the current health value with automatic clamping and state management.
## This method handles health changes, emits appropriate signals, and manages
## alive/dead state transitions automatically.
## [br][br]
## Critical implementation details:
## - Emits health_changed signal with new value and delta
## - Handles edge cases for health transitions (death to life, etc.)
## - Automatically clamps health between 0 and max_health
## - Manages alive state based on health threshold
##
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
## This method manages the entity's alive/dead state and notifies listeners.
## [br][br]
## [param value] The new alive state (true for alive, false for dead)
func set_alive(value: bool):
	_alive = value
	alive.emit(_alive)

## Set the invincibility state and update collision monitoring.
## This method controls damage immunity and collision detection state.
## [br][br]
## Critical implementation details:
## - Disables collision monitoring while invincible to prevent damage
## - Emits invi_started/invi_ended signals appropriately
## - Uses deferred calls to ensure safe state changes during physics processing
##
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
## This method activates temporary damage immunity with automatic timeout.
## [br][br]
## Critical implementation details:
## - Immediately sets invincible state to true
## - Starts the internal timer with specified or default duration
## - Timer automatically calls _on_timeout when expired
##
## [param duration] Duration of invincibility in seconds (uses tspeed if not specified)
func start_invincible(duration: float = tspeed):
	if duration > 0:
		self.invincible = true
		t.start(duration)

## Initialize the HurtBox3D when entering the scene tree.
## This method sets up signal connections, initializes health values,
## and configures the invincibility timer system.
## [br][br]
## Critical initialization steps:
## - Connects collision detection signals
## - Emits initial health and max health signals
## - Configures and adds the invincibility timer
## - Sets up automatic timer management
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

## Physics process for handling continuous damage from colliding HitBox3D entities.
## This method manages ongoing damage application and cleanup of invalid exceptions.
## [br][br]
## Critical processing logic:
## - Removes null references from exceptions array
## - Applies damage from all active collision shapes
## - Runs every physics frame for real-time damage calculation
##
## [param delta] Time elapsed since the last physics frame
func _physics_process(delta: float) -> void:
	for i in exceptions.size():
		if exceptions[i] == null:
			exceptions.remove_at(i)
	for area_col in bs:
		_change_health_by_area(area_col, delta)

## Process damage from a specific HitBox3D collision, with optional 3D raycast verification.
## This method handles individual collision damage with line-of-sight checking.
## [br][br]
## Critical implementation details:
## - Performs 3D raycast when HitBox3D requires line-of-sight verification
## - Uses physics space state for accurate 3D raycasting
## - Excludes self from raycast to prevent false positives
## - Applies damage only when raycast succeeds or is disabled
##
## [param area_col] The CollisionShape3D that triggered the collision
## [param delta] Time delta for damage scaling
func _change_health_by_area(area_col, delta: float = 1.0):
	var area: HitBox3D = area_col.get_parent()
	if area.detect_by_ray:
		var length: float = 100
		var dir: Vector3 = area_col.global_position.direction_to(global_position)
		var space := get_world_3d().direct_space_state
		var from_pos: Vector3 = area_col.global_position - dir.normalized() * length
		var to_pos: Vector3 = from_pos + dir * length * 2
		var params = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
		params.exclude = [self.get_rid()]
		params.collision_mask = flags
		params.collide_with_areas = true
		var result = space.intersect_ray(params)
		if result.is_empty() or result.get("collider") == null or result.get("collider") is HitBox3D:
			_apply_dmg(area.damage, delta)
	else:
		_apply_dmg(area.damage, delta)

## Apply damage to the HurtBox3D and start invincibility frames.
## This method processes damage application and triggers defensive cooldown.
## [br][br]
## [param damage] The amount of damage to apply
## [param delta] Time delta for scaling damage over time
func _apply_dmg(damage, delta):
	health -= damage * delta
	start_invincible()

## Handle HitBox3D exiting the collision area.
## This method manages collision cleanup and single-detect exception handling.
## [br][br]
## Critical implementation details:
## - Validates HitBox3D instance existence before processing
## - Removes HitBox3D from active collision tracking
## - Handles single-detect mode exception management
## - Ensures safe removal during invincibility periods
##
## [param _area_rid] The RID of the exiting area (unused)
## [param area] The HitBox3D that exited
## [param area_shape_index] The shape index of the exiting HitBox3D
## [param _local_shape_index] The local shape index (unused)
func _on_area_shape_exited(_area_rid: RID, area: HitBox3D, area_shape_index: int, _local_shape_index: int) -> void:
	if not is_instance_valid(area) and area == null:
		return
	if area in exceptions and area.single_detect and not invincible:
		exceptions.remove_at(exceptions.find(area))
	var other_shape_owner = area.shape_find_owner(area_shape_index)
	var area_col = area.shape_owner_get_owner(other_shape_owner)
	if bs.find(area_col) >= 0:
		bs.erase(area_col)

## Handle HitBox3D entering the collision area.
## This method processes new collisions and initiates damage application.
## [br][br]
## Critical implementation details:
## - Validates health threshold before processing collisions
## - Checks exception list to prevent unwanted damage
## - Handles single-detect mode with immediate damage and exception addition
## - Manages continuous collision tracking for ongoing damage
##
## [param _area_rid] The RID of the entering area (unused)
## [param area] The HitBox3D that entered
## [param area_shape_index] The shape index of the entering HitBox3D
## [param _local_shape_index] The local shape index (unused)
func _on_area_shape_entered(_area_rid: RID, area: HitBox3D, area_shape_index: int, _local_shape_index: int) -> void:
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
## This method automatically ends invincibility frames when the timer expires.
## [br][br]
## Critical implementation:
## - Automatically resets invincible state to false
## - Allows normal collision detection to resume
func _on_timeout():
	self.invincible = false
