extends Action
class_name DashAction2D

signal dash_count_max_changed(count: int)

@export var dash_speed:float=2000:
	set(v):
		dash_speed=v
		dash_duration=dash_distance/dash_speed
@export var dash_count_max: int = 1:
	set(v):
		dash_count_max = v
		dash_count_max_changed.emit(v)
@export var dash_distance := 200.0:
	set(v):
		dash_distance=v
		dash_duration=dash_distance/dash_speed
@export var dash_cooldown := 0.75

var want_act:bool=false

var last_input_direction:Vector2
var velocity:Vector2
var last_velocity:Vector2

var dash_buffer := Buffer.new(0.2, 0.2)
var dashing: bool = false
var dash_tween: Tween
var dash_cooldown_timer: float = 0
var dash_timer: float = 0
var dash_duration:float=0

func _action(delta:float) -> void:
	if dash_buffer.should_run_action():
		dashing = true
		dash_cooldown_timer += dash_cooldown
		last_velocity = velocity
		velocity = last_input_direction * dash_speed
		return

	if dashing:
		dash_timer += delta
		if dash_timer > dash_duration:
			velocity=last_velocity
			dashing = false
			dash_timer = 0

func _addition(delta:float) -> void:
	dash_buffer.update(want_act, dash_cooldown_timer + dash_cooldown <= \
		dash_count_max * dash_cooldown and not dashing, delta)
	if not dashing:
		dash_cooldown_timer = max(0, dash_cooldown_timer - delta)
