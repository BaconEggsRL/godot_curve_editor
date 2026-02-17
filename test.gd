extends Control

@export var bacon_curve:BaconCurve
@export var curve:Curve

@onready var node: Sprite2D = $node
@onready var start: Marker2D = $start
@onready var end: Marker2D = $end


var tween:Tween



func _ready() -> void:
	node.position = start.position
	start_tween()


func start_tween() -> void:
	# POSITION
	var position_tweener:PropertyTweener
	var target := end.position
	var duration := 1.0

	if tween: tween.kill()
	tween = create_tween()

	position_tweener = tween.tween_property(node, "position", target, duration)
	# position_tweener.set_ease(mouse_entered_ease_type).set_trans(mouse_entered_transition_type)
	if bacon_curve:
		position_tweener.set_custom_interpolator(tween_bacon_curve.bind(bacon_curve))
	else:
		position_tweener.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)


func tween_bacon_curve(_offset: float, _curve: BaconCurve) -> float:
	# return _curve.sample_baked(_offset)
	return _curve.sample(_offset)
