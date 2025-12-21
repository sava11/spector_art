## HitBox - Offensive collision area for dealing damage to HurtBoxes.
##
## This class defines offensive collision areas that can damage HurtBox-equipped entities.
## Supports various detection modes and automatic cleanup for projectile-like behavior.
## [br][br]
## [codeblock]
## # Basic usage:
## var hitbox = HitBox.new()
## hitbox.damage = 25.0
## hitbox.deletion_timer = 2.0  # Auto-destroy after 2 seconds
## add_child(hitbox)
## [/codeblock]

class_name HitBox
extends Area2D

## Amount of damage to deal to HurtBoxes on contact.
@export var damage: float = 1.0

## Time in seconds after which this HitBox will automatically delete itself.
## Useful for projectiles that should disappear after a certain time.
@export var deletion_timer: float = 0

## Whether to use raycast detection instead of direct area collision.
## When true, performs a raycast to verify line-of-sight before applying damage.
@export var detect_by_ray: bool = true

## Whether this HitBox should only trigger once per HurtBox.
## When true, adds the HurtBox to exceptions after first contact.
@export var single_detect: bool = false

## Internal flag for single_detect logic.
## Tracks whether this HitBox has already interacted with a HurtBox.
var stepped: bool = true

## Initialize the HitBox when entering the scene tree.
## Sets up automatic deletion timer if configured.
func _ready() -> void:
	if deletion_timer > 0:
		var t = Timer.new()
		t.timeout.connect(queue_free)
		add_child(t)
		t.start(deletion_timer)
