@tool
extends MarginContainer

var constant_refresh:bool = false

@onready var graph:ViVeTorqueGraph = $Split/Graph/graph
@onready var torque_stats:Label = $Split/Graph/TorqueStats
@onready var power_stats:Label = $Split/Graph/HorsepowerStats

var prev_power_unit:int
var prev_torque_unit:int

func _ready() -> void:
	graph.custom_minimum_size.y = $Split/Graph.size.y / 2.0
	prev_power_unit = graph.Power_Unit
	prev_torque_unit = graph.Torque_Unit
	graph.connect("graph_updated", set_info)

func _process(_delta: float) -> void:
	if constant_refresh:
		_on_refresh_pressed()

func _on_car_select_pressed() -> void:
	var nods:Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	#TODO: Make this check a lot more... check-y (not as glaringly scuffed and flawed)
	if nods.size() == 1 and nods[0].get_class() == "RigidBody3D": #RigidBody3D is the base class of ViVeCar
		graph.car = nods[0] as ViVeCar
		nods[0].get_script()
	else:
		graph.car = ViVeCar.new()

func _on_refresh_pressed() -> void:
	graph.draw_graph()

func _on_constant_toggled(toggled_on: bool) -> void:
	constant_refresh = toggled_on

func _on_torque_unit_item_selected(index: int) -> void:
	if index != prev_torque_unit:
		prev_torque_unit = index
		graph.Torque_Unit = index
		graph.draw_graph()

func _on_power_unit_item_selected(index: int) -> void:
	if index != prev_power_unit:
		prev_power_unit = index
		graph.Power_Unit = index
		graph.draw_graph()

func set_info() -> void:
	var torque_unit:String = "ft⋅lb"
	if graph.Torque_Unit == 1:
		torque_unit = "nm"
	elif graph.Torque_Unit == 2:
		torque_unit = "kg/m"
	
	torque_stats.text = "Torque: %s %s @ %s RPM" % [str(snappedf(graph.peak_torque, 0.1)), torque_unit, str(snappedf(graph.peak_torque_rpm, 0.1))]
	
	var horsepower_unit:String
	match graph.Power_Unit:
		1:
			horsepower_unit = "bhp"
		2:
			horsepower_unit = "ps"
		3:
			horsepower_unit = "kW"
		_:
			horsepower_unit = "hp"
	
	power_stats.text = "Power: %s %s @ %s RPM" % [str(snappedf(graph.peak_horsepower, 0.1)), horsepower_unit, str(snappedf(graph.peak_horsepower_rpm, 0.1))]
