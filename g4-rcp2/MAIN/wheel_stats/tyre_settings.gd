extends Resource
##A [Resource] for tyre settings.
class_name ViVeTyreSettings

##Grip and traction amplification.
@export var GripInfluence:float = 1.0:
	set(new_influence):
		GripInfluence = new_influence
		if is_instance_valid(wheel_parent):
			wheel_parent.set_physical_stats()
##Width of the tyre, in nanometers.
@export_range(0, INF) var Width_mm:int = 185:
	set(new_size):
		Width_mm = new_size
		if is_instance_valid(wheel_parent):
			wheel_parent.set_physical_stats()
##Aspect ratios are delivered in percentages. 
##Tire makers calculate the aspect ratio by dividing a tire's height off the rim by its width. 
##If a tire has an aspect ratio of 70, it means the tire's height is 70 percent of its width.
@export_range(0.0, 100.0) var Aspect_Ratio:float = 60.0:
	set(new_ratio):
		Aspect_Ratio = new_ratio
		if is_instance_valid(wheel_parent):
			wheel_parent.set_physical_stats()
##Rim size, in inches(?).
@export_range(0, INF) var Rim_Size_in:int = 14:
	set(new_size):
		Rim_Size_in = new_size
		if is_instance_valid(wheel_parent):
			wheel_parent.set_physical_stats()
##Air pressure of the tire, in PSI (hypothetical).
#previously [TyrePressure]
@export var AirPressure:float = 30.0:
	set(new_pressure):
		AirPressure = new_pressure
		if is_instance_valid(wheel_parent):
			wheel_parent.set_physical_stats()

##Reference to the owning/parent ViVeWheel
var wheel_parent:ViVeWheel

func get_size() -> float:
	const magic_number_d:float = 0.003269
	return ((Width_mm * ((Aspect_Ratio * 2.0) * 0.01) + Rim_Size_in * 25.4) * magic_number_d) * 0.5

func get_stiffness() -> float:
	return Width_mm / (Aspect_Ratio / 1.5)
