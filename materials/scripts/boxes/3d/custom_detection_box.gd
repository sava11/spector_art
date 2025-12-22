## CustomDetectionBox3D - 3D area trigger with dynamic callback execution.
##
## This class creates a detection area in 3D space that executes dynamic expressions when bodies enter or exit.
## Useful for creating interactive zones, triggers, or complex event systems without writing code.
## Supports multiple callback expressions that can modify game state, play sounds, or trigger events.
## Designed specifically for 3D environments with proper physics body handling.
## [br][br]
## [codeblock]
## # Basic usage:
## var detector = CustomDetectionBox3D.new()
## var enter_expr = DynamicExpression.create("print('Body entered!')", {})
## var exit_expr = DynamicExpression.create("print('Body exited!')", {})
## detector.body_entered_callbacks = [enter_expr]
## detector.body_exited_callbacks = [exit_expr]
## add_child(detector)
## [/codeblock]

class_name CustomDetectionBox3D
extends Area3D

## Array of dynamic expressions executed when a 3D physics body enters the detection area.
## Each expression receives this node as context for NodePath resolution and variable access.
## Supports complex logic for interactive 3D zones and trigger systems.
@export var body_entered_callbacks: Array[DynamicExpression] = []

## Array of dynamic expressions executed when a 3D physics body exits the detection area.
## Each expression receives this node as context for NodePath resolution and variable access.
## Enables cleanup logic and state management for 3D interactive areas.
@export var body_exited_callbacks: Array[DynamicExpression] = []

## Initialize the 3D detection area and connect collision signals.
## This method sets up body enter/exit event handlers for callback execution
## in the 3D physics environment.
## [br][br]
## Critical initialization steps:
## - Connects body_entered signal to _on_body_entered
## - Connects body_exited signal to _on_body_exited
## - Ensures proper 3D physics body signal handling
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## Handle 3D physics body entering the detection area.
## This method executes all configured enter callbacks with this node as execution context.
## [br][br]
## Critical implementation details:
## - Iterates through all body_entered_callbacks expressions
## - Executes each valid callback with this node as context
## - Provides NodePath resolution for dynamic expressions in 3D space
## - Handles null callback validation to prevent runtime errors
##
## [param _body] The 3D physics body that entered (unused parameter, kept for signal compatibility)
func _on_body_entered(_body: Node3D):
	for callback in body_entered_callbacks:
		# CRITICAL: Execute each callback with this node as context for NodePath resolution
		# Ensures dynamic expressions can access scene nodes and modify 3D game state
		if callback != null:
			callback.execute(self)

## Handle 3D physics body exiting the detection area.
## This method executes all configured exit callbacks with this node as execution context.
## [br][br]
## Critical implementation details:
## - Iterates through all body_exited_callbacks expressions
## - Executes each valid callback with this node as context
## - Provides NodePath resolution for dynamic expressions in 3D space
## - Handles cleanup and state management for exiting bodies
##
## [param _body] The 3D physics body that exited (unused parameter, kept for signal compatibility)
func _on_body_exited(_body: Node3D):
	for callback in body_exited_callbacks:
		# CRITICAL: Execute each callback with this node as context for NodePath resolution
		# Enables cleanup logic and state transitions in 3D interactive zones
		if callback != null:
			callback.execute(self)
