extends Action
class_name GravityAction3D

@export_range(0.001, 2, 0.001, "or_greater") var apex: float = 0.35
@export_range(0.001, 2, 0.001, "or_greater") var fall: float = 0.35
var velocity:Vector3

func _action(delta:float) -> void:
	velocity.y -= apex * delta

func _not_action(delta:float) -> void:
	velocity.y -= fall * delta
