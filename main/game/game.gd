extends Node

func _physics_process(delta: float) -> void:
	$ui/debug/fps.text="FPS: "+ str(Engine.get_frames_per_second())
