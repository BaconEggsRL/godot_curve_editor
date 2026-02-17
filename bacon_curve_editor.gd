@tool
class_name BaconCurveEditor
extends Control

var _curve: BaconCurve

const ASPECT_RATIO: float = 6. / 13.
const MIN_X: float = 0.0
const MAX_X: float = 1.0
const MIN_Y: float = 0.0
const MAX_Y: float = 1.0

const BASE_POINT_RADIUS = 4
const BASE_HOVER_RADIUS = 10
const BASE_CONTROL_RADIUS = 3
const BASE_CONTROL_HOVER_RADIUS = 8
const BASE_CONTROL_LENGTH = 36

const LINE_COLOR = Color(1, 1, 1)
const CONTROL_LINE_COLOR = Color(1, 1, 1, 0.4)

enum GrabMode { NONE, ADD, MOVE }
enum ControlIndex { NONE = -1, LEFT = 0, RIGHT = 1 }

var point_radius: int = BASE_POINT_RADIUS
var hover_radius: int = BASE_HOVER_RADIUS
var control_radius: int = BASE_CONTROL_RADIUS
var control_hover_radius: int = BASE_CONTROL_HOVER_RADIUS
var control_length: int = BASE_CONTROL_LENGTH

var selected_index: int = -1
var hovered_index: int = -1
var selected_control_index: ControlIndex = ControlIndex.NONE
var hovered_control_index: ControlIndex = ControlIndex.NONE

var dragging_point: int = -1
var dragging_control: String = ""

var grabbing: GrabMode = GrabMode.NONE
var initial_grab_pos: Vector2
var initial_grab_index: int
var initial_grab_left_control: Vector2
var initial_grab_right_control: Vector2

var snap_enabled: bool = false
var snap_count: int = 10

var _world_to_view: Transform2D

var _editor_scale: float = 1.0





func _ready() -> void:
	self.custom_minimum_size = Vector2(0, 150)
	# self.set_curve(get_init_curve())

	focus_mode = Control.FOCUS_ALL
	clip_contents = true

	if Engine.is_editor_hint():
		_editor_scale = EditorInterface.get_editor_scale()

	if _curve == null:
		_curve = BaconCurve.new()
		_curve.range_changed.connect(_on_curve_changed)
		_curve.changed.connect(_on_curve_changed)


func _on_curve_changed() -> void:
	queue_redraw()

func set_curve(bacon_curve: BaconCurve):
	if _curve != bacon_curve:
		if _curve != null:
			_curve.changed.disconnect(_on_curve_changed)
		_curve = bacon_curve
		if _curve != null:
			_curve.changed.connect(_on_curve_changed)
		queue_redraw()

func get_curve() -> BaconCurve:
	return _curve

func _get_minimum_size() -> Vector2:
	return Vector2(64, max(35, size.x * ASPECT_RATIO) * _editor_scale)

func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER:
		queue_redraw()
	elif what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()

func update_view_transform() -> void:
	var margin = 4 * _editor_scale
	var min_y: float = _curve.min_value
	var max_y: float = _curve.max_value

	var world_rect: Rect2 = Rect2(MIN_X, min_y, MAX_X, max_y - min_y)
	var view_margin: Vector2 = Vector2(margin, margin)
	var view_size: Vector2 = size - view_margin * 2
	var view_scale = view_size / world_rect.size

	var world_trans: Transform2D
	world_trans = world_trans.translated_local(-world_rect.position - Vector2(0, world_rect.size.y))
	world_trans = world_trans.scaled(Vector2(view_scale.x, -view_scale.y))

	var view_trans: Transform2D
	view_trans = view_trans.translated_local(view_margin)

	_world_to_view = view_trans * world_trans

func get_view_pos(world_pos: Vector2) -> Vector2:
	return _world_to_view * world_pos

func get_world_pos(view_pos: Vector2) -> Vector2:
	return _world_to_view.affine_inverse() * view_pos

func get_point_at(pos: Vector2) -> int:
	if _curve == null:
		return -1

	# var _points := _curve.get_points()
	# var _curve.points.size() := _curve.get_curve.points.size()()

	var closest_idx = -1
	var closest_dist_squared: float = point_radius * point_radius * 4
	for i in range(_curve.points.size()):
		var p = _curve.points[i]
		var view_p = get_view_pos(p.position)
		var dist_sq = view_p.distance_squared_to(pos)
		if dist_sq < closest_dist_squared:
			closest_dist_squared = dist_sq
			closest_idx = i
	return closest_idx if closest_dist_squared < point_radius * point_radius else -1

func get_control_at(pos: Vector2) -> Array: # [index, "left" or "right"]
	if _curve == null:
		return [-1, ""]

	# var _points := _curve.get_points()
	# var _curve.points.size() := _curve.get_curve.points.size()()

	for i in range(_curve.points.size()):
		var p = _curve.points[i]
		var left_view = get_view_pos(p.left_control_point)
		if left_view.distance_squared_to(pos) < control_radius * control_radius:
			return [i, "left"]
		var right_view = get_view_pos(p.right_control_point)
		if right_view.distance_squared_to(pos) < control_radius * control_radius:
			return [i, "right"]
	return [-1, ""]

