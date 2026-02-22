# easing_curve_plugin.gd
@tool
extends EditorInspectorPlugin
const X_STYLEBOX = preload("uid://dsapcj11t0kpu")
const BTN_NORMAL = preload("uid://c6hb75fm8lwht")

const GUI_TREE_ARROW_RIGHT = preload("uid://dnkfk70we8l0")
const GUI_TREE_ARROW_DOWN = preload("uid://chvtawloukkig")

const OPEN_SANS_BOLD = preload("uid://byt4ohyep02mx")
const INTER_24_PT_BOLD = preload("uid://cxflgjp5gmsnn")
const INTER_18_PT_BOLD = preload("uid://bh5u5wtwnj3ah")

const ZOOM_SLIDER_CONTAINER = preload("uid://r1ymwr6nae")




const RELOAD = preload("uid://ckq8rdh87fm8m")
const REMOVE = preload("uid://rcefrsneyc5r")
const ADD = preload("uid://ciwi4nujiopse")
const MOVE_DOWN = preload("uid://gxsiiq855i3e")
const MOVE_UP = preload("uid://w1qm6tuhyikq")
const TRIPLE_BAR = preload("uid://dj3cvuhldit7o")

const LOCK = preload("uid://du5ohl6t613a2")
const UNLOCK = preload("uid://dgft8eu5f5ayn")


var editor_undo_redo:EditorUndoRedoManager  # assigned from EditorPlugin

var bacon_curve_editor:BaconCurveEditor
var ease_option:OptionButton
var trans_option:OptionButton
#var _preset_initialized := false

var curve:BaconCurve

const STEP = 0.001



# var points:Array[Dictionary] = []



func _can_handle(object):
	# We support all objects in this example.
	return true



#func _update_reset_btn(reset_btn:Button, value:float, default:float) -> void:
	#reset_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	## reset_btn.visible = !(value == default)
	#reset_btn.visible = !(value == 0.0)
func _update_reset_btn(reset_btn: Button, value: float, default: float) -> void:
	reset_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	# reset_btn.visible = !(value == default)
	# Use is_equal_approx for float safety
	reset_btn.visible = !is_equal_approx(value, default)


func _on_reset_btn_pressed(
	i:int,
	_default:Vector2,
	x_input:EditorSpinSlider,
	y_input:EditorSpinSlider,
	property_name:String,
	reset_btn:Button
) -> void:

	var new_default := curve.get_default_for_property(i, property_name)

	x_input.value = new_default.x
	y_input.value = new_default.y

	reset_btn.visible = false



func _on_remove_btn_pressed(point_list:VBoxContainer, i:int, point_panel:PanelContainer, p:Point) -> void:
	# print("p%d: remove" % i)
	# curve.remove_point(point)
	editor_undo_redo.create_action("Remove point")
	editor_undo_redo.add_do_method(curve, "remove_point", p)
	editor_undo_redo.add_undo_method(curve, "add_point", p)
	editor_undo_redo.commit_action()


func _on_x_input_value_changed(value:float, i:int, x_input:EditorSpinSlider, reset_btn:Button, default:float, property_name:String) -> void:
	# print("p%d x: %.3f" % [i, value])
	var point := curve.points[i]
	var v: Vector2 = point.get(property_name)
	v.x = value
	point.set(property_name, v) # write to correct property
	_update_reset_btn(reset_btn, value, default) # show reset if different
	bacon_curve_editor.queue_redraw()


func _on_y_input_value_changed(value:float, i:int, y_input:EditorSpinSlider, reset_btn:Button, default:float, property_name:String) -> void:
	# print("p%d y: %.3f" % [i, value])
	var point := curve.points[i]
	var v: Vector2 = point.get(property_name)
	v.y = value
	point.set(property_name, v) # write to correct property
	_update_reset_btn(reset_btn, value, default) # show reset if different
	bacon_curve_editor.queue_redraw()



