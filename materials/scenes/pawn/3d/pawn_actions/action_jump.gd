extends PawnAction
class_name JumpPawnAction3D

signal jump_count_max_changed(jump_count: int)

@export var jump_count_max: int = 1:
	set(v):
		jump_count_max = v
		jump_count_max_changed.emit(v)
@export var height: float = 1
@export var distance: float = 2.5
@export_range(0.001, 2, 0.001, "or_greater") var time_to_apex: float = 0.35
@export_range(0.001, 2, 0.001, "or_greater") var time_to_land: float = 0.35

var buffer := Buffer.new(0.1, 0.1)
var jump_velocity: float

func _on_action(_delta:float) -> void:
	if buffer.should_run_action():
		pawn_node.is_jumping = true
		pawn_node._on_ground = false
		pawn_node.jump_count += 1
		pawn_node.velocity.x = pawn_node.input_direction.x * abs(pawn_node.velocity.x)
		pawn_node.velocity.z = pawn_node.input_direction.y * abs(pawn_node.velocity.z)
		pawn_node.velocity.y = jump_velocity

	elif not pawn_node.is_jumping and not pawn_node._on_ground and pawn_node.jump_count == 0:
		pawn_node.jump_count += 1

	if pawn_node.jump_released and pawn_node.velocity.y > 0:
		pawn_node.velocity.y *= 0.5

func _additional(delta:float) -> void:
	buffer.update(pawn_node.want_jump, pawn_node.jump_count < jump_count_max, delta)
