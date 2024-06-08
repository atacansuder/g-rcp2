extends Control
##A class representing the root of the in-game debug panel.
class_name ViVeDebug

##The debug panel singleton
static var singleton:ViVeDebug = null

var changed_graph_size:Vector2 = Vector2.ZERO

@onready var car_node:ViVeCar
@onready var tacho:ViVeTachometer = $"tacho"
@onready var tacho_gear:Label = $tacho/gear
@onready var tacho_rpm:Label = $tacho/rpm
@onready var power_graph:ViVeInEngineTorqueGraph = $power_graph
@onready var vgs:ViVeVGS = $vgs

@onready var fps:Label = $"container/fps"
@onready var weight_dist:Label = $"container/weight_dist"

func _ready() -> void:
	if not ViVeEnvironment.singleton.is_connected("ready", setup):
		ViVeEnvironment.get_singleton().connect("ready", setup)
	if not ViVeEnvironment.singleton.is_connected("car_changed", update_car):
		ViVeEnvironment.get_singleton().connect("car_changed", update_car)
	singleton = self

func update_car() -> void:
	car_node = ViVeEnvironment.singleton.car
	
	var horsepower_unit:String
	match power_graph.Power_Unit:
		1:
			horsepower_unit = "bhp"
		2:
			horsepower_unit = "ps"
		3:
			horsepower_unit = "kW"
		_:
			horsepower_unit = "hp"
	
	$hp.text = "Power: %s%s @ %s RPM" % [str( int(power_graph.peakhp[0] * 10.0) / 10.0 ), horsepower_unit, str(int(power_graph.peakhp[1] * 10.0) / 10.0)]
	
	var torque_unit:String = "ft⋅lb"
	if power_graph.Torque_Unit == 1:
		torque_unit = "nm"
	elif power_graph.Torque_Unit == 2:
		torque_unit = "kg/m"
	$tq.text = "Torque: %s%s @ %s RPM" % [str(int(power_graph.peaktq[0] * 10.0) / 10.0 ), torque_unit, str(int(power_graph.peaktq[1] * 10.0) / 10.0)]


#This is signal-ified due to being "too early" when done in _ready()
func setup() -> void:
	update_car()
	vgs.clear()
	for d:ViVeWheel in car_node.get_wheels():
		vgs.append_wheel(d)
	
	#sync the power graph
	power_graph.draw_graph()


func _process(delta:float) -> void:
	if not is_instance_valid(car_node):
		return
	
	if car_node.Debug_Mode:
		#This gives a more precise FPS at the cost of calculation
		fps.text = "fps: " + str(1.0 / delta)
	else:
		#This gives performs slightly better but gives a less precise FPS
		fps.text = "fps: " + str(Performance.get_monitor(Performance.TIME_FPS))
	
	$sw.rotation_degrees = car_node.car_controls.steer * 380.0
	$sw_desired.rotation_degrees = car_node.car_controls.steer2 * 380.0
	if car_node.Debug_Mode:
		weight_dist.text = "weight distribution: F%f/R%f" % [car_node.weight_dist[0] * 100, car_node.weight_dist[1] * 100]
	else:
		weight_dist.text = "[ enable Debug_Mode or press F to\nfetch weight distribution ]"
	
	if not changed_graph_size == power_graph.size:
		changed_graph_size = power_graph.size
		power_graph.draw_graph()
	
	$"fix engine".visible = car_node.rpm < car_node.DeadRPM
	
	$throttle.bar_scale = car_node.car_controls.gaspedal
	$brake.bar_scale = car_node.car_controls.brakepedal
	$handbrake.bar_scale = car_node.car_controls.handbrakepull
	$clutch.bar_scale = car_node._clutchpedalreal
	
	$tacho/speedk.text = "KM/PH: " +str(int(car_node.linear_velocity.length() * 1.10130592))
	$tacho/speedm.text = "MPH: " +str(int((car_node.linear_velocity.length() * 1.10130592) / 1.609 ) )
	
	$power_graph/rpm.position.x = (car_node.rpm / power_graph.Generation_Range) * power_graph.size.x - 1.0
	$power_graph/redline.position.x = (car_node.RPMLimit / power_graph.Generation_Range) * power_graph.size.x - 1.0
	
	$g.text = "Gs:\nx%s,\ny%s,\nz%s" % [str(int(car_node.gforce.x * 100.0) / 100.0), str(int(car_node.gforce.y * 100.0) / 100.0), str(int(car_node.gforce.z * 100.0) / 100.0)]
	
	tacho.currentpsi = car_node.turbo_psi * (car_node.TurboAmount)
	tacho.currentrpm = car_node.rpm
	tacho_rpm.text = str(int(car_node.rpm))
	
	if car_node.rpm < 0:
		tacho_rpm.self_modulate = Color.RED
	else:
		tacho_rpm.self_modulate = Color.WHITE
	
	if car_node.car_controls.gear == 0:
		tacho_gear.text = "N"
	elif car_node.car_controls.gear == -1:
		tacho_gear.text = "R"
	else:
		if car_node.TransmissionType == 1 or car_node.TransmissionType == 2:
			tacho_gear.text = "D"
		else:
			tacho_gear.text = str(car_node.car_controls.gear)

func _physics_process(_delta:float) -> void:
	if not is_instance_valid(car_node):
		return
	vgs.gforce -= (vgs.gforce - Vector2(car_node.gforce.x, car_node.gforce.z)) * 0.5
	
	var tacho_label:Label = $tacho/abs
	tacho_label.visible = car_node.abs_pump > 0 and car_node.car_controls.brakepedal > 0.1
	tacho_label = $tacho/tcs
	tacho_label.visible = car_node.tcs_flash
	tacho_label = $tacho/esp
	tacho_label.visible = car_node.esp_flash

##Restarts the car's engine. Needed if the RPM dips to low and it stalls.
func engine_restart() -> void:
	if is_instance_valid(car_node):
		car_node.rpm = car_node.IdleRPM
