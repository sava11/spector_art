## PullBox - Attraction area that pulls physics bodies toward itself.
##
## This class creates an area that attracts physics bodies (CharacterBody2D, RigidBody2D)
## toward its center with configurable speed and detection modes. Useful for creating
## magnets, vacuum effects, or gravitational pulls in 2D games.
## [br][br]
## [codeblock]
## # Basic usage:
## var pull_box = PullBox.new()
## pull_box.speed = 300.0
## pull_box.enabled = true
## pull_box.single_detect = false  # Continuous pulling
## add_child(pull_box)
## [/codeblock]

extends Area2D
class_name PullBox

## Whether the pull effect is currently active.
@export var enabled: bool = true

## Speed at which bodies are pulled toward the center (units per second).
@export var speed: float = 200

## Whether bodies should only be affected once or continuously.
## When true, bodies are only pulled when they first enter the area.
@export var single_detect: bool = false

## Array of Node2D objects that should be excluded from the pull effect.
@export var exceptions: Array[Node2D]

## Internal array storing bodies currently being pulled (for continuous mode).
var bs: Array = []

## Initialize the PullBox when entering the scene tree.
## Connects body enter/exit signals for pull detection.
func _ready():
	body_exited.connect(_on_body_exited)
	body_entered.connect(_on_body_entered)

## Handles body exit events, removing bodies from the pull list.
## [br][br]
## [param body] The body that exited the PullBox area
func _on_body_exited(body: Node2D) -> void:
	if not is_instance_valid(body) and body == null:
		return
	if bs.find(body) >= 0:
		bs.erase(body)

## Handles body enter events, adding valid bodies to the pull effect.
## [br][br]
## [param body] The body that entered the PullBox area
func _on_body_entered(body: Node2D) -> void:
	if !(body in exceptions):
		if single_detect:
			_update(body)
		else:
			bs.append(body)

## Physics process for continuous pull effects.
## Updates all tracked bodies and cleans up invalid exceptions.
func _physics_process(_delta: float) -> void:
	for i in exceptions.size():
		if exceptions[i] == null:
			exceptions.remove_at(i)
	for i in bs: _update(i)

## Applies the pull force to a specific body based on PullBox rotation and speed.
## [br][br]
## [param body] The body to apply the pull force to
func _update(body: Node2D):
	if enabled:
		var vec := _move(global_rotation_degrees) * speed
		if body is CharacterBody2D:
			body.velocity = vec
		elif body is RigidBody2D:
			body.linear_velocity = vec

## Creates a unit vector in the direction of the given angle.
## [br][br]
## [param angle_deg] The angle in degrees
## [return] A normalized Vector2 pointing in the specified direction
func _move(angle_deg: float) -> Vector2:
	return Vector2(cos(deg_to_rad(angle_deg)), sin(deg_to_rad(angle_deg)))
