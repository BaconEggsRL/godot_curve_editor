@tool
class_name BaconCurveEditor
extends Control

signal point_changed

var _zoom_x: float = 1.0  # horizontal zoom
var _zoom_y: float = 1.0  # vertical zoom
const ZOOM_MIN := 0.1      # can't zoom out past auto range
const ZOOM_MAX := 10.0     # how far you can zoom in
# var _user_zoomed := false
# var _user_panned := false

var pan_offset := Vector2.ZERO
var is_panning := false
var last_mouse_pos := Vector2.ZERO


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
var dragging_control: ControlIndex = ControlIndex.NONE

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

	# var min_y: float = _curve.min_value
	# var max_y: float = _curve.max_value
	var auto_range = _compute_auto_y_range()
	var auto_min_y = auto_range.x
	var auto_max_y = auto_range.y
	var auto_height = auto_max_y - auto_min_y

	# Apply Y zoom (zoom in reduces visible height)
	var zoomed_height = auto_height / _zoom_y
	var center_y = (auto_min_y + auto_max_y) * 0.5
	#var zoomed_height: float
	#var center_y: float
	#if _user_zoomed:
		## Keep current zoom/pan
		#center_y = (auto_min_y + auto_max_y) * 0.5  # Or store previous center
		#zoomed_height = (auto_max_y - auto_min_y) / _zoom_y
	#else:
		## Auto-fit range
		#center_y = (auto_min_y + auto_max_y) * 0.5
		#zoomed_height = auto_height / _zoom_y



	var min_y = center_y - zoomed_height * 0.5
	var max_y = center_y + zoomed_height * 0.5

	# Apply X zoom (zoomed width)
	var zoomed_width = (MAX_X - MIN_X) / _zoom_x
	var center_x = (MIN_X + MAX_X) * 0.5
	var min_x = center_x - zoomed_width * 0.5
	var max_x = center_x + zoomed_width * 0.5



	# Get world rect
	var world_rect = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	var view_margin = Vector2(margin, margin)
	var view_size = size - view_margin * 2
	var view_scale = view_size / world_rect.size

	var world_trans: Transform2D
	world_trans = world_trans.translated_local(-world_rect.position - Vector2(0, world_rect.size.y))
	world_trans = world_trans.scaled(Vector2(view_scale.x, -view_scale.y))

	var view_trans: Transform2D
	view_trans = view_trans.translated_local(view_margin)

	_world_to_view = view_trans * world_trans


#func get_view_pos(world_pos: Vector2) -> Vector2:
	#return _world_to_view * world_pos
func get_view_pos(world_pos: Vector2) -> Vector2:
	return (_world_to_view * world_pos) + pan_offset


#func get_world_pos(view_pos: Vector2) -> Vector2:
	#return _world_to_view.affine_inverse() * view_pos
func get_world_pos(view_pos: Vector2) -> Vector2:
	return _world_to_view.affine_inverse() * (view_pos - pan_offset)


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


# =========================
# CONTROL POINT FILTERING
# =========================
# Only allow valid control points
func get_control_at(pos: Vector2) -> Array: # [point_index, ControlIndex]
	if _curve == null:
		return [-1, ControlIndex.NONE]

	for i in range(_curve.points.size()):
		var p = _curve.points[i]

		# LEFT (only if not first and not locked)
		if i != 0: # and not p.locked["left_control_point"]:
			var left_view = get_view_pos(p.left_control_point)
			if left_view.distance_squared_to(pos) < control_hover_radius * control_hover_radius:
				return [i, ControlIndex.LEFT]

		# RIGHT (only if not last and not locked)
		if i != _curve.points.size() - 1: # and not p.locked["right_control_point"]:
			var right_view = get_view_pos(p.right_control_point)
			if right_view.distance_squared_to(pos) < control_hover_radius * control_hover_radius:
				return [i, ControlIndex.RIGHT]

	return [-1, ControlIndex.NONE]



