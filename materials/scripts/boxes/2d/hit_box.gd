## HitBox2D - Offensive collision area for dealing damage to HurtBox2D entities in 2D space.
##
## This class defines offensive collision areas that can damage HurtBox2D-equipped entities.
## Supports various detection modes and automatic cleanup for projectile-like behavior.
## Designed for 2D game environments with raycast verification and collision detection.
## [br][br]
## [codeblock]
## # Basic usage:
## var hitbox = HitBox2D.new()
## hitbox.damage = 25.0
## hitbox.deletion_timer = 2.0  # Auto-destroy after 2 seconds
## add_child(hitbox)
## [/codeblock]

class_name HitBox2D
extends Area2D

## Amount of damage to deal to HurtBox2D entities on contact.
## This value represents the base damage per collision frame.
@export var damage: float = 1.0

## Time in seconds after which this HitBox will automatically delete itself.
## Useful for projectiles that should disappear after a certain time.
@export var deletion_timer: float = 0

## Whether to use raycast detection instead of direct area collision.
## When true, performs a raycast to verify line-of-sight before applying damage.
@export var detect_by_ray: bool = true

## Whether this HitBox2D should only trigger once per HurtBox2D.
## When true, adds the HurtBox2D to exceptions after first contact,
## preventing multiple damage applications from the same HitBox2D instance.
@export var single_detect: bool = false

## Internal flag for single_detect logic.
## Internal flag for single_detect logic.
## Tracks whether this HitBox2D has already interacted with a HurtBox2D.
## This flag is automatically managed and should not be modified directly.
var stepped: bool = true

## Initialize the HitBox2D when entering the scene tree.
## Sets up automatic deletion timer if configured and prepares the collision system.
## [br][br]
## This method handles critical initialization steps:
## - Creates and configures the deletion timer if deletion_timer > 0
## - Connects timeout signal to queue_free for automatic cleanup
## - Ensures proper lifecycle management for temporary HitBox2D instances
func _ready() -> void:
	if deletion_timer > 0:
		var t = Timer.new()
		t.timeout.connect(queue_free)
		add_child(t)
		t.start(deletion_timer)
