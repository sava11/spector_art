## Main game scene controller.
##
## This class manages the core game scene, including UI updates and debug information.
## Currently handles FPS display in the debug UI overlay.
extends Node

## Physics process for real-time game updates.
## Updates debug information like FPS counter.
##
## [param delta] Time elapsed since the last physics frame in seconds
func _physics_process(delta: float) -> void:
	# Update FPS display in debug UI
	$ui/debug/fps.text = "FPS: " + str(Engine.get_frames_per_second())
