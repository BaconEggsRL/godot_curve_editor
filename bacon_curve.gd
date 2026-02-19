@tool
class_name BaconCurve
extends Resource


var _last_t := 0.0


@export var bacon_curve_editor:bool

@export var points: Array[Point] = []
#func get_point_count() -> int:
	#return points.size()
#func get_point(index:int) -> Point:
	#return points[index]
#func set_point(index:int, p:Point) -> void:
	#points[index] = p
#func getpoints() -> Array[Point]:
	#return points.duplicate()


@export var min_value: float = 0.0:
	set(value):
		min_value = value
		range_changed.emit()

@export var max_value: float = 1.0:
	set(value):
		max_value = value
		range_changed.emit()

signal range_changed


enum PRESET {
	LINEAR
}
func set_preset(preset:PRESET) -> void:
	match preset:
		PRESET.LINEAR:
			points.clear()  # ensure it’s empty
			var p0 := Point.new(Vector2(0,0))
			var p1 = Point.new(Vector2(1,1))
			add_point(p0)
			add_point(p1)
		_:
			push_warning("Preset not found")

# --- Constructor ---
func _init():
	if points.size() == 0:
		set_preset(PRESET.LINEAR)



func printpoints():
	for i in range(points.size()):
		var p = points[i]
		print(i, ": ", p.position, " L:", p.left_control_point, " R:", p.right_control_point)


func sort_points() -> void:
	points.sort_custom(func(a, b): return a.position.x < b.position.x)
	force_update()


func swap_properties(p0:Point, p1:Point) -> void:
	var temp_position_x = p0.position.x
	p0.position.x = p1.position.x
	p1.position.x = temp_position_x

	var temp_lcp_x = p0.left_control_point.x
	p0.left_control_point.x = p1.left_control_point.x
	p1.left_control_point.x = temp_lcp_x

	var temp_rcp_x = p0.right_control_point.x
	p0.right_control_point.x = p1.right_control_point.x
	p1.right_control_point.x = temp_rcp_x


# Swap two points, either by Point references or by indices
func swap_points(a, b) -> void:

	if a is int and b is int:
		var i = a
		var j = b
		swap_points(points[i], points[j])

	elif a is Point and b is Point:
		# var p0 = a
		# var p1 = b
		#var temp_x = p0.position.x
		#p0.position.x = p1.position.x
		#p1.position.x = temp_x
		swap_properties(a, b)
		sort_points()

	else:
		push_warning("Could not swap due to type mismatch")



func add_point(p:Point) -> void:
	# print("adding point")
	points.append(p)
	p.changed.connect(_on_point_changed)
	sort_points()


func remove_point(p:Point) -> void:
	# print("removing point")
	if p not in points:
		return

	points.erase(p)
	p.changed.disconnect(_on_point_changed)

	force_update()


func _on_point_changed() -> void:
	print("point changed")
	force_update()


func set_point(i, p) -> void:
	points[i] = p
	# emit_changed()
	# force_update()


func force_update() -> void:
	# Force inspector update
	points = points.duplicate(true)
	notify_changed()


func notify_changed() -> void:
	emit_changed()
	notify_property_list_changed()


func sample(offset: float) -> float:
	if points.size() < 2:
		return 0.0

	offset = clamp(offset, 0.0, 1.0)

	var a = points[0]
	var b = points[1]

	# Solve t from X using Newton–Raphson
	var t = _solve_for_t(offset, a, b)
	_last_t = t  # store for debug

	# Evaluate Y at that t
	return _bezier_interpolate(
		a.position.y,
		a.right_control_point.y,
		b.left_control_point.y,
		b.position.y,
		t
	)


# Newton-Raphson solver
func _solve_for_t(x: float, a: Point, b: Point) -> float:
	var t := x  # good initial guess

	for i in 5: # usually converges in 3–4 iterations
		var x_est = _bezier_interpolate(
			a.position.x,
			a.right_control_point.x,
			b.left_control_point.x,
			b.position.x,
			t
		)

		var dx = _bezier_derivative(
			a.position.x,
			a.right_control_point.x,
			b.left_control_point.x,
			b.position.x,
			t
		)

		if abs(dx) < 0.000001:
			break

		t -= (x_est - x) / dx
		t = clamp(t, 0.0, 1.0)

	return t


func _bezier_derivative(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var omt = 1.0 - t
	return 3.0 * omt * omt * (p1 - p0) \
		+ 6.0 * omt * t * (p2 - p1) \
		+ 3.0 * t * t * (p3 - p2)


func _bezier_interpolate(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var omt = 1.0 - t
	return omt*omt*omt*p0 + 3*omt*omt*t*p1 + 3*omt*t*t*p2 + t*t*t*p3



# assumes x is linear in t
#func sample(offset: float) -> float:
	#if points.size() == 0:
		#return 0.0
	#elif points.size() == 1:
		#return points[0].position.y
#
	## find the segment
	#var i = 0
	#for j in range(points.size() - 1):
		#if points[j + 1].position.x > offset:
			#i = j
			#break
#
	#var a = points[i]
	#var b = points[i + 1]
#
	#var t = (offset - a.position.x) / (b.position.x - a.position.x)
	#return _bezier_interpolate(a.position.y, a.right_control_point.y, b.left_control_point.y, b.position.y, t)


#func sample(offset: float) -> float:
	#if points.size() < 2:
		#return 0.0
#
	#var a = points[0]
	#var b = points[1]
#
	## Solve for t from x
	#var t = _solve_for_t(offset, a, b)
#
	## Evaluate Y at that t
	#return _bezier_interpolate(
		#a.position.y,
		#a.right_control_point.y,
		#b.left_control_point.y,
		#b.position.y,
		#t
	#)


# binary search
#func _solve_for_t(x: float, a: Point, b: Point) -> float:
	#var low := 0.0
	#var high := 1.0
	#var mid := 0.0
#
	#for i in 20:
		#mid = (low + high) * 0.5
		#var estimate = _bezier_interpolate(
			#a.position.x,
			#a.right_control_point.x,
			#b.left_control_point.x,
			#b.position.x,
			#mid
		#)
#
		#if estimate < x:
			#low = mid
		#else:
			#high = mid
#
	#return mid
