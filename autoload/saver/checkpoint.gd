extends Node
class_name SaveCheckpoint

## Checkpoint system for saving specific game states.
##
## Allows creating predefined save points with specific node states.
## Useful for level checkpoints, save points, or quick save functionality.
## Can execute custom expressions when saving.
## [br][br]
## [codeblock]
## # Example checkpoint setup:
## # data = {
## #   NodePath("../Player"): {"position": Vector2(100, 200), "health": 50},
## #   NodePath("../GameState"): {"level": 3, "score": 1000}
## # }
## [/codeblock]

signal on_saved

## Dictionary defining the state to save for each node.
## Format: {NodePath: {property: value}}
@export var data:Dictionary[NodePath,Dictionary]

## Whether this checkpoint is enabled and can be used.
@export var enabled:bool=true

## Internal SaveLoader instance for managing this checkpoint's save state.
var sl:SaveLoader

## Initialize the checkpoint system.
func _ready() -> void:
	sl=SaveLoader.new()
	sl.auto_update=false
	sl.name="SaveLoader"
	sl.properties=["enabled"]
	add_child(sl)

## Save the checkpoint data to the global save system.
## Applies the predefined data values to registered nodes and triggers save.
## Only works if the checkpoint is enabled.
func save():
	if enabled:
		for n in data.keys():
			if get_node_or_null(n)==null:
				push_error("isn't exists node: ",n)
				return
			var node_path:String=get_node(n).get_path()
			if not SLD.registered_nodes.has(node_path):
				push_warning("not exists: ",node_path)
				continue
			for e in data[n].keys():
				if SLD.saved_data[node_path].has(e):
					SLD.saved_data[node_path][e]=data[n][e]
				else:
					push_warning("element "+e+" not exists in SLD.saved_data[",
					node_path,"]: ",SLD.saved_data[node_path])
		sl._check_and_push_changes()
		SLD.make_save()
		on_saved.emit()
