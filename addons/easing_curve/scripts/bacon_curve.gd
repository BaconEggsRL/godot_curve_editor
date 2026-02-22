@tool
@icon("uid://cgoejfwhdwmop")
class_name BaconCurve
extends Resource

const ZOOM_MIN := 0.1
const ZOOM_MAX := 10.0
const ZOOM_FACTOR := 1.2   # same as wheel multiplier
const ZOOM_STEPS := int(round(log(ZOOM_MAX / ZOOM_MIN) / log(ZOOM_FACTOR)))

const DEFAULT_SLIDER_VALUE := floor(ZOOM_STEPS / 2.0)

var _last_slider_value:float = DEFAULT_SLIDER_VALUE
var _last_zoom := Vector2(1,1)
var _last_pan := Vector2.ZERO

func _on_curve_editor_slider_value_changed(slider_value:float) -> void:
	_last_slider_value = slider_value
	print("_curve._last_slider_value = ", slider_value)

func _on_curve_editor_zoom_changed(zoom:Vector2) -> void:
	_last_zoom = zoom

func _on_curve_editor_pan_changed(pan: Vector2) -> void:
	_last_pan = pan



var _last_t := 0.0


@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR)
var _points_section_expanded: bool = true



@export var bacon_curve_editor:bool

# @export_group("Points")
@export var points: Array[Point] = []

#@export_group("Points ")
#@export var test_arr:Array = [1,2,3]

@export_group("")
#func get_point_count() -> int:
	#return points.size()
#func get_point(index:int) -> Point:
	#return points[index]
#func set_point(index:int, p:Point) -> void:
	#points[index] = p
#func getpoints() -> Array[Point]:
	#return points.duplicate()


#@export var min_value: float = 0.0:
	#set(value):
		#min_value = value
		#range_changed.emit()
#
#@export var max_value: float = 1.0:
	#set(value):
		#max_value = value
		#range_changed.emit()

const min_value := 0.0
const max_value := 1.0
signal range_changed


enum EASE { IN, OUT, IN_OUT, OUT_IN }
enum TRANS {
	CONSTANT,

	LINEAR,
	QUAD,
	CUBIC,
	QUART,
	QUINT,
	EXPO,

	CIRC,
	BACK,

	ELASTIC,
	BOUNCE,
	SPRING,

	SINE
}

var ease_type:EASE = EASE.IN
var trans_type:TRANS = TRANS.LINEAR


func get_default_for_property(i:int, property_name:String) -> Vector2:
	var temp := BaconCurve.new()
	temp.set_ease(ease_type)
	temp.set_trans(trans_type)
	temp._update_preset()
	return temp.points[i].get(property_name)


func cubic_bezier(x0, y0, x1, y1) -> void:
	var p0 := Point.new(Vector2(0,0))
	var p1 := Point.new(Vector2(1,1))
	p0.right_control_point = Vector2(x0, y0)
	p1.left_control_point = Vector2(x1, y1)
	add_point(p0)
	add_point(p1)


func set_ease(_ease:EASE) -> void:
	ease_type = _ease
	_update_preset()


func set_trans(_trans:TRANS) -> void:
	trans_type = _trans
	_update_preset()


