extends Area2D
class_name ZipPoint

@export var blocked: bool = false: set = set_blocked
@export var keys_paths: Array[KLLockItem] = []

var hl:ColorRect
var img:Sprite2D
var lock:KLLock

func _ready() -> void:
	hl=ColorRect.new()
	hl.material=preload("res://mats/objects/zip_zones/zip_node.tres")
	add_child(hl)
	#hl.hide()
	hl.size=Vector2(40,40)
	hl.position=-hl.size/2
	lock=KLLock.new()
	lock.name="lock"
	lock.activated.connect(set_blocked)
	lock.keys_paths=keys_paths
	add_child(lock)
	img=Sprite2D.new()
	img.texture=preload("res://mats/objects/zip_zones/zip_point_img.svg")
	img.name="img"
	img.scale=Vector2(0.045,0.045)
	img.offset=Vector2(0,128)
	img.hide()
	add_child(img)

func _process(_delta: float) -> void:
	var real_time: float = Time.get_ticks_msec() / 1000.0  # В секундах
	hl.material.set_shader_parameter("unscaled_time", real_time)

func set_blocked(value: bool) -> void:
	blocked = value
	set_deferred("monitorable",not value)
	set_deferred("monitoring",not value)
