@tool
class_name BaconCurve
extends Resource


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
			var p0 := Point.new()
			p0.position = Vector2(0,0)

			var p1 = Point.new()
			p1.position = Vector2(1,1)

			add_point(p0)
			add_point(p1)
		_:
			push_warning("Preset not found")


func printpoints():
	for i in range(points.size()):
		var p = points[i]
		print(i, ": ", p.position, " L:", p.left_control_point, " R:", p.right_control_point)


func add_point(p: Point) -> void:
	print("adding point")
	points.append(p)
	points.sort_custom(func(a, b): return a.position.x < b.position.x)
	p.changed.connect(_on_point_changed)
	emit_changed()
	printpoints()
	notify_property_list_changed()

func remove_point(p: Point) -> void:
	print("removing point")
	if p in points:
		points.erase(p)
		p.changed.disconnect(_on_point_changed)
		emit_changed()
		printpoints()

func _on_point_changed() -> void:
	print("point changed")
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
