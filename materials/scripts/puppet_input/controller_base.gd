extends Node
class_name BaseController

@export var enabled:=true
@export var puppet:Puppet

var input_direction: Vector2
var jump_held: bool

func input_control():
	pass

func _physics_process(_delta: float) -> void:
	input_control()
	puppet.jump_held=jump_held
	puppet.input_direction=input_direction
