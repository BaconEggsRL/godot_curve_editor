@tool
@icon("uid://cgoejfwhdwmop")
class_name BaconCurve
extends Resource

const TANGENT_FREE = Point.TangentMode.TANGENT_FREE
const TANGENT_LINEAR = Point.TangentMode.TANGENT_LINEAR

const MIN_X_RANGE: float = 0.01
const MIN_Y_RANGE: float = 0.01

var _min_domain: float = 0.0
var _max_domain: float = 1.0
var _min_value: float = 0.0
var _max_value: float = 1.0
var _bake_resolution: int = 100
var _points: Array[Point] = []

signal range_changed
signal domain_changed
signal bake_resolution_changed

@export_group("Curve Editor")
@export var bacon_curve_editor:bool

@export_group("Settings")
@export_range(-1024, 1024, 0.01, "or_less") var min_domain:float=0.0: get = get_min_domain, set = set_min_domain
@export_range(-1024, 1024, 0.01, "or_greater") var max_domain:float=1.0: get = get_max_domain, set = set_max_domain
@export_range(-1024, 1024, 0.01, "or_less") var min_value:float=0.0: get = get_min_value, set = set_min_value
@export_range(-1024, 1024, 0.01, "or_greater") var max_value:float=1.0: get = get_max_value, set = set_max_value
@export_range(-1024, 1024, 0.01) var bake_resolution:int=100: get = get_bake_resolution, set = set_bake_resolution

@export_group("Points")
@export var points:Array[Point]=[]: get = get_points, set = set_points
var point_count:int=0: get = get_point_count, set = set_point_count



func _init() -> void:
	pass



func get_points() -> Array[Point]:
	return _points

func set_points(value) -> void:
	_points = value
	# Reconnect signals to all points
	for point in _points:
		if point != null and not point.changed.is_connected(_on_point_changed):
			point.changed.connect(_on_point_changed)
	emit_changed()



func get_point_count() -> int:
	return _points.size()

func set_point_count(p_count: int) -> void:
	if p_count < 0:
		return

	var old_size = _points.size()
	if old_size == p_count:
		return

	if old_size > p_count:
		# Disconnect signals from points being removed
		for i in range(p_count, old_size):
			if _points[i].changed.is_connected(_on_point_changed):
				_points[i].changed.disconnect(_on_point_changed)
		_points.resize(p_count)
	else:
		# Connect signals to new points
		while _points.size() < p_count:
			var new_point = Point.new()
			new_point.changed.connect(_on_point_changed)
			_points.append(new_point)

	notify_property_list_changed()


func _add_point(p_position: Vector2, p_left_tangent: float = 0.0, p_right_tangent: float = 0.0,
	p_left_mode: Point.TangentMode = Point.TangentMode.TANGENT_FREE,
	p_right_mode: Point.TangentMode = Point.TangentMode.TANGENT_FREE,
	p_left_handle_length: float = 1.0, p_right_handle_length: float = 1.0,
	p_mark_dirty: bool = true) -> int:
	# Add a point and preserve order

	# Points must remain within the given value and domain ranges
	p_position.x = clamp(p_position.x, _min_domain, _max_domain)
	p_position.y = clamp(p_position.y, _min_value, _max_value)

	var ret = -1

	if _points.is_empty():
		_points.append(Point.new(p_position, p_left_tangent, p_right_tangent, p_left_mode, p_right_mode, p_left_handle_length, p_right_handle_length))
		_points[0].update_control_points()
		_points[0].changed.connect(_on_point_changed)
		ret = 0
	else:
		# Find the correct position to insert to maintain sorted order by x coordinate
		var insert_idx = _points.size()
		for i in range(_points.size()):
			if _points[i].position.x > p_position.x:
				insert_idx = i
				break

		_points.insert(insert_idx, Point.new(p_position, p_left_tangent, p_right_tangent, p_left_mode, p_right_mode, p_left_handle_length, p_right_handle_length))
		_points[insert_idx].update_control_points()
		_points[insert_idx].changed.connect(_on_point_changed)
		ret = insert_idx

	update_auto_tangents(ret)

	if p_mark_dirty:
		emit_changed()

	return ret


func _on_point_changed() -> void:
	# Called when any point is modified (e.g., via inspector)
	# Don't notify property list here - it's too expensive during continuous updates
	# Property list will be notified at the end of interactive edits
	emit_changed()


func add_point(p_position: Vector2, p_left_tangent: float = 0.0, p_right_tangent: float = 0.0,
	p_left_mode: Point.TangentMode = Point.TangentMode.TANGENT_FREE,
	p_right_mode: Point.TangentMode = Point.TangentMode.TANGENT_FREE) -> int:
	var ret = _add_point(p_position, p_left_tangent, p_right_tangent, p_left_mode, p_right_mode)
	notify_property_list_changed()
	return ret


