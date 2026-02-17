@tool
class_name BaconCurveEditor
extends Control

@export var curve: BaconCurve
@export var point_radius: float = 6.0
@export var control_radius: float = 4.0
@export var line_color: Color = Color(1, 1, 1)
@export var control_line_color: Color = Color(1, 1, 1, 0.4)

var dragging_point: int = -1
var dragging_control: String = "" # "left" or "right"

func _draw():
	if not curve:
		return

	# Draw curve segments
	for i in range(curve.points.size() - 1):
		var a = curve.points[i]
		var b = curve.points[i + 1]
		_draw_bezier_segment(a, b)

	# Draw points and control points
	for i in range(curve.points.size()):
		var p = curve.points[i]
		draw_circle(p.position, point_radius, Color(1, 0, 0))
		draw_circle(p.left_control_point, control_radius, Color(0, 1, 0))
		draw_circle(p.right_control_point, control_radius, Color(0, 0, 1))
		draw_line(p.position, p.left_control_point, control_line_color)
		draw_line(p.position, p.right_control_point, control_line_color)


func _draw_bezier_segment(a: Point, b: Point) -> void:
	var steps = 20
	var prev = a.position
	for j in range(1, steps + 1):
		var t = j / float(steps)
		var pt = _bezier(a.position, a.right_control_point, b.left_control_point, b.position, t)
		draw_line(prev, pt, line_color, 2)
		prev = pt


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var omt = 1.0 - t
	return omt*omt*omt*p0 + 3*omt*omt*t*p1 + 3*omt*t*t*p2 + t*t*t*p3



func _gui_input(event: InputEvent) -> void:
	if not curve:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check for clicking points or control points
				for i in range(curve.points.size()):
					var p = curve.points[i]
					if p.position.distance_to(event.position) < point_radius:
						dragging_point = i
						dragging_control = ""
						return
					if p.left_control_point.distance_to(event.position) < control_radius:
						dragging_point = i
						dragging_control = "left"
						return
					if p.right_control_point.distance_to(event.position) < control_radius:
						dragging_point = i
						dragging_control = "right"
						return
			else:
				dragging_point = -1
				dragging_control = ""

	elif event is InputEventMouseMotion:
		if dragging_point != -1:
			var p = curve.points[dragging_point]
			if dragging_control == "left":
				p.left_control_point = event.position
			elif dragging_control == "right":
				p.right_control_point = event.position
			else:
				# Drag point and move its controls accordingly
				var delta = event.relative
				p.position += delta
				p.left_control_point += delta
				p.right_control_point += delta
			p.emit_changed()
			queue_redraw()
