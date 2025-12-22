class_name CustomDetectingArea2D
extends Area2D

@export var body_entered_callbacks: Array[DynamicExpression] = []
@export var body_exited_callbacks: Array[DynamicExpression] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(_body:Node2D):
	for cd in body_entered_callbacks:
		cd.execute(self)

func _on_body_exited(_body:Node2D):
	for cd in body_exited_callbacks:
		cd.execute(self)
