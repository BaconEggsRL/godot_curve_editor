# easing_curve_plugin.gd
extends EditorInspectorPlugin
const X_STYLEBOX = preload("uid://dsapcj11t0kpu")


func _can_handle(object):
	# We support all objects in this example.
	return true


func _on_x_input_value_changed(value:float, index:int) -> void:
	print("p%d x: %.3f" % [index, value])


func _on_y_input_value_changed(value:float, index:int) -> void:
	print("p%d y: %.3f" % [index, value])


func handle_points(curve: BaconCurve) -> void:
	var point_list = VBoxContainer.new()  # contains the list of points

	# Show list of points
	for i in range(curve.points.size()):
		var point = curve.points[i]

		# Panel container for each point
		var point_panel = PanelContainer.new()      # contains the point
		var point_panel_vbox = VBoxContainer.new()  # contains each property of the point
		point_panel.add_child(point_panel_vbox)

		# Title label
		#var title = Label.new()  # contains the point label
		#title.text = "Point %d" % i
		#point_panel_vbox.add_child(title)

		# Position

		# Label
		var position_hbox = HBoxContainer.new()  # separates the property label and the property value
		var position_label = Label.new()
		position_label.text = "Position"
		position_hbox.add_child(position_label)

		# Value
		var position = point.position
		var x_color := EditorInterface.get_editor_theme().get_color("property_color_x", "Editor")
		var y_color := EditorInterface.get_editor_theme().get_color("property_color_y", "Editor")

		var x_input_hbox = HBoxContainer.new()
		x_input_hbox.add_theme_constant_override("separation", -8)
		var x_input_label = Label.new()
		x_input_label.add_theme_color_override("font_color", x_color)
		x_input_label.text = "x"
		var x_input = EditorSpinSlider.new()
		x_input_hbox.add_child(x_input_label)
		x_input_hbox.add_child(x_input)
		x_input.add_theme_color_override("label_color", x_color)
		x_input.value_changed.connect(_on_x_input_value_changed.bind(i))
		x_input.flat = true
		x_input.step = 0.001
		x_input.hide_slider = true
		x_input.label = ""
		x_input.value = position.x
		x_input.custom_minimum_size = Vector2(100,25)

		var y_input_hbox = HBoxContainer.new()
		y_input_hbox.add_theme_constant_override("separation", -8)
		var y_input_label = Label.new()
		y_input_label.text = "y"
		y_input_label.add_theme_color_override("font_color", y_color)
		var y_input = EditorSpinSlider.new()
		y_input_hbox.add_child(y_input_label)
		y_input_hbox.add_child(y_input)
		y_input.add_theme_color_override("label_color", y_color)
		y_input.value_changed.connect(_on_y_input_value_changed.bind(i))
		y_input.flat = true
		y_input.step = 0.001
		y_input.hide_slider = true
		y_input.label = ""
		y_input.value = position.y
		y_input.custom_minimum_size = Vector2(100,25)

		var xy_vbox = VBoxContainer.new()
		xy_vbox.add_theme_constant_override("separation", 0)
		xy_vbox.add_child(x_input_hbox)
		xy_vbox.add_child(y_input_hbox)

		var xy_panel = PanelContainer.new()
		xy_panel.add_theme_stylebox_override("panel", X_STYLEBOX)
		xy_panel.add_child(xy_vbox)
		position_hbox.add_child(xy_panel)

		point_list.add_child(position_hbox)


	# Add Point button
	var add_btn = Button.new()
	add_btn.text = "Add Point"
	add_btn.pressed.connect(func():
		curve.points.append(Point.new())
		curve.notify_property_list_changed()
	)
	point_list.add_child(add_btn)

	add_custom_control(point_list)


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
	if object is BaconCurve and name == "bacon_curve_editor":
		handle_bacon_curve_editor(object)
		return true
	if object is BaconCurve and name == "points":
		handle_points(object)
		return true
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
