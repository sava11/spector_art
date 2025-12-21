## ParryBox - Defensive collision area for parrying HitBox attacks.
##
## This class defines defensive collision areas that can intercept and parry HitBox attacks.
## When a HitBox enters the ParryBox area, it calculates knockback direction and emits signals
## for game logic to handle the parry mechanics.
## [br][br]
## [codeblock]
## # Basic usage:
## var parry_box = ParryBox.new()
## parry_box.parried.connect(_on_parry_successful)
## parry_box.self_knockback.connect(_apply_knockback)
## add_child(parry_box)
##
## func _on_parry_successful(hitbox: HitBox):
##     # Handle successful parry logic
##     pass
## [/codeblock]

class_name ParryBox
extends Area2D

## Emitted when the ParryBox successfully parries a HitBox.
## Provides the knockback direction vector for the defending entity.
signal self_knockback(direction: Vector2)

## Emitted when a HitBox is successfully parried.
## [br][br]
## [param area] The HitBox that was parried
signal parried(area: HitBox)

## Initialize the ParryBox when entering the scene tree.
## Connects the area shape entered signal to handle parry detection.
func _ready():
	area_shape_entered.connect(_on_area_shape_entered)

## Handles collision detection when a HitBox enters the ParryBox area.
## Calculates knockback direction and emits parry signals.
## [br][br]
## [param _area_rid] The RID of the entering area (unused)
## [param area] The HitBox that entered the ParryBox
## [param area_shape_index] The shape index of the entering HitBox
## [param _local_shape_index] The local shape index (unused)
func _on_area_shape_entered(_area_rid: RID, area: HitBox, area_shape_index: int, _local_shape_index: int) -> void:
	parried.emit(area)
	var area_col: CollisionShape2D = area.get_child(area_shape_index)
	var knockback_direction: Vector2 = (global_position - area_col.global_position).normalized()
	self_knockback.emit(knockback_direction)
