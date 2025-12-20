extends Node
class_name SaveSystemBase

## Base class for save system implementations.
##
## Provides core file I/O functionality for saving and loading game data.
## Handles file operations, directory creation, and data serialization.
## Should be extended by specific save system implementations.
## [br][br]
## [codeblock]
## # Extending SaveSystemBase:
## extends SaveSystemBase
##
## func save_game():
##     # Custom save logic
##     _save_to_file("my_save")
##
## func load_game():
##     # Custom load logic
##     _load_from_file("my_save")
## [/codeblock]

## Directory path for save files relative to project root.
const SAVE_DIR := "saves/"

## File extension for save files.
const EXT:=".dat"

## Dictionary containing all save data in memory.
## Format: {node_path: {property: value}}
var saved_data: Dictionary = {}

## Initialize the save system when entering the scene tree.
## Creates the save directory if it doesn't exist and calls post-initialization.
func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_post_ready()

## Hook for subclasses to perform additional initialization after directory setup.
## Called after the save directory is ensured to exist.
func _post_ready() -> void: pass

# ---------------- File Operations ----------------

## Save current save data to a file with backup.
## Creates a backup of the previous save file before writing new data.
## [br][br]
## [param save_file_name] Name of the save file (without extension)
## [return] Error code - OK on success, or specific error code on failure
func _save_to_file(save_file_name:String) -> Error:
	var path := SAVE_DIR + save_file_name + EXT
	DirAccess.rename_absolute(SAVE_DIR + save_file_name + EXT,
		SAVE_DIR + save_file_name + "_past" + EXT)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if not f: return Error.ERR_FILE_CANT_OPEN
	if !f.store_var(saved_data,true):
		return Error.ERR_FILE_CANT_WRITE
	f.close()
	return Error.OK

## Load save data from a file.
## Reads and validates save file data, loading it into memory.
## [br][br]
## [param save_file_name] Name of the save file to load (without extension)
## [return] Error code - OK on success, or specific error code on failure
func _load_from_file(save_file_name:String) -> Error:
	var path := SAVE_DIR + save_file_name + EXT
	if not FileAccess.file_exists(path):
		return Error.ERR_DOES_NOT_EXIST
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return Error.ERR_FILE_CANT_OPEN
	var data=f.get_var(true)
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return Error.ERR_FILE_CORRUPT
	saved_data = data
	return Error.OK

## Remove a save file from disk.
## Permanently deletes the specified save file.
## [br][br]
## [param save_file_name] Name of the save file to remove (without extension)
## [return] Error code - OK on success, or specific error code on failure
func _remove_save_file(save_file_name:String)->Error:
	var path := SAVE_DIR + save_file_name + EXT
	return DirAccess.remove_absolute(path)

## Load save data and return it, clearing internal data afterward.
## Useful for one-time data extraction without affecting internal state.
## [br][br]
## [param save_file_name] Name of the save file to load (without extension)
## [return] Dictionary containing the loaded save data
func get_and_clear_data(save_file_name:String)->Dictionary:
	_load_from_file(save_file_name)
	return saved_data