func _move_point_up(i:int) -> void:
	if i > 0 == false:
		return
	# curve.swap_points(i, i-1)
	# bacon_curve_editor.queue_redraw()
	editor_undo_redo.create_action("Move point up")
	editor_undo_redo.add_do_method(curve, "swap_points", i, i-1)
	editor_undo_redo.add_undo_method(curve, "swap_points", i-1, i)
	editor_undo_redo.commit_action()


func _move_point_down(i:int) -> void:
	if i < curve.points.size()-1 == false:
		return
	# curve.swap_points(i, i+1)
	# bacon_curve_editor.queue_redraw()
	editor_undo_redo.create_action("Move point up")
	editor_undo_redo.add_do_method(curve, "swap_points", i, i+1)
	editor_undo_redo.add_undo_method(curve, "swap_points", i+1, i)
	editor_undo_redo.commit_action()



# remember bind() arguments are at the end
func _create_point_side_vbox(i:int, point_list:VBoxContainer, point_panel:PanelContainer, point:Point) -> VBoxContainer:
	var side_vbox = VBoxContainer.new()
	side_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# side_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Move Up Button
	var move_up_btn = Button.new()
	move_up_btn.icon = MOVE_UP
	move_up_btn.flat = true
	move_up_btn.tooltip_text = "Move Point Up"
	move_up_btn.pressed.connect(_move_point_up.bind(i))
	side_vbox.add_child(move_up_btn)


	# TripleBar TextureRect (drag handle)
	var triple_bar = DragHandle.new()
	triple_bar.texture = TRIPLE_BAR
	triple_bar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	triple_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	triple_bar.set_focus_mode(Control.FOCUS_ALL)

	triple_bar.index = i
	triple_bar.point_panel = point_panel
	triple_bar.point_list = point_list
	triple_bar.curve = curve
	triple_bar.bacon_curve_editor = bacon_curve_editor
	triple_bar.editor_undo_redo = editor_undo_redo

	side_vbox.add_child(triple_bar)


	# Move Down Button
	var move_down_btn = Button.new()
	move_down_btn.icon = MOVE_DOWN
	move_down_btn.flat = true
	move_down_btn.tooltip_text = "Move Point Down"
	move_down_btn.pressed.connect(_move_point_down.bind(i))
	side_vbox.add_child(move_down_btn)

	return side_vbox


