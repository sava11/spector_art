## Main game scene controller.
##
## This class manages the core game scene, including UI updates and debug information.
## Currently handles FPS display in the debug UI overlay.
extends Node


@onready var player:=$world/player
var current_levels:=[]
var current_location_name:String


func _ready() -> void:
	SLD.saving_started.connect(_on_save_loader_start_saving_data)
	SLD.loading_finished.connect(_on_save_loader_data_loaded)
	for e in %lvls.get_children():
		if e.scene_file_path!="":
			current_levels.append(e.scene_file_path)


## Physics process for real-time game updates.
## Updates debug information like FPS counter.
##
## [param delta] Time elapsed since the last physics frame in seconds
func _physics_process(_delta: float) -> void:
	# Update FPS display in debug UI
	$ui/debug/fps.text = "FPS: " + str(Engine.get_frames_per_second())


func _enter_tree() -> void:
	var sd:=SaveLoader.new()
	sd.properties=["data", "timers"]
	sd.name="SaveLoader"
	KLD.add_child(sd)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("fast_save"):
		SLD.make_save()
	elif Input.is_action_just_pressed("fast_load"):
		SLD.load_save()


func _on_save_loader_start_saving_data() -> void:
	current_levels.clear()
	for e in %lvls.get_children():
		if e.scene_file_path!="":
			current_levels.append(e.scene_file_path)


func _on_save_loader_data_loaded() -> void:
	for e in %lvls.get_children():
		e.free()
	for e in current_levels:
		var lvl:Node=load(e).instantiate()
		%lvls.add_child.call_deferred(lvl)
		current_location_name=lvl.editor_description


func _on_hurt_box_alive(alive: bool) -> void:
	if not alive:
		SLD.load_from_file()
