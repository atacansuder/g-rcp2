@tool
extends VBoxContainer

var generated:bool = false

@onready var vari:Button = $vari.duplicate()
@onready var desc:Label = $desc.duplicate()
@onready var type:Label = $type.duplicate()
@onready var cat1:Button = $category1.duplicate()
@onready var cat2:Button = $category2.duplicate()

var controls:Dictionary = {
	"Use_Global_Control_Settings": ["Applies all control settings globally. This also affects cars that were already spawned.",false],
	"UseMouseSteering": ["Uses your cursor to steer the vehicle.",false],
	"UseAccelerometreSteering": ["Uses your accelerometre to steer, typically on mobile devices that have them.",false],
	"SteerSensitivity": ["Steering amplification on mouse and accelerometre steering.",0.0],

	"KeyboardSteerSpeed": ["Keyboard steering response rate.",0.0],
	"KeyboardReturnSpeed": ["Keyboard steering centring rate.",0.0],
	"KeyboardCompensateSpeed": ["Return rate when steering from an opposite direction.",0.0],
	"SteerAmountDecay": ["Reduces steering rate based on the vehicle’s speed.",0.0],
	"SteeringAssistance": ["Drift Help",0.0],
	"SteeringAssistanceAngular": ["Drift Stability Help",0.0],
	"GearAssistant": ["Gear Assistance (see below)",Array([])],
	"GearAssistant[0]": ["Shift Delay",0],
	"GearAssistant[1]": ["Assistance Level (0 - 2)",0],
	"GearAssistant[2]": ["Speed influence relative to wheel sizes. (This will be set automatically)",0.0],
	"GearAssistant[3]": ["Downshift RPM",0.0],
	"GearAssistant[4]": ["Upshift RPM",0.0],
	"GearAssistant[5]": ["Clutch-Out RPM",0.0],
	"OnThrottleRate": ["Throttle Pressure Rate",0.0],
	"OffThrottleRate": ["Throttle Depress Rate",0.0],
	"OnBrakeRate": ["Brake Pressure Rate",0.0],
	"OffBrakeRate": ["Brake Depress Rate",0.0],
	"OnHandbrakeRate": ["Handbrake Pull Rate",0.0],
	"OffHandbrakeRate": ["Handbrake Push Rate",0.0],
	"OnClutchRate": ["Clutch Release Rate",0.0],
	"OffClutchRate": ["Clutch Engage Rate",0.0],
	"MaxThrottle": ["Button Maximum Throttle Amount",0.0],
	"MaxBrake": ["Button Maximum Brake Amount",0.0],
	"MaxHandbrake": ["Button Maximum Handbrake Amount",0.0],
	"MaxClutch": ["Button Maximum Clutch Amount",0.0],
}

var chassis:Dictionary = {
}
var body:Dictionary = {

}
var steering:Dictionary = {
}

var dt:Dictionary = {
	"AutoSettings[0]": ["Upshift RPM",0.0],
	"AutoSettings[1]": ["Downshift Threshold",0.0],
	"AutoSettings[2]": ["",0.0],
	"AutoSettings[3]": ["",0.0],
	"AutoSettings[4]": ["",0.0],
	"CVTSettings": ["Settings for CVT.",[]],
	"CVTSettings[0]": ["",0.0],
	"CVTSettings[1]": ["",0.0],
	"CVTSettings[2]": ["",0.0],
	"CVTSettings[3]": ["",0.0],
	"CVTSettings[4]": ["",0.0],
	"CVTSettings[5]": ["",0.0],
}

var stab:Dictionary = {
	"ABS": ["Anti-lock Braking System (see below)",[]],
	"ABS[0]": ["Threshold",0.0],
	"ABS[1]": ["Pump Time",0],
	"ABS[2]": ["Vehicle Speed Before Activation",0.0],
	"ABS[3]": ["Enabled",false],
	"ESP": ["Electronic Stability Program.\n\nCURRENTLY DOESN'T WORK",[]],
	"BTCS": ["Prevents wheel slippage using the brakes.\n\nCURRENTLY DOESN'T WORK",[]],
	"TTCS": ["Prevents wheel slippage by partially closing the throttle.\n\nCURRENTLY DOESN'T WORK",[]],
}
var diff:Dictionary = {
}
var engine:Dictionary = {
}

var ecu:Dictionary = {
	"RPMLimit": ["Throttle Cutoff RPM",0.0],
	"LimiterDelay": ["Throttle cutoff time",0],
	"ThrottleLimit": ["Minimum throttle cutoff. (0.0 - 1.0)",0.0],
	"ThrottleIdle": ["Throttle intake on idle. (0.0 - 1.0)",0.0],
	"VVTRPM": ["Timing on RPM.",0.0],
}