func _create_vector2_property(
		point: Point,
		i: int,
		property_name: String,
		label_text: String
	) -> Control:

	var position := point.position
	var property_vbox := VBoxContainer.new()

	# Row container
	var property_hbox := HBoxContainer.new()
	# property_hbox.size_flags_horizontal = Control.SIZE_FILL
	property_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_vbox.add_child(property_hbox)

	# Property label (Position / Left Control / Right Control)
	var property_label := Label.new()
	property_label.text = label_text
	# property_label.custom_minimum_size.x = 150
	property_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_hbox.add_child(property_label)

	# Reset Button
	var reset_btn := Button.new()
	reset_btn.icon = RELOAD
	reset_btn.hide()
	# position_hbox.add_child(reset_btn)
	property_label.add_child(reset_btn)

	# Value container panel (x/y inputs; lock_btn)
	var value_panel := PanelContainer.new()
	value_panel.add_theme_stylebox_override("panel", X_STYLEBOX)
	value_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_panel.custom_minimum_size = Vector2(100, 0)
	property_hbox.add_child(value_panel)


	# HBox for x/y inputs; lock_btn
	var value_hbox := HBoxContainer.new()
	value_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_panel.add_child(value_hbox)

	# Left side (the X/Y stack)
	var value_vbox := VBoxContainer.new()
	var x_input := EditorSpinSlider.new()
	var y_input := EditorSpinSlider.new()
	value_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_vbox.add_theme_constant_override("separation", 0)
	value_hbox.add_child(value_vbox)

	# Right side (lock button)
	var lock_btn := Button.new()
	lock_btn.icon = LOCK
	lock_btn.flat = true
	lock_btn.toggle_mode = true
	lock_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lock_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var normal_color := lock_btn.get_theme_color("icon_normal_color")
	# var pressed_color := Color("#57a0ff")
	var pressed_color := Color.WHITE
	lock_btn.add_theme_color_override("icon_pressed_color", pressed_color)
	lock_btn.add_theme_color_override("icon_hover_pressed_color", pressed_color)

	# lock_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	# lock_btn.add_theme_stylebox_override("pressed", BTN_NORMAL)

	# var toggled_on := lock_btn.button_pressed
	var locked := point.locked[property_name]
	lock_btn.button_pressed = locked
	var toggled_on := lock_btn.button_pressed

	lock_btn.icon = LOCK if toggled_on else UNLOCK
	lock_btn.modulate.a = 1.0 if toggled_on else 0.5


	lock_btn.toggled.connect(func(toggled_on:bool):
		lock_btn.icon = LOCK if toggled_on else UNLOCK
		lock_btn.modulate.a = 1.0 if toggled_on else 0.5
		# 🔒 Disable editing when locked
		# x_input.read_only = toggled_on
		# y_input.read_only = toggled_on
		point.set_locked(property_name, toggled_on)
	)

	value_hbox.add_child(lock_btn)


	var vec: Vector2 = point.get(property_name)

	var x_color := EditorInterface.get_editor_theme().get_color("property_color_x", "Editor")
	var y_color := EditorInterface.get_editor_theme().get_color("property_color_y", "Editor")

	# X
	var x_row := HBoxContainer.new()
	x_row.add_theme_constant_override("separation", -8)

	var x_label := Label.new()
	x_label.text = "x"
	x_label.add_theme_color_override("font_color", x_color)


	if property_name == "position":
		x_input.min_value = 0.0
		x_input.max_value = 1.0
	else:
		x_input.min_value = -1024
		x_input.max_value = 1024
	x_input.step = STEP
	x_input.flat = true
	x_input.hide_slider = true
	x_input.label = ""
	x_input.value = vec.x
	x_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	x_input.value_changed.connect(_on_x_input_value_changed.bind(i, x_input, reset_btn, position.x, property_name))
	point.input[property_name].x = x_input

	x_row.add_child(x_label)
	x_row.add_child(x_input)
	value_vbox.add_child(x_row)

	# Y
	var y_row := HBoxContainer.new()
	y_row.add_theme_constant_override("separation", -8)

	var y_label := Label.new()
	y_label.text = "y"
	y_label.add_theme_color_override("font_color", y_color)


	if property_name == "position":
		y_input.min_value = 0.0
		y_input.max_value = 1.0
	else:
		y_input.min_value = -1024
		y_input.max_value = 1024
	y_input.step = STEP
	y_input.flat = true
	y_input.hide_slider = true
	y_input.label = ""
	y_input.value = vec.y
	y_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	y_input.value_changed.connect(_on_y_input_value_changed.bind(i, y_input, reset_btn, position.y, property_name))
	point.input[property_name].y = y_input

	reset_btn.pressed.connect(_on_reset_btn_pressed.bind(i, position, x_input, y_input, property_name, reset_btn))

	y_row.add_child(y_label)
	y_row.add_child(y_input)
	value_vbox.add_child(y_row)

	return property_vbox



func _on_add_point_btn_pressed() -> void:
	editor_undo_redo.create_action("Add point")
	var p := Point.new()
	editor_undo_redo.add_do_method(curve, "add_point", p)
	editor_undo_redo.add_undo_method(curve, "remove_point", p)
	editor_undo_redo.commit_action()



