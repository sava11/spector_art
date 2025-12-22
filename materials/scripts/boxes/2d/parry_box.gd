## ParryBox2D - Defensive collision area for parrying HitBox2D attacks in 2D space.
##
## This class defines defensive collision areas that can intercept and parry HitBox2D attacks.
## When a HitBox2D enters the ParryBox2D area, it calculates 2D knockback direction and emits signals
## for game logic to handle the parry mechanics in two-dimensional space.
## [br][br]
## [codeblock]
## # Basic usage:
## var parry_box = ParryBox2D.new()
## parry_box.parried.connect(_on_parry_successful)
## parry_box.self_knockback.connect(_apply_knockback)
## add_child(parry_box)
##
## func _on_parry_successful(hitbox: HitBox2D):
##     # Handle successful parry logic
##     pass
## [/codeblock]

class_name ParryBox2D
extends Area2D

## Emitted when the ParryBox2D successfully parries a HitBox2D.
## Provides the 2D knockback direction vector for the defending entity.
signal self_knockback(direction: Vector2)

## Emitted when a HitBox2D is successfully parried.
## Connect to this signal to handle parry success events and trigger game logic.
## [br][br]
## [param area] The HitBox2D that was parried
signal parried(area: HitBox2D)

## Initialize the ParryBox2D when entering the scene tree.
## This method sets up collision detection by connecting the area shape entered signal.
## [br][br]
## Critical initialization:
## - Connects area_shape_entered signal to _on_area_shape_entered
## - Ensures proper signal handling for parry detection
func _ready():
	area_shape_entered.connect(_on_area_shape_entered)

## Handles collision detection when a HitBox2D enters the ParryBox2D area.
## This method processes parry events, calculates 2D knockback direction, and emits signals.
## [br][br]
## [param _area_rid] The RID of the entering area (unused)
## [param area] The HitBox2D that entered the ParryBox2D
## [param area_shape_index] The shape index of the entering HitBox2D
## [param _local_shape_index] The local shape index (unused)
func _on_area_shape_entered(_area_rid: RID, area: HitBox2D, area_shape_index: int, _local_shape_index: int) -> void:
	parried.emit(area)
	var area_col: CollisionShape2D = area.get_child(area_shape_index)
	var knockback_direction: Vector2 = (global_position - area_col.global_position).normalized()
	self_knockback.emit(knockback_direction)
