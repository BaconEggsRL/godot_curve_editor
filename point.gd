class_name Point
extends Resource

@export var position: Vector2 = Vector2.ZERO
@export var left_control_point: Vector2 = Vector2.ZERO
@export var right_control_point: Vector2 = Vector2.ZERO

func _set(property: StringName, value: Variant) -> bool:
	if property == "position":
		position = value
		emit_changed()
		return true
	elif property == "left_control_point":
		left_control_point = value
		emit_changed()
		return true
	elif property == "right_control_point":
		right_control_point = value
		emit_changed()
		return true
	return false
