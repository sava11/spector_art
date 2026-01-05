extends PawnAction
class_name AttackPawnAction3D

signal on_reset
signal on_end(id:int,time:float)
signal on_start(id:int,time:float)

@export var attacks_paths:Array[HitBox3D]
@export var attacks:Dictionary[int,float]

var attack_buffer := Buffer.new(0.2, 0.2)
var attacking := false
var cur_att: int =0
var current_time:float=0.0
var current_timer:float=0.0

func _ready() -> void:
	super._ready()
	if attacks.size() > 0:
		var keys = attacks.keys()
		keys.sort()
		cur_att = keys[0]
	else:
		cur_att = 0

func _on_action(delta:float) -> void:
	# First, handle finishing current attack
	if attacking:
		current_timer += delta
		if current_timer >= current_time:
			# Finish current attack
			on_end.emit(cur_att,attacks_paths[cur_att])
			var n := attacks_paths[cur_att]
			n.monitoring = false
			n.monitorable = false
			n.hide()
			attacking = false
			current_timer = 0.0
			current_time = 0.0

			# Move to next attack
			if attacks.size() > 0:
				cur_att = wrap(cur_att + 1, 0, attacks.size())

	# Then, check if we should start a new attack
	if attack_buffer.should_run_action() and not attacking:
		if attacks.size() > 0 and cur_att < attacks.size() and \
			attacks.has(cur_att) and cur_att < attacks_paths.size():
			on_start.emit(cur_att,attacks[cur_att])
			current_time = attacks[cur_att]
			var n := attacks_paths[cur_att]
			n.monitoring = true
			n.monitorable = true
			n.show()
			attacking = true
			current_timer = 0.0

	# Reset to first attack when appropriate
	if attack_buffer.get_post_buffer_time_passed() == 0.0 and \
	   attack_buffer.get_pre_buffer_time_passed() == attack_buffer.pre_buffer_max_time:
		if attacks.size() > 0:
			on_reset.emit()
			cur_att = 0

func _additional(delta:float) -> void:
	attack_buffer.update(pawn_node.want_attack && !attacks.is_empty() && \
		!attacks_paths.is_empty(), not attacking, delta)
