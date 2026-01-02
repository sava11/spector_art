extends CharacterBody2D
# Universal 2D Character Controller with Multi-Jump and Dash

signal cling_enabled_changed(enabled: bool)
signal cling_control_changed(enabled: bool)
signal jump_count_max_changed(count: int)
signal dash_count_max_changed(count: int)


@export var can_move: bool = true
@export var can_input: bool = true


@export var zip_enabled: bool = true:
	set(v):
		zip_enabled = v
		if zip_zone != null:
			zip_zone.set_collision_layer_value(9, v)
			zip_zone.set_collision_mask_value(9, v)

@export_group("move ground", "ground")
@export var ground_accel := 1200.0
@export var ground_decel := 1400.0
@export var ground_turn_accel := 2000.0

@export_group("move air", "air")
@export var air_accel := 800.0
@export var air_decel := 800.0
@export var air_turn_accel := 1200.0

@export_group("climb", "cling")
@export var cling_enabled: bool = true:
	set(v):
		cling_enabled = v
		cling_enabled_changed.emit(v)
@export var cling_control: bool = false:
	set(v):
		cling_control = v
		cling_control_changed.emit(v)
@export var cling_up: float = 100.0
@export var cling_fall: float = 100.0

@export_group("drop_down","drop_down")
@export var drop_down_enabled: bool = false
@export var drop_down_time:=0.5
@export var drop_down_speed:=1204

@export_group("jump", "jump")
@export var jump_count_max: int = 1:
	set(v):
		jump_count_max = v
		jump_count_max_changed.emit(v)
@export var jump_height: float = 96.0
@export var jump_distance: float = 144.0
@export_range(0.001, 2, 0.001) var jump_time_to_apex: float = 0.35
@export var jump_time_to_land: float = 0.35

@export_group("dash", "dash")
@export var dash_count_max: int = 1:
	set(v):
		dash_count_max = v
		dash_count_max_changed.emit(v)
@export var dash_distance := 200.0
@export var dash_duration := 0.2
@export var dash_cooldown := 0.5

@export_group("Hit animation")
@export var hit_curve: Curve

# --- soft-body параметры (вставьте вместе с другими var/@export) ---
@export_group("soft body", "sb")
@export var sb_spring_k: float = 400.0        # жёсткость "пружины" к rest-позиции
@export var sb_damping: float = 18.0         # внутренний демпфер скорости точки
@export var sb_mass: float = 1.0             # масса точки (влияет на отклик)
@export var sb_velocity_influence: float = 0.06  # как сильно глобальная скорость тянет точки
@export var sb_directional_stretch: float = 0.9 # множитель растяжения в направлении движения
@export var sb_neighbor_stiffness: float = 60.0 # сила сглаживания между соседями
@export var sb_max_point_vel: float = 1000.0  # лимит скорости точки
@export var sb_ground_pin: float = 0.6       # при приземлении нижние точки меньше дергаются (0..1)
@export var sb_area_preserve: float = 0.05   # корекция сохраняющая площадь (маленькая)

@onready var mz:=$marks/zip
@onready var zip_zone: Area2D = $detectors/zip_zone
@onready var eye = $visual/skin/eye
@onready var skin = $visual/skin
@onready var dash_container = $visual/vbc/dash_container
@onready var hurt_box = $HurtBox
@onready var climb_det: RayCast2D = $detectors/climb
@onready var wall_det: RayCast2D = $detectors/wall_det
@onready var gu_r: RayCast2D = $get_up_r
@onready var ngu_r: RayCast2D = $get_up_r/not_get_up
@onready var gu_l: RayCast2D = $get_up_r/get_up_l

@onready var rays_l:=$rays/l
@onready var rays_r:=$rays/r

# --- internal (автоматически) ---
var _sb_pos := []        # текущие позиции точек (локальные координаты Polygon2D)
var _sb_vel := []        # скорости точек (локальные)
var _sb_rest := []       # rest-позиции точек (локальные)
var _sb_inited: bool = false