func _draw():
	if _curve == null:
		print("Curve is null, returning")
		return

	# print("Drawing curve editor, curve has ", _curve.points.size(), " points")
	update_view_transform()

	# Draw Style Box
	var style_box = get_theme_stylebox("panel", "Tree")
	if style_box == null:
		# Fallback if theme stylebox not found
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.1, 0.8))
	else:
		draw_style_box(style_box, Rect2(Vector2.ZERO, size))

	# Draw Grid
	draw_set_transform_matrix(_world_to_view)

	var min_edge: Vector2 = get_world_pos(Vector2(0, size.y))
	var max_edge: Vector2 = get_world_pos(Vector2(size.x, 0))

	# FIXME: Get editor theme colors, not GraphEdit, can't find how to get them
	var grid_color_primary: Color = Color(0.3, 0.3, 0.3, 0.8)  # Temporary hardcoded color
	var grid_color: Color = Color(0.2, 0.2, 0.2, 0.3)  # Temporary hardcoded color

	var grid_steps: Vector2 = Vector2i(4, 2)
	var step_size: Vector2 = Vector2(1, (_curve.max_value - _curve.min_value)) / grid_steps

	draw_line(Vector2(min_edge.x, _curve.min_value), Vector2(max_edge.x, _curve.min_value), grid_color_primary)
	draw_line(Vector2(max_edge.x, _curve.max_value), Vector2(min_edge.x, _curve.max_value), grid_color_primary)
	draw_line(Vector2(0, min_edge.y), Vector2(0, max_edge.y), grid_color_primary)
	draw_line(Vector2(1, max_edge.y), Vector2(1, min_edge.y), grid_color_primary)

	for i in range(1, grid_steps.x):
		var x = i * step_size.x
		draw_line(Vector2(x, min_edge.y), Vector2(x, max_edge.y), grid_color)

	for i in range(1, grid_steps.y):
		var y = _curve.min_value + i * step_size.y
		draw_line(Vector2(min_edge.x, y), Vector2(max_edge.x, y), grid_color)

	# Reset transform for other drawing
	draw_set_transform_matrix(Transform2D())

	# var _points := _curve.get_points()
	# var _curve.points.size() := _curve.get_curve.points.size()()


	# Draw curve segments
	for i in range(_curve.points.size() - 1):
		var a = _curve.points[i]
		var b = _curve.points[i + 1]
		_draw_bezier_segment(a, b)

	# Draw points and control points
	for i in range(_curve.points.size()):
		var p = _curve.points[i]
		var pos_view = get_view_pos(p.position)
		var color = Color(1, 0.5, 0) if i == selected_index else Color(1, 0, 0)
		draw_circle(pos_view, point_radius, color)
		if i == selected_index or i == hovered_index:
			var left_view = get_view_pos(p.left_control_point)
			var right_view = get_view_pos(p.right_control_point)
			draw_circle(left_view, control_radius, Color(0, 1, 0))
			draw_circle(right_view, control_radius, Color(0, 0, 1))
			draw_line(pos_view, left_view, CONTROL_LINE_COLOR)
			draw_line(pos_view, right_view, CONTROL_LINE_COLOR)


func _draw_bezier_segment(a: Point, b: Point) -> void:
	var steps = 20
	var prev = get_view_pos(a.position)
	for j in range(1, steps + 1):
		var t = j / float(steps)
		var pt = _bezier(a.position, a.right_control_point, b.left_control_point, b.position, t)
		var pt_view = get_view_pos(pt)
		draw_line(prev, pt_view, LINE_COLOR, 2)
		prev = pt_view


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var omt = 1.0 - t
	return omt*omt*omt*p0 + 3*omt*omt*t*p1 + 3*omt*t*t*p2 + t*t*t*p3



func _gui_input(event: InputEvent) -> void:
	if _curve == null:
		return

	# var _points := _curve.get_points()
	# var _curve.points.size() := _curve.get_curve.points.size()()

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DELETE and selected_index != -1:
			_curve.remove_point(_curve.points[selected_index])
			selected_index = -1
			queue_redraw()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var world_pos = get_world_pos(event.position)
				# Check for clicking control points first
				var control = get_control_at(event.position)
				if control[0] != -1:
					dragging_point = control[0]
					dragging_control = control[1]
					selected_index = control[0]
					queue_redraw()
					return
				# Then points
				var point_idx = get_point_at(event.position)
				if point_idx != -1:
					dragging_point = point_idx
					dragging_control = ""
					selected_index = point_idx
					queue_redraw()
					return
				# If not clicked on anything, add a new point
				var new_point = Point.new()
				var clamped_pos = world_pos.clamp(Vector2(0, _curve.min_value), Vector2(1.0, _curve.max_value))
				new_point.position = clamped_pos
				new_point.left_control_point = clamped_pos + Vector2(-0.1, 0)
				new_point.right_control_point = clamped_pos + Vector2(0.1, 0)
				_curve.add_point(new_point)
				selected_index = _curve.points.find(new_point)
			else:
				dragging_point = -1
				dragging_control = ""
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Check for right-clicking on points to remove
			var point_idx = get_point_at(event.position)
			if point_idx != -1:
				_curve.remove_point(_curve.points[point_idx])
				if selected_index == point_idx:
					selected_index = -1
				elif selected_index > point_idx:
					selected_index -= 1
				queue_redraw()
				return

	elif event is InputEventMouseMotion:
		var new_hovered = get_point_at(event.position)
		if new_hovered != hovered_index:
			hovered_index = new_hovered
			queue_redraw()
		if dragging_point != -1:
			var world_pos = get_world_pos(event.position)
			var p = _curve.points[dragging_point]
			if dragging_control == "left":
				p.left_control_point = world_pos
			elif dragging_control == "right":
				p.right_control_point = world_pos
			else:
				# Drag point and move its controls accordingly
				var clamped_pos = world_pos.clamp(Vector2(0, _curve.min_value), Vector2(1.0, _curve.max_value))
				var delta = clamped_pos - p.position
				p.position = clamped_pos
				p.left_control_point += delta
				p.right_control_point += delta
			queue_redraw()
