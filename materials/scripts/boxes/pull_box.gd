extends Area2D
class_name PullBox
@export var enabled:bool=true
@export var speed:float=200
@export var single_detect:bool=false
@export var exceptions:Array[Node2D]

var bs:Array=[]

func _ready():
	body_exited.connect(_on_body_exited)
	body_entered.connect(_on_body_entered)

func _on_body_exited(body: Node2D) -> void:
	if not is_instance_valid(body) and body==null:
		return
	if bs.find(body)>=0:
		bs.erase(body)

func _on_body_entered(body: Node2D) -> void:
	if !(body in exceptions):
		if single_detect:
			_update(body)
		else:
			bs.append(body)

func _physics_process(_delta: float) -> void:
	for i in exceptions.size():
		if exceptions[i]==null:
			exceptions.remove_at(i)
	for i in bs: _update(i)

func _update(body:Node2D):
	if enabled:
		var vec:=_move(global_rotation_degrees)*speed
		if body is CharacterBody2D:
			body.velocity=vec
		elif body is RigidBody2D:
			body.linear_velocity=vec

func _move(angle_deg:float)->Vector2:
	return Vector2(cos(deg_to_rad(angle_deg)),sin(deg_to_rad(angle_deg)))
