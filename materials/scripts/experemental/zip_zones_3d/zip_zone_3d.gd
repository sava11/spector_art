## ZipZone3D - 3D teleportation zone that detects and manages available zip points.
##
## This component creates a 3D area that detects ZipPoint3D instances within its range and determines
## which points are visible and available for teleportation. Uses 3D raycasting to check line-of-sight
## between the zone and zip points, filtering points based on distance, angle, and collision detection.
## Supports exclusion lists and collision masks for complex level geometry.
## [br][br]
## [codeblock]
## # Basic usage:
## var zip_zone = ZipZone3D.new()
## zip_zone.min_distance = 5.0
## zip_zone.collision_mask = 1
## zip_zone.positive_collision_mask = 2
## add_child(zip_zone)
##
## # Get available zip points
## var points = zip_zone.get_available_zip_points()
## var point = zip_zone.get_available_zip_point(Vector3.FORWARD)
## [/codeblock]

extends Area3D
class_name ZipZone3D

## Minimum distance required for a zip point to be considered available.
## Points closer than this distance will be filtered out to prevent teleportation to nearby locations.
@export var min_distance: float = 4.0

## Array of Node3D nodes to exclude from raycast collision detection.
## Useful for excluding the player, the zone itself, or other dynamic objects from blocking line-of-sight.
@export var exclude: Array[Node3D] = []

## Collision layer mask for detecting zip points that should be highlighted.
## Zip points on this layer will be marked as available when visible.
@export var positive_collision_mask: int = 0

## Internal array of detected ZipPoint3D instances within the area.
## Updated automatically as zip points enter and exit the detection area.
var _bs: Array[Area3D] = []

## Array of ZipPoint3D instances that are currently visible and available.
## These points have passed all visibility and distance checks.
var _collided_with: Array[Area3D] = []

## Array of RID references for excluded objects in raycast queries.
## Prevents excluded objects from blocking line-of-sight checks.
var exclude_rids: Array[RID] = []

## Update visual shader parameters each frame.
## Passes unscaled time to the visual material for animated effects.
## [br][br]
## Critical visual update:
## - Updates shader time parameter for animated effects
## - Safely handles missing visual node or material
## - Supports both surface override and material override
## [br][br]
## [param _delta] Time elapsed since last frame (unused but kept for signature)
func _process(_delta: float) -> void:
	var real_time: float = Time.get_ticks_msec() / 1000.0  # В секундах
	
	# Try to update visual node if it exists
	if has_node("visual"):
		
		var visual = $visual
		var material: Material = null
		visual.look_at(get_viewport().get_camera_3d().global_position)
		
		# Check for MeshInstance3D with surface material
		if visual is MeshInstance3D:
			material = visual.get_surface_override_material(0)
			if material == null:
				material = visual.get_surface_material(0)
		
		# Update shader parameter if material is a ShaderMaterial
		if material is ShaderMaterial:
			material.set_shader_parameter("unscaled_time", real_time)

## Initialize the zip zone when entering the scene tree.
## Connects area signals and builds the exclusion list for raycast queries.
## [br][br]
## Critical initialization steps:
## - Connects area_entered and area_exited signals for zip point detection
## - Collects RIDs of excluded nodes for raycast filtering
## - Adds self to exclusion list to prevent self-collision
func _ready() -> void:
	area_exited.connect(_on_area_exited)
	area_entered.connect(_on_area_entered)
	
	# Build exclusion list from exported array
	for ex in exclude:
		if is_instance_valid(ex):
			exclude_rids.append(ex.get_rid())
	
	# Always exclude self from raycasts
	exclude_rids.append(get_rid())

