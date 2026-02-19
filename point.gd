@tool
class_name Point
extends Resource

signal lock_changed(property_name: String, locked: bool)

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

var locked:Dictionary[String, bool] = {
	"position": false,
	"left_control_point": false,
	"right_control_point": false
}


func set_locked(property_name: String, toggled_on:bool) -> void:
	var x_input = input[property_name].x
	var y_input = input[property_name].y
	if x_input:
		x_input.read_only = toggled_on
	if y_input:
		y_input.read_only = toggled_on
	locked[property_name] = toggled_on
	lock_changed.emit(property_name, toggled_on)


func _init(pos: Vector2 = Vector2.ZERO):
	position = pos
	left_control_point = pos
	right_control_point = pos


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
