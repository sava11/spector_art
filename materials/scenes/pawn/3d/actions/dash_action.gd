extends Action
class_name DashAction3D

signal count_max_changed(count: int)

@export var speed:float=200:
	set(v):
		speed=v
		duration=distance/speed
@export var count_max: int = 1:
	set(v):
		count_max = v
		count_max_changed.emit(v)
@export var distance := 100.0:
	set(v):
		distance=v
		duration=distance/speed
@export var cooldown := 0.75

var want_dash:bool=false

var last_input_direction:Vector2
var velocity:Vector3
var last_velocity:Vector3

var buffer := Buffer.new(0.2, 0.2)
var dashing: bool = false
var tween: Tween
var cooldown_timer: float = 0
var timer: float = 0
var duration:float=0

func _ready() -> void:
	duration=distance/speed

func _action(delta:float) -> void:
	if buffer.should_run_action():
		dashing = true
		cooldown_timer += cooldown
		last_velocity = Vector3(velocity.x,0,velocity.z)
		velocity = Vector3(last_input_direction.x, 0, last_input_direction.y) * speed
		return

	if dashing:
		timer += delta
		if timer > duration:
			velocity=last_velocity
			dashing = false
			timer = 0

func _addition(delta:float) -> void:
	buffer.update(want_dash, cooldown_timer + cooldown <= \
		count_max * cooldown and not dashing, delta)
	if not dashing:
		cooldown_timer = max(0, cooldown_timer - delta)
