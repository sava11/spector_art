## ZipPoint3D - 3D teleportation destination point with lock system integration.
##
## This component represents a teleportation destination in 3D space. Integrates with the Key-Lock
## system to control availability based on key states. Provides visual feedback through 3D meshes
## and shader materials. Can be blocked/unblocked dynamically based on lock conditions.
## [br][br]
## [codeblock]
## # Basic usage:
## var zip_point = ZipPoint3D.new()
## zip_point.keys_paths = [some_kllock_item]
## add_child(zip_point)
##
## # Check if point is blocked
## if zip_point.blocked:
##     print("Point is locked")
## [/codeblock]

extends Area3D
class_name ZipPoint3D

## Whether this zip point is currently blocked from teleportation.
## When blocked, the point is excluded from collision detection and cannot be used.
@export var blocked: bool = false: set = set_blocked

## Array of KLLockItem resources that control this point's availability.
## The point will be blocked if any of the associated locks are not activated.
@export var keys_paths: Array = []  # Array[KLLockItem] - using Array to avoid type errors if KLLockItem not found

## Visual highlight mesh instance for 3D display.
## Created automatically and uses shader material for animated effects.
var hl: MeshInstance3D

## Sprite3D node for displaying the zip point icon in 3D space.
## Shows the visual indicator for the teleportation point.
var img: Sprite3D

## KLLock instance that manages the blocking state based on key conditions.
## Evaluates lock expressions and updates blocked state accordingly.
var lock: KLLock

## Initialize the zip point when entering the scene tree.
## Creates visual components, sets up the lock system, and configures 3D display elements.
## [br][br]
## Critical initialization steps:
## - Creates highlight mesh with shader material for visual feedback
## - Sets up KLLock with keys_paths for blocking logic
## - Creates Sprite3D for icon display
## - Configures proper 3D positioning and scaling
func _ready() -> void:
	# Create highlight mesh instance
	hl = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(2.0, 2.0)  # 2x2 units in 3D space
	hl.mesh = quad_mesh
	
	# Load and apply shader material
	# Try 3D material first, fallback to creating one from shader if resource doesn't exist
	var material_resource = preload("res://materials/scripts/zip_zones_3d/zip_node_3d.tres")
	if material_resource:
		hl.material_override = material_resource
	else:
		# Create material from shader if resource file doesn't exist
		var shader = preload("res://materials/scripts/zip_zones_3d/zip_zone_3d.gdshader")
		if shader:
			var new_material = ShaderMaterial.new()
			new_material.shader = shader
			hl.material_override = new_material
	
	hl.name = "highlight"
	add_child(hl)
	
	# Position highlight at origin with proper orientation
	hl.position = Vector3.ZERO
	hl.rotation_degrees = Vector3(-90, 0, 0)  # Face upward (Y-up in Godot)
	
	# Create and configure lock system
	lock = KLLock.new()
	lock.name = "lock"
	lock.activated.connect(set_blocked)
	
	# Set up lock keys from exported array
	# If KLLock has keys_paths property, use it directly (matching 2D version)
	if lock.get("keys_paths"):
		lock.keys_paths = keys_paths
	elif keys_paths.size() > 0:
		# Fallback: try to extract keys if keys_paths property doesn't exist
		# This handles the case where KLLock uses keys property directly
		var lock_keys: Array[String] = []
		for item in keys_paths:
			# Try to extract keys from KLLockItem if it has a keys property
			if item.has_method("get") and item.get("keys") != null:
				var item_keys = item.get("keys")
				if item_keys is Array:
					lock_keys.append_array(item_keys)
		
		if lock_keys.size() > 0:
			lock.keys = lock_keys
	
	add_child(lock)
	
	# Create Sprite3D for icon display
	img = Sprite3D.new()
	img.texture = preload("res://materials/scripts/zip_zones/zip_point_img.svg")
	img.name = "img"
	img.pixel_size = 0.01  # Adjust size in 3D space
	img.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Always face camera
	img.position = Vector3(0, 1.0, 0)  # Position above the point
	img.hide()
	add_child(img)

## Update visual shader parameters each frame.
## Passes unscaled time to the highlight material for animated effects.
## [br][br]
## [param _delta] Time elapsed since last frame (unused but kept for signature)
func _process(_delta: float) -> void:
	var real_time: float = Time.get_ticks_msec() / 1000.0  # В секундах
	if hl and hl.material_override:
		var material = hl.material_override
		if material is ShaderMaterial:
			material.set_shader_parameter("unscaled_time", real_time)

## Set the blocked state of this zip point.
## When blocked, the point is excluded from collision detection and teleportation.
## Uses deferred calls to safely update physics properties.
## [br][br]
## Critical blocking logic:
## - Updates internal blocked state
## - Disables monitoring and monitorable when blocked
## - Prevents teleportation to this point when blocked
## [br][br]
## [param value] True to block the point, false to unblock
func set_blocked(value: bool) -> void:
	blocked = value
	# Use deferred calls to safely update physics properties
	set_deferred("monitorable", not value)
	set_deferred("monitoring", not value)
