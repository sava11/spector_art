extends Area2D
class_name ZipZone

@export var min_distance:float=4
@export var exclude: Array[Node2D]
@export var positive_collision_mask: int

var _bs: Array[Area2D] = []
var _collided_with: Array[Area2D] = []
var exclude_rids: Array[RID] = []

func _process(_delta: float) -> void:
	var real_time: float = Time.get_ticks_msec() / 1000.0  # В секундах
	$visual.material.set_shader_parameter("unscaled_time", real_time)

func _ready() -> void:
	area_exited.connect(_on_area_exited)
	area_entered.connect(_on_area_entered)
	for ex in exclude:
		if is_instance_valid(ex):
			exclude_rids.append(ex.get_rid())
	exclude_rids.append(get_rid())

func _physics_process(_delta: float) -> void:
	var space_state := get_world_2d().direct_space_state
	var from_pos := global_position

	for e in _bs.duplicate():
		if not is_instance_valid(e):
			_bs.erase(e)
			continue
		
		var to_pos:Vector2 = e.global_position
		var params := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
		params.exclude = exclude_rids
		params.collision_mask = collision_mask
		params.collide_with_areas = true
		var result := space_state.intersect_ray(params)
		
		var _visible := false
		var collider = result.get("collider")
		if collider == null or (collider == e and not collider.blocked):
			_visible = true
		if _visible and e.get_collision_layer_value(positive_collision_mask):
			if not e in _collided_with:
				_collided_with.append(e)
				#e.hl.visible = true
		else:
			#e.hl.visible = false
			var id := _collided_with.find(e)
			if id >= 0:
				_collided_with.remove_at(id)

func get_available_zip_points():
	return _collided_with

func get_available_zip_point(direction:Vector2)->ZipPoint:
	if _collided_with.is_empty():
		return null
	var candidates: Array = []
	for e: ZipPoint in _collided_with:
		var pos_diff: Vector2 = e.global_position - global_position
		var dist: float = pos_diff.length()
		var angle_a: float = pos_diff.angle()
		var angle_b: float = direction.angle()
		var angle_diff: float = abs(fmod(angle_a - angle_b + PI, TAU) - PI)
		if not _angle_in_view(rad_to_deg(angle_a),
			rad_to_deg(direction.angle())-45, 
			rad_to_deg(direction.angle())+45):
			continue
		candidates.append({"point": e, "dist": dist, "angle_diff": angle_diff})
	candidates=candidates.filter(_more_than_min_distance)
	candidates.sort_custom(_sort_by_criteria)
	return candidates[0]["point"] if not candidates.is_empty() else null

func _more_than_min_distance(x):
	return x.dist>=min_distance

func _sort_by_criteria(a: Dictionary, b: Dictionary) -> bool:
	if a["angle_diff"] != b["angle_diff"]:
		return a["angle_diff"] < b["angle_diff"]
	return a["dist"] < b["dist"]

func _angle_in_view(angle_deg: float, start_angle_view: float, end_angle_view: float) -> bool:
	var s := wrapf(start_angle_view, -180, 180)
	var e := wrapf(end_angle_view, -180, 180)
	if s <= e:
		return angle_deg >= s and angle_deg <= e
	return angle_deg >= s or angle_deg <= e

func _on_area_entered(area: Area2D) -> void:
	if area is ZipPoint and area not in _bs:
		_bs.append(area)

func _on_area_exited(area: Area2D) -> void:
	if area is ZipPoint:
		#if area.hl != null:
			#area.hl.visible = false
		_bs.erase(area)
		#_collided_with.erase(area)
		var id := _collided_with.find(area)
		if id >= 0:
			_collided_with.remove_at(id)