var jump_buffer := Buffer.new(0.2, 0.2)
var dash_buffer := Buffer.new(0.2, 0.2)
var attack_buffer := Buffer.new(0.2, 0.2)

var climbout_time: float = 0.5
var climbout_timer: float = 0.5

var platform_down_time:=0.5
var platform_down_timer:=0.0

# State
var input_dir: Vector2 = Vector2.ZERO
var last_input_dir_x: int = -1

var want_jump: bool = false
var is_jumping: bool = false
var jump_held: bool = false
var jump_released: bool = false
var jump_count: int = 0
var jump_avaliable:=false

var _on_ground: bool = false
var on_wall: int = 0
var _climb: bool = false

var want_drop_down:=false
var droping_down:=false
var drop_down_timer:=0.0

# Dash state
var want_dash: bool = false
var dashing: bool = false
var dash_tween: Tween
var dash_cooldown_timer: float = 0
var dash_timer: float = 0

var want_attack: bool = false
var attacking: bool = false
var cur_att: int = 0
var attack_times := [0.15,0.25,0.2]
var current_time:float=0.0
var current_timer:float=0.0

var want_zip: bool = false
var in_zip_mode: bool =false
var zipping: bool = false
var zipped: bool = false
var zip_node: Node2D
const ZIP_SPEED: float = pow(2, 10)
const ZIP_ACCEL: float = pow(2, 16)

var stuned: bool = false

var hited: bool = false
var hit_animation_timer: float = 0.0

var get_up_speed: float = 3
var get_up_dir:int=0
var get_up_anim: PathFollow2D = null

var gravity_apex: float
var gravity_fall: float
var jump_velocity: float
var max_speed: float
var dash_speed: float

var skin_size:=Vector2(32.0,32.0)

func can_save():
	return !dashing and !zip_node and !droping_down and _on_ground and !_climb and \
	!validate_node(get_up_anim) and !is_jumping and !stuned

var world_cam:PhantomCamera2D
func _ready() -> void:
	world_cam=get_tree().current_scene.get_node("%world_cam")
	gravity_apex = (2 * jump_height) / pow(jump_time_to_apex, 2)
	gravity_fall = (2 * jump_height) / pow(jump_time_to_land, 2)
	jump_velocity = gravity_apex * jump_time_to_apex
	max_speed = jump_distance / (jump_time_to_apex + jump_time_to_land)
	dash_speed = dash_distance / dash_duration
	soft_body_init()
	
	var height:float=32.0
	platform_down_time=height/gravity_fall
	zip_zone.set_collision_layer_value(9, zip_enabled)
	zip_zone.set_collision_mask_value(9, zip_enabled)
	_create_dash_visual(dash_count_max)
	dash_count_max_changed.connect(_create_dash_visual)
	dash_container.visible = dash_count_max > 0

func _create_dash_visual(count: int):
	for child in dash_container.get_children():
		child.queue_free()
	for i in range(count):
		var prb := ProgressBar.new()
		prb.name = "prb" + str(i)
		prb.show_percentage = false
		prb.custom_minimum_size = Vector2(32, 4)
		prb.min_value = 0
		prb.max_value = dash_cooldown
		prb.value = dash_cooldown
		dash_container.add_child(prb)

func get_input() -> void:
	if can_input:
		if not attacking and not dashing and not (zipping or zipped):
			input_dir = Vector2(
				int(Input.is_action_pressed("ui_right")) -
				int(Input.is_action_pressed("ui_left")),
				int(Input.is_action_pressed("ui_down")) -
				int(Input.is_action_pressed("ui_up"))
			)
			if input_dir.x != 0 and not _climb and \
				not validate_node(get_up_anim):
				last_input_dir_x = sign(input_dir.x)
		elif _on_ground:
			input_dir.x = 0
		else:
			input_dir = Vector2(
				int(Input.is_action_pressed("ui_right")) -
				int(Input.is_action_pressed("ui_left")),
				int(Input.is_action_pressed("ui_down")) -
				int(Input.is_action_pressed("ui_up"))
			)
		want_attack = Input.is_action_just_pressed("attack")
		want_jump = Input.is_action_just_pressed("jump")
		jump_held = Input.is_action_pressed("jump")
		jump_released = Input.is_action_just_released("jump")
		want_dash = dash_count_max > 0 and Input.is_action_just_pressed("spirit")
		want_zip = zip_enabled and Input.is_action_pressed("zip")
		want_drop_down=input_dir.y>0 and want_jump and drop_down_enabled
	else:
		input_dir = Vector2.ZERO
		jump_released = false
		jump_held = jump_released
		want_jump = jump_held
		want_dash = false
		want_attack = false
		want_zip = false
		want_drop_down=false
		return

