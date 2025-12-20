class_name ParryBox
extends Area2D

signal self_knockback(direcion:Vector2)
signal parried(area:HitBox)

func _ready():
	area_shape_entered.connect(_on_area_shape_entered)

func _on_area_shape_entered(_area_rid: RID, area: HitBox, area_shape_index: int, _local_shape_index: int) -> void:
	parried.emit(area)
	var area_col:CollisionShape2D=area.get_child(area_shape_index)
	var knockback_direction:Vector2=(global_position - area_col.global_position).normalized()
	self_knockback.emit(knockback_direction)
