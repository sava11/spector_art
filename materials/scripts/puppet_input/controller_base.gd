## Abstract base class for pawn controllers that handle input and control logic.
##
## This class provides the foundation for all controller implementations that manage
## pawn movement, actions, and input processing. Controllers act as intermediaries
## between input devices and pawn characters, translating raw input into game actions.
## [br][br]
## [b]Key Features:[/b]
## - Abstract input processing framework
## - Pawn state synchronization
## - Enable/disable functionality
## - Automatic input reset when disabled
## [br][br]
## [codeblock]
## # Extending BaseController:
## extends BaseController
##
## func input_control():
##     # Implement your input logic here
##     input_direction = Input.get_vector("left", "right", "up", "down")
##     want_attack = Input.is_action_pressed("attack")
## [/codeblock]

class_name BaseController
extends Node

## Master enable/disable switch for this controller.
## When disabled, all inputs are reset and no control is applied to the pawn.
@export var enabled: bool = true

## Reference to the pawn node that this controller will manipulate.
## The controller will set input properties on this node each physics frame.
@export var puppet_pawn: Node

## Current look direction for the pawn (normalized vector).
## Typically represents mouse position or right stick direction.
var look_direction: Vector2 = Vector2.ZERO

## Whether the pawn wants to perform an attack action.
## Set to true when attack input is detected.
var want_attack: bool = false

## Current movement input direction (normalized vector).
## Represents the desired movement direction from input devices.
var input_direction: Vector2

## Whether the jump button is currently held down.
var jump_held: bool

## Whether the dash button is currently held down.
var dash_held: bool

## Abstract method for processing input and updating controller state.
## CRITICAL: This method must be implemented by subclasses to handle specific input logic.
## Called every physics frame when the controller is enabled.
##
## Subclasses should override this method to:
## - Read input from devices (keyboard, mouse, gamepad)
## - Update input_direction, look_direction, want_attack, etc.
## - Handle any controller-specific logic
func input_control() -> void:
	pass

## Resets all input states to their default values.
## Used when the controller is disabled to ensure clean state transitions.
func reset() -> void:
	jump_held = false
	look_direction = Vector2.ZERO
	input_direction = Vector2.ZERO
	want_attack = false

## Physics process for input handling and pawn synchronization.
## CRITICAL: This is the main update loop that processes input and applies it to the pawn.
## [br][br]
## [param delta] Time elapsed since the last physics frame (unused but kept for consistency)
func _physics_process(_delta: float) -> void:
	if enabled:
		input_control()  # Process input when enabled
	else:
		reset()  # Reset inputs when disabled

	# CRITICAL: Synchronize controller state with pawn
	# These assignments ensure the pawn receives the latest input state
	puppet_pawn.input_direction = input_direction
	puppet_pawn.look_direction = look_direction
	puppet_pawn.want_attack = want_attack
	puppet_pawn.dash_held = dash_held
	puppet_pawn.jump_held = jump_held