func _process(delta: float) -> void:
	if input_dir != Vector2.ZERO:
		eye.position = eye.position.move_toward(
			input_dir.normalized() * (skin_size / 2 - eye.size / 2) - eye.size / 2,
			200 * delta)
	play_hit_animation(delta)
	body_animations(delta)

func validate_node(obj):
	return obj != null and is_instance_valid(obj)

func _physics_process(delta: float) -> void:
	#var base_angle:=0.0
	#if rays_l.is_colliding() or rays_r.is_colliding():
		#var target_point:=Vector2.ZERO
		##target_point_size*=2
		#if rays_r.is_colliding():
			#target_point+=rays_r.get_collision_point(0)
		#if rays_l.is_colliding():
			#target_point+=rays_l.get_collision_point(0)
			#base_angle=snappedf(wrapf(FNC.angle(target_point/2-rays_l.get_collision_point(0)),
			#-180,180),0.001)
			#print(base_angle)
			#print(target_point/2-global_position)
	#rotation_degrees=move_toward(snappedf(base_angle,0.001),0,200*delta)
	get_input()
	update_ground_and_timers(delta)
	wall_det.position.x = last_input_dir_x * abs(wall_det.position.x)
	wall_det.target_position.x = last_input_dir_x * \
		abs(wall_det.target_position.x)
	climb_det.target_position.x = last_input_dir_x * \
		abs(climb_det.target_position.x)
	gu_r.position.x = last_input_dir_x * abs(gu_r.position.x)
	gu_l.position.x = -last_input_dir_x * abs(gu_l.position.x)
	$hitboxes.scale.x = last_input_dir_x
	$detectors/not_grab.target_position.x=last_input_dir_x * abs(gu_r.position.x)
	dash_container.visible = dash_count_max > 0
	
	handle_get_up()
	if validate_node(get_up_anim):
		if get_up_anim.progress_ratio >= 1.0 or input_dir.y > 0 or \
			_on_ground or zipping:
			_free_get_up_anim()
		else:
			if get_up_anim.progress_ratio == 0:
				if want_jump and not _look_from_wall() and on_wall != 0:
					_ledge_jump()
				elif want_dash and not _look_from_wall() and on_wall != 0:
					_ledge_dash(delta)
				elif ((want_jump or input_dir.y < 0) and (_look_from_wall() or on_wall == 0)):
					get_up_anim.progress_ratio += delta * get_up_speed
			elif get_up_anim.progress_ratio > 0:
				get_up_anim.progress_ratio += delta * get_up_speed
	
	process_zipping(delta)
	if not validate_node(get_up_anim):
		process_drop_down(delta)
		process_dash(delta)
		if not dashing and not zipping and not want_dash and not droping_down:
			process_climb(delta)
			if input_dir.y <= 0:
				process_jumping()
			process_attack(delta)
			process_horizontal(delta)
			apply_gravity(delta)
			#set_collision_mask_value(2, not (input_dir.y > 0 and want_jump))
			if (input_dir.y > 0 and want_jump):
				set_collision_mask_value(2,false)
				platform_down_timer=platform_down_time
			if platform_down_timer<=0.0 and not get_collision_mask_value(2):
				set_collision_mask_value(2,true)
			platform_down_timer=max(platform_down_timer-delta,0)
	move_and_slide()
	