func add_point_no_update(p_position: Vector2, p_left_tangent: float = 0.0, p_right_tangent: float = 0.0,
		p_left_mode: Point.TangentMode = Point.TangentMode.TANGENT_FREE,
		p_right_mode: Point.TangentMode = Point.TangentMode.TANGENT_FREE) -> int:
	# Add a point but do not notify the property list or emit heavy updates.
	# Useful for interactive insertion where the Inspector must not rebuild.
	return _add_point(p_position, p_left_tangent, p_right_tangent, p_left_mode, p_right_mode, 1.0, 1.0, false)



func get_index(p_offset: float) -> int:
	# Lower-bound float binary search
	var imin = 0
	var imax = _points.size() - 1

	while imax - imin > 1:
		@warning_ignore('integer_division')
		var imid:int = (imin + imax) / 2
		if _points[imid].position.x < p_offset:
			imin = imid
		else:
			imax = imid

	# Will happen if the offset is out of bounds
	if p_offset > _points[imax].position.x:
		return _points.size() - 1

	return imin


func clean_dupes() -> void:
	var dirty = false

	for i in range(1, _points.size()):
		if _points[i - 1].position.x == _points[i].position.x:
			_points.remove_at(i)
			i -= 1
			dirty = true

	if dirty:
		emit_changed()


func set_point_left_tangent(p_index: int, p_tangent: float) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].left_tangent = p_tangent
	_points[p_index].left_mode = Point.TangentMode.TANGENT_FREE
	_points[p_index].update_control_points()
	mark_dirty()


func set_point_right_tangent(p_index: int, p_tangent: float) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].right_tangent = p_tangent
	_points[p_index].right_mode = Point.TangentMode.TANGENT_FREE
	_points[p_index].update_control_points()
	mark_dirty()


func set_point_left_mode(p_index: int, p_mode: Point.TangentMode) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].left_mode = p_mode
	if p_index > 0:
		update_auto_tangents(p_index - 1)
	mark_dirty()


func set_point_right_mode(p_index: int, p_mode: Point.TangentMode) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].right_mode = p_mode
	if p_index + 1 < _points.size():
		update_auto_tangents(p_index + 1)
	mark_dirty()


func get_point_left_tangent(p_index: int) -> float:
	if p_index < 0 or p_index >= _points.size():
		return 0.0
	return _points[p_index].left_tangent


func get_point_right_tangent(p_index: int) -> float:
	if p_index < 0 or p_index >= _points.size():
		return 0.0
	return _points[p_index].right_tangent


func get_point_left_mode(p_index: int) -> Point.TangentMode:
	if p_index < 0 or p_index >= _points.size():
		return Point.TangentMode.TANGENT_FREE
	return _points[p_index].left_mode


func get_point_right_mode(p_index: int) -> Point.TangentMode:
	if p_index < 0 or p_index >= _points.size():
		return Point.TangentMode.TANGENT_FREE
	return _points[p_index].right_mode


func set_point_left_handle_length(p_index: int, p_length: float) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].left_handle_length = max(0.0, p_length)
	_points[p_index].update_control_points()
	mark_dirty()


func set_point_right_handle_length(p_index: int, p_length: float) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].right_handle_length = max(0.0, p_length)
	_points[p_index].update_control_points()
	mark_dirty()


func get_point_left_handle_length(p_index: int) -> float:
	if p_index < 0 or p_index >= _points.size():
		return 1.0
	return _points[p_index].left_handle_length


func get_point_right_handle_length(p_index: int) -> float:
	if p_index < 0 or p_index >= _points.size():
		return 1.0
	return _points[p_index].right_handle_length


func get_point_left_control_point(p_index: int) -> Vector2:
	if p_index < 0 or p_index >= _points.size():
		return Vector2.ZERO
	return _points[p_index].left_control_point


func set_point_left_control_point(p_index: int, p_control_point: Vector2) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].update_from_control_points(p_control_point, _points[p_index].right_control_point)
	_points[p_index].update_control_points()
	mark_dirty()


func get_point_right_control_point(p_index: int) -> Vector2:
	if p_index < 0 or p_index >= _points.size():
		return Vector2.ZERO
	return _points[p_index].right_control_point


func set_point_right_control_point(p_index: int, p_control_point: Vector2) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].update_from_control_points(_points[p_index].left_control_point, p_control_point)
	_points[p_index].update_control_points()
	mark_dirty()


func _remove_point(p_index: int, p_mark_dirty: bool = true) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	_points[p_index].changed.disconnect(_on_point_changed)
	_points.remove_at(p_index)
	if p_mark_dirty:
		emit_changed()


