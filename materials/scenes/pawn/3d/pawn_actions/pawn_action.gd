extends Node
class_name PawnAction

@export var pawn_node:Node

## Expression string to execute (mathematical, logical)
@export var expression: String = ""

## Dictionary of variables for use in the expression
## Keys - variable names, values - their values
## Supports NodePath that are converted to nodes during execution
@export var data: Dictionary[String, Variant] = {}

## Create Godot expression object
var expression_object := Expression.new()

var modified_data:Dictionary
var executable:int

func _ready() -> void:
	executable=expression_object.parse(expression, \
		PackedStringArray(data.keys()))==0
	modified_data = modify_data()
	if executable: expression_object.execute(modified_data.values())

## Converts NodePath to real nodes and returns a modified copy of the data
## @return: New dictionary with converted data
func modify_data() -> Dictionary[String, Variant]:
	var _modified_data:Dictionary = data.duplicate(true)  # Deep copy for safety
	_convert_nodepaths_recursive(_modified_data, self)
	return _modified_data

## Recursively converts all NodePath in the specified container
## @param container: Container to process (Dictionary or Array)
## @param from_what: Node for resolving NodePath
func _convert_nodepaths_recursive(container: Variant, from_what: Node) -> void:
	match typeof(container):
		TYPE_DICTIONARY:
			_convert_nodepaths_in_dictionary(container, from_what)
		TYPE_ARRAY:
			_convert_nodepaths_in_array(container, from_what)

## Converts NodePath in dictionary recursively
## @param dict: Dictionary to process
## @param from_what: Node for resolving paths
func _convert_nodepaths_in_dictionary(dict: Dictionary, from_what: Node) -> void:
	for key: String in dict.keys():
		var value: Variant = dict[key]

		if value is NodePath:
			# Convert NodePath to real node
			var node: Node = from_what.get_node_or_null(value)
			if node != null:
				dict[key] = node
			else:
				push_warning("DynamicExpression: NodePath '%s' not found from node '%s'. Key: '%s'" % [value, from_what.name, key])
		elif value is Dictionary:
			_convert_nodepaths_in_dictionary(value, from_what)
		elif value is Array:
			_convert_nodepaths_in_array(value, from_what)

## Converts NodePath in array recursively
## @param array: Array to process
## @param from_what: Node for resolving paths
func _convert_nodepaths_in_array(array: Array, from_what: Node) -> void:
	for i: int in array.size():
		var value: Variant = array[i]

		if value is NodePath:
			# Convert NodePath to real node
			var node: Node = from_what.get_node_or_null(value)
			if node != null:
				array[i] = node
			else:
				push_warning("DynamicExpression: NodePath '%s' not found from node '%s'. Index: %d" % [value, from_what.name, i])
		elif value is Dictionary:
			_convert_nodepaths_in_dictionary(value, from_what)
		elif value is Array:
			_convert_nodepaths_in_array(value, from_what)

func _physics_process(delta: float) -> void:
	if not executable or ( executable and \
		expression_object.execute(modified_data.values()) ):
		_on_action(delta)
	else:
		_on_not_action(delta)
	_additional(delta)

func _additional(_delta:float): pass

func _on_not_action(_delta:float): pass

func _on_action(_delta:float): pass
