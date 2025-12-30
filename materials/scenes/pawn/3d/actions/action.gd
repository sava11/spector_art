## Abstract base class for pawn actions with conditional execution and dynamic expressions.
##
## This class provides a framework for implementing pawn behaviors (movement, combat, etc.)
## with support for conditional execution based on dynamic expressions. Actions can have
## pre-execution, post-execution, and conditional logic that determines when the action runs.
## [br][br]
## [b]Key Features:[/b]
## - Conditional action execution based on dynamic expressions
## - Pre and post action expressions for setup/cleanup logic
## - Abstract methods for custom action implementation
## - Automatic physics process integration
## [br][br]
## [codeblock]
## # Basic action implementation:
## extends Action
##
## func _action(delta: float):
##     # Action logic here (runs when executable_expression is true/null)
##     pass
##
## func _not_action(delta: float):
##     # Alternative logic when executable_expression is false
##     pass
##
## func _addition(delta: float):
##     # Always runs after main action logic
##     pass
## [/codeblock]

class_name Action
extends Node

## Dynamic expression that controls whether the action executes.
## If null or evaluates to true, _action() is called.
## If evaluates to false, _not_action() is called instead.
@export var executable_expression: DynamicExpression

## Array of expressions executed before the main action logic every physics frame.
## Useful for setup operations, input processing, or state validation.
@export var pre_expressions: Array[DynamicExpression]

## Array of expressions executed after the main action logic every physics frame.
## Useful for cleanup operations, state updates, or side effects.
@export var post_expressions: Array[DynamicExpression]

## Main physics process that orchestrates action execution flow.
## CRITICAL: This method implements the complete action execution pipeline:
## 1. Execute pre-expressions for setup
## 2. Evaluate executable_expression to determine action path
## 3. Call _action() or _not_action() based on condition
## 4. Call _addition() for always-executed logic
## 5. Execute post-expressions for cleanup
##
## [param delta] Time elapsed since the last physics frame in seconds
func _physics_process(delta: float) -> void:
	# Execute pre-action expressions (setup, validation, etc.)
	for expression in pre_expressions:
		expression.execute(self)

	# Determine action execution path based on conditional expression
	if executable_expression == null or (executable_expression != null and executable_expression.execute(self)):
		_action(delta)  # Main action logic when condition is true/null
	else:
		_not_action(delta)  # Alternative logic when condition is false

	_addition(delta)  # Always-executed additional logic

	# Execute post-action expressions (cleanup, side effects, etc.)
	for expression in post_expressions:
		expression.execute(self)

## Abstract method for main action logic.
## Called when executable_expression is null or evaluates to true.
## Override this method to implement the primary action behavior.
##
## [param delta] Time elapsed since the last physics frame in seconds
func _action(_delta: float) -> void:
	pass

## Abstract method for alternative action logic.
## Called when executable_expression evaluates to false.
## Override this method for conditional behavior when the main action shouldn't run.
##
## [param delta] Time elapsed since the last physics frame in seconds
func _not_action(_delta: float) -> void:
	pass

## Abstract method for additional logic that always executes.
## Called after both _action() and _not_action() have run.
## Override this method for logic that should always happen regardless of conditions.
##
## [param delta] Time elapsed since the last physics frame in seconds
func _addition(_delta: float) -> void:
	pass