func remove_point(p_index: int) -> void:
	_remove_point(p_index)
	notify_property_list_changed()


func clear_points() -> void:
	if _points.is_empty():
		return

	# Disconnect signals from all points
	for point in _points:
		if point.changed.is_connected(_on_point_changed):
			point.changed.disconnect(_on_point_changed)

	_points.clear()
	mark_dirty()
	notify_property_list_changed()


func set_point_value(p_index: int, p_position: float) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	# Delegate to unified setter (keeps backward compatibility)
	set_point_position(p_index, Vector2(_points[p_index].position.x, p_position))
	return


func set_point_offset(p_index: int, p_offset: float) -> int:
	if p_index < 0 or p_index >= _points.size():
		return -1

	# Delegate to unified setter (keeps backward compatibility)
	return set_point_position(p_index, Vector2(p_offset, _points[p_index].position.y))


func set_point_position(p_index: int, p_pos: Vector2, p_reopen_inspector: bool = false) -> int:
	# Set a point's position (x and/or y). If x changes the point is reinserted to keep ordering.
	if p_index < 0 or p_index >= _points.size():
		return -1

	# Clamp into valid ranges
	p_pos.x = clamp(p_pos.x, _min_domain, _max_domain)
	p_pos.y = clamp(p_pos.y, _min_value, _max_value)

	var p = _points[p_index]

	# If X changed, remove and reinsert to maintain sorted order
	if p_pos.x != p.position.x:
		p.position = p_pos

		# Re-sort without destroying instances
		_points.sort_custom(func(a, b):
			return a.position.x < b.position.x
		)

		var new_idx = _points.find(p)

		update_auto_tangents(new_idx)
		p.emit_changed()
		mark_dirty()

		return new_idx

	else:
		# Only Y changed
		_points[p_index].position.y = p_pos.y
		_points[p_index].update_control_points()
		update_auto_tangents(p_index)
		_points[p_index].emit_changed()
		mark_dirty()
		return p_index


func get_point_position(p_index: int) -> Vector2:
	if p_index < 0 or p_index >= _points.size():
		return Vector2.ZERO
	return _points[p_index].position


func get_point(p_index: int) -> Point:
	if p_index < 0 or p_index >= _points.size():
		return Point.new()
	return _points[p_index]


func update_auto_tangents(p_index: int) -> void:
	if p_index < 0 or p_index >= _points.size():
		return

	var p = _points[p_index]

	if p_index > 0:
		if _points[p_index - 1].right_mode == Point.TangentMode.TANGENT_FREE:
			var v1 = (p.position - _points[p_index - 1].position).normalized()
			# var v2 = (p.position - _points[p_index - 1].position)
			# var tangent_len = v2.length()
			# var prev_len = (p.position - _points[p_index - 1].position).length() if p_index > 1 else tangent_len
			# var next_len = (_points[p_index + 1].position - p.position).length() if p_index < _points.size() - 1 else tangent_len
			_points[p_index - 1].right_tangent = -v1.y / v1.x if v1.x != 0 else 0

	if p_index + 1 < _points.size():
		if p.right_mode == Point.TangentMode.TANGENT_FREE:
			var v1 = (_points[p_index + 1].position - p.position).normalized()
			# var tangent_len = (_points[p_index + 1].position - p.position).length()
			# var prev_len = (p.position - _points[p_index - 1].position).length() if p_index > 0 else tangent_len
			# var next_len = (_points[p_index + 1].position - p.position).length()
			p.right_tangent = v1.y / v1.x if v1.x != 0 else 0


func get_limits() -> Array:
	var output = [_min_value, _max_value, _min_domain, _max_domain]
	return output


func set_limits(p_input: Array) -> void:
	if p_input.size() != 4:
		return

	_min_value = p_input[0]
	_max_value = p_input[1]
	_min_domain = p_input[2]
	_max_domain = p_input[3]


func set_min_value(p_min: float) -> void:
	_min_value = min(p_min, _max_value - MIN_Y_RANGE)

	for p in _points:
		if p.position.y < _min_value:
			p.position.y = _min_value

	range_changed.emit()


func set_max_value(p_max: float) -> void:
	_max_value = max(p_max, _min_value + MIN_Y_RANGE)

	for p in _points:
		if p.position.y > _max_value:
			p.position.y = _max_value

	range_changed.emit()


func set_min_domain(p_min: float) -> void:
	_min_domain = min(p_min, _max_domain - MIN_X_RANGE)

	if _points.size() > 0 and _min_domain > _points[0].position.x:
		_points[0].position.x = _min_domain

	mark_dirty()
	domain_changed.emit()


func set_max_domain(p_max: float) -> void:
	_max_domain = max(p_max, _min_domain + MIN_X_RANGE)

	if _points.size() > 0 and _max_domain < _points[_points.size() - 1].position.x:
		_points[_points.size() - 1].position.x = _max_domain

	mark_dirty()
	domain_changed.emit()


