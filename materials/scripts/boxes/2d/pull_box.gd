## PullBox2D - 2D attraction area that pulls physics bodies toward itself.
##
## This class creates an area in 2D space that attracts physics bodies (CharacterBody2D, RigidBody2D)
## toward its center with configurable speed and detection modes. Useful for creating
## magnets, vacuum effects, or gravitational pulls in 2D games.
## [br][br]
## [codeblock]
## # Basic usage:
## var pull_box = PullBox2D.new()
## pull_box.speed = 300.0
## pull_box.enabled = true
## pull_box.single_detect = false  # Continuous pulling
## add_child(pull_box)
## [/codeblock]

class_name PullBox2D
extends Area2D

## Whether the pull effect is currently active in 2D space.
## When disabled, no pulling forces are applied to entering bodies.
@export var enabled: bool = true:
	set(v):
		enabled=v
		monitorable=v
		monitoring=v

## Speed at which bodies are pulled toward the center (units per second).
## This value determines the magnitude of the attraction force in 2D space.
@export var speed: float = 200

## Whether bodies should only be affected once or continuously in 2D.
## When true, bodies are only pulled when they first enter the area.
## When false, continuous pulling is applied during overlap.
@export var single_detect: bool = false

## Array of Node2D objects that should be excluded from the pull effect.
## Bodies in this array will not be affected by the PullBox2D attraction.
@export var exceptions: Array[Node2D]

## Internal array storing 2D bodies currently being pulled (for continuous mode).
## This array tracks bodies that are actively being affected by the pull force.
var bs: Array = []

## Initialize the PullBox2D when entering the scene tree.
## This method connects body enter/exit signals for 2D pull detection.
## [br][br]
## Critical initialization:
## - Connects body_exited signal to _on_body_exited
## - Connects body_entered signal to _on_body_entered
## - Ensures proper 2D physics body signal handling
func _ready():
	body_exited.connect(_on_body_exited)
	body_entered.connect(_on_body_entered)

## Handles 2D body exit events, removing bodies from the pull list.
## This method manages cleanup when bodies leave the PullBox2D area.
## [br][br]
## Critical implementation details:
## - Validates body instance existence before processing
## - Removes bodies from the active pull tracking array
## - Prevents processing of invalid or destroyed bodies
##
## [param body] The 2D body that exited the PullBox2D area
func _on_body_exited(body: Node2D) -> void:
	if not is_instance_valid(body) and body == null:
		return
	if bs.find(body) >= 0:
		bs.erase(body)

## Handles 2D body enter events, adding valid bodies to the pull effect.
## This method processes new bodies entering the PullBox2D area.
## [br][br]
## Critical implementation details:
## - Checks exception list to prevent unwanted attraction
## - Handles single_detect mode for one-time effects
## - Manages continuous mode by adding bodies to tracking array
##
## [param body] The 2D body that entered the PullBox2D area
func _on_body_entered(body: Node2D) -> void:
	if !(body in exceptions):
		if single_detect:
			_update(body,1)
		else:
			bs.append(body)

## Physics process for continuous pull effects in 2D space.
## This method updates all tracked bodies and performs cleanup operations.
## [br][br]
## Critical processing logic:
## - Removes null references from exceptions array
## - Applies pull force to all tracked bodies each physics frame
## - Ensures continuous attraction for overlapping bodies
func _physics_process(delta: float) -> void:
	for i in exceptions.size():
		if exceptions[i] == null:
			exceptions.remove_at(i)
	for i in bs: _update(i,delta)

## Applies the pull force to a specific 2D body based on PullBox2D rotation and speed.
## This method calculates and applies attraction forces in 2D space.
## [br][br]
## Critical implementation details:
## - Converts Euler angles to direction vector for 2D movement
## - Scales direction vector by speed for force magnitude
## - Handles both CharacterBody2D and RigidBody2D physics types
## - Applies velocity directly for immediate attraction effect
##
## [param body] The 2D body to apply the pull force to
func _update(body: Node2D,delta:float):
	var vec := _move(global_rotation_degrees) * speed * delta
	if body is CharacterBody2D:
		body.velocity += vec
	elif body is RigidBody2D:
		body.linear_velocity += vec

## Creates a unit vector in the direction of the given 2D rotation.
## This method converts Euler angles to a normalized direction vector.
## [br][br]
## Critical implementation:
## - Returns normalized vector pointing in the PullBox2D's forward direction
## - Essential for 2D spatial calculations and force application
##
## [param angle_deg] The angle in degrees
## [return] A normalized Vector2 pointing in the specified 2D direction
func _move(angle_deg: float) -> Vector2:
	return Vector2(cos(deg_to_rad(angle_deg)), sin(deg_to_rad(angle_deg)))
