extends Action
class_name AttackAction2D

## 2D attack action system for pawn characters.
##
## Manages sequential attack combos with configurable HitBox2D components and timing.
## Supports attack buffering, combo chains, and automatic progression through attack sequences.
## [br][br]
## [codeblock]
## # Setup attack sequence:
## attack_action.attacks_paths = [$HitBox1, $HitBox2, $HitBox3]
## attack_action.attacks = {0: 0.5, 1: 0.7, 2: 1.0}  # attack index -> duration
##
## # Trigger attack in pawn controller:
## attack_action.want_attack = true
## [/codeblock]

## Array of HitBox2D nodes used for attacks in sequence.
## Each HitBox2D corresponds to an attack in the combo chain.
@export var attacks_paths: Array[HitBox2D]

## Dictionary mapping attack indices to their duration in seconds.
## Format: {attack_index: duration_seconds}
## Example: {0: 0.5, 1: 0.7, 2: 1.0}
@export var attacks: Dictionary[int, float]

## Input buffer for attack actions to improve responsiveness.
var attack_buffer := Buffer.new(0.2, 0.2)

## Whether the player wants to perform an attack (input state).
var want_attack := false

## Whether an attack is currently active and being executed.
var attacking := false

## Current attack index in the combo sequence.
var cur_att: int = 0

## Duration of the currently active attack in seconds.
var current_time: float = 0.0

## Timer tracking how long the current attack has been active.
var current_timer: float = 0.0

## Initialize the attack action system.
## Sets up the starting attack index based on available attacks.
func _ready() -> void:
	if attacks.size() > 0:
		var keys = attacks.keys()
		keys.sort()
		cur_att = keys[0]  # Start with the lowest attack index
	else:
		cur_att = 0

## Main attack action logic called every frame.
## Handles attack timing, combo progression, and attack state management.
## [br][br]
## [param delta] Time elapsed since last frame in seconds
func _action(delta: float) -> void:
	# First, handle finishing current attack
	if attacking:
		current_timer += delta
		if current_timer >= current_time:
			# Finish current attack - deactivate hitbox and reset state
			var n := attacks_paths[cur_att]
			n.monitoring = false  # Stop detecting collisions
			n.monitorable = false  # Make non-collidable
			n.hide()  # Hide visual representation
			attacking = false
			current_timer = 0.0
			current_time = 0.0

			# Move to next attack in combo sequence
			if attacks.size() > 0:
				cur_att = wrap(cur_att + 1, 0, attacks.size())

	# Then, check if we should start a new attack
	if attack_buffer.should_run_action() and not attacking:
		# Validate attack configuration before starting
		if attacks.size() > 0 and cur_att < attacks.size() and \
			attacks.has(cur_att) and cur_att < attacks_paths.size():
			current_time = attacks[cur_att]  # Set duration for this attack
			var n := attacks_paths[cur_att]
			n.monitoring = true  # Enable collision detection
			n.monitorable = true  # Make collidable
			n.show()  # Show visual representation
			attacking = true
			current_timer = 0.0

	# Reset to first attack when appropriate (input buffer timeout)
	if attack_buffer.get_post_buffer_time_passed() == 0.0 and \
	   attack_buffer.get_pre_buffer_time_passed() == attack_buffer.pre_buffer_max_time:
		if attacks.size() > 0:
			cur_att = 0

## Additional update logic called every frame.
## Updates the attack input buffer with current state.
## [br][br]
## [param delta] Time elapsed since last frame in seconds
func _addition(delta: float) -> void:
	# Update attack buffer: input state, can attack condition, delta time
	attack_buffer.update(want_attack and attacks.size() > 0, not attacking, delta)