func set_bake_resolution(p_res: int) -> void:
	_bake_resolution = clamp(p_res, 1, 1000)

	mark_dirty()
	bake_resolution_changed.emit()



func get_bake_resolution() -> int:
	return _bake_resolution


func get_min_value() -> float:
	return _min_value


func get_max_value() -> float:
	return _max_value


func get_min_domain() -> float:
	return _min_domain


func get_max_domain() -> float:
	return _max_domain


func get_value_range() -> float:
	return _max_value - _min_value


func get_domain_range() -> float:
	return _max_domain - _min_domain


func sample(p_offset: float) -> float:
	if _points.is_empty():
		return 0.0

	if _points.size() == 1:
		return _points[0].position.y

	var i = get_index(p_offset)

	if i == _points.size() - 1:
		return _points[i].position.y

	var local = p_offset - _points[i].position.x

	if i == 0 and local <= 0:
		return _points[0].position.y

	return sample_local_nocheck(i, local)


func sample_local_nocheck(p_index: int, p_local_offset: float) -> float:
	if p_index < 0 or p_index + 1 >= _points.size():
		return 0.0

	var a = _points[p_index]
	var b = _points[p_index + 1]

	# Cubic bézier with handle-based control points
	var d = b.position.x - a.position.x
	if is_zero_approx(d):
		return a.position.y

	p_local_offset /= d

	# Calculate control points based on tangent direction and handle length
	# Right control point: moves from a in the direction of right_tangent by handle_length
	var right_handle_dist = d * a.right_handle_length
	var right_tangent_normalized = sqrt(1.0 + a.right_tangent * a.right_tangent)
	var yac = a.position.y + (right_handle_dist / right_tangent_normalized) * a.right_tangent

	# Left control point: moves from b in the direction of left_tangent by handle_length
	var left_handle_dist = d * b.left_handle_length
	var left_tangent_normalized = sqrt(1.0 + b.left_tangent * b.left_tangent)
	var ybc = b.position.y - (left_handle_dist / left_tangent_normalized) * b.left_tangent

	var y = _bezier_interpolate(a.position.y, yac, ybc, b.position.y, p_local_offset)

	return y


func _bezier_interpolate(p_a: float, p_b: float, p_c: float, p_d: float, p_t: float) -> float:
	# Cubic Bézier interpolation
	var omt = 1.0 - p_t
	var omt2 = omt * omt
	var omt3 = omt2 * omt
	var t2 = p_t * p_t
	var t3 = t2 * p_t

	return omt3 * p_a + omt2 * 3.0 * p_t * p_b + omt * 3.0 * t2 * p_c + t3 * p_d


func mark_dirty() -> void:
	emit_changed()


func get_data() -> Array:
	var output = []
	const ELEMS = 7
	output.resize(_points.size() * ELEMS)

	for j in range(_points.size()):
		output[j * ELEMS + 0] = _points[j].position.x
		output[j * ELEMS + 1] = _points[j].position.y
		output[j * ELEMS + 2] = _points[j].left_tangent
		output[j * ELEMS + 3] = _points[j].right_tangent
		output[j * ELEMS + 4] = _points[j].left_mode
		output[j * ELEMS + 5] = _points[j].left_handle_length
		output[j * ELEMS + 6] = _points[j].right_handle_length
		# Note: right_mode is not stored, it's computed

	return output


func set_data(p_input: Array) -> void:
	var old_size:int = _points.size()

	# Detect format: 5 elements = old format, 7 elements = new format with handle lengths
	var elems = 5
	if p_input.size() > 0 and p_input.size() % 7 == 0:
		elems = 7
	elif p_input.size() % 5 != 0:
		return

	@warning_ignore('integer_division')
	var new_size:int = p_input.size() / elems

	if old_size != new_size:
		set_point_count(new_size)

	for j in range(_points.size()):
		_points[j].position.x = p_input[j * elems + 0]
		_points[j].position.y = p_input[j * elems + 1]
		_points[j].left_tangent = p_input[j * elems + 2]
		_points[j].right_tangent = p_input[j * elems + 3]
		_points[j].left_mode = p_input[j * elems + 4]

		# Handle lengths are only in new format (7 elements)
		if elems == 7:
			_points[j].left_handle_length = p_input[j * elems + 5]
			_points[j].right_handle_length = p_input[j * elems + 6]
		else:
			# For old format, default to 1.0
			_points[j].left_handle_length = 1.0
			_points[j].right_handle_length = 1.0

		# Update control points after loading
		_points[j].update_control_points()

	mark_dirty()
	if old_size != new_size:
		notify_property_list_changed()