func handle_points(curve: BaconCurve) -> VBoxContainer:
	var point_list = VBoxContainer.new()  # contains the list of points

	# Show list of points
	for i in range(curve.points.size()):
		var point := curve.points[i]
		var position := point.position

		# Panel container for each point
		var point_panel := PanelContainer.new()      # contains the point
		point_panel.add_theme_stylebox_override("panel", X_STYLEBOX)

		# Main horizontal layout
		var point_main_hbox := HBoxContainer.new()
		point_panel.add_child(point_main_hbox)

		# Left side VBox with Move Up / TripleBar / Move Down
		var side_vbox := _create_point_side_vbox(i, point_list, point_panel, point)
		point_main_hbox.add_child(side_vbox)

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

		# Control Points
		var point_count = curve.points.size()

		if point_count > 1:
			if i != 0: # not the first point -> add left control
				point_panel_vbox.add_child(
					_create_vector2_property(point, i, "left_control_point", "Left Control")
				)
			if i != point_count - 1: # not the last point -> add right control
				point_panel_vbox.add_child(
					_create_vector2_property(point, i, "right_control_point", "Right Control")
				)

		# IMPORTANT: add panel to list
		point_list.add_child(point_panel)


	# Add Point button
	var add_point_btn := Button.new()
	add_point_btn.icon = ADD
	add_point_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_point_btn.text = "Add Point"
	add_point_btn.pressed.connect(_on_add_point_btn_pressed)
	point_list.add_child(add_point_btn)

	# add_custom_control(point_list)
	return point_list



func _create_inspector_section(title:String, content:Control, curve:BaconCurve) -> Control:
	return content
	#var root = VBoxContainer.new()
	#root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#
	##var header_label := Label.new()
	##header_label.text = "Points"
	##header_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	##header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	##root.add_child(header_label)
#
	#var header := Button.new()
	#header.text = "Points"
	#header.toggle_mode = true
	#header.button_pressed = curve._points_section_expanded
	#header.flat = true
	#header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	#header.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	#header.focus_mode = Control.FOCUS_NONE
	#header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#
	#var icons = EditorInterface.get_editor_theme()
	#var icon_open = icons.get_icon("GuiTreeArrowDown", "EditorIcons")
	#var icon_closed = icons.get_icon("GuiTreeArrowRight", "EditorIcons")
	## var icon_open := GUI_TREE_ARROW_DOWN
	## var icon_closed := GUI_TREE_ARROW_RIGHT
#
	#header.add_theme_font_override("font", INTER_18_PT_BOLD)
#
	#header.icon = icon_open if header.button_pressed else icon_closed
#
	#root.add_child(header)
#
	#content.visible = header.button_pressed
	#root.add_child(content)
#
	#header.toggled.connect(func(pressed:bool):
		#content.visible = pressed
		#header.icon = icon_open if pressed else icon_closed
#
		## 🔥 Persist to resource
		#curve._points_section_expanded = pressed
		#curve.notify_property_list_changed()
		#curve.emit_changed()
	#)
#
	#return root



func _on_curve_editor_point_changed(i: int, new_point: Point) -> void:
	# Update the point in the BaconCurve resource
	var point := curve.points[i]

	# Copy the new_point values into the existing point
	point.position = new_point.position
	# point.left_control_point = new_point.left_control_point
	# point.right_control_point = new_point.right_control_point

	# Notify the BaconCurve that it changed (so the Inspector updates)
	# curve.emit_changed()

	# Force Inspector UI to update the spinboxes
	# curve.notify_property_list_changed()
	# point.emit_changed()
	# point.notify_property_list_changed()


	# Update the editor UI if needed
	bacon_curve_editor.queue_redraw()

	# print("Point %d changed: %s" % [i, str(point.position)])


# Returns a dictionary containing the OptionButton and its Reset Button
func _create_option_with_reset(enum_dict:Dictionary, default_index:int, label_text:String="", on_change:Callable=func():pass) -> Dictionary:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Label
	if label_text != "":
		var label = Label.new()
		label.text = label_text
		label.size_flags_horizontal = Control.SIZE_FILL
		hbox.add_child(label)

	# Inner HBox for reset + option
	var option_and_reset = HBoxContainer.new()
	option_and_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Reset button
	var reset_btn = Button.new()
	reset_btn.icon = RELOAD
	reset_btn.flat = true
	reset_btn.visible = false
	option_and_reset.add_child(reset_btn)

	# OptionButton
	var option = OptionButton.new()
	var keys = enum_dict.keys()
	for key in keys:
		var display = key.to_lower().capitalize().replace("_", " ")
		option.add_item(display, enum_dict[key])  # store enum value as ID
	#for i in range(options.size()):
		#option.add_item(options[i])
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.selected = default_index
	option_and_reset.add_child(option)

	hbox.add_child(option_and_reset)

	# Show reset if value != default
	option.item_selected.connect(func(idx):
		reset_btn.visible = (option.selected != default_index)
		if on_change != null:
			if on_change.get_argument_count() == 0:
				on_change.call()
			else:
				on_change.call(idx)
	)

	# Reset button pressed
	reset_btn.pressed.connect(func():
		option.selected = default_index
		reset_btn.visible = false
		if on_change != null:
			if on_change.get_argument_count() == 0:
				on_change.call()
			else:
				on_change.call(default_index)
	)

	return {"container": hbox, "option": option, "reset_btn": reset_btn}


