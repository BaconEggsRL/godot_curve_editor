extends Control

var _debug_prev_curve_pos: Vector2
var _debug_prev_tween_pos: Vector2
var _debug_curve_speed: float = 0.0
var _debug_tween_speed: float = 0.0

var _debug_offset: float = 0.0
var _debug_curve_value: float = 0.0
var _debug_last_t: float = 0.0


enum TWEEN_TYPE {
	LINEAR,
	EASE_IN_CUBIC,
	EASE_OUT_CUBIC
}
@export var tween_type := TWEEN_TYPE.LINEAR

@export var bacon_curve:BaconCurve
@export var curve:Curve
# @export var curve:Curve

@onready var curve_node: Sprite2D = $curve_nodes_container/curve_node
@onready var curve_start: Marker2D = $curve_nodes_container/curve_start
@onready var curve_end: Marker2D = $curve_nodes_container/curve_end

@onready var tween_node: Sprite2D = $tween_nodes_container/tween_node
@onready var tween_start: Marker2D = $tween_nodes_container/tween_start
@onready var tween_end: Marker2D = $tween_nodes_container/tween_end


var curve_tween:Tween
var tween_tween:Tween



func kill_tweens() -> void:
	if curve_tween: curve_tween.kill()
	if tween_tween: tween_tween.kill()

func reset_positions() -> void:
	curve_node.position = curve_start.position
	tween_node.position = tween_start.position

func reset_and_start() -> void:
	kill_tweens()
	reset_positions()
	start_tween(curve_tween, curve_end, curve_node, true)
	start_tween(tween_tween, tween_end, tween_node, false)


func _ready() -> void:
	reset_and_start()


func _process(delta: float) -> void:
	# Curve-driven node speed
	if _debug_prev_curve_pos != Vector2.ZERO:
		var d = curve_node.global_position.distance_to(_debug_prev_curve_pos)
		_debug_curve_speed = d / delta

	# Built-in tween node speed
	if _debug_prev_tween_pos != Vector2.ZERO:
		var d2 = tween_node.global_position.distance_to(_debug_prev_tween_pos)
		_debug_tween_speed = d2 / delta

	_debug_prev_curve_pos = curve_node.global_position
	_debug_prev_tween_pos = tween_node.global_position

	queue_redraw()


func _draw() -> void:
	var font = ThemeDB.fallback_font
	var font_size = 14
	var y := 20

	draw_string(font, Vector2(10, y),
		"offset: %.4f" % _debug_offset,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	y += 18

	draw_string(font, Vector2(10, y),
		"t (Newton): %.4f" % _debug_last_t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	y += 18

	draw_string(font, Vector2(10, y),
		"curve value (y): %.4f" % _debug_curve_value,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	y += 18

	draw_string(font, Vector2(10, y),
		"Curve speed: %.2f px/sec" % _debug_curve_speed,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	y += 18

	draw_string(font, Vector2(10, y),
		"Tween speed: %.2f px/sec" % _debug_tween_speed,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)



func start_tween(tween_ref: Tween, end: Marker2D, node: Node2D, use_curve: bool) -> void:
	var target := end.position
	var duration := 2.0

	# Kill existing tween
	if tween_ref:
		tween_ref.kill()

	# Create new tween and store it in the member variable
	var new_tween = create_tween()
	if tween_ref == curve_tween:
		curve_tween = new_tween
	elif tween_ref == tween_tween:
		tween_tween = new_tween

	var position_tweener = new_tween.tween_property(node, "position", target, duration)

	if bacon_curve and use_curve:
		position_tweener.set_custom_interpolator(tween_bacon_curve.bind(bacon_curve))
	else:
		match tween_type:
			TWEEN_TYPE.LINEAR:
				position_tweener.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
			TWEEN_TYPE.EASE_IN_CUBIC:
				position_tweener.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			TWEEN_TYPE.EASE_OUT_CUBIC:
				position_tweener.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)





#func tween_bacon_curve(_offset: float, _curve: BaconCurve) -> float:
	## return _curve.sample_baked(_offset)
	#return _curve.sample(_offset)
func tween_bacon_curve(offset:float, _curve:BaconCurve) -> float:
	_debug_offset = offset
	_debug_curve_value = _curve.sample(offset)
	_debug_last_t = _curve._last_t  # store t from your sample()

	return _debug_curve_value



func _on_restart_pressed() -> void:
	reset_and_start()
