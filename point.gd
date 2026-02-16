class_name Point
extends Resource

enum TangentMode { TANGENT_FREE = 0, TANGENT_LINEAR = 1 }

@export var position: Vector2 = Vector2.ZERO
@export var left_tangent: float = 0.0
@export var left_mode: TangentMode = TangentMode.TANGENT_FREE
@export var right_tangent: float = 0.0
@export var right_mode: TangentMode = TangentMode.TANGENT_FREE

func _init(pos: Vector2 = Vector2.ZERO, l_tan: float = 0.0, r_tan: float = 0.0,
		   l_mode: TangentMode = TangentMode.TANGENT_FREE,
		   r_mode: TangentMode = TangentMode.TANGENT_FREE) -> void:
	position = pos
	left_tangent = l_tan
	right_tangent = r_tan
	left_mode = l_mode
	right_mode = r_mode
