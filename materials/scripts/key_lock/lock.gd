extends Node
class_name KLLock

signal activated(active: bool)

@export var expression: String
@export var keys: Array[String] # ["key_uid_0", "key_uid_1", ...]

var last_state := false

func _ready():
	KLD.key_changed.connect(_on_key_changed)
	_check()

func _key_value(index: int) -> bool:
	if index < 0 or index >= keys.size():
		return false
	var data = KLD.keys.get(keys[index])
	return data != null and data.activated and not data.blocked

func evaluate() -> bool:
	var expr := expression
	
	for i in keys.size():
		expr = expr.replace(
			str(i),
			str(_key_value(i)).to_lower()
		)
	
	expr = expr.replace("!", " not ")
	expr = expr.replace("&", " and ")
	expr = expr.replace("&&", " and ")
	expr = expr.replace("|", " or ")
	expr = expr.replace("||", " or ")
	
	var expr_obj:=Expression.new()
	return expr_obj.parse(expr) == OK \
		and expr_obj.execute()

func _on_key_changed(_uid, _state):
	_check()

func _check():
	var current = evaluate()
	if current != last_state:
		last_state = current
		activated.emit(current)
