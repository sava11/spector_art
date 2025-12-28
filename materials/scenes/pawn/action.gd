extends Node
class_name Action

@export var executable_expression:DynamicExpression
@export var pre_expressions:Array[DynamicExpression]
@export var post_expressions:Array[DynamicExpression]


func _physics_process(delta: float) -> void:
	for e in pre_expressions:
		e.execute(self)
	if executable_expression==null or (executable_expression!=null and executable_expression.execute(self)):
		_action(delta)
	else:
		_not_action(delta)
	_addition(delta)
	for e in post_expressions:
		e.execute(self)

func _action(delta:float) -> void: pass

func _not_action(delta:float) -> void: pass

func _addition(delta:float) -> void: pass
