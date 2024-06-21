@tool
extends EditorPlugin

const GraphPanel:PackedScene = preload("res://addons/vitavehicle_ui/portable_graph/power_graph_ui.tscn")
const logo:Texture2D = preload("res://vlogo.png")

var graph_panel_instance:Control

var graph_button:Button

var has_init:bool = false

func _init() -> void:
	initalize()

func _enable_plugin() -> void:
	initalize()

func _enter_tree() -> void:
	initalize()

func initalize() -> void:
	if has_init:
		return
	var car_script:Script = load("res://MAIN/car.gd")
	add_custom_type("ViVeCar", "RigidBody3D", car_script, logo)

	graph_panel_instance = GraphPanel.instantiate()
	graph_button = add_control_to_bottom_panel(graph_panel_instance, "Torque Graph")
	graph_button.hide()
	
	has_init = true

func _handles(object: Object) -> bool:
	if object.is_class("RigidBody3D"):
		return true
	else:
		return false

func _make_visible(visible: bool) -> void:
	graph_button.visible = visible

func _edit(object: Object) -> void:
	graph_panel_instance.graph.car = object
	graph_panel_instance._on_refresh_pressed()

func _disable_plugin() -> void:
	deinitalize()

func _exit_tree() -> void:
	deinitalize()

func deinitalize() -> void:
#	if main_panel_instance:
#		main_panel_instance.queue_free()
	if is_instance_valid(graph_panel_instance):
		remove_control_from_bottom_panel(graph_panel_instance)
		graph_panel_instance.queue_free()
	
	remove_custom_type("ViVeCar")
	has_init = false

func _has_main_screen() -> bool:
	return false

func _get_plugin_name() -> String:
	return "VitaVehicle Interface"

func _get_plugin_icon() -> Texture2D:
	return logo
