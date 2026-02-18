# easing_curve_plugin.gd
extends EditorInspectorPlugin
const X_STYLEBOX = preload("uid://dsapcj11t0kpu")
const RELOAD = preload("uid://ckq8rdh87fm8m")
const REMOVE = preload("uid://rcefrsneyc5r")


var bacon_curve_editor:BaconCurveEditor
var curve:BaconCurve

const STEP = 0.001

# var points:Array[Dictionary] = []


func _can_handle(object):
	# We support all objects in this example.
	return true


func _on_reset_btn_pressed(i:int, default:Vector2, x_input:EditorSpinSlider, y_input:EditorSpinSlider) -> void:
	print("p%d: reset" % i)
	# curve.points[i].position = default
	x_input.value = default.x
	y_input.value = default.y


func _on_remove_btn_pressed(point_list:VBoxContainer, i:int, point_panel:PanelContainer, point:Point) -> void:
	print("p%d: remove" % i)
	curve.remove_point(point)
	point_list.remove_child(point_panel)


func _update_reset_btn(reset_btn:Button, value:float, default:float) -> void:
	reset_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	reset_btn.visible = !(value == default)


func _on_x_input_value_changed(value:float, i:int, x_input:EditorSpinSlider, reset_btn:Button, default:float) -> void:
	print("p%d x: %.3f" % [i, value])
	curve.points[i].position.x = value
	_update_reset_btn(reset_btn, value, default)
	bacon_curve_editor.queue_redraw()


func _on_y_input_value_changed(value:float, i:int, y_input:EditorSpinSlider, reset_btn:Button, default:float) -> void:
	print("p%d y: %.3f" % [i, value])
	curve.points[i].position.y = value
	_update_reset_btn(reset_btn, value, default)
	bacon_curve_editor.queue_redraw()


func _create_vector2_property(
		point: Point,
		i: int,
		property_name: String,
		label_text: String
	) -> Control:

	var property_vbox := VBoxContainer.new()

	# Row container
	var property_hbox := HBoxContainer.new()
	property_hbox.size_flags_horizontal = Control.SIZE_FILL
	property_vbox.add_child(property_hbox)

	# Property label (Position / Left Control / Right Control)
	var property_label := Label.new()
	property_label.text = label_text
	property_label.custom_minimum_size.x = 90
	property_hbox.add_child(property_label)

	# Value container panel
	var value_panel := PanelContainer.new()
	value_panel.add_theme_stylebox_override("panel", X_STYLEBOX)
	value_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_hbox.add_child(value_panel)

	var value_vbox := VBoxContainer.new()
	value_vbox.add_theme_constant_override("separation", 0)
	value_panel.add_child(value_vbox)

	var vec: Vector2 = point.get(property_name)

	var x_color := EditorInterface.get_editor_theme().get_color("property_color_x", "Editor")
	var y_color := EditorInterface.get_editor_theme().get_color("property_color_y", "Editor")

	# X
	var x_row := HBoxContainer.new()
	x_row.add_theme_constant_override("separation", -8)

	var x_label := Label.new()
	x_label.text = "x"
	x_label.add_theme_color_override("font_color", x_color)

	var x_input := EditorSpinSlider.new()
	x_input.min_value = -1024
	x_input.max_value = 1024
	x_input.step = STEP
	x_input.flat = true
	x_input.hide_slider = true
	x_input.label = ""
	x_input.value = vec.x
	x_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	x_input.value_changed.connect(func(value):
		var v: Vector2 = point.get(property_name)
		v.x = value
		point.set(property_name, v)
		bacon_curve_editor.queue_redraw()
	)

	x_row.add_child(x_label)
	x_row.add_child(x_input)
	value_vbox.add_child(x_row)

	# Y
	var y_row := HBoxContainer.new()
	y_row.add_theme_constant_override("separation", -8)

	var y_label := Label.new()
	y_label.text = "y"
	y_label.add_theme_color_override("font_color", y_color)

	var y_input := EditorSpinSlider.new()
	y_input.min_value = -1024
	y_input.max_value = 1024
	y_input.step = STEP
	y_input.flat = true
	y_input.hide_slider = true
	y_input.label = ""
	y_input.value = vec.y
	y_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	y_input.value_changed.connect(func(value):
		var v: Vector2 = point.get(property_name)
		v.y = value
		point.set(property_name, v)
		bacon_curve_editor.queue_redraw()
	)

	y_row.add_child(y_label)
	y_row.add_child(y_input)
	value_vbox.add_child(y_row)

	return property_vbox


func _on_add_point_btn_pressed() -> void:
	var p := Point.new()

	# choose your default position (example: 0,0 or something smarter)
	# p.position = Vector2.ZERO

	# set control points to match position
	# p.left_control_point = p.position
	# p.right_control_point = p.position

	# curve.points.append(p)
	curve.add_point(p)
	curve.notify_property_list_changed()


