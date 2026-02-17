class_name Point
extends Resource

enum TangentMode {
	FREE = 0,
	ALIGNED = 1,
	MIRRORED = 2
}

@export var position: Vector2 = Vector2.ZERO:
	set(value):
		var delta := value - position
		position = value

		# Move both handles with the anchor
		left_control_point += delta
		right_control_point += delta

		emit_changed()

@export var left_control_point: Vector2 = Vector2.ZERO:
	set(value):
		left_control_point = value
		_apply_mode_from_left()
		emit_changed()

@export var right_control_point: Vector2 = Vector2.ZERO:
	set(value):
		right_control_point = value
		_apply_mode_from_right()
		emit_changed()

@export var tangent_mode: TangentMode = TangentMode.FREE:
	set(value):
		tangent_mode = value
		_enforce_mode()
		emit_changed()


func _init(pos: Vector2 = Vector2.ZERO) -> void:
	position = pos
	left_control_point = pos + Vector2(-0.25, 0)
	right_control_point = pos + Vector2(0.25, 0)


# -----------------------------
# Mode Logic
# -----------------------------

func _apply_mode_from_left() -> void:
	if tangent_mode == TangentMode.FREE:
		return

	var left_offset := left_control_point - position
	if left_offset == Vector2.ZERO:
		return

	var dir := left_offset.normalized()
	var right_offset := right_control_point - position

	match tangent_mode:
		TangentMode.ALIGNED:
			var right_len := right_offset.length()
			right_control_point = position - dir * right_len

		TangentMode.MIRRORED:
			var left_len := left_offset.length()
			right_control_point = position - dir * left_len


func _apply_mode_from_right() -> void:
	if tangent_mode == TangentMode.FREE:
		return

	var right_offset := right_control_point - position
	if right_offset == Vector2.ZERO:
		return

	var dir := right_offset.normalized()
	var left_offset := left_control_point - position

	match tangent_mode:
		TangentMode.ALIGNED:
			var left_len := left_offset.length()
			left_control_point = position - dir * left_len

		TangentMode.MIRRORED:
			var right_len := right_offset.length()
			left_control_point = position - dir * right_len


func _enforce_mode() -> void:
	if tangent_mode == TangentMode.FREE:
		return

	# Reapply constraints using right side as source
	_apply_mode_from_right()