var v1:Dictionary = {
	"BuildUpTorque": ["Torque buildup relative to RPM.",0.0],
	"TorqueRise": ["Sqrt torque buildup relative to RPM.",0.0],
	"RiseRPM": ["Initial RPM for TorqueRise.",0.0],
	"OffsetTorque": ["Static torque.",0.0],
	"FloatRate": ["Torque reduction relative to RPM.",0.0],
	"DeclineRate": ["Rapid reduction of torque.",0.0],
	"DeclineRPM": ["Initial RPM for DeclineRate.",0.0],
}
var v2:Dictionary = {
	"VVT_BuildUpTorque": ["See BuildUpTorque.",0.0],
	"VVT_TorqueRise": ["See TorqueRise.",0.0],
	"VVT_RiseRPM": ["See RiseRPM.",0.0],
	"VVT_OffsetTorque": ["See OffsetTorque.",0.0],
	"VVT_FloatRate": ["See FloatRate.",0.0],
	"VVT_DeclineRate": ["See DeclineRate.",0.0],
	"VVT_DeclineRPM": ["See DeclineRPM.",0.0],
}
var clutch:Dictionary = {
	"ClutchStable": ["Fix for engine's responses to friction. Higher values would make it sluggish.",0.0],
	"GearRatioRatioThreshold": ["Usually on a really short gear, the engine would jitter. This fixes it to say the least.",0.0],
	"ThresholdStable": ["Fix correlated to GearRatioRatioThreshold. Keep this value as it is.",0.0],
	"ClutchGrip": ["Clutch Capacity (nm)",0.0],
	"ClutchFloatReduction": ['Prevents RPM "Floating". This gives a better sensation on accelerating. Setting it too high would reverse the "floating". Setting it to 0 would turn it off.',0.0],
	"ClutchWobble": ["",0.0],
	"ClutchElasticity": ["",0.0],
	"WobbleRate": ["",0.0],
}

var forced:Dictionary = {
}

var wheel:Dictionary = {
	"A_InclineArea": ["",0.0],
	"A_ImpactForce": ["",0.0],
	"A_Geometry4": ["",0.0],
	"ESP_Role": ["",0.0],
	"ContactBTCS": ["",0.0],
	"ContactTTCS": ["",0.0],
}

var cs:Dictionary = {
	"Note": ["See TyreCompoundSettings in ViVeWheel", 0.0],
	"Stiffness": ["",0.0],
	"DeformFactor": ["",0.0],
	"ForeFriction": ["",0.0],
	"ForeStiffness": ["",0.0],
	"GroundDragAffection": ["",0.0],
}

var tyreset:Dictionary = {
	"Note": ["See ViVeTyreSettings in the in-engine docs (search it up).", 0.0],
}

func _type(n):
	const builtin_type_names = ["nil", "bool", "int", "float", "string", "vector2", "rect2", "vector3", "maxtrix32", "plane", "quat", "aabb",  "matrix3", "transform", "color", "image", "nodepath", "rid", null, "array", "dictionary", "array", "floatarray", "stringarray", "realarray", "stringarray", "vector2array", "vector3array", "colorarray", "unknown"]
	
	return builtin_type_names[n]

func add(categ:Dictionary, catname:String, descr:String) -> Button:
	var cat:Button = cat2.duplicate()
	add_child(cat)
	cat.text = catname + str(" +")
	cat.default_text = catname
	cat.visible = false
	var desc1 = desc.duplicate()
	add_child(desc1)
	desc1.text = descr
	desc1.visible = false
	cat.nodes.append(desc1)
	for i in categ:
		var v = vari.duplicate()
		add_child(v)
		v.text = i +str(" +")
		var d = desc.duplicate()
		add_child(d)
		d.text = "\n" +str(categ[i][0]) +str("\n")
		var t = type.duplicate()
		add_child(t)
		t.text = "Type: "+str(_type( typeof(categ[i][1]) )) +str("\n")
		v.default_text = i
		v.nodes = [d,t]
		v.visible = false
		d.visible = false
		t.visible = false
		cat.nodes.append(v)
	
	return cat

func generate():
	if not generated:
		$vari.queue_free()
		$desc.queue_free()
		$type.queue_free()
		$category1.queue_free()
		$category2.queue_free()
		
		var car:Button = cat1.duplicate()
		add_child(car)
		car.text = "car.gd +"
		car.default_text = "car.gd"
		car.nodes = [
			add(controls,"Controls", ""),
			add(chassis,"Chassis", ""),
			add(body,"Body", ""),
			add(steering,"Steering", ""),
			add(dt,"Drivetrain", ""),
			add(stab,"Stability (BETA)", ""),
			add(diff,"Differentials", ""),
			add(ecu,"ECU", ""),
			add(v1,"Configuration", ""),
			add(v2,"Configuration VVT","These variables are the second iteration. Vehicles will select these settings when RPMs reach a certain point (VVTRPM), portrayed as Variable Valve Timing."),
			add(clutch,"Clutch (BETA)", ""),
			add(forced,"Forced Inductions (BETA)", ""),
			]
		
		var wheels:Button = cat1.duplicate()
		add_child(wheels)
		wheels.text = "wheel.gd +"
		wheels.default_text = "wheel.gd"
		wheels.nodes = [
			add(wheel,"General", ""),
			add(tyreset,"TyreSettings", ""),
			add(cs,"CompoundSettings", ""),
			]
		
		generated = true
