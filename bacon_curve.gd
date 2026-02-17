class_name BaconCurve
extends Resource

const TANGENT_FREE = Point.TangentMode.FREE
const TANGENT_LINEAR = Point.TangentMode.ALIGNED

@export var points: Array[Point] = []
var point_count := 0

var min_value := 0.0
var max_value := 0.0

signal range_changed


# -------------------------------------------------------
# Point Management
# -------------------------------------------------------

func add_point(pos: Vector2) -> int:
	var p := Point.new(pos)
	points.append(p)
	points.sort_custom(func(a, b): return a.position.x < b.position.x)
	emit_changed()
	return -1


func remove_point(index: int) -> void:
	if index >= 0 and index < points.size():
		points.remove_at(index)
		emit_changed()


func get_point_count() -> int:
	return points.size()


func get_point(index: int) -> Point:
	return points[index]


func get_point_position(index: int) -> Vector2:
	return points[index].position


func set_point_position(index: int, pos: Vector2) -> int:
	points[index].position = pos
	points.sort_custom(func(a, b): return a.position.x < b.position.x)
	emit_changed()
	return index


# -------------------------------------------------------
# Cubic Bezier Evaluation
# -------------------------------------------------------

func sample(x: float) -> float:
	if points.size() < 2:
		return 0.0

	# Clamp to bounds
	if x <= points[0].position.x:
		return points[0].position.y

	if x >= points[-1].position.x:
		return points[-1].position.y

	# Find segment
	for i in points.size() - 1:
		var p0 := points[i]
		var p1 := points[i + 1]

		if x >= p0.position.x and x <= p1.position.x:
			return _sample_segment(p0, p1, x)

	return 0.0


func _sample_segment(p0: Point, p1: Point, x: float) -> float:
	var P0 := p0.position
	var P1 := p0.right_control_point
	var P2 := p1.left_control_point
	var P3 := p1.position

	# Solve cubic Bezier for given x using binary search on t
	var t_min := 0.0
	var t_max := 1.0
	var t := 0.5

	for i in 20:
		t = (t_min + t_max) * 0.5
		var point := _cubic_bezier(P0, P1, P2, P3, t)

		if point.x > x:
			t_max = t
		else:
			t_min = t

	var result := _cubic_bezier(P0, P1, P2, P3, t)
	return result.y


func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 \
		+ 3.0*u*u*t*p1 \
		+ 3.0*u*t*t*p2 \
		+ t*t*t*p3
