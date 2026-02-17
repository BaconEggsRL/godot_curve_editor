@tool
class_name BaconCurve
extends Resource

@export var points: Array[Point] = []

func add_point(p: Point) -> void:
	points.append(p)
	points.sort_custom(func(a, b): return a.position.x < b.position.x)
	p.changed.connect(_on_point_changed)
	emit_changed()

func remove_point(p: Point) -> void:
	if p in points:
		points.erase(p)
		p.changed.disconnect(_on_point_changed)
		emit_changed()

func _on_point_changed() -> void:
	emit_changed()

func sample(offset: float) -> float:
	if points.size() == 0:
		return 0.0
	elif points.size() == 1:
		return points[0].position.y

	# find the segment
	var i = 0
	for j in range(points.size() - 1):
		if points[j + 1].position.x > offset:
			i = j
			break

	var a = points[i]
	var b = points[i + 1]

	var t = (offset - a.position.x) / (b.position.x - a.position.x)
	return _bezier_interpolate(a.position.y, a.right_control_point.y, b.left_control_point.y, b.position.y, t)

func _bezier_interpolate(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var omt = 1.0 - t
	return omt*omt*omt*p0 + 3*omt*omt*t*p1 + 3*omt*t*t*p2 + t*t*t*p3
