extends SaveSystemBase

## Main save/load system for managing game state persistence.
##
## This class extends SaveSystemBase to provide node registration and save/load functionality.
## It manages a registry of nodes and their properties, allowing selective saving and loading
## of game state across scene changes or application restarts.
## [br][br]
## [codeblock]
## # Basic usage:
## SLD.register_node(player_node, ["position", "health", "inventory"])
## SLD.register_node(game_state, ["level", "score"])
##
## # Save current state
## SLD.make_save()
##
## # Load saved state
## SLD.load_save()
## [/codeblock]

## Emitted when saving process begins.
signal saving_started

## Emitted when saving process completes successfully.
signal saving_finished

## Emitted when loading process begins.
signal loading_started

## Emitted when loading process completes successfully.
signal loading_finished

## Name of the save file to use for persistence.
var save_file := "save"

## Registry of nodes and their properties to save/load.
## Format: {node_path: [properties]}
var registered_nodes: Dictionary = {}

# ---------------- Node Registration ----------------

## Register a node and its properties for automatic save/load tracking.
## The node will be monitored and its specified properties will be included in save operations.
## [br][br]
## [param node] The node to register for saving
## [param properties] Array of property names to save for this node
func register_node(node: Node, properties: Array[String]) -> void:
	if not registered_nodes.has(str(node.get_path())):
		registered_nodes[str(node.get_path())] = properties
		node.tree_exiting.connect(unregister_node.bind(node))
	else:
		push_warning("Node already exist in register")

## Unregister a node from the save system.
## Removes the node from tracking and disconnects cleanup signals.
## [br][br]
## [param node] The node to unregister
func unregister_node(node: Node) -> void:
	registered_nodes.erase(str(node.get_path()))
	node.tree_exiting.disconnect(unregister_node.bind(node))

# ---------------- Saving ----------------

## Save the current state of all registered nodes to file.
## Collects current property values from all registered nodes and writes them to disk.
func make_save() -> void:
	emit_signal("saving_started")
	for path in registered_nodes.keys():
		var node := get_node_or_null(path)
		if node:
			var node_data: Dictionary = {}
			for prop in registered_nodes[path]:
				var value = node.get(prop)
				node_data[prop] = value  # Save as-is, serialization happens in base class
			saved_data[path] = node_data
	_save_to_file(save_file)
	emit_signal("saving_finished")

# ---------------- Loading ----------------

## Load saved state from file and apply it to registered nodes.
## Reads save data from disk and restores property values to registered nodes.
func load_save() -> void:
	emit_signal("loading_started")
	_load_from_file(save_file)
	for path in saved_data.keys():
		var node := get_node_or_null(path)
		if node:
			for prop in saved_data[path].keys():
				if node.has_method("set"):
					node.set(prop, saved_data[path][prop])
	emit_signal("loading_finished")
