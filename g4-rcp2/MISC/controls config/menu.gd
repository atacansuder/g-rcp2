extends HBoxContainer

var car:ViVeCar

func setcar() -> void:
	car = ViVeEnvironment.get_singleton().car
	ViVeGUIControlVariable.control_ref = car.car_controls

func _ready() -> void:
	ViVeEnvironment.get_singleton().connect("ready", setup)
	ViVeEnvironment.get_singleton().connect("car_changed", setcar)

func setup() -> void:
	setcar()
	ViVeEnvironment.get_singleton().emit_signal("car_changed")

func old_setup() -> void:
	for i:Control in $Config/List.get_children():
		match i.get_class():
			"HSlider":
				if i.treat_as_int:
					#Currently, and only because of this one exception, 
					# this works. But this should be changed in the future.
					i.value = car.GearAssist.get(i.var_name)
					i.get_node("amount").text = str(int(i.value))
				else:
					i.value = car.car_controls.get(i.var_name)
					i.get_node("amount").text = str(i.value)
			"OptionButton":
				i.select(car.control_type)
			"CheckBox":
				i.button_pressed = car.car_controls.get(i.var_name)
				i.get_node("amount").text = str(i.button_pressed)
			_:
				continue


func _on_top_pressed() -> void:
	pass # Replace with function body.


func _on_steer_digital_pressed() -> void:
	pass # Replace with function body.


func _on_steer_analog_pressed() -> void:
	pass # Replace with function body.


func _on_throttle_pressed() -> void:
	pass # Replace with function body.


func _on_brake_pressed() -> void:
	pass # Replace with function body.


func _on_handbrake_pressed() -> void:
	pass # Replace with function body.


func _on_clutch_pressed() -> void:
	pass # Replace with function body.


func _on_apply_pressed() -> void:
	pass # Replace with function body.


func _on_cancel_pressed() -> void:
	pass # Replace with function body.


func _on_save_pressed() -> void:
	pass # Replace with function body.


#these misc options are directly connected up here

func _on_input_options_item_selected(index: int) -> void:
	car.control_type = index


func _on_gear_assist_drag_ended(value_changed: bool) -> void:
	pass # Replace with function body.


func _on_gear_assist_value_changed(value: float) -> void:
	pass # Replace with function body.
