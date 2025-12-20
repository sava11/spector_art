extends Node

## Global utility functions and systems for the game.
##
## This script provides various helper functions for common game operations
## including pause management, mathematical utilities, screen effects, and geometry helpers.

## Emitted when screen darkening effect completes.
signal darked(result:bool)

## Random number generator instance for game-wide random operations.
var rng:=RandomNumberGenerator.new()

## Counter for nested pause calls. Game is paused when this is greater than 0.
var already_paused:int=0

## Set the game pause state with support for nested pause calls.
## Each call to pause increments a counter, each call to unpause decrements it.
## The game is only truly paused when the counter is greater than 0.
func set_pause(paused:bool=true):
	already_paused+=-1+2*int(paused)
	get_tree().paused=already_paused>0

#var already_physics_server2d_activated:int=0
#func set_physics_server2d_active(active:bool=true):
#	already_physics_server2d_activated+=-1+2*int(active)
#	PhysicsServer2D.set_active(already_physics_server2d_activated>0)

func _ready() -> void:
	rng.randomize()

## Calculate the angle in degrees of a 2D vector.
## Returns the angle in degrees, with 0° pointing right and increasing counterclockwise.
## [br][br]
## [codeblock]
## var angle = angle(Vector2(1, 0))  # Returns 0
## var angle = angle(Vector2(0, 1))  # Returns 90
## var angle = angle(Vector2(-1, 0)) # Returns 180
## [/codeblock]
static func angle(V:Vector2)->float:
	return rad_to_deg(-atan2(-V.y,V.x))

## Rotate a vector by a given angle in degrees.
## [br][br]
## [param vec] The vector to rotate
## [param ang] The angle in degrees to rotate by
## [br][br]
## [codeblock]
## var rotated = rotate_vec(Vector2(1, 0), 90)  # Returns Vector2(0, 1)
## [/codeblock]
static func rotate_vec(vec:Vector2,ang:float)->Vector2:
	return move(rad_to_deg(angle(vec))+ang)*Vector2.ZERO.distance_to(vec)

## Create a unit vector from an angle in degrees.
## This is equivalent to [method Vector2.from_angle] but uses degrees instead of radians.
## [br][br]
## [param ang] The angle in degrees
## [br][br]
## [codeblock]
## var right = move(0)    # Returns Vector2(1, 0)
## var up = move(90)      # Returns Vector2(0, 1)
## var left = move(180)   # Returns Vector2(-1, 0)
## [/codeblock]
static func move(ang)->Vector2:
	return Vector2(cos(deg_to_rad(ang)),sin(deg_to_rad(ang)))

## Calculate the sum of all elements in an array.
## Works with arrays containing numbers (int or float).
## [br][br]
## [param array] The array of numbers to sum
## [br][br]
## [codeblock]
## var total = sum([1, 2, 3, 4])  # Returns 10.0
## [/codeblock]
static func sum(array) -> float:
	var _sum = 0.0
	for element in array:
		_sum += element
	return _sum

## Find the index of an element in an array.
## Returns the index of the first occurrence of the element, or -1 if not found.
## [br][br]
## [param array] The array to search in
## [param i] The element to search for
## [br][br]
## [codeblock]
## var index = i_search(["a", "b", "c"], "b")  # Returns 1
## var index = i_search(["a", "b", "c"], "z")  # Returns -1
## [/codeblock]
static func i_search(array,i):
	var inte=0
	for k in array:
		if k==i:
			return inte
		inte+=1
	return -1