func _update_preset() -> void:
	points.clear()

	match trans_type:

		TRANS.CONSTANT:
			add_point(Point.new(Vector2(0, .5)))
			add_point(Point.new(Vector2(1, .5)))

		TRANS.LINEAR:
			add_point(Point.new(Vector2(0, 0)))
			add_point(Point.new(Vector2(1, 1)))

		TRANS.QUAD:
			match ease_type:
				EASE.IN:
					cubic_bezier(.11, 0, .5, 0)
				EASE.OUT:
					cubic_bezier(.5, 1, .89, 1)
				EASE.IN_OUT:
					cubic_bezier(.45, 0, .55, 1)
				EASE.OUT_IN:
					cubic_bezier(.55, 1, .45, 0)

		TRANS.CUBIC:
			match ease_type:
				EASE.IN:
					cubic_bezier(.32, 0, .67, 0)
				EASE.OUT:
					cubic_bezier(.33, 1, .68, 1)
				EASE.IN_OUT:
					cubic_bezier(.65, 0, .35, 1)
				EASE.OUT_IN:
					cubic_bezier(.35, 1, .65, 0)

		TRANS.QUART:
			match ease_type:
				EASE.IN:
					cubic_bezier(.5, 0, .75, 0)
				EASE.OUT:
					cubic_bezier(.25, 1, .5, 1)
				EASE.IN_OUT:
					cubic_bezier(.76, 0, .24, 1)
				EASE.OUT_IN:
					cubic_bezier(.24, 1, .76, 0)

		TRANS.QUINT:
			match ease_type:
				EASE.IN:
					cubic_bezier(.64, 0, .78, 0)
				EASE.OUT:
					cubic_bezier(.22, 1, .36, 1)
				EASE.IN_OUT:
					cubic_bezier(.83, 0, .17, 1)
				EASE.OUT_IN:
					cubic_bezier(.17, 1, .83, 0)

		TRANS.EXPO:
			match ease_type:
				EASE.IN:
					cubic_bezier(.7, 0, .84, 0)
				EASE.OUT:
					cubic_bezier(.16, 1, .3, 1)
				EASE.IN_OUT:
					cubic_bezier(.87, 0, .13, 1)
				EASE.OUT_IN:
					cubic_bezier(.13, 1, .87, 0)

		TRANS.CIRC:
			match ease_type:
				EASE.IN:
					cubic_bezier(.55, 0, 1, .45)
				EASE.OUT:
					cubic_bezier(0, .55, .45, 1)
				EASE.IN_OUT:
					cubic_bezier(.85, 0, .15, 1)
				EASE.OUT_IN:
					cubic_bezier(.15, 1, .85, 0)

		TRANS.BACK:
			match ease_type:
				EASE.IN:
					cubic_bezier(.36, 0, .66, -0.56)
				EASE.OUT:
					cubic_bezier(.34, 1.56, .64, 1)
				EASE.IN_OUT:
					cubic_bezier(.68, -0.6, .32, 1.6)
				EASE.OUT_IN:
					cubic_bezier(.32, 1.6, .68, -0.6)

		TRANS.ELASTIC:
			add_point(Point.new(Vector2(0, 0)))

			add_point(Point.new(Vector2(.04, -0.0004)))

			add_point(Point.new(Vector2(.08, -0.0016)))

			add_point(Point.new(Vector2(.14, -0.0017)))

			add_point(Point.new(Vector2(.18, 0.0004)))

			add_point(Point.new(Vector2(.26, 0.0058)))

			add_point(Point.new(Vector2(.28, 0.0055)))

			add_point(Point.new(Vector2(.40, -0.0156)))

			add_point(Point.new(Vector2(.42, -0.0164)))

			add_point(Point.new(Vector2(.56, 0.0463)))

			add_point(Point.new(Vector2(.58, -0.044)))
			add_point(Point.new(Vector2(.72, .1312)))
			add_point(Point.new(Vector2(.86, -0.3706)))
			add_point(Point.new(Vector2(1, 1)))

			auto_smooth_handles()


		TRANS.BOUNCE:
			pass

		TRANS.SPRING:
			pass


		TRANS.SINE:
			match ease_type:
				EASE.IN:
					cubic_bezier(.12, 0, .39, 0)
				EASE.OUT:
					cubic_bezier(.61, 1, .88, 1)
				EASE.IN_OUT:
					cubic_bezier(.37, 0, .63, 1)
				EASE.OUT_IN:
					cubic_bezier(.63, 1, .37, 0)


# --- Constructor ---
func _init():
	if points.size() == 0:
		_update_preset()



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



