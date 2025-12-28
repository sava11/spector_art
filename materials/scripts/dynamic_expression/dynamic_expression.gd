extends Resource
class_name DynamicExpression

## Dynamic expression for executing code with variables
##
## Allows executing mathematical, logical expressions or assignments
## using variables from the data dictionary. Supports NodePath references
## that are automatically converted to real nodes.
##
## Used in:
## - key_lock system for logical expressions of dependencies (example: "(key1 && key2) || !key3")
## - boxes system for damage, health and physics calculations (example: "damage * multiplier + bonus")
## - other systems for flexible configurable calculations
##
## Usage examples:
## [codeblock]
## # Mathematical expression
## var expr = DynamicExpression.create("health * 0.5 + armor", {"health": 100, "armor": 20})
## var result = expr.execute(self) # Returns 70
##
## # Logical expression
## var expr = DynamicExpression.create("key1 && (key2 || key3)", {"key1": true, "key2": false, "key3": true})
## var result = expr.execute(self) # Returns true
##
## # Assignment with NodePath
## var expr = DynamicExpression.create("player.health = current_health - damage",
##     {"player": NodePath("../Player"), "current_health": 100, "damage": 25})
## expr.execute(self) # Sets player health to 75
##
## # Usage in key_lock system
## var lock_expr = DynamicExpression.create("key_activated && !door_locked",
##     {"key_activated": NodePath("../Key"), "door_locked": false})
## var can_open = lock_expr.execute(self)
## [/codeblock]

## Expression string to execute (mathematical, logical or assignment)
@export var expression: String = ""

## Dictionary of variables for use in the expression
## Keys - variable names, values - their values
## Supports NodePath that are converted to nodes during execution
@export var data: Dictionary[String, Variant] = {}

## Converts NodePath to real nodes and returns a modified copy of the data
## @param from_what: Node relative to which NodePath are resolved
## @return: New dictionary with converted data
func modify_data(from_what: Node) -> Dictionary[String, Variant]:
	var modified_data := data.duplicate(true)  # Deep copy for safety
	_convert_nodepaths_recursive(modified_data, from_what)
	return modified_data

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

## Executes the expression using data from the data dictionary
## @param from_what: Node for resolving NodePath references (needed to convert paths to real objects)
## @return: Expression execution result or null on error
##
## Execution process:
## 1. Expression emptiness validation
## 2. Expression transformation (for assignments like obj.prop = value)
## 3. Convert NodePath in data to real nodes
## 4. Parse expression with syntax checking
## 5. Execute with provided variables
## 6. Check for execution errors
func execute(from_what: Node) -> Variant:
	# CRITICAL: Validate input data
	if expression.strip_edges().is_empty():
		push_error("DynamicExpression: Expression is empty")
		return null

	if from_what == null:
		push_error("DynamicExpression: Context node (from_what) is null")
		return null

	# Prepare expression for execution (handle assignments)
	var processed_expression := _process_expression_for_execution()

	# CRITICAL: Convert NodePath to real objects for correct access
	var modified_data := modify_data(from_what)

	# Create Godot expression object
	var expression_object := Expression.new()

	# Parse expression - check syntax and available variables
	var variable_names: Array[StringName] = []
	variable_names.assign(modified_data.keys())
	var parse_error := expression_object.parse(processed_expression, variable_names)

	if parse_error != OK:
		push_error("DynamicExpression: Failed to parse expression '%s'. Error: %s" % [processed_expression, parse_error])
		return null

	# Execute expression with data in correct order
	var args: Array = []
	args.assign(modified_data.values())
	var result: Variant = expression_object.execute(args)

	# CRITICAL: Check for execution errors (division by zero, invalid operations, etc.)
	if expression_object.has_execute_failed():
		push_error("DynamicExpression: Failed to execute expression '%s'" % processed_expression)
		return null

	return result

## Processes the expression for correct execution
## Converts assignments like "obj.property = value" to "obj.set('property', value)" calls
## @return: Processed expression ready for Expression execution
##
## Why this is needed:
## Godot Expression doesn't support direct assignments like "obj.property = value"
## Instead, we need to use method calls: "obj.set('property', value)"
## This allows modifying object properties through expressions
func _process_expression_for_execution() -> String:
	var expr := expression.strip_edges()

	# If expression doesn't contain assignment, return as is
	if not expr.contains("="):
		return expr
	#if not (expr.contains("=") or expr.contains("!=") or expr.contains("<=") or \
		#expr.contains(">=")):
		#return expr

	# CRITICAL: Parse assignment into parts
	# Example: "player.health = damage * 2" -> ["player.health ", " damage * 2"]
	var parts := expr.split("=", true, 1)  # true, 1 = split only on first occurrence
	if parts.size() != 2:
		push_warning("DynamicExpression: Invalid assignment format: '%s'. Expected 'target = value'" % expr)
		return expr

	var target := parts[0].strip_edges()  # "player.health"
	var value := parts[1].strip_edges()   # "damage * 2"

	# Check if target is an object property (contains dot)
	# Example: "player.health" -> ["player", "health"]
	var target_parts := target.rsplit(".", true, 1)  # true, 1 = maximum 1 split from right
	if target_parts.size() != 2:
		# Simple variable assignment (not object property)
		# Example: "result = a + b" - leave as is
		return expr

	# CRITICAL: Convert to setter method call
	# "player.health = damage * 2" -> "player.set("health", damage * 2)"
	var object_name := target_parts[0]    # "player"
	var property_name := target_parts[1]  # "health"
	var setter_call := "%s.set(\"%s\", %s)" % [object_name, property_name, value]

	return setter_call

## Creates a new dynamic expression
## @param expr: Expression string
## @param context_data: Dictionary with variables
## @return: New DynamicExpression instance
static func create(expr: String, context_data: Dictionary[String, Variant] = {}) -> DynamicExpression:
	var instance := DynamicExpression.new()
	instance.expression = expr
	instance.data = context_data.duplicate(true)
	return instance

## Validates expression correctness without execution
## @param test_expression: Expression to validate
## @param variable_names: List of variable names
## @return: true if expression is valid
func validate_expression(test_expression: String = "", variable_names: Array[StringName] = []) -> bool:
	var expr := test_expression if not test_expression.is_empty() else expression
	var names := variable_names if not variable_names.is_empty() else []
	names.assign(data.keys() if names.is_empty() else names)

	var test_expr := Expression.new()
	var error := test_expr.parse(expr, names)
	return error == OK

## Returns list of variables used in the expression
## @return: Array of variable names
func get_expression_variables() -> Array[String]:
	var variables: Array[String] = []
	var expr_obj := Expression.new()

	# Parse expression to get list of variables
	var dummy_names: Array[StringName] = []
	dummy_names.assign(data.keys())

	if expr_obj.parse(expression, dummy_names) == OK:
		# Get list of variables from expression
		for var_name in data.keys():
			if expression.contains(var_name):
				variables.append(var_name)

	return variables

## Checks if expression contains an assignment
## @return: true if expression is an assignment
func is_assignment_expression() -> bool:
	return expression.strip_edges().contains("=")

## Returns string representation of the expression for debugging
## @return: Formatted string with expression information
func _to_string() -> String:
	return "DynamicExpression{expr='%s', variables=%s}" % [expression, data.keys()]
