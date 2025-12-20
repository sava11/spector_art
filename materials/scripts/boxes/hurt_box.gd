class_name HurtBox
extends Area2D

signal invi_started
signal invi_ended
signal alive(alive:bool)
signal health_changed(value:float, delta:float)
signal max_health_changed(value:float, delta:float)

@export_flags_2d_physics() var flags:=0
@export var exceptions:Array[HitBox]
@export var tspeed:float=1.0
@export var max_health:float=1: set=set_max_health

@onready var t:=Timer.new()

var invincible=false:set=set_invincible
var health:float=max_health: set=set_health
var _alive:=false:set=set_alive
var bs:Array=[]

func set_max_health(value:float):
	emit_signal("max_health_changed",value,value-max_health)
	self.health=value*float(health)/float(max_health)
	max_health=value

func set_health(value:float):
	var delta:=value-health
	emit_signal("health_changed",value,delta)
	if health<=0 and delta>0:
		_alive=true
	if is_node_ready():
		health=min(value,max_health)
	else:
		_alive=true
		health=value
	if health<=0 and _alive:
		_alive=false
		health=0

func set_alive(value:bool):
	_alive=value
	alive.emit(_alive)

func set_invincible(v):
	invincible=v
	self.set_deferred("monitorable",!v)
	self.set_deferred("monitoring",!v)
	if invincible:
		emit_signal("invi_started")
	else:
		emit_signal("invi_ended")

func start_invincible(duration:float=tspeed):
	if duration>0:
		self.invincible=true
		t.start(duration)

func _ready():
	if not area_exited.is_connected(_on_area_shape_exited):
		area_shape_exited.connect(_on_area_shape_exited)
	if not area_shape_entered.is_connected(_on_area_shape_entered):
		area_shape_entered.connect(_on_area_shape_entered)
	
	emit_signal("max_health_changed",max_health,max_health)
	emit_signal("health_changed",health,health)
	t.name="timer"
	add_child(t)
	t.timeout.connect(_on_timeout)
	if tspeed>0:
		t.wait_time=tspeed

func _physics_process(delta: float) -> void:
	for i in exceptions.size():
		if exceptions[i]==null:
			exceptions.remove_at(i)
	for area_col in bs:
		_change_health_by_area(area_col,delta)

func _change_health_by_area(area_col, delta:float=1.0):
	var area:HitBox=area_col.get_parent()
	if area.detect_by_ray:
		var lenght:float=100
		var dir:Vector2=area_col.global_position.direction_to(global_position)
		var space := get_world_2d().direct_space_state
		var from_pos: Vector2 = area_col.global_position-dir.normalized()*lenght
		var to_pos :Vector2= from_pos + dir*lenght*2
		var params = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
		params.exclude = [self.get_rid()]
		params.collision_mask = flags
		params.collide_with_areas = true 
		var result = space.intersect_ray(params)
		if result.is_empty() or result.get("collider") == null or result.get("collider") is HitBox:
			_apply_dmg(area.damage, delta)
	else:
		_apply_dmg(area.damage, delta)

func _apply_dmg(damage,delta):
	health-=damage*delta
	start_invincible()

func _on_area_shape_exited(_area_rid: RID, area: HitBox, area_shape_index: int, _local_shape_index: int) -> void:
	if not is_instance_valid(area) and area==null:
		return
	if area in exceptions and area.single_detect and not invincible:
		exceptions.remove_at(exceptions.find(area))
	var other_shape_owner = area.shape_find_owner(area_shape_index)
	var area_col=area.shape_owner_get_owner(other_shape_owner)
	if bs.find(area_col)>=0:
		bs.erase(area_col)

func _on_area_shape_entered(_area_rid: RID, area: HitBox, area_shape_index: int, _local_shape_index: int) -> void:
	if !(area in exceptions) and health>0:
		var other_shape_owner = area.shape_find_owner(area_shape_index)
		var area_col=area.shape_owner_get_owner(other_shape_owner)
		if area.single_detect:
			if not area.stepped:
				exceptions.append(area)
			_change_health_by_area(area_col)
		else:
			bs.append(area_col)

func _on_timeout():
	self.invincible=false
