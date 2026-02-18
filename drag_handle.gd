# DragHandle.gd
@tool
class_name DragHandle
extends TextureRect

var index: int
var point_panel: PanelContainer
var point_list: VBoxContainer
var curve: BaconCurve
var bacon_editor: BaconCurveEditor


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered():
	# print("enter")
	mouse_default_cursor_shape = Control.CURSOR_DRAG

func _on_mouse_exited():
	# print("exit")
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _get_drag_data(at_position: Vector2) -> Variant:
	var drag_data = {"index": index, "point": point_panel}
	var preview = TextureRect.new()
	preview.texture = texture
	preview.scale = Vector2(1.2, 1.2)
	set_drag_preview(preview)
	return drag_data


func _can_drop_data(position: Vector2, data) -> bool:
	return data.has("index") and data.has("point")


func _drop_data(position: Vector2, data) -> void:
	if not _can_drop_data(position, data):
		return
	var from_index = data["index"]
	var to_index = index
	if from_index != to_index:
		curve.swap_points(from_index, to_index)
		point_list.move_child(point_list.get_child(from_index), to_index)
		bacon_editor.queue_redraw()
