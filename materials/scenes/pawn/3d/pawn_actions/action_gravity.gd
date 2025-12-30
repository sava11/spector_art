extends PawnAction
class_name GravityPawnAction3D

@export_range(0.001, 2, 0.001, "or_greater") var apex: float = 0.35
@export_range(0.001, 2, 0.001, "or_greater") var fall: float = 0.35

func _on_action(delta:float):
	pawn_node.velocity.y -= apex * delta

func _on_not_action(delta:float) -> void:
	pawn_node.velocity.y -= fall * delta
