extends Control

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



func reset_positions() -> void:
	curve_node.position = curve_start.position
	tween_node.position = tween_start.position

func reset_and_start() -> void:
	reset_positions()
	start_tween(curve_tween, curve_end, curve_node, true)
	start_tween(tween_tween, tween_end, tween_node, false)


func _ready() -> void:
	reset_and_start()



func start_tween(tween:Tween, end:Marker2D, node:Node2D, use_curve:bool) -> void:

	# POSITION
	var position_tweener:PropertyTweener
	var target := end.position
	var duration := 2.0

	if tween: tween.kill()
	tween = create_tween()

	position_tweener = tween.tween_property(node, "position", target, duration)
	# position_tweener.set_ease(mouse_entered_ease_type).set_trans(mouse_entered_transition_type)
	if bacon_curve and use_curve:
		position_tweener.set_custom_interpolator(tween_bacon_curve.bind(bacon_curve))
	else:
		position_tweener.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# position_tweener.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)


func tween_bacon_curve(_offset: float, _curve: BaconCurve) -> float:
	# return _curve.sample_baked(_offset)
	return _curve.sample(_offset)


func _on_restart_pressed() -> void:
	reset_and_start()
