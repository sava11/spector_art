## ParryBox3D - Defensive collision area for parrying HitBox3D attacks in 3D space.
##
## This class defines defensive collision areas that can intercept and parry HitBox3D attacks.
## When a HitBox3D enters the ParryBox3D area, it calculates 3D knockback direction and emits signals
## for game logic to handle the parry mechanics in three-dimensional space.
## [br][br]
## [codeblock]
## # Basic usage:
## var parry_box = ParryBox3D.new()
## parry_box.parried.connect(_on_parry_successful)
## parry_box.self_knockback.connect(_apply_knockback)
## add_child(parry_box)
##
## func _on_parry_successful(hitbox: HitBox3D):
##     # Handle successful parry logic
##     pass
## [/codeblock]

class_name ParryBox3D
extends Area3D

## Emitted when the ParryBox3D successfully parries a HitBox3D.
## Provides the 3D knockback direction vector for the defending entity.
## [br][br]
## [param direction] Normalized Vector3 pointing away from the HitBox3D collision point
signal self_knockback(direction: Vector3)

## Emitted when a HitBox3D is successfully parried.
## Connect to this signal to handle parry success events and trigger game logic.
## [br][br]
## [param area] The HitBox3D that was parried
signal parried(area: HitBox3D)

## Initialize the ParryBox3D when entering the scene tree.
## This method sets up collision detection by connecting the area shape entered signal.
## [br][br]
## Critical initialization:
## - Connects area_shape_entered signal to _on_area_shape_entered
## - Ensures proper signal handling for parry detection
func _ready():
	area_shape_entered.connect(_on_area_shape_entered)

## Handles collision detection when a HitBox3D enters the ParryBox3D area.
## This method processes parry events, calculates 3D knockback direction, and emits signals.
## [br][br]
## Critical implementation details:
## - Emits parried signal with the intercepted HitBox3D
## - Calculates normalized direction from collision point to ParryBox3D center
## - Provides 3D knockback vector for physics-based parry responses
##
## [param _area_rid] The RID of the entering area (unused parameter)
## [param area] The HitBox3D that entered the ParryBox3D
## [param area_shape_index] The shape index of the entering HitBox3D
## [param _local_shape_index] The local shape index (unused parameter)
func _on_area_shape_entered(_area_rid: RID, area: HitBox3D, area_shape_index: int, _local_shape_index: int) -> void:
	parried.emit(area)
	var area_col: CollisionShape3D = area.get_child(area_shape_index)
	var knockback_direction: Vector3 = (global_position - area_col.global_position).normalized()
	self_knockback.emit(knockback_direction)
