class_name ZoomSliderContainer
extends Control

@onready var slider: HSlider = $HBoxContainer/slider
@onready var autofit_btn: Button = $HBoxContainer/autofit_btn


func _ready():
	# Accept events so dragging the slider doesn't scroll the editor
	slider.gui_input.connect(_on_slider_gui_input)
	# slider.mouse_entered.connect(_on_slider_hover)
	# slider.mouse_exited.connect(_on_slider_exit)
	autofit_btn.pressed.connect(_on_autofit_btn_pressed)


func _on_autofit_btn_pressed() -> void:
	slider.value = 0.5

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
