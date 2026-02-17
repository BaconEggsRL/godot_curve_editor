# easing_curve_plugin.gd
extends EditorInspectorPlugin


func _can_handle(object):
	# We support all objects in this example.
	return true


func handle_bacon_curve_editor(object) -> void:
	if object == null:
		return
	if object is BaconCurve:
		# Only set linear preset if there are no points yet
		if object.points.size() == 0:
			object.set_preset(BaconCurve.PRESET.LINEAR)
		# Add curve editor
		var bacon_curve_editor := BaconCurveEditor.new()
		bacon_curve_editor.set_curve(object)
		add_custom_control(bacon_curve_editor)


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	# print_properties(object, type, name, hint_type, hint_string, usage_flags, wide)
	# Handle properties
	match name:
		"bacon_curve_editor":
			handle_bacon_curve_editor(object)
			return true
		_:
			return false


func print_properties(object, type, name, hint_type, hint_string, usage_flags, wide):
	print("=============================")
	print("object: ", object)
	print("type: ", type)
	print("name: ", name)
	print("hint_type: ", hint_type)
	print("hint_string: ", hint_string)
	print("usage_flags: ", usage_flags)
	print("wide: ", wide)
