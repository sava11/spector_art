## CustomDetectionBox - Area trigger with dynamic callback execution.
##
## This class creates a detection area that executes dynamic expressions when bodies enter or exit.
## Useful for creating interactive zones, triggers, or complex event systems without writing code.
## Supports multiple callback expressions that can modify game state, play sounds, or trigger events.
## [br][br]
## [codeblock]
## # Basic usage:
## var detector = CustomDetectionBox.new()
## var enter_expr = DynamicExpression.create("print('Body entered!')", {})
## var exit_expr = DynamicExpression.create("print('Body exited!')", {})
## detector.body_entered_callbacks = [enter_expr]
## detector.body_exited_callbacks = [exit_expr]
## add_child(detector)
## [/codeblock]

class_name CustomDetectionBox
extends Area2D

## Array of dynamic expressions executed when a body enters the detection area.
## Each expression receives this node as context for NodePath resolution and variable access.
@export var body_entered_callbacks: Array[DynamicExpression] = []

## Array of dynamic expressions executed when a body exits the detection area.
## Each expression receives this node as context for NodePath resolution and variable access.
@export var body_exited_callbacks: Array[DynamicExpression] = []

## Initialize the detection area and connect collision signals.
## Sets up body enter/exit event handlers for callback execution.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## Handle body entering the detection area.
## Executes all configured enter callbacks with this node as execution context.
## [br][br]
## [param _body] The body that entered (unused parameter, kept for signal compatibility)
## [br][br]
## [b]Critical:[/b] Iterates through all expressions - ensure expressions are valid to prevent runtime errors.
func _on_body_entered(_body:Node2D):
	for callback in body_entered_callbacks:
		# CRITICAL: Execute each callback with this node as context for NodePath resolution
		if callback != null:
			callback.execute(self)

## Handle body exiting the detection area.
## Executes all configured exit callbacks with this node as execution context.
## [br][br]
## [param _body] The body that exited (unused parameter, kept for signal compatibility)
## [br][br]
## [b]Critical:[/b] Iterates through all expressions - ensure expressions are valid to prevent runtime errors.
func _on_body_exited(_body:Node2D):
	for callback in body_exited_callbacks:
		# CRITICAL: Execute each callback with this node as context for NodePath resolution
		if callback != null:
			callback.execute(self)
