# easing_curve_plugin.gd
extends EditorInspectorPlugin


func _can_handle(object):
	# We support all objects in this example.
	return true


func handle_bacon_curve_editor(object) -> void:
	# Add curve editor
	var bacon_curve_editor := BaconCurveEditor.new()
	# Ensure the inspector allocates enough vertical space for the editor control
	# Set a reasonable minimum height (width 0 to allow full inspector width)
	bacon_curve_editor.custom_minimum_size = Vector2(0, 140)

	# Give the editor the resource so edits operate on the actual exported data
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
