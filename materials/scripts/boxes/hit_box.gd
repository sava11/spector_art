class_name HitBox
extends Area2D
@export var damage:float=1.0
@export var deletion_timer:float=0
@export var detect_by_ray:=true
@export var single_detect:=false
@export var stepped:=true

func _ready() -> void:
	if deletion_timer>0:
		var t=Timer.new()
		t.timeout.connect(queue_free)
		add_child(t)
		t.start(deletion_timer)
