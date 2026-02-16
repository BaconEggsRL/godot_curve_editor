@tool
extends EditorPlugin

const EasingCurvePlugin = preload("uid://bqic40cwwnu7l")
var easing_curve_plugin


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	easing_curve_plugin = EasingCurvePlugin.new()
	if easing_curve_plugin:
		add_inspector_plugin(easing_curve_plugin)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	if easing_curve_plugin:
		remove_inspector_plugin(easing_curve_plugin)
	pass