# --- инициализация soft-body (вызвать в _ready()) ---
func soft_body_init() -> void:
	# берем текущий полигон skin (локальные координаты)
	var poly = []
	for p in skin.polygon:
		poly.append(Vector2(p))
	# если нет 4 точек — создаём прямоугольник по skin_size
	if poly.size() != 4:
		var w = skin_size.x
		var h = skin_size.y
		# порядок: TL, TR, BR, BL (соответствует нашему соглашению)
		poly = [
			Vector2(-w/2, -h/2),
			Vector2( w/2, -h/2),
			Vector2( w/2,  h/2),
			Vector2(-w/2,  h/2),
		]
	# init arrays
	_sb_pos.clear()
	_sb_vel.clear()
	_sb_rest.clear()
	for p in poly:
		_sb_rest.append(Vector2(p))
		_sb_pos.append(Vector2(p))
		_sb_vel.append(Vector2.ZERO)
	# записываем в skin (на случай, если мы сгенерировали полигон)
	skin.polygon = PackedVector2Array(poly)
	_sb_inited = true

# --- helper: соседний индекс ---
func _sb_prev(i:int) -> int:
	return (i + 3) % 4
func _sb_next(i:int) -> int:
	return (i + 1) % 4

# --- основная функция анимации (заменяет существующую body_animations) ---
func body_animations(delta: float):
	if not _sb_inited:
		soft_body_init()

	# базовые внешние параметры
	var global_vel = velocity  # world-space velocity (CharacterBody2D)
	# приводим влияние скорости в локальные координаты skin (без поворота узла -> skin локализация)
	# skin может быть rotated/scaled, используем to_local:
	var vel_local = skin.to_local(global_position + global_vel) - skin.to_local(global_position)
	# направление движения (0 если нет)
	var move_dir = Vector2.ZERO
	if global_vel.length() > 1e-3:
		move_dir = global_vel.normalized()

	# настройка силы при состояниях
	var dash_factor = 1.0
	if dashing:
		dash_factor = 2.4
	elif zipping or zipped:
		dash_factor = 1.6
	elif in_zip_mode:
		dash_factor = 0.9

	# индекс точек: 0=TL,1=TR,2=BR,3=BL (считаем по часовой)
	# для каждой точки: рассчитываем spring к rest + влияние скорости + коррекцию соседей
	for i in range(4):
		var pos = _sb_pos[i]
		var vel = _sb_vel[i]
		var rest = _sb_rest[i]

		# сила, возвращающая точку в rest-позицию (пружина)
		var spring_force = (rest - pos) * sb_spring_k

		# влияние глобальной скорости: тянет фронтальные точки в направлении движения
		# вычислим вес точки по направлению движения: правые точки положительно влияют при движении вправо и т.д.
		# для простоты используем x-координату rest (левый = отрицат, правый = положит)
		var sidedness = sign(rest.x)  # -1 для левых, +1 для правых
		var verticalness = sign(rest.y)  # -1 для верхних, +1 для нижних

		# горизонтальное (front/back) влияние скорости:
		var vel_pull = vel_local * (sb_velocity_influence * dash_factor)
		# усилим влияние на "фронт" — если движение направо, правые точки тянутся вперёд сильнее
		var front_weight = 0.5 + 0.5 * clamp(move_dir.x * sidedness, -1.0, 1.0)
		# верх/низ участвуют меньше
		var vertical_weight = 0.3 + 0.7 * clamp(-move_dir.y * verticalness, -1.0, 1.0)

		var velocity_force = vel_pull * (0.6 * front_weight + 0.4 * vertical_weight)

		# акцентированный растягивающий эффект при даш/zip: тянем дальнюю (фронт) сторону вперёд и сжимаем противоположную
		var dash_stretch = Vector2.ZERO
		if move_dir != Vector2.ZERO:
			# фронтовые точки (по х) получают положительный смещ
			dash_stretch = move_dir * (sb_directional_stretch * dash_factor * front_weight * 0.5)

		# neighbor (smoothing) forces — удержание локальной формы
		var nbr_force = (_sb_pos[_sb_prev(i)] + _sb_pos[_sb_next(i)] - pos * 2.0) * sb_neighbor_stiffness

		# ground pin: если на земле — нижние точки менее подвижны
		var ground_modifier = 1.0
		if _on_ground:
			# считаем нижними те, у которых rest.y > 0
			if rest.y > 0:
				ground_modifier = sb_ground_pin

		# суммарная сила
		var total_force = (spring_force + velocity_force + nbr_force + dash_stretch) * ground_modifier
		# демпфирование
		var damping_force = -vel * sb_damping
		total_force += damping_force

		# интегрируем (semi-implicit Euler)
		var acc = total_force / sb_mass
		vel += acc * delta
		# ограничение скорости точки
		if vel.length() > sb_max_point_vel:
			vel = vel.normalized() * sb_max_point_vel
		pos += vel * delta

		# записываем назад
		_sb_vel[i] = vel
		_sb_pos[i] = pos

	# Простая area-preserve коррекция (малое сглаживание, чтобы не "расползалось")
	if sb_area_preserve > 0.0:
		# area текущего полигона vs rest area
		var area_rest = abs(PolyArea(_sb_rest))
		var area_now = abs(PolyArea(_sb_pos))
		if area_now > 0:
			var area_error = (area_rest - area_now) * sb_area_preserve
			# корректируем каждую точку немного в сторону центра, пропорционально площади ошибки
			var center = _sb_pos[0] + _sb_pos[1] + _sb_pos[2] + _sb_pos[3]
			center /= 4.0
			for i in range(4):
				var dir_to_center = (center - _sb_pos[i])
				_sb_pos[i] += dir_to_center * (area_error / max(area_now, 1.0)) * 0.25

	# лёгкая позиционная коррекция, чтобы точки не слишком отдалялись от rest (порог + мягкая притяжка)
	for i in range(4):
		var d = _sb_pos[i] - _sb_rest[i]
		var max_dist = max(skin_size.x, skin_size.y) * 0.7
		if d.length() > max_dist:
			_sb_pos[i] = _sb_rest[i] + d.normalized() * max_dist
			_sb_vel[i] *= 0.5

	# применяем в Polygon2D (локальные координаты)
	var out_poly := PackedVector2Array()
	for p in _sb_pos:
		out_poly.append(p)
	skin.polygon = out_poly

	# (опционально) плавная подстройка глобальной rotation/scale для дополнительного клеемого ощущения:
	# сохраняем небольшую общую squash/tilt по сравнению с rest-ограничением
	# вычислим bbox текущий и rest, и плавно применим scale на skin
	var bb_now = _bbox_size(_sb_pos)
	var bb_rest = _bbox_size(_sb_rest)
	if bb_rest.x > 0 and bb_rest.y > 0:
		var scale_x = clamp(bb_now.x / bb_rest.x, 0.7, 1.6)
		var scale_y = clamp(bb_now.y / bb_rest.y, 0.7, 1.6)
		skin.scale.x = lerp(skin.scale.x, scale_x, 8.0 * delta)
		skin.scale.y = lerp(skin.scale.y, scale_y, 8.0 * delta)