#func _on_trans_changed(idx: int) -> void:
	## idx corresponds to the Transition OptionButton selection
	#match idx:
		#0: # Linear
			#curve.set_preset(BaconCurve.PRESET.LINEAR)
		#1: # Constant
			#curve.set_preset(BaconCurve.PRESET.CONSTANT)
#
	## Disable Ease if Linear or Constant
	#_update_ease_disabled(idx)


func _update_ease_disabled(_idx):
	# Disable Ease if Linear (0) or Constant (1) is selected
	ease_option.disabled = (trans_option.selected == 0 or trans_option.selected == 1)


func handle_bacon_curve_editor(object) -> void:
	if object == null:
		return
	if object is BaconCurve:
		var curve_section := VBoxContainer.new()
		curve_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		curve_section.add_theme_constant_override("separation", 0)

		# Add toolbar
		var _toolbar:HBoxContainer
		_toolbar = HBoxContainer.new()
		_toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_toolbar.alignment = BoxContainer.ALIGNMENT_END

		# Toolbar setup
		var ease_dict = _create_option_with_reset(
			BaconCurve.EASE,
			object.ease_type,
		    "Ease"
		)

		var trans_dict = _create_option_with_reset(
			BaconCurve.TRANS,
			object.trans_type,
			"Trans",
			_update_ease_disabled
		)

		# Add the containers
		_toolbar.add_child(ease_dict.container)
		_toolbar.add_child(trans_dict.container)

		# Keep references
		ease_option = ease_dict.option
		trans_option = trans_dict.option
		_update_ease_disabled(trans_option.selected)

		# Add toolbar
		# add_custom_control(_toolbar)
		curve_section.add_child(_toolbar)


		########################################
		# Add curve editor
		bacon_curve_editor = BaconCurveEditor.new()
		bacon_curve_editor.set_curve(object)

		# Restore last UI state
		if object._last_zoom:
			bacon_curve_editor.set_zoom(object._last_zoom)
		if object._last_pan:
			bacon_curve_editor.set_pan(object._last_pan)

		bacon_curve_editor.slider_changed.connect(object._on_curve_editor_slider_value_changed)
		bacon_curve_editor.zoom_changed.connect(object._on_curve_editor_zoom_changed)
		bacon_curve_editor.pan_changed.connect(object._on_curve_editor_pan_changed)
		bacon_curve_editor.point_changed.connect(_on_curve_editor_point_changed)

		curve = object

		ease_option.item_selected.connect(curve.set_ease)
		trans_option.item_selected.connect(curve.set_trans)

		# add_custom_control(bacon_curve_editor)
		curve_section.add_child(bacon_curve_editor)

		########################################
		# Add zoom slider
		var zoom_slider_container := ZOOM_SLIDER_CONTAINER.instantiate()
		zoom_slider_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		curve_section.add_child(zoom_slider_container)
		bacon_curve_editor._slider = zoom_slider_container
		bacon_curve_editor.set_slider_value(object._last_slider_value)

		########################################
		# Add all controls
		add_custom_control(curve_section)





func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	# print_properties(object, type, name, hint_type, hint_string, usage_flags, wide)
	# Handle properties
	if object is BaconCurve and name == "bacon_curve_editor":
		handle_bacon_curve_editor(object)
		return true
	if object is BaconCurve and name == "points":
		# handle_points(object)
		var content = handle_points(object)
		var section = _create_inspector_section("Points", content, object)
		add_custom_control(section)
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