func handle_points(curve: BaconCurve) -> void:
	var point_list = VBoxContainer.new()  # contains the list of points

	# Show list of points
	for i in range(curve.points.size()):
		var point := curve.points[i]
		var position := point.position

		# Panel container for each point
		var point_panel := PanelContainer.new()      # contains the point
		point_panel.add_theme_stylebox_override("panel", X_STYLEBOX)

		#var point_panel_vbox := VBoxContainer.new()  # contains each property of the point
		#point_panel.add_child(point_panel_vbox)
		# Main horizontal layout
		var point_main_hbox := HBoxContainer.new()
		point_panel.add_child(point_main_hbox)

		# VBox containing all properties
		var point_panel_vbox := VBoxContainer.new()
		point_panel_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		point_main_hbox.add_child(point_panel_vbox)

		# Remove button (centered vertically)
		var remove_btn := Button.new()
		remove_btn.icon = REMOVE
		remove_btn.flat = true
		remove_btn.tooltip_text = "Remove Point"
		remove_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		remove_btn.pressed.connect(_on_remove_btn_pressed.bind(point_list, i, point_panel, point))

		point_main_hbox.add_child(remove_btn)

		# Position
		point_panel_vbox.add_child(
			_create_vector2_property(point, i, "position", "Position")
		)

		# Left Control Point
		point_panel_vbox.add_child(
			_create_vector2_property(point, i, "left_control_point", "Left Control")
		)

		# Right Control Point
		point_panel_vbox.add_child(
			_create_vector2_property(point, i, "right_control_point", "Right Control")
		)

		# IMPORTANT: add panel to list
		point_list.add_child(point_panel)
		## Position
#
		## Label
		#var position_hbox := HBoxContainer.new()  # separates the property label and the property value
		#point_panel_vbox.add_child(position_hbox)
#
		#position_hbox.size_flags_horizontal = Control.SIZE_FILL
		#var position_label := Label.new()
		#position_label.text = "Position"
		#position_hbox.add_child(position_label)
#
		## Reset Button
		#var reset_btn := Button.new()
		#reset_btn.icon = RELOAD
		#reset_btn.hide()
		## position_hbox.add_child(reset_btn)
		#position_label.add_child(reset_btn)
#
#
		## Value
#
		#var x_color := EditorInterface.get_editor_theme().get_color("property_color_x", "Editor")
		#var y_color := EditorInterface.get_editor_theme().get_color("property_color_y", "Editor")
#
		#var x_input_hbox := HBoxContainer.new()
		#x_input_hbox.add_theme_constant_override("separation", -8)
		#var x_input_label = Label.new()
		#x_input_label.add_theme_color_override("font_color", x_color)
		#x_input_label.text = "x"
		#var x_input := EditorSpinSlider.new()
		#x_input_hbox.add_child(x_input_label)
		#x_input_hbox.add_child(x_input)
		#x_input.min_value = 0.0
		#x_input.max_value = 1.0
		#x_input.add_theme_color_override("label_color", x_color)
#
		#x_input.value_changed.connect(_on_x_input_value_changed.bind(i, x_input, reset_btn, position.x))
		#x_input.value = position.x
#
		#x_input.flat = true
		#x_input.step = STEP
		#x_input.hide_slider = true
		#x_input.label = ""
		#x_input.custom_minimum_size = Vector2(100,25)
#
		#var y_input_hbox := HBoxContainer.new()
		#y_input_hbox.add_theme_constant_override("separation", -8)
		#var y_input_label := Label.new()
		#y_input_label.text = "y"
		#y_input_label.add_theme_color_override("font_color", y_color)
		#var y_input = EditorSpinSlider.new()
		#y_input_hbox.add_child(y_input_label)
		#y_input_hbox.add_child(y_input)
		#y_input.min_value = -1024
		#y_input.max_value = 1024
		#y_input.add_theme_color_override("label_color", y_color)
#
		#y_input.value_changed.connect(_on_y_input_value_changed.bind(i, y_input, reset_btn, position.y))
		#y_input.value = position.y
#
		#y_input.flat = true
		#y_input.step = STEP
		#y_input.hide_slider = true
		#y_input.label = ""
		#y_input.custom_minimum_size = Vector2(100,25)
#
		#reset_btn.pressed.connect(_on_reset_btn_pressed.bind(i, position, x_input, y_input))
#
		#var xy_vbox := VBoxContainer.new()
		#xy_vbox.add_theme_constant_override("separation", 0)
		#xy_vbox.add_child(x_input_hbox)
		#xy_vbox.add_child(y_input_hbox)
#
		#var xy_panel := PanelContainer.new()
		#xy_panel.add_theme_stylebox_override("panel", X_STYLEBOX)
		#xy_panel.add_child(xy_vbox)
		#position_hbox.add_child(xy_panel)
#
		## Remove Button
		#var remove_btn := Button.new()
		#remove_btn.icon = REMOVE
		#remove_btn.pressed.connect(_on_remove_btn_pressed.bind(point_list, i, point_panel, point))
		#position_hbox.add_child(remove_btn)
#
		#point_list.add_child(point_panel)


	# Add Point button
	var add_point_btn := Button.new()
	add_point_btn.text = "Add Point"
	add_point_btn.pressed.connect(_on_add_point_btn_pressed)
	point_list.add_child(add_point_btn)

	add_custom_control(point_list)


func handle_bacon_curve_editor(object) -> void:
	if object == null:
		return
	if object is BaconCurve:
		# Only set linear preset if there are no points yet
		if object.points.size() == 0:
			object.set_preset(BaconCurve.PRESET.LINEAR)
		# Add curve editor
		bacon_curve_editor = BaconCurveEditor.new()
		bacon_curve_editor.set_curve(object)
		curve = object
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