# --- вспомогательные функции ---

# вычисляет ориентированную площадь полигона (полезно для коррекции площади)
func PolyArea(points: Array) -> float:
	var s: float = 0.0
	for i in range(points.size()):
		var a = points[i]
		var b = points[(i + 1) % points.size()]
		s += a.x * b.y - b.x * a.y
	return s * 0.5

# возвращает Vector2(width, height) bounding box по локальным точкам
func _bbox_size(points: Array) -> Vector2:
	var minx = points[0].x
	var maxx = points[0].x
	var miny = points[0].y
	var maxy = points[0].y
	for p in points:
		minx = min(minx, p.x)
		maxx = max(maxx, p.x)
		miny = min(miny, p.y)
		maxy = max(maxy, p.y)
	return Vector2(maxx - minx, maxy - miny)



func _look_from_wall():
	return (
		(0>=input_dir.x and on_wall > 0) or \
		(0<=input_dir.x and on_wall < 0)
		) or ( gu_l.is_colliding() and  gu_r.is_colliding() )

func process_climb(_delta: float) -> void:
	climb_det.force_raycast_update()
	_climb = can_move and cling_enabled and \
		climb_det.is_colliding() and climbout_timer > 0.0
	if not _climb:
		return

func handle_get_up():
	gu_r.force_raycast_update()
	gu_l.force_raycast_update()
	wall_det.force_raycast_update()
	if not validate_node(get_up_anim) and is_instance_valid(gu_r.get_collider()) \
		and not attacking and not is_instance_valid(ngu_r.get_collider()) and \
		input_dir.y <= 0 and not _on_ground and not zipping and \
		not (gu_r.get_collider() as Node).is_in_group("not_grab") and \
		not $detectors/not_grab.is_colliding():
		if is_instance_valid(dash_tween):
			dash_tween.kill()
		dashing = false
		ngu_r.force_raycast_update()
		var p: Vector2 = gu_r.get_collision_point()
		if is_instance_valid(gu_l.get_collider()):
			p = (p + gu_l.get_collision_point()) / 2.0
		get_up_dir = sign(snapped(p.x - global_position.x, 0.5))
		ngu_r.global_position = p
		var pth := Path2D.new()
		pth.curve = Curve2D.new()
		pth.curve.add_point(Vector2(get_up_dir * -abs(gu_r.position.x), skin_size.y / 2),
			Vector2.ZERO, Vector2(0, -skin_size.y))
		pth.curve.add_point(Vector2(0, -skin_size.y / 2), Vector2(get_up_dir * -skin_size.x, 0),
			Vector2(get_up_dir * skin_size.x, 0))
		var pthf := PathFollow2D.new()
		var rt := RemoteTransform2D.new()
		pthf.loop = false
		pthf.rotates = false
		rt.update_rotation = false
		rt.update_scale = false
		pth.add_child(pthf)
		pthf.add_child(rt)
		var target = gu_r.get_collider()
		var shape_id = gu_r.get_collider_shape()
		var owner_id = target.shape_find_owner(shape_id)
		var shape = target.shape_owner_get_owner(owner_id)
		shape.add_child(pth)
		if wall_det.is_colliding() and not zipped and not zipping:
			p += wall_det.get_collision_point() - global_position + \
				Vector2(-skin_size.x / 2 * last_input_dir_x, 0)
		pth.global_position = p
		get_up_anim = pthf
		rt.remote_path = rt.get_path_to(self)
		get_up_anim.progress = 0.0
		velocity = Vector2.ZERO
	else:
		ngu_r.global_position = gu_r.global_position + gu_r.target_position

