@tool
class_name ZoomSliderContainer
extends Control

signal slider_changed
signal autofit_pressed

const ZOOM_MIN := 0.1
const ZOOM_MAX := 10.0
const ZOOM_FACTOR := 1.2   # same as wheel multiplier
const ZOOM_STEPS := int(round(log(ZOOM_MAX / ZOOM_MIN) / log(ZOOM_FACTOR)))

const DEFAULT_SLIDER_VALUE := floor(ZOOM_STEPS / 2.0)

@export var slider:HSlider
@export var autofit_btn:Button


func _ready():
	# Accept events so dragging the slider doesn't scroll the editor
	slider.gui_input.connect(_on_slider_gui_input)
	# slider.mouse_entered.connect(_on_slider_hover)
	# slider.mouse_exited.connect(_on_slider_exit)
	autofit_btn.pressed.connect(_on_autofit_btn_pressed)
	slider.value_changed.connect(_on_slider_value_changed)



func _on_slider_value_changed(value:float) -> void:
	slider_changed.emit(value)


func _on_autofit_btn_pressed() -> void:
	# print("fit")
	# slider.value = DEFAULT_SLIDER_VALUE
	autofit_pressed.emit()
	pass


func _on_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# --- Mouse Wheel Zoom ---
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			accept_event()
			slider.value += slider.step
			return
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			accept_event()
			slider.value -= slider.step
			return


func _on_slider_hover():
	slider.grab_focus()  # make sure the slider gets input when hovered


func _on_slider_exit():
	get_tree().set_input_as_handled() # optional, release if needed
