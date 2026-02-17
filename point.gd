class_name Point
extends Resource

enum TangentMode { TANGENT_FREE = 0, TANGENT_LINEAR = 1 }

@export var position: Vector2 = Vector2.ZERO
@export var left_tangent: float = 0.0
@export var left_mode: TangentMode = TangentMode.TANGENT_FREE
@export var right_tangent: float = 0.0
@export var right_mode: TangentMode = TangentMode.TANGENT_FREE
@export var left_handle_length: float = 1.0
@export var right_handle_length: float = 1.0
@export var left_control_point: Vector2 = Vector2.ZERO
@export var right_control_point: Vector2 = Vector2.ZERO

func _init(pos: Vector2 = Vector2.ZERO, l_tan: float = 0.0, r_tan: float = 0.0,
		   l_mode: TangentMode = TangentMode.TANGENT_FREE,
		   r_mode: TangentMode = TangentMode.TANGENT_FREE,
		   l_handle_len: float = 1.0, r_handle_len: float = 1.0) -> void:
	position = pos
	left_tangent = l_tan
	right_tangent = r_tan
	left_mode = l_mode
	right_mode = r_mode
	left_handle_length = l_handle_len
	right_handle_length = r_handle_len
	update_control_points()


func update_control_points() -> void:
	# Calculate control point positions from tangent and handle length
	# Left control point
	var left_dir = -Vector2(1.0, left_tangent).normalized()
	left_control_point = position + left_dir * left_handle_length
	
	# Right control point
	var right_dir = Vector2(1.0, right_tangent).normalized()
	right_control_point = position + right_dir * right_handle_length


func update_from_control_points(left_cp: Vector2, right_cp: Vector2) -> void:
	# Update tangent and handle length from control point positions
	# Left control point
	if left_cp != position:
		var left_offset = left_cp - position
		left_handle_length = left_offset.length()
		if left_offset.x != 0.0:
			left_tangent = -left_offset.y / left_offset.x
		left_control_point = left_cp
	
	# Right control point
	if right_cp != position:
		var right_offset = right_cp - position
		right_handle_length = right_offset.length()
		if right_offset.x != 0.0:
			right_tangent = right_offset.y / right_offset.x
		right_control_point = right_cp


func _set(property: StringName, value: Variant) -> bool:
	# Intercept property changes to update and notify
	if property == "position":
		position = value
		update_control_points()
		emit_changed()
		return true
	elif property == "left_tangent":
		left_tangent = value
		update_control_points()
		emit_changed()
		return true
	elif property == "right_tangent":
		right_tangent = value
		update_control_points()
		emit_changed()
		return true
	elif property == "left_handle_length":
		left_handle_length = value
		update_control_points()
		emit_changed()
		return true
	elif property == "right_handle_length":
		right_handle_length = value
		update_control_points()
		emit_changed()
		return true
	elif property == "left_control_point":
		update_from_control_points(value, right_control_point)
		update_control_points()
		emit_changed()
		return true
	elif property == "right_control_point":
		update_from_control_points(left_control_point, value)
		update_control_points()
		emit_changed()
		return true
	
	return false
