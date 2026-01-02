@tool
class_name ControlablePathFollow3D
extends PathFollow3D
signal active(activated: bool)

enum inf_move{greater,none,lesser}

@export var infinite_move:inf_move=inf_move.none:
	set(v):
		infinite_move=v
		if v==inf_move.none:
			to_position(progress)
@export var enabled: bool = true: set = set_enabled
@export var blocked: bool = false: set = set_blocked
@export_range(0.001,99,0.001,"or_greater","hide_slider","suffix:m") 
var speed: float = 200.0
@export_range(0,99,0.0001,"or_greater","hide_slider","suffix:m") 
var to_point: float = 0 : set = to_position
@export_range(0,1,0.001) 
var to_point_ratio: float = 0 : set = set_to_point_ratio, get = get_to_point_ratio
@export_range(0.001,99,0.001,"or_greater","hide_slider","suffix:deg/s") 
var rotation_speed: float = 100
@export var to_rotation: Vector3 = Vector3.ZERO

var _raw_progress: float = 0.0
var _target_raw: float = 0.0
var emited := false
var is_closed := false
var path_len := 0.0
func _ready() -> void:
	_raw_progress = progress
	to_point = progress
	_recalculate_curve()

func set_enabled(v: bool) -> void:
	enabled = v

func set_blocked(v: bool) -> void:
	blocked = v

func _recalculate_curve():
	var path := (get_parent() as Path3D)
	if path:
		var curve := path.curve
		path_len = curve.get_baked_length()
		if curve.get_point_count() >= 2:
			var first := curve.get_point_position(0)
			var last := curve.get_point_position(curve.get_point_count() - 1)
			is_closed = first.distance_to(last) < 0.01


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		_recalculate_curve()
	if enabled and not blocked:
		if not Engine.is_editor_hint():
			match infinite_move:
				inf_move.greater:
					_target_raw =_target_raw+speed*delta
				inf_move.lesser:
					_target_raw =_target_raw-speed*delta

		_raw_progress = move_toward(_raw_progress, _target_raw, speed * delta)
		progress = _raw_progress if !is_closed else wrapf(_raw_progress, 0.0, path_len)
		rotation_degrees = rotation_degrees.move_toward(to_rotation, rotation_speed * delta)
		if snapped(progress, 0.01) == snapped(to_point, 0.01) and not emited:
			active.emit(false)
			emited = true


func to_position(point: float = 0.0) -> void:
	if enabled and not blocked:
		var desired := point if !is_closed else wrapf(point, 0.0, path_len)
		var current_wrapped := _raw_progress if !is_closed else wrapf(_raw_progress, 0.0, path_len)

		var delta := desired - current_wrapped
		# Если путь замкнут — выбираем кратчайший путь
		if is_closed and abs(delta) > path_len * 0.5:
			if delta > 0.0:
				delta -= path_len
			else:
				delta += path_len

		_target_raw = _raw_progress + delta
		to_point = desired

		active.emit(true)
		emited = false

func set_to_point_ratio(value: float) -> void:
	to_position(value * path_len)

func get_to_point_ratio() -> float:
	return to_point / path_len if path_len > 0 else 0.0

func to_rotation_deg(_rotation: Vector3 = Vector3.ZERO) -> void:
	to_rotation = _rotation