## Main physics update loop for visibility checking and zip point management.
## Performs 3D raycasts from zone position to each detected zip point to determine visibility.
## Updates the available zip points list based on line-of-sight and collision layer checks.
## [br][br]
## Critical update operations:
## - Cleans up invalid zip point references
## - Performs 3D raycasts using PhysicsRayQueryParameters3D
## - Checks if raycast hits the zip point itself (indicating visibility)
## - Filters points based on positive_collision_mask for highlighting
## - Maintains _collided_with array of visible and available points
## [br][br]
## [param _delta] Time elapsed since last frame (unused but kept for signature)
func _physics_process(_delta: float) -> void:
	var space_state := get_world_3d().direct_space_state
	var from_pos := global_position

	# Process all detected zip points
	for e in _bs.duplicate():
		if not is_instance_valid(e):
			_bs.erase(e)
			continue
		
		var to_pos: Vector3 = e.global_position
		
		# Create 3D raycast query
		var params := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
		params.exclude = exclude_rids
		params.collision_mask = collision_mask
		params.collide_with_areas = true
		var result := space_state.intersect_ray(params)
		
		# Check if zip point is visible (raycast hits the point itself or nothing)
		var _visible := false
		var collider = result.get("collider")
		if collider == null:
			_visible = true
		elif collider == e:
			# Check if the zip point itself is not blocked
			if collider is ZipPoint3D and not collider.blocked:
				_visible = true
		
		# Add to available list if visible and on positive collision layer
		if _visible and e.get_collision_layer_value(positive_collision_mask):
			if not e in _collided_with:
				_collided_with.append(e)
		else:
			# Remove from available list if not visible
			var id := _collided_with.find(e)
			if id >= 0:
				_collided_with.remove_at(id)
	print(_collided_with)

## Get all currently available zip points that are visible and pass all checks.
## Returns an array of ZipPoint3D instances that can be used for teleportation.
## [br][br]
## [return] Array of available ZipPoint3D instances
func get_available_zip_points() -> Array:
	return _collided_with

## Get the best available zip point in a specific direction.
## Filters available points by angle and distance, returning the closest point
## that matches the desired direction within a 45-degree cone.
## [br][br]
## Critical selection logic:
## - Filters points by minimum distance requirement
## - Calculates angle difference between direction and point position
## - Only considers points within 45-degree view cone
## - Sorts candidates by angle difference (preferred) then distance
## - Returns the best matching point or null if none found
## [br][br]
## [param direction] Desired teleportation direction (normalized Vector3)
## [return] Best matching ZipPoint3D or null if no suitable point found
func get_available_zip_point(direction: Vector3) -> ZipPoint3D:
	if _collided_with.is_empty():
		return null
	
	var candidates: Array = []
	var direction_normalized = direction.normalized()
	
	# Evaluate each available point
	for e: ZipPoint3D in _collided_with:
		var pos_diff: Vector3 = e.global_position - global_position
		var dist: float = pos_diff.length()
		
		# Skip if too close
		if dist < min_distance: continue
		
		# Calculate angle between direction and point position
		var pos_normalized = pos_diff.normalized()
		var dot_product = direction_normalized.dot(pos_normalized)
		var angle_diff = acos(clamp(dot_product, -1.0, 1.0))
		
		# Check if point is within 45-degree view cone
		if angle_diff > deg_to_rad(60.0): continue
		
		candidates.append({"point": e, "dist": dist, "angle_diff": angle_diff})
	
	# Sort by angle difference (preferred), then by distance
	candidates.sort_custom(_sort_by_criteria)
	return candidates[0]["point"] if not candidates.is_empty() else null

## Sort function for zip point candidates.
## Prioritizes points with smaller angle differences, then closer distances.
## [br][br]
## [param a] First candidate dictionary with "angle_diff" and "dist" keys
## [param b] Second candidate dictionary with "angle_diff" and "dist" keys
## [return] True if a should come before b in sorted array
func _sort_by_criteria(a: Dictionary, b: Dictionary) -> bool:
	if a["angle_diff"] != b["angle_diff"]:
		return a["angle_diff"] < b["angle_diff"]
	return a["dist"] < b["dist"]

## Handle when a zip point enters the detection area.
## Adds valid ZipPoint3D instances to the tracking array for visibility checking.
## [br][br]
## [param area] The Area3D that entered (should be ZipPoint3D)
func _on_area_entered(area: Area3D) -> void:
	if area is ZipPoint3D and area not in _bs:
		_bs.append(area)

## Handle when a zip point exits the detection area.
## Removes the zip point from tracking and available lists.
## [br][br]
## [param area] The Area3D that exited (should be ZipPoint3D)
func _on_area_exited(area: Area3D) -> void:
	if area is ZipPoint3D:
		_bs.erase(area)
		var id := _collided_with.find(area)
		if id >= 0:
			_collided_with.remove_at(id)