## Control the screen darkening effect for scene transitions or dramatic moments.
## Creates or removes a full-screen black overlay with smooth transitions.
## [br][br]
## [param r] If true, darkens the screen; if false, lightens it back to normal
## [param time] Duration of the transition in seconds
## [br][br]
## Emits the [signal darked] signal when the transition completes.
## [br][br]
## [codeblock]
## # Darken screen over 2 seconds
## set_dark(true, 2.0)
##
## # Wait for darkening to complete, then lighten back
## await darked
## set_dark(false, 1.0)
## [/codeblock]
func set_dark(r:bool=true,time:float=1):
	var cl:CanvasLayer=get_tree().root.get_node_or_null("darkness_bg")
	if r and cl==null:
		cl=CanvasLayer.new()
		cl.layer=3
		cl.name="darkness_bg"
		var cr=ColorRect.new()
		cr.name="darkness"
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		cr.color=Color(0,0,0,0)
		cl.add_child(cr)
		get_tree().root.add_child(cl)
		var tween = get_tree().create_tween().bind_node(cr).chain().set_trans(Tween.TRANS_EXPO)
		tween.tween_property(cr, "color", Color(0,0,0,1), time)
		tween.tween_callback((func():emit_signal("darked",r)))
	elif cl!=null:
		var cr=cl.get_node("darkness")
		cr.color=Color(0,0,0,1)
		var tween = get_tree().create_tween().bind_node(cr).chain().set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(cr, "color", Color(0,0,0,0), time)
		tween.tween_callback((func():
			emit_signal("darked",r)
			cl.queue_free()))

## Check if the screen darkening effect is currently active.
## Returns true if there's a darkness overlay present in the scene.
func has_darked()->bool:
	return get_tree().root.get_node_or_null("darkness_bg")!=null

## Extract polygon representations from an Area2D's collision shapes.
## Converts various collision shape types (CollisionPolygon2D, CollisionShape2D with different Shape2D types)
## into arrays of polygons in global coordinates. Useful for geometry operations, debugging, or custom physics.
## [br][br]
## Supported shape types:
## - [CollisionPolygon2D]: Direct polygon data
## - [RectangleShape2D]: Converted to 4-point rectangle
## - [CircleShape2D]: Approximated with 16-sided polygon
## - [CapsuleShape2D]: Approximated with semicircles and connecting segments
## - [ConvexPolygonShape2D]: Direct polygon data
## - [SegmentShape2D]: Converted to 2-point line segment
## [br][br]
## [param area] The Area2D node to extract polygons from
## [return] Array of [PackedVector2Array] representing polygons in global coordinates
## [br][br]
## [codeblock]
## var polygons = get_area_polygons(my_area)
## for polygon in polygons:
##     draw_polygon(polygon, [Color.WHITE])  # Debug visualization
## [/codeblock]
static func get_area_polygons(area: Area2D) -> Array:
	var result := []
	for child in area.get_children():
		var shape: Shape2D
		var transform: Transform2D

		# 1) CollisionPolygon2D
		if child is CollisionPolygon2D:
			var poly := PackedVector2Array()
			for p in child.polygon:
				poly.append(child.to_global(p))
			result.append(poly)
			continue

		# 2) CollisionShape2D with Shape2D
		if child is CollisionShape2D:
			shape = child.shape
			# local node Transform
			transform = child.get_global_transform()
			var pts:=[]
			# Depending on the type of Shape2D, construct a polygon.
			match shape:
				RectangleShape2D:
					var he = shape.extents
					pts = [
						Vector2(-he.x, -he.y),
						Vector2( he.x, -he.y),
						Vector2( he.x,  he.y),
						Vector2(-he.x,  he.y)
					]
				CircleShape2D:
					# approximate a circle with an N-gon
					var segments = 16
					for i in segments:
						var _angle = TAU * i / segments
						pts.append(Vector2(cos(_angle), sin(_angle)) * shape.radius)
				CapsuleShape2D:
					# approximation of a capsule from a circle + rectangle
					var seg = 16
					# upper semicircle
					for i in seg:
						var a = PI * i / seg + PI * 0.5
						pts.append(Vector2(cos(a), sin(a)) * shape.radius + Vector2(0, -shape.height*0.5))
					# lower semicircle
					for i in seg:
						var a = PI * i / seg + PI * 1.5
						pts.append(Vector2(cos(a), sin(a)) * shape.radius + Vector2(0, shape.height*0.5))
				ConvexPolygonShape2D:
					pts = shape.points.duplicate()
				SegmentShape2D:
					pts = [ shape.a, shape.b ]
				_:
					# ... other Shape2D objects, if necessary ...
					continue

			# transform local pts into global ones
			var poly := PackedVector2Array()
			for p in pts:
				poly.append(transform.basis_xform(p))
			result.append(poly)

	return result