# Sample the curve, calculating f(t) given x
func sample(offset: float) -> float:
	if points.size() < 2:
		return 0.0

	offset = clamp(offset, 0.0, 1.0)

	for i in range(points.size() - 1):
		var a = points[i]
		var b = points[i + 1]

		# Quick rejection: skip segment if offset not in its X bounds
		var min_x = min(a.position.x, b.position.x)
		var max_x = max(a.position.x, b.position.x)

		if offset < min_x or offset > max_x:
			continue

		var t = _solve_for_t(offset, a, b)

		# Validate solution
		if t >= 0.0 and t <= 1.0:
			return _bezier_interpolate(
				a.position.y,
				a.right_control_point.y,
				b.left_control_point.y,
				b.position.y,
				t
			)

	# Fallback (should not happen if curve monotonic)
	return 0.0



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
			return _binary_search_t(x, a, b)

		t -= (x_est - x) / dx
		t = clamp(t, 0.0, 1.0)

	return t



func _binary_search_t(x: float, a: Point, b: Point) -> float:
	var low := 0.0
	var high := 1.0
	var mid := 0.5

	for i in range(12): # 10–15 iterations is plenty
		mid = (low + high) * 0.5

		var x_est = _bezier_interpolate(
			a.position.x,
			a.right_control_point.x,
			b.left_control_point.x,
			b.position.x,
			mid
		)

		if x_est < x:
			low = mid
		else:
			high = mid

	return mid




func _bezier_derivative(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var omt = 1.0 - t
	return 3.0 * omt * omt * (p1 - p0) \
		+ 6.0 * omt * t * (p2 - p1) \
		+ 3.0 * t * t * (p3 - p2)


func _bezier_interpolate(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var omt = 1.0 - t
	return omt*omt*omt*p0 + 3*omt*omt*t*p1 + 3*omt*t*t*p2 + t*t*t*p3



##########################################################

# Catmull-Rom → Bézier conversion
func auto_smooth_handles():
	if points.size() < 2:
		return

	for i in range(points.size()):
		var p = points[i]

		var p_prev = points[max(i - 1, 0)]
		var p_next = points[min(i + 1, points.size() - 1)]

		var prev = p_prev.position.y
		var curr = p.position.y
		var next = p_next.position.y

		var is_peak = (curr > prev and curr > next)
		var is_valley = (curr < prev and curr < next)


		#var tangent = (p_next.position - p_prev.position) * 0.5
		var d1 = p.position - p_prev.position
		var d2 = p_next.position - p.position

		var len1 = d1.length()
		var len2 = d2.length()

		if len1 == 0 or len2 == 0:
			continue

		var tangent = (d1.normalized() + d2.normalized())
		tangent *= min(len1, len2)


		var handle_length = 1.0/3.0
		#if is_peak or is_valley:
			#handle_length *= 0.6

		p.right_control_point = p.position + tangent * handle_length
		p.left_control_point  = p.position - tangent * handle_length

		p.right_control_point.x = clamp(
			p.right_control_point.x,
			p.position.x,
			points[min(i + 1, points.size() - 1)].position.x
		)

		p.left_control_point.x = clamp(
			p.left_control_point.x,
			points[max(i - 1, 0)].position.x,
			p.position.x
		)

	# Clamp endpoints
	points[0].left_control_point = points[0].position
	points[-1].right_control_point = points[-1].position




func ease_in_elastic(x: float) -> float:
	var c4 = (2.0 * PI) / 3.0

	if x == 0.0:
		return 0.0
	if x == 1.0:
		return 1.0

	return -pow(2.0, 10.0 * x - 10.0) * sin((x * 10.0 - 10.75) * c4)



func generate_from_function(func_ref: Callable, resolution := 40):
	points.clear()

	for i in range(resolution + 1):
		var x = float(i) / resolution
		var y = func_ref.call(x)
		add_point(Point.new(Vector2(x, y)))



func derivative(func_ref: Callable, x: float, eps := 0.0001) -> float:
	return (func_ref.call(x + eps) - func_ref.call(x - eps)) / (2.0 * eps)
