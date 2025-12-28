@abstract
extends Node
class_name BaseController

@export var enabled:=true
@export var puppet_pawn:Node

var look_direction:=Vector2.ZERO
var want_attack:=false
var input_direction: Vector2
var jump_held: bool
var dash_held: bool

func input_control():
	pass

func reset():
	jump_held=false
	look_direction=Vector2.ZERO
	input_direction=Vector2.ZERO
	want_attack=false

func _physics_process(_delta: float) -> void:
	if enabled:
		input_control()
	else:
		reset()
	puppet_pawn.input_direction=input_direction
	puppet_pawn.look_direction=look_direction
	puppet_pawn.want_attack=want_attack
	puppet_pawn.dash_held=dash_held
	puppet_pawn.jump_held=jump_held