func _free_get_up_anim():
	if validate_node(get_up_anim):
		get_up_anim.get_parent().queue_free()
	get_up_anim = null

func _ledge_jump():
	_free_get_up_anim()
	#is_jumping = true
	#_on_ground = false
	#jump_count += 1
	#velocity.y = -jump_velocity * 1.2
	#velocity.x = on_wall * max_speed * 0.8
	#last_input_dir_x = on_wall

func _ledge_dash(delta: float):
	_free_get_up_anim()
	process_dash(delta)

func process_attack(delta: float):
	if attack_buffer.should_run_action():
		current_time=attack_times[cur_att]
		var n:=$hitboxes.get_child(cur_att)
		n.monitoring=true
		n.monitorable=true
		n.show()
		attacking = true
	if attacking and current_timer>=current_time:
		var n:=$hitboxes.get_child(cur_att)
		n.monitoring=false
		n.monitorable=false
		n.hide()
		attacking=false
		cur_att = wrap(cur_att + 1, 0, attack_times.size())
		current_time=0
		current_timer=0
	current_timer=min(current_timer+delta,current_time)
	if attack_buffer.get_post_buffer_time_passed()==0.0 and \
	attack_buffer.get_pre_buffer_time_passed()==attack_buffer.pre_buffer_max_time:
		cur_att=0