# =========================
# DRAWING POINTS & CONTROLS
# =========================
func _draw():
	if _curve == null:
		return

	update_view_transform()

	# --- Draw background panel ---
	var style_box = get_theme_stylebox("panel", "Tree")
	if style_box:
		draw_style_box(style_box, Rect2(Vector2.ZERO, size))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.1, 0.8))



	# --- Draw Grid ---
	var grid_color_primary: Color = Color(0.3, 0.3, 0.3, 0.8)
	var grid_color: Color = Color(0.2, 0.2, 0.2, 0.3)

	var grid_steps: Vector2 = Vector2i(4, 2)
	var step_size: Vector2 = Vector2(1, (_curve.max_value - _curve.min_value)) / grid_steps

	# Primary borders
	draw_line(get_view_pos(Vector2(MIN_X, _curve.min_value)),
			  get_view_pos(Vector2(MAX_X, _curve.min_value)), grid_color_primary)
	draw_line(get_view_pos(Vector2(MAX_X, _curve.max_value)),
			  get_view_pos(Vector2(MIN_X, _curve.max_value)), grid_color_primary)
	draw_line(get_view_pos(Vector2(MIN_X, _curve.min_value)),
			  get_view_pos(Vector2(MIN_X, _curve.max_value)), grid_color_primary)
	draw_line(get_view_pos(Vector2(MAX_X, _curve.min_value)),
			  get_view_pos(Vector2(MAX_X, _curve.max_value)), grid_color_primary)

	# Internal grid
	for i in range(1, grid_steps.x):
		var x = MIN_X + i * step_size.x
		draw_line(get_view_pos(Vector2(x, _curve.min_value)),
				  get_view_pos(Vector2(x, _curve.max_value)), grid_color)
	for i in range(1, grid_steps.y):
		var y = _curve.min_value + i * step_size.y
		draw_line(get_view_pos(Vector2(MIN_X, y)),
				  get_view_pos(Vector2(MAX_X, y)), grid_color)



	# --- Draw curve segments ---
	for i in range(_curve.points.size() - 1):
		var a = _curve.points[i]
		var b = _curve.points[i + 1]
		_draw_bezier_segment(a, b)

	# --- Draw points and control points ---
	for i in range(_curve.points.size()):
		var p = _curve.points[i]
		var pos_view = get_view_pos(p.position)

		# var is_selected = (i == selected_index)
		var is_hovered = (i == hovered_index)

		# Slightly dim when not selected/hovered
		# var alpha := 1.0 if (is_selected or is_hovered) else 0.5
		var alpha := 1.0 if (is_hovered) else 0.5
		# var locked_position = p.locked["position"]
		# var alpha := 0.2 if locked_position else (1.0 if is_hovered else 0.5)

		# ----- Colors -----
		var point_color = Color(1, 0.5, 0, alpha) if i == selected_index else Color(1, 0, 0, alpha)
		# var left_color := Color(0, 1, 0, alpha)
		# var right_color := Color(0, 0, 1, alpha)
		# var line_color := Color(CONTROL_LINE_COLOR.r, CONTROL_LINE_COLOR.g, CONTROL_LINE_COLOR.b, alpha)

		# ----- Main Point -----
		draw_circle(pos_view, point_radius, point_color)

		# ----- Control Points -----
		## left control
		#if i != 0:  # only draw if not first point
			#var left_view = get_view_pos(p.left_control_point)
			#draw_line(pos_view, left_view, line_color)
			#draw_circle(left_view, control_radius, left_color)
		## right control
		#if i != _curve.points.size() - 1:  # only draw if not last point
			#var right_view = get_view_pos(p.right_control_point)
			#draw_line(pos_view, right_view, line_color)
			#draw_circle(right_view, control_radius, right_color)

		# ----- Control Points -----

		# LEFT
		if i != 0:
			var left_view = get_view_pos(p.left_control_point)

			var left_hovered = (
				i == hovered_index and
				hovered_control_index == ControlIndex.LEFT
			)

			var left_alpha = 1.0 if left_hovered else alpha
			# var left_locked = p.locked["left_control_point"]
			# var left_alpha = 0.2 if left_locked else (1.0 if left_hovered else alpha)
			var left_radius = control_radius

			var left_color = Color(0, 1, 0, left_alpha)
			var left_line_color = Color(
				CONTROL_LINE_COLOR.r,
				CONTROL_LINE_COLOR.g,
				CONTROL_LINE_COLOR.b,
				left_alpha
			)

			draw_line(pos_view, left_view, left_line_color)
			draw_circle(left_view, left_radius, left_color)

		# RIGHT
		if i != _curve.points.size() - 1:
			var right_view = get_view_pos(p.right_control_point)

			var right_hovered = (
				i == hovered_index and
				hovered_control_index == ControlIndex.RIGHT
			)

			var right_alpha = 1.0 if right_hovered else alpha
			# var right_locked = p.locked["left_control_point"]
			# var right_alpha = 0.2 if right_locked else (1.0 if right_hovered else alpha)
			var right_radius = control_radius

			var right_color = Color(0, 0, 1, right_alpha)
			var right_line_color = Color(
				CONTROL_LINE_COLOR.r,
				CONTROL_LINE_COLOR.g,
				CONTROL_LINE_COLOR.b,
				right_alpha
			)

			draw_line(pos_view, right_view, right_line_color)
			draw_circle(right_view, right_radius, right_color)






