## HitBox3D - Offensive collision area for dealing damage to HurtBox3D entities in 3D space.
##
## This class defines offensive collision areas that can damage HurtBox3D-equipped entities.
## Supports various detection modes and automatic cleanup for projectile-like behavior.
## Designed for 3D game environments with raycast verification and collision detection.
## [br][br]
## [codeblock]
## # Basic usage:
## var hitbox = HitBox3D.new()
## hitbox.damage = 25.0
## hitbox.deletion_timer = 2.0  # Auto-destroy after 2 seconds
## add_child(hitbox)
## [/codeblock]

class_name HitBox3D
extends Area3D

## Amount of damage to deal to HurtBox3D entities on contact.
## This value represents the base damage per collision frame.
@export var damage: float = 1.0

## Time in seconds after which this HitBox3D will automatically delete itself.
## Set to 0 for permanent HitBoxes. Useful for projectiles that should disappear
## after a certain time or temporary attack effects.
@export var deletion_timer: float = 0

## Whether to use raycast detection instead of direct area collision.
## When enabled, performs a 3D raycast to verify line-of-sight before applying damage.
## This prevents damage through walls or other obstacles in 3D space.
@export var detect_by_ray: bool = true

## Whether this HitBox3D should only trigger once per HurtBox3D.
## When enabled, adds the HurtBox3D to exceptions after first contact,
## preventing multiple damage applications from the same HitBox3D instance.
@export var single_detect: bool = false

## Internal flag for single_detect logic.
## Tracks whether this HitBox3D has already interacted with a HurtBox3D.
## This flag is automatically managed and should not be modified directly.
var stepped: bool = true

## Initialize the HitBox3D when entering the scene tree.
## Sets up automatic deletion timer if configured and prepares the collision system.
## [br][br]
## This method handles critical initialization steps:
## - Creates and configures the deletion timer if deletion_timer > 0
## - Connects timeout signal to queue_free for automatic cleanup
## - Ensures proper lifecycle management for temporary HitBox3D instances
func _ready() -> void:
	if deletion_timer > 0:
		var t = Timer.new()
		t.timeout.connect(queue_free)
		add_child(t)
		t.start(deletion_timer)