func process_horizontal(delta: float) -> void:
	if _climb or zip_node or dashing: return
	var target_speed = input_dir.x * max_speed
	var accel = ground_accel if _on_ground else air_accel
	var decel = ground_decel if _on_ground else air_decel
	var turn_accel = ground_turn_accel if _on_ground else air_turn_accel
	var rate: float = accel if (sign(velocity.x) == sign(target_speed) or target_speed == 0) else turn_accel
	if target_speed != 0 and can_move and not _climb and (snapped(abs(velocity.x), 0.1) <= snapped(abs(target_speed), 0.1)):
		velocity.x = move_toward(velocity.x, target_speed, rate * delta)
	else:
		if _on_ground:
			velocity.x = move_toward(velocity.x, 0, decel * delta)

func process_dash(delta: float) -> void:
	if dash_buffer.should_run_action():
		dashing = true
		dash_cooldown_timer += dash_cooldown
		var dir_x:=0
		if on_wall!=0:
			dir_x=on_wall
		else:
			dir_x=last_input_dir_x
		var vec := Vector2(dir_x * dash_speed, 0)
		velocity = vec
		dash_tween = get_tree().create_tween()
		dash_tween.tween_property(self, "velocity", 
			velocity - vec, dash_duration)
		return
	if dashing:
		dash_timer += delta
		if dash_timer > dash_duration:
			dashing = false
			dash_timer = 0

func process_jumping() -> void:
	if jump_buffer.should_run_action():
		is_jumping = true
		_on_ground = false
		jump_count += 1
		if velocity.y > 0:
			velocity.y = 0
		if _climb:
			velocity.x = int(not _look_from_wall()) * on_wall * max_speed
			velocity.y = -jump_velocity
			last_input_dir_x = on_wall
		else:
			velocity.x = input_dir.x * abs(velocity.x)
			velocity.y = -jump_velocity
	elif not is_jumping and not jump_avaliable and jump_count == 0:
		jump_count += 1

	if jump_released and velocity.y < 0:
		velocity.y *= 0.5

func _gen_dir() -> Vector2:
	var dir := Vector2.ZERO
	match IV.device_id:
		0:
			dir = (get_global_mouse_position() - zip_zone.global_position).normalized()
		1:
			dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return dir

func process_zipping(delta: float) -> void:
	in_zip_mode = want_zip and not zipping and not zipped and \
	not validate_node(get_up_anim) and not _on_ground
	Engine.time_scale = 0.05 + 0.95 * int(!in_zip_mode)
	$detectors/zip_zone/visual.visible=in_zip_mode
	world_cam.follow_target=mz if in_zip_mode else $marks/base
	mz.position=get_local_mouse_position().normalized()*min(
		get_local_mouse_position().length(),
		zip_zone.get_node("c").shape.radius/2)
	if zip_enabled and not _on_ground and not (_climb and cling_control and 
		input_dir.y==0):
		if in_zip_mode:
			var dir := _gen_dir()
			var _new_zip_node = zip_zone.get_available_zip_point(
				dir * zip_zone.get_child(0).shape.radius)
			if _new_zip_node:
				_new_zip_node.img.show()
				_new_zip_node.img.global_rotation_degrees = rad_to_deg(
					(zip_zone.global_position - \
					_new_zip_node.global_position).angle())-90
			if _new_zip_node == zip_node: return
			if zip_node: zip_node.img.hide()
			zip_node = _new_zip_node

		if zip_node and not in_zip_mode:
			zipping = true
			var to: Vector2 = zip_node.global_position
			var from: Vector2 = global_position
			velocity = velocity.move_toward(
				from.direction_to(to) * ZIP_SPEED, ZIP_ACCEL * delta)
			if from.distance_squared_to(to) <= pow(ZIP_SPEED * delta,2)*1.5:
				if zip_node:
					zip_node.img.hide()
				global_position = zip_node.global_position
				velocity = Vector2.ZERO
				last_input_dir_x = 1-2*int(0>=from.direction_to(to).x)
				zipping = false
				zipped = true
		if zipped and (_on_ground or jump_buffer.should_run_action() or \
			dash_buffer.should_run_action() or (validate_node(get_up_anim) and input_dir.y<0)):
			clear_zip()
	else:
		clear_zip()

