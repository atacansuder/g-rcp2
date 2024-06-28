@tool
extends PanelContainer

class_name ViVeTorqueGraph

@export_group("Display Units")
@export_enum("ft⋅lb", "nm", "kg/m") var Torque_Unit:int = 1
@export_enum("current_horsepower", "bcurrent_horsepower", "ps", "kW") var Power_Unit:int = 0

@export_group("Graph settings")
@export var graph_scale:float = 0.005
## How many points will be rendered to the graph. 
##Higher numbers will take longer to "render", but you get a more precise and detailed result.
@export var Generation_Range:float = 7000.0

@export var car:ViVeCar = ViVeCar.new()

@onready var torque:Line2D = $torque
@onready var torque_peak_position:Polygon2D = $torque/peak
@onready var power:Line2D = $power
@onready var power_peak_point:Polygon2D = $power/peak

var peak_torque:float = 0.0
var peak_torque_rpm:float = 0.0

var peak_horsepower:float 
var peak_horsepower_rpm:float

signal graph_updated

func _ready() -> void:
	connect("resized", draw_graph) #This is inefficient but I didn't want to make a function to convert the points

func draw_graph() -> void:
	if not is_instance_valid(car):
		push_warning("Car instance is not valid for graph calculations")
		return
	
	find_peak_values()
	graph_scale = 1.0 / maxf(peak_torque, peak_horsepower)
	full_graph_calculation()
	emit_signal("graph_updated")

func find_peak_values() -> void:
	for ranged_rpm:int in range(Generation_Range):
		if ranged_rpm > car.IdleRPM:
			var current_torque:float = car.multivariate(ranged_rpm)
			var current_horsepower:float = (ranged_rpm / 5252.0) * current_torque
			if current_horsepower > peak_horsepower:
				peak_horsepower = current_horsepower
			if current_torque > peak_torque:
				peak_torque = current_torque

func full_graph_calculation() -> void:
	peak_horsepower = 0.0
	peak_horsepower_rpm = 0.0
	peak_torque = 0.0
	peak_torque_rpm = 0.0
	torque.clear_points()
	power.clear_points()
	
	var skip:int = 0
	#var draw_scale:Vector2 = Vector2(size.x / Generation_Range, size.y / Generation_Range) 
	for ranged_rpm:int in range(Generation_Range):
		if ranged_rpm > car.IdleRPM:
			var current_torque:float = car.multivariate(ranged_rpm)
			var current_horsepower:float = (ranged_rpm / 5252.0) * current_torque
			
			if Torque_Unit == 1:
				current_torque *= 1.3558179483
			elif Torque_Unit == 2:
				current_torque *= 0.138255
			
			match Power_Unit:
				1:
					current_horsepower *= 0.986
				2:
					current_horsepower *= 1.01387
				3:
					current_horsepower *= 0.7457
			
			var torque_position:Vector2 = Vector2((ranged_rpm / Generation_Range) * size.x, size.y - (current_torque * size.y) * graph_scale)
			var horsepower_position:Vector2 = Vector2((ranged_rpm / Generation_Range) * size.x, size.y - (current_horsepower * size.y) * graph_scale)
			
			if current_horsepower > peak_horsepower:
				peak_horsepower = current_horsepower
				peak_horsepower_rpm = ranged_rpm
				power_peak_point.position = horsepower_position
			
			if current_torque > peak_torque:
				peak_torque = current_torque
				peak_torque_rpm = ranged_rpm
				torque_peak_position.position = torque_position
			
			skip -= 1
			if skip <= 0:
				torque.add_point(torque_position)
				power.add_point(horsepower_position)
				skip = 100