# =========================
# GUI INPUT (DRAGGING)
# =========================
func _gui_input(event: InputEvent) -> void:
	if _curve == null:
		return

	# Middle mouse pressed → start panning
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				last_mouse_pos = event.position
				get_viewport().set_input_as_handled()  # stop editor from stealing input
			else:
				is_panning = false
				get_viewport().set_input_as_handled()
	# Mouse motion → pan
	elif event is InputEventMouseMotion and is_panning:
		var delta = event.position - last_mouse_pos
		pan_offset += delta
		last_mouse_pos = event.position
		# _user_panned = true
		queue_redraw()
		get_viewport().set_input_as_handled()

	# =========================
	# MOUSE MOTION (drag points/controls)
	# =========================
	if event is InputEventMouseMotion:

		# ----- DRAGGING -----
		if dragging_point != -1:
			var p = _curve.points[dragging_point]
			var world_pos = get_world_pos(event.position)

			# Block main point movement
			if dragging_control == ControlIndex.NONE and p.locked["position"]:
				return

			# Block left control
			if dragging_control == ControlIndex.LEFT and p.locked["left_control_point"]:
				return

			# Block right control
			if dragging_control == ControlIndex.RIGHT and p.locked["right_control_point"]:
				return


			match dragging_control:
				ControlIndex.LEFT:
					if dragging_point != 0: # ignore left control for first point
						p.left_control_point = world_pos
						# Clamp left control X between previous point and main point
						# var min_x = _curve.points[dragging_point - 1].position.x
						# var max_x = p.position.x
						# p.left_control_point = Vector2(clamp(world_pos.x, min_x, max_x), world_pos.y)

				ControlIndex.RIGHT:
					if dragging_point != _curve.points.size() - 1: # ignore right control for last point
						p.right_control_point = world_pos
						# Clamp right control X between main point and next point
						# var min_x = p.position.x
						# var max_x = _curve.points[dragging_point + 1].position.x
						# p.right_control_point = Vector2(clamp(world_pos.x, min_x, max_x), world_pos.y)

				ControlIndex.NONE: # dragging main point
					var clamped_pos = world_pos.clamp(Vector2(0, _curve.min_value), Vector2(1.0, _curve.max_value))
					# Clamp main point X between previous and next points
					# var min_x = 0.0 if dragging_point == 0 else _curve.points[dragging_point - 1].position.x + 0.001
					# var max_x = 1.0 if dragging_point == _curve.points.size() - 1 else _curve.points[dragging_point + 1].position.x - 0.001
					# var clamped_pos = Vector2(clamp(world_pos.x, min_x, max_x), clamp(world_pos.y, _curve.min_value, _curve.max_value))

					var delta = clamped_pos - p.position
					p.position = clamped_pos
					#p.left_control_point += delta
					#p.right_control_point += delta

					# Only move controls if they are NOT locked
					if not p.locked["left_control_point"]:
						p.left_control_point += delta
						# Ensure left control X <= main point X
						# p.left_control_point.x = min(p.left_control_point.x, p.position.x)
					if not p.locked["right_control_point"]:
						p.right_control_point += delta
						# Ensure right control X >= main point X
						# p.right_control_point.x = max(p.right_control_point.x, p.position.x)


			point_changed.emit(dragging_point, p)
			queue_redraw()


		# ----- HOVER DETECTION -----
		if dragging_point == -1:
			var control = get_control_at(event.position)

			if control[0] != -1:
				hovered_index = control[0]
				hovered_control_index = control[1]
			else:
				hovered_control_index = ControlIndex.NONE
				hovered_index = get_point_at(event.position)

			queue_redraw()

			# Cursor feedback
			if hovered_control_index != ControlIndex.NONE:
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			elif hovered_index != -1:
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW


	# =========================
	# MOUSE BUTTONS
	# =========================
	if event is InputEventMouseButton:

		# --- Mouse Wheel Zoom ---
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# var step = 0.1
			# var num_steps = 5
			_zoom_x = clamp(_zoom_x * 1.2, ZOOM_MIN, ZOOM_MAX)
			_zoom_y = clamp(_zoom_y * 1.2, ZOOM_MIN, ZOOM_MAX)
			# _user_zoomed = true
			queue_redraw()
			accept_event()
			return
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_x = clamp(_zoom_x / 1.2, ZOOM_MIN, ZOOM_MAX)
			_zoom_y = clamp(_zoom_y / 1.2, ZOOM_MIN, ZOOM_MAX)
			# _user_zoomed = true
			queue_redraw()
			accept_event()
			return

		# --- LEFT CLICK ---
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var control = get_control_at(event.position)
			var point_idx = get_point_at(event.position)

			# --- If we hit a control ---
			if control[0] != -1:
				var p = _curve.points[control[0]]
				var can_drag_control := false

				match control[1]:
					ControlIndex.LEFT:
						can_drag_control = not p.locked["left_control_point"]
					ControlIndex.RIGHT:
						can_drag_control = not p.locked["right_control_point"]

				# Always select the point
				selected_index = control[0]

				# Only allow dragging if the control is not locked
				if can_drag_control:
					dragging_point = control[0]
					dragging_control = control[1]
				else:
					# Try dragging main point if under cursor
					if point_idx != -1 and not _curve.points[point_idx].locked["position"]:
						dragging_point = point_idx
						dragging_control = ControlIndex.NONE

				queue_redraw()
				return

			# --- If we hit only a main point ---
			if point_idx != -1:
				var p = _curve.points[point_idx]
				if not p.locked["position"]:
					dragging_point = point_idx
					dragging_control = ControlIndex.NONE
				selected_index = point_idx
				queue_redraw()
				return

			# --- If we hit nothing, add a new point ---
			var new_point = Point.new()
			var world_pos = get_world_pos(event.position)
			var clamped_pos = world_pos.clamp(Vector2(0, _curve.min_value), Vector2(1.0, _curve.max_value))
			new_point.position = clamped_pos
			new_point.left_control_point = clamped_pos + Vector2(-0.1, 0)
			new_point.right_control_point = clamped_pos + Vector2(0.1, 0)
			_curve.add_point(new_point)
			selected_index = _curve.points.find(new_point)


		# --- RIGHT CLICK ---
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			var point_idx = get_point_at(event.position)
			if point_idx != -1:
				_curve.remove_point(_curve.points[point_idx])
				if selected_index == point_idx:
					selected_index = -1
				elif selected_index > point_idx:
					selected_index -= 1
				queue_redraw()
				return

		# Reset dragging state when mouse button released
		elif not event.pressed:
			dragging_point = -1
			dragging_control = ControlIndex.NONE




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



func _compute_auto_y_range() -> Vector2:
	if _curve == null or _curve.points.size() < 2:
		return Vector2(0.0, 1.0)

	var min_y := 0.0
	var max_y := 1.0

	var steps := 40

	for i in range(_curve.points.size() - 1):
		var a = _curve.points[i]
		var b = _curve.points[i + 1]

		for j in range(steps + 1):
			var t = j / float(steps)
			var pt = _bezier(
				a.position,
				a.right_control_point,
				b.left_control_point,
				b.position,
				t
			)

			# Expand only if overshooting
			if pt.y < min_y:
				min_y = pt.y
			elif pt.y > max_y:
				max_y = pt.y

	# If still inside [0,1], keep default range
	if min_y >= 0.0 and max_y <= 1.0:
		min_y = 0.0
		max_y = 1.0

	# Add padding
	var padding := (max_y - min_y) * 0.1
	min_y -= padding
	max_y += padding

	return Vector2(min_y, max_y)