func clear_zip():
	if zip_node:
		zip_node.img.hide()
	zip_node = null
	zipping = false
	zipped = false

func process_drop_down(delta:float):
	if want_drop_down and not _on_ground:
		droping_down=true
		drop_down_timer=0
	if droping_down:
		velocity.x=0
		velocity.y = drop_down_speed
		drop_down_timer=min(drop_down_timer+delta,drop_down_time)
		if drop_down_timer>=drop_down_time or _on_ground:
			droping_down=false

func apply_gravity(delta: float) -> void:
	if not (zipping or zipped or dashing):
		if is_jumping and velocity.y < 0:
			velocity.y += gravity_apex * delta
		else:
			if climb_det.is_colliding():
				if cling_enabled and cling_control and input_dir.y <= 0:
					velocity.y = move_toward(velocity.y,
						clampf(input_dir.y, -1, 0) * cling_up, 1000 * delta)
				else:
					velocity.y = move_toward(velocity.y, cling_fall, 1000 * delta)
			else:
				velocity.y += gravity_fall * delta

func update_ground_and_timers(delta: float) -> void:
	if wall_det.is_colliding() or climb_det.is_colliding():
		on_wall=int(wall_det.is_colliding() or climb_det.is_colliding()) * \
			-int(sign(wall_det.target_position.x))
		if on_wall < 0 and input_dir.x < 0 or on_wall > 0 and input_dir.x > 0:
			climbout_timer = max(0, climbout_timer - delta)
	else:
		on_wall = 0
		climbout_timer = climbout_time
	
	if _climb or validate_node(get_up_anim) or zipped:
		jump_count = 0
		is_jumping = false
	
	if is_on_floor():
		_on_ground = true
		jump_count = 0
		is_jumping = false
	else:
		_on_ground = false
	
	jump_avaliable=_on_ground or _climb or validate_node(get_up_anim) or zipped
	jump_buffer.update(want_jump, jump_count < jump_count_max, delta)
	attack_buffer.update(want_attack, not attacking, delta)
	dash_buffer.update(want_dash and not _look_from_wall(), !droping_down and
		dash_cooldown_timer + dash_cooldown <= dash_count_max * dash_cooldown \
		and not dashing, delta)
	if not dashing and (_on_ground or _climb or (zip_node != null and \
		not want_zip and zipped) or validate_node(get_up_anim)):
		dash_cooldown_timer = max(0, dash_cooldown_timer - delta)
	for i in dash_container.get_child_count():
		var t = (dash_count_max * dash_cooldown - dash_cooldown_timer) / dash_cooldown
		var frac = maxf(minf(t - i, 1.0), 0.0)
		dash_container.get_child(i).value = frac * dash_cooldown

func play_hit_animation(delta: float) -> void:
	if hited:
		hit_animation_timer += delta
		$visual/skin/hit.color.a = hit_curve.sample(hit_animation_timer / 
			hurt_box.tspeed) * 0.75
		if hit_animation_timer > hurt_box.tspeed:
			hit_animation_timer = 0
			hited = false
	elif $visual/skin/hit.color.a != 0:
		$visual/skin/hit.color.a = 0

func _on_hurt_box_health_changed(value: float, delta: float) -> void:
	$visual/skin.material.set_deferred("shader_parameter/sector", 
		value / $HurtBox.max_health)
	if value > 0 and delta < 0:
		hited = true
	if value == 0:
		can_input = false
		can_move = false

func _on_data_loaded() -> void:
	velocity = Vector2.ZERO

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name.contains("attack"):
		attacking = false
