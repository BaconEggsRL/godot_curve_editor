@tool
class_name Point
extends Resource


@export var position: Vector2 = Vector2.ZERO: set = set_position
@export var left_control_point: Vector2 = Vector2.ZERO: set = set_left_control_point
@export var right_control_point: Vector2 = Vector2.ZERO: set = set_right_control_point


var input = {
	"position":
		{"x": null, "y": null},
	"left_control_point":
		{"x": null, "y": null},
	"right_control_point":
		{"x": null, "y": null}
}




func set_position(value) -> void:
	var x_input = input["position"].x
	var y_input = input["position"].y
	if x_input:
		x_input.value = value.x
	if y_input:
		y_input.value = value.y
	position = value

func set_left_control_point(value) -> void:
	var x_input = input["left_control_point"].x
	var y_input = input["left_control_point"].y
	if x_input:
		x_input.value = value.x
	if y_input:
		y_input.value = value.y
	left_control_point = value

func set_right_control_point(value) -> void:
	var x_input = input["right_control_point"].x
	var y_input = input["right_control_point"].y
	if x_input:
		x_input.value = value.x
	if y_input:
		y_input.value = value.y
	right_control_point = value


#func _on_x_input_value_changed(value:float, i:int, x_input:EditorSpinSlider, reset_btn:Button, default:float, property_name:String) -> void:
	## print("p%d x: %.3f" % [i, value])
	#var point := curve.points[i]
	#var v: Vector2 = point.get(property_name)
	#v.x = value
	#point.set(property_name, v) # write to correct property
	#_update_reset_btn(reset_btn, value, default) # show reset if different
	#bacon_curve_editor.queue_redraw()


#func _on_y_input_value_changed(value:float, i:int, y_input:EditorSpinSlider, reset_btn:Button, default:float, property_name:String) -> void:
	## print("p%d y: %.3f" % [i, value])
	#var point := curve.points[i]
	#var v: Vector2 = point.get(property_name)
	#v.y = value
	#point.set(property_name, v) # write to correct property
	#_update_reset_btn(reset_btn, value, default) # show reset if different
	#bacon_curve_editor.queue_redraw()

#@export var position: Vector2 = Vector2.ZERO:
	#set(value):
		#position = value
		#emit_changed()
#
#@export var left_control_point: Vector2 = Vector2.ZERO:
	#set(value):
		#left_control_point = value
		#emit_changed()
#
#@export var right_control_point: Vector2 = Vector2.ZERO:
	#set(value):
		#right_control_point = value
		#emit_changed()


func _init(pos: Vector2 = Vector2.ZERO):
	position = pos
	left_control_point = pos
	right_control_point = pos


#func _set(property: StringName, value: Variant) -> bool:
	#if property == "position":
		#print("changed position")
		#position = value
		#emit_changed()
		#return true
	#elif property == "left_control_point":
		#left_control_point = value
		#emit_changed()
		#return true
	#elif property == "right_control_point":
		#right_control_point = value
		#emit_changed()
		#return true
	#return false
