@abstract
extends Node
class_name BaseController

@export var enabled:=true
@export var puppet_pawn:Node

var input_direction: Vector2
var jump_held: bool

func input_control():
	pass

func reset():
	jump_held=false
	input_direction=Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if enabled:
		input_control()
	else:
		reset()
	puppet_pawn.jump_held=jump_held
	puppet_pawn.input_direction=input_direction
