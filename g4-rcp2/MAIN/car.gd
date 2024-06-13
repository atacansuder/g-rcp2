extends RigidBody3D
##A class representing a car in VitaVehicle.
class_name ViVeCar

#These are magic numbers that have been pulled out of the codebase.
#Any guesses or information on what these could actually be would be appreciated!
const magic_1:float = 0.609
const magic_2:float = 1.475

const keyboard_mouse_controls:ViVeCarControls = preload("res://MISC/controls config/presets/keyboard_and_mouse.tres")
const keyboard_controls:ViVeCarControls = preload("res://MISC/controls config/presets/keyboard.tres")
const touch_controls:ViVeCarControls = preload("res://MISC/controls config/presets/touch_screen.tres")
const joypad_controls:ViVeCarControls = preload("res://MISC/controls config/presets/joypad.tres")

##Which control type the car is going to be associated with.
enum ControlType {
	##Use the keyboard and mouse for control.
	CONTROLS_KEYBOARD_MOUSE,
	##Use just the keyboard for control.
	CONTROLS_KEYBOARD,
	##Use the touchscreen for control.
	CONTROLS_TOUCH,
	##Use a connected game controller for control.
	CONTROLS_JOYPAD,
}

##Selection of transmission types that are implemented in VitaVehicle.
enum TransmissionTypes {
	##Full manual transmission.
	full_manual = 0,
	##Automatic transmission.
	auto = 1,
	##CVT (continuously variable transmission)
	continuous_variable = 2,
	##Semi auto transmission.
	semi_auto = 3
}

@export_group("Controls")
##The control set of this car.
@export var car_controls:ViVeCarControls = ViVeCarControls.new()
##The control preset for this car to use.
@export_enum("Keyboard and Mouse", "Keyboard", "Touch controls (Gyro)", "Joypad") var control_type:int = 1

## Gear Assistance.
@export var GearAssist:ViVeGearAssist = ViVeGearAssist.new()

@export_group("Meta")
##Whether the car is a user-controlled vehicle or not
@export var Controlled:bool = true
##Whether or not debug mode is active. [br]
##TODO: Make this do more than just hide weight distribution.
@export var Debug_Mode:bool = false

@export_group("Chassis")
##Vehicle weight in kilograms.
@export var Weight:float = 900.0 # kg

@export_group("Body")
##Up-pitch force based on the car’s velocity.
@export var LiftAngle:float = 0.1
##A force moving opposite in relation to the car’s velocity.
@export var DragCoefficient:float = 0.25
##A force moving downwards in relation to the car’s velocity.
@export var Downforce:float = 0.0

@export_group("Steering")
##The longitudinal pivot point from the car’s geometry (measured in default unit scale).
@export var AckermannPoint:float = -3.8
##Minimum turning circle (measured in default unit scale).
@export var Steer_Radius:float = 13.0
#there's an upstream glitch where these values don't save properly when this is a PackedStringArray
#@export var Powered_Wheels:PackedStringArray = ["fl", "fr"]
#The node names of the [ViVeWheels] actively driving (powering) the car.
@export var Powered_Wheels:Array[String] = ["fl", "fr"]

@export_group("Drivetrain")
##Final Drive Ratio refers to the last set of gears that connect a vehicle's engine to the driving axle.
@export var FinalDriveRatio:float = 4.250
#there's an upstream glitch where these values don't save properly when this is a PackedFloat32Array
#@export var GearRatios:PackedFloat32Array = [ 3.250, 1.894, 1.259, 0.937, 0.771 ]
##A set of gears a vehicle's transmission has, in order. [br]
##A gear  ratio is the ratio of the number of rotations of a driver gear  to the number of rotations of a driven gear .
@export var GearRatios:Array[float] = [ 3.250, 1.894, 1.259, 0.937, 0.771 ]
##The reversed equivalent to GearRatios, only containing one gear.
@export var ReverseRatio:float = 3.153
##Similar to FinalDriveRatio, but this should not relate to any real-life data. You may keep the value as it is.
@export var RatioMult:float = 9.5
##The amount of stress put into the transmission (as in accelerating or decelerating) to restrict clutchless gear shifting.
@export var StressFactor:float = 1.0
##A space between the teeth of all gears to perform clutchless gear shifts. Higher values means more noise. Compensate with StressFactor.
@export var GearGap:float = 60.0
## Leave this be, unless you know what you're doing.
##Possibly driveshaft weight?
@export var DSWeight:float = 150.0

##The [ViVeCar.TransmissionTypes] used for this car.
@export_enum("Fully Manual", "Automatic", "Continuously Variable", "Semi-Auto") var TransmissionType:int = 0

@export var AutoSettings:ViVeAutoSettings = ViVeAutoSettings.new()

## Settings for CVT.
@export var CVTSettings:ViVeCVT = ViVeCVT.new()

@export_group("Stability")
## Anti-lock Braking System. 
@export var ABS:ViVeABS = ViVeABS.new()
## @experimental 
## Electronic Stability Program. [br][br] CURRENTLY DOESN'T WORK!
@export var ESP:ViVeESP = ViVeESP.new()
## @experimental 
## Prevents wheel slippage using the brakes. [br] [br] CURRENTLY DOESN'T WORK!
@export var BTCS:ViVeBTCS = ViVeBTCS.new()
## @experimental 
## Prevents wheel slippage by partially closing the throttle. [br] [br] CURRENTLY DOESN'T WORK!
@export var TTCS:ViVeTTCS = ViVeTTCS.new()

@export_group("Differentials")
## Locks differential under acceleration.
@export var Locking:float = 0.1
## Locks differential under deceleration.
@export var CoastLocking:float = 0.0
## Static differential locking.
@export_range(0.0, 1.0) var Preload:float = 0.0
## Locks centre differential under acceleration.
@export var Centre_Locking:float = 0.5
## Locks centre differential under deceleration.
@export var Centre_CoastLocking:float = 0.5
## Static centre differential locking.
@export_range(0.0, 1.0) var Centre_Preload:float = 0.0

@export_group("Engine")
## Flywheel lightness.
@export var RevSpeed:float = 2.0 
## Chance of stalling.
@export var EngineFriction:float = 18000.0
## Rev drop rate.
@export var EngineDrag:float = 0.006
## How instant the engine corresponds with throttle input.
@export_range(0.0, 1.0) var ThrottleResponse:float = 0.5
## RPM below this threshold would stall the engine.
@export var DeadRPM:float = 100.0

@export_group("ECU")
## Throttle Cutoff RPM.
@export var RPMLimit:float = 7000.0
## Throttle cutoff time.
@export var LimiterDelay:float = 4
##The idling RPM.
@export var IdleRPM:float = 800.0
## Minimum throttle cutoff.
@export_range(0.0, 1.0) var ThrottleLimit:float = 0.0
## Throttle intake on idle.
@export_range(0.0, 1.0) var ThrottleIdle:float = 0.25
## Timing on RPM.
## Set this beyond the rev range to disable it, set it to 0 to use this vvt state permanently.
@export var VVTRPM:float = 4500.0 

@export_group("Torque normal state")
@export var torque_norm:ViVeCarTorque = ViVeCarTorque.new()

@export_group("Torque")
@export var torque_vvt:ViVeCarTorque = ViVeCarTorque.new("VVT")

@export_group("Clutch")
## Fix for engine's responses to friction. Higher values would make it sluggish.
@export var ClutchStable:float = 0.5
## Usually on a really short gear, the engine would jitter. This fixes it.
@export var GearRatioRatioThreshold:float = 200.0
## Fix correlated to GearRatioRatioThreshold. Keep this value as it is.
@export var ThresholdStable:float = 0.01
## Clutch Capacity (nm).
@export var ClutchGrip:float = 176.125
## Prevents RPM "Floating". This gives a better sensation on accelerating. 
## Setting it too high would reverse the "floating". Setting it to 0 would turn it off.
@export var ClutchFloatReduction:float = 27.0

@export var ClutchWobble:float = 2.5 * 0

@export var ClutchElasticity:float = 0.2 * 0

@export var WobbleRate:float = 0.0

@export_group("Forced Inductions")
## Maximum air generated by any forced inductions.
@export var MaxPSI:float = 9.0
## Compression ratio has an effect on forced induction systems. 
##This is only an information for VitaVehicle to read boosts and it doesn't affect torque when TurboEnabled is off.
@export var EngineCompressionRatio:float = 8.0 # Piston travel distance

@export_group("Turbo")
## Turbocharger. Enables turbo.
@export var TurboEnabled:bool = false
## Amount of turbochargers, multiplies boost power.
@export var TurboAmount:float = 1.0
## Turbo Lag. Higher = More turbo lag.
@export var TurboSize:float = 8.0
## Counters TurboSize. Higher = Allows more spooling on low RPM.
@export var Compressor:float = 0.3
## Threshold of throttle before spooling.
@export_range(0.0, 0.9999) var SpoolThreshold:float = 0.1
## How instant spooling stops.
@export var BlowoffRate:float = 0.14
## Turbo Response.
@export_range(0.0, 1.0) var TurboEfficiency:float = 0.075
## Allowing Negative PSI. Performance deficiency upon turbo idle.
@export var TurboVacuum:float = 1.0 

@export_group("Supercharger")
## Enables supercharger.
@export var SuperchargerEnabled:bool = false 
## Boost applied upon engine speeds.
@export var SCRPMInfluence:float = 1.0
## Boost Amplification.
@export var BlowRate:float = 35.0
## Deadzone before boost.
@export var SCThreshold:float = 6.0

@onready var front_left:ViVeWheel = $"fl"
@onready var front_right:ViVeWheel = $"fr"
@onready var back_left:ViVeWheel = $"rl"
@onready var back_right:ViVeWheel = $"rr"
@onready var drag_center:Marker3D = $"DRAG_CENTRE"

##An array containing the front wheels of the car.
@onready var front_wheels:Array[ViVeWheel] = [front_left, front_right]
##An array containing the rear wheels of the car.
@onready var rear_wheels:Array[ViVeWheel] = [back_left, back_right]
##An array containing all wheels of the car.
var all_wheels:Array[ViVeWheel]

##This is value compared to determine if the control scheme should be changed.
var car_controls_cache:ControlType

var rpm:float = 0.0

#var _rpmspeed:float = 0.0

var lim_del:float = 0.0

var actualgear:int = 0

var gear_stress:float = 0.0

var throttle:float = 0.0
##Acceleration if the car is using a Continuously Variable Transmission
var cvt_accel:float = 0.0
##
var shift_assist_delay:float = 0.0
##The step that shift assistance is on, used in full_manual_transmission
var shift_assist_step:int = 0
##Used in full_manual_transmission.
var clutch_pedal_real:float = 0.0

var abs_pump:float = 0.0

var tcs_weight:float = 0.0
##Used in the tachometer.
var tcs_flash:bool = false
##Used in the tachometer.
var esp_flash:bool = false
##The gear ratio of the current gear.
var current_gear_ratio:float = 0.0 #previously _ratio
##Whether Variable Valve Timing stats for the torque will be used
var vvt:bool = false

var brake_allowed:float = 0.0

var readout_torque:float = 0.0

var brake_line:float = 0.0
##The total power bias of all powered wheels together.
var power_bias_total:float = 0.0
##[power_bias_total] from the last physics frame.
var previous_power_bias_total:float = 0.0

#var _diffspeed:float = 0.0

#var _diffspeedun:float = 0.0
##Related to Locking/CoastLocking
var differential_lock_influence:float = 0.0

var center_differential_lock_influence:float = 0.0

var wv_difference:float = 0.0

var rpm_force:float = 0.0

var whine_pitch:float = 0.0

var turbo_psi:float = 0.0

var sc_rpm:float = 0.0

var boosting:float = 0.0

var rpm_cs:float = 0.0

var rpm_csm:float = 0.0

var current_stable:float = 0.0

#var steering_geometry:Array[float] = [0.0,0.0] #0 is x, 1 is z?
#Only x and z are used, it's not a Vec2 for consistency
var steering_geometry:Vector3 = Vector3.ZERO 

var resistance:float = 0.0

var clutch_wobble:float = 0.0

var ds_weight_2:float = 0.0

#var _steer_torque:float = 0.0
##This is the average of [w_size] of all the drive wheel combined.
var average_drivewheel_size:float = 1.0
##An array of the global_rotation.y values of each steering wheel at the current physics frame.
##These angles are in degrees.
var steering_angles:PackedFloat32Array = []
##The largest value in [steering_angles], set each physics frame.
var max_steering_angle:float = 0.0

#physics values
##The velocity from the last physics frame
var past_velocity:Vector3 = Vector3.ZERO
##The force of gravity on the car.
var gforce:Vector3 = Vector3.ZERO

var clock_mult:float = 1.0

var dist:float = 0.0

var stress_total:float = 0.0

var velocity:Vector3 = Vector3.ZERO

var r_velocity:Vector3 = Vector3.ZERO

var stalled:float = 0.0

var front_load:float = 0.0

var total_load:float = 0.0

var weight_dist:Array[float] = [0.0,0.0]

var physics_tick:float = 60.0

##A set of wheels that are powered parented under the vehicle.
var powered_wheels:Array[ViVeWheel]


var gear:int



var steer_velocity:float

var assistance_factor:float

var clutch_in:bool = false

var rev_match:bool = false

var gas_restricted:bool = false

var left:bool = false

var right:bool = false

var shift_up_pressed:bool = false

var shift_down_pressed:bool = false

var gas_pressed:bool = false

var brake_pressed:bool = false

var handbrake_pressed:bool = false

var clutch_pressed:bool = false

var gas_pedal:float = 0.0

var brake_pedal:float = 0.0

var handbrake_pull:float = 0.0

var clutch_pedal:float = 0.0

var steer:float

var steer_2:float







## Emitted when the wheel arrays are updated.
signal wheels_updated

#Holdover from Godot 3. 
#Still here because Bullet is available as an optional GDExtension, so you never know
##Function for fixing ViVe under Bullet physics. Not needed when using Godot physics.
func bullet_fix() -> void:
	var offset:Vector3 = drag_center.position
	AckermannPoint -= offset.z
	
	for i:Node3D in get_children():
		i.position -= offset

func _ready() -> void:
#	bullet_fix()
	physics_tick = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0)
	
	swap_controls()
	
	rpm = IdleRPM
	
	mass = Weight / 10.0
	
	#powered_wheels = get_powered_wheels()
	update_wheel_arrays()
	
	emit_signal("wheels_updated")

##Updates several internal arrays used for iterating over wheels of various types.
func update_wheel_arrays() -> void:
	all_wheels.clear()
	front_wheels.clear()
	rear_wheels.clear()
	powered_wheels.clear()
	
	for nodes:Node in get_children():
		if nodes.is_class("RayCast3D"): #When in C++, check for "ViVeWheel"
			all_wheels.append(nodes)
			#front or rear wheels
			if nodes.position.z > 0:
				front_wheels.append(nodes)
			else:
				rear_wheels.append(nodes)
			#powered wheel
			if Powered_Wheels.has(nodes.name):
				powered_wheels.append(nodes)
	
	emit_signal("wheels_updated")

##Do all the setup needed when swapping control schemes
func swap_controls() -> void:
	var new_control_scheme:ControlType = control_type as ControlType
	##TODO: swap Control resources
	match new_control_scheme:
		ControlType.CONTROLS_KEYBOARD_MOUSE:
			ViVeTouchControls.singleton.hide()
			car_controls = keyboard_mouse_controls
		ControlType.CONTROLS_KEYBOARD:
			ViVeTouchControls.singleton.hide()
			car_controls = keyboard_controls
		ControlType.CONTROLS_TOUCH:
			ViVeTouchControls.singleton.show()
			car_controls = touch_controls
		ControlType.CONTROLS_JOYPAD:
			ViVeTouchControls.singleton.hide()
			car_controls = joypad_controls
	
	car_controls_cache = new_control_scheme
	
	ViVeEnvironment.get_singleton().emit_signal("car_changed")

func new_controls() -> void:
	if control_type != car_controls_cache:
		swap_controls()
	
	if control_type == ControlType.CONTROLS_KEYBOARD_MOUSE:
		var mouseposx:float = get_window().get_mouse_position().x / get_window().size.x
		newer_controls(mouseposx)
	elif control_type == ControlType.CONTROLS_KEYBOARD:
		newer_controls()
	elif control_type == ControlType.CONTROLS_TOUCH:
		newer_controls(Input.get_accelerometer().x / 10.0)
	elif control_type == ControlType.CONTROLS_JOYPAD:
		newer_controls(car_controls.get_steer_axis())

func newer_controls(analog_axis:float = 0.0) -> void:
	gas_pressed = car_controls.is_gas_pressed()
	brake_pressed = car_controls.is_brake_pressed()
	handbrake_pressed = car_controls.is_handbrake_pressed()
	shift_up_pressed = car_controls.is_shift_up_pressed()
	shift_down_pressed = car_controls.is_shift_down_pressed()
	clutch_pressed = car_controls.is_clutch_pressed()
	
	if car_controls.LooseSteering:
		steer += steer_velocity
		
		if absf(steer) > 1.0:
			steer_velocity *= -0.5
		
		for front_wheel:ViVeWheel in front_wheels:
			steer_velocity += (front_wheel.directional_force.x * 0.00125) * front_wheel.Caster
			#steer_velocity -= (front_wheel.stress * 0.0025) * (atan2(absf(front_wheel.wv), 1.0) * front_wheel.angle)
			steer_velocity -= (front_wheel.stress * 0.0025) * (atan(absf(front_wheel.wv)) * front_wheel.angle)
			
			steer_velocity += steer * (front_wheel.directional_force.z * 0.0005) * front_wheel.Caster
			
			steer_velocity += front_wheel.directional_force.z * 0.0001 * signf(front_wheel.position.x)
			
			steer_velocity /= front_wheel.stress / (front_wheel.slip_percpre * (front_wheel.slip_percpre * 100.0) + 1.0) + 1.0
	
	if not Controlled:
		return
	
	match GearAssist.assist_level:
		2: #automatically go "forwards" regardless of pedal pressed, using the current gear to decide direction.
			if gear == -1: #going in reverse
				gas_pedal = car_controls.get_throttle(brake_pressed or rev_match)
				brake_pedal = car_controls.get_brake(gas_pressed)
			else: #Forward moving gear 
				gas_pedal = car_controls.get_throttle((gas_pressed and not gas_restricted) or rev_match)
				brake_pedal = car_controls.get_brake(brake_pressed)
		1: #go forward if gas_pressed is pressed, go backwards if brake_pressed is pressed.
			gas_pedal = car_controls.get_throttle(gas_pressed and not gas_restricted or rev_match)
			brake_pedal = car_controls.get_brake(brake_pressed)
		0: #1, but also automatically disable clutch
			gas_restricted = false
			clutch_in = false
			rev_match = false
			
			gas_pedal = car_controls.get_throttle(gas_pressed and not gas_restricted or rev_match)
			brake_pedal = car_controls.get_brake(brake_pressed)
	
	handbrake_pull = car_controls.get_handbrake(handbrake_pressed)
	
	#previously called "going"
	var forward_force:float
	
	#if the car is actively going left or right (and is not stationary)
	if (velocity.x > 0 and steer_2 > 0) or (velocity.x < 0 and steer_2 < 0):
		forward_force = maxf(velocity.z, 0.0)
	else:
		forward_force = maxf(velocity.z / (absf(velocity.x)), 0.0)
	
	if car_controls.LooseSteering:
		return
	
	steer_2 = car_controls.get_steer_axis(analog_axis)
	
	#steering assistance
	if assistance_factor > 0.0:
		var max_steer:float = 1.0 / (forward_force * (car_controls.SteerAmountDecay / assistance_factor) + 1.0)
		var assist_mult:float = 0.0
		
		if car_controls.EnableSteeringAssistance:
			assist_mult = car_controls.SteeringAssistance * assistance_factor
		
		var assist_commence:float = minf(linear_velocity.length() / 10.0, 1.0)
		
		steer = (steer_2 * max_steer) - (velocity.normalized().x * assist_commence) * assist_mult + r_velocity.y * assist_mult
	else:
		steer = steer_2

func old_controls() -> void:
	#Tbh I don't see why these need to be divided, but...
	if car_controls.UseAnalogSteering:
		gas_pressed = Input.is_action_pressed("gas_mouse")
		brake_pressed = Input.is_action_pressed("brake_mouse")
		shift_up_pressed = Input.is_action_just_pressed("shiftup_mouse")
		shift_down_pressed = Input.is_action_just_pressed("shiftdown_mouse")
		handbrake_pressed = Input.is_action_pressed("handbrake_mouse")
	else:
		gas_pressed = Input.is_action_pressed("gas")
		brake_pressed = Input.is_action_pressed("brake")
		shift_up_pressed = Input.is_action_just_pressed("shiftup")
		shift_down_pressed = Input.is_action_just_pressed("shiftdown")
		handbrake_pressed = Input.is_action_pressed("handbrake")
	
	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	
	if left:
		steer_velocity -= 0.01
	elif right:
		steer_velocity += 0.01
	
	if car_controls.LooseSteering:
		steer += steer_velocity
		
		if absf(steer) > 1.0:
			steer_velocity *= -0.5
		
		for front_wheel:ViVeWheel in [front_left,front_right]:
			steer_velocity += (front_wheel.directional_force.x * 0.00125) * front_wheel.Caster
			steer_velocity -= (front_wheel.stress * 0.0025) * (atan2(absf(front_wheel.wv), 1.0) * front_wheel.angle)
			
			steer_velocity += steer * (front_wheel.directional_force.z * 0.0005) * front_wheel.Caster
			
			if front_wheel.position.x > 0:
				steer_velocity += front_wheel.directional_force.z * 0.0001
			else:
				steer_velocity -= front_wheel.directional_force.z * 0.0001
		
			steer_velocity /= front_wheel.stress / (front_wheel.slip_percpre * (front_wheel.slip_percpre * 100.0) + 1.0) + 1.0
	
	if Controlled:
		if GearAssist.assist_level == 2:
			if (gas_pressed and not gas_restricted and not gear  == -1) or (brake_pressed and gear  == -1) or rev_match:
				gas_pedal += car_controls.OnThrottleRate / clock_mult
			else:
				gas_pedal -= car_controls.OffThrottleRate / clock_mult
			if (brake_pressed and not gear  == -1) or (gas_pressed and gear  == -1):
				brake_pedal += car_controls.OnBrakeRate / clock_mult
			else:
				brake_pedal -= car_controls.OffBrakeRate / clock_mult
		else:
			if GearAssist.assist_level == 0:
				gas_restricted = false
				clutch_in = false
				rev_match = false
			
			if gas_pressed and not gas_restricted or rev_match:
				gas_pedal += car_controls.OnThrottleRate / clock_mult
			else:
				gas_pedal -= car_controls.OffThrottleRate / clock_mult
			
			if brake_pressed:
				brake_pedal += car_controls.OnBrakeRate / clock_mult
			else:
				brake_pedal -= car_controls.OffBrakeRate / clock_mult
		
		if handbrake_pressed:
			handbrake_pull += car_controls.OnHandbrakeRate / clock_mult
		else:
			handbrake_pull -= car_controls.OffHandbrakeRate / clock_mult
		
		var siding:float = absf(velocity.x)
		
		#Based on the syntax, I'm unsure if this is doing what it "should" do...?
		if (velocity.x > 0 and steer_2 > 0) or (velocity.x < 0 and steer_2 < 0):
			siding = 0.0
		
		var going:float = velocity.z / (siding + 1.0)
		going = maxf(going, 0)
		
		#Steer based on control options
		if not car_controls.LooseSteering:
			
			if car_controls.UseAnalogSteering:
				var mouseposx:float = 0.0
#				if get_viewport().size.x > 0.0:
#					mouseposx = get_viewport().get_mouse_position().x / get_viewport().size.x
				if get_window().size.x > 0.0:
					mouseposx = get_window().get_mouse_position().x / get_window().size.x
				
				steer_2 = (mouseposx - 0.5) * 2.0
				steer_2 *= car_controls.SteerSensitivity
				
				steer_2 = clampf(steer_2, -1.0, 1.0)
				
				var s:float = absf(steer_2) * 1.0 + 0.5
				s = minf(s, 1.0)
				
				steer_2 *= s
				mouseposx = (mouseposx - 0.5) * 2.0
				#steer2 = control_steer_analog(mouseposx)
				
				#steer2 = control_steer_analog(Input.get_joy_axis(0, JOY_AXIS_LEFT_X))
				
			elif car_controls.UseAnalogSteering:
				steer_2 = Input.get_accelerometer().x / 10.0
				steer_2 *= car_controls.SteerSensitivity
				
				steer_2 = clampf(steer_2, -1.0, 1.0)
				
				var s:float = absf(steer_2) * 1.0 + 0.5
				s = minf(s, 1.0)
				
				steer_2 *= s
			else:
				if right:
					if steer_2 > 0:
						steer_2 += car_controls.KeyboardSteerSpeed
					else:
						steer_2 += car_controls.KeyboardCompensateSpeed
				elif left:
					if steer_2 < 0:
						steer_2 -= car_controls.KeyboardSteerSpeed
					else:
						steer_2 -= car_controls.KeyboardCompensateSpeed
				else:
					if steer_2 > car_controls.KeyboardReturnSpeed:
						steer_2 -= car_controls.KeyboardReturnSpeed
					elif steer_2 < - car_controls.KeyboardReturnSpeed:
						steer_2 += car_controls.KeyboardReturnSpeed
					else:
						steer_2 = 0.0
				steer_2 = clampf(steer_2, -1.0, 1.0)
			
			
			if assistance_factor > 0.0:
				var maxsteer:float = 1.0 / (going * (car_controls.SteerAmountDecay / assistance_factor) + 1.0)
				
				var assist_commence:float = linear_velocity.length() / 10.0
				assist_commence = minf(assist_commence, 1.0)
				
				steer = (steer_2 * maxsteer) - (velocity.normalized().x * assist_commence) * (car_controls.SteeringAssistance * assistance_factor) + r_velocity.y * (car_controls.SteeringAssistanceAngular * assistance_factor)
			else:
				steer = steer_2

func transmission() -> void:
	if not GearAssist.assist_level == 0:
		clutch_pressed = handbrake_pressed
	clutch_pressed = not clutch_pressed
	
	if TransmissionType == TransmissionTypes.full_manual:
		full_manual_transmission()
	elif TransmissionType == TransmissionTypes.auto:
		automatic_transmission()
	elif TransmissionType == TransmissionTypes.continuous_variable:
		cvt_transmission()
	elif TransmissionType == TransmissionTypes.semi_auto:
		semi_auto_transmission()
	
	clutch_pedal = clampf(clutch_pedal, 0.0, 1.0)

func full_manual_transmission() -> void:
	clutch_pedal_real = car_controls.get_clutch(not (clutch_pressed and not clutch_in))
	
	clutch_pedal = 1.0 - clutch_pedal_real
	
	if gear > 0:
		current_gear_ratio = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
	elif gear == -1:
		current_gear_ratio = ReverseRatio * FinalDriveRatio * RatioMult
	
	if GearAssist.assist_level == 0:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < GearRatios.size():
				if gear_stress < GearGap:
					actualgear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > -1:
				if gear_stress < GearGap:
					actualgear -= 1
	
	elif GearAssist.assist_level == 1:
		if rpm < GearAssist.clutch_out_RPM:
			var irga_ca:float = (GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM)
			#clutch_pedal_real = minf(pow(irga_ca, 2.0), 1.0)
			clutch_pedal_real = minf(irga_ca * irga_ca, 1.0)
		else:
			if not gas_restricted and not rev_match:
				clutch_in = false
		
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < GearRatios.size():
				if rpm < GearAssist.clutch_out_RPM:
					actualgear += 1
				else:
					if actualgear < 1:
						actualgear += 1
						if rpm > GearAssist.clutch_out_RPM:
							clutch_in = false
					else:
						if shift_assist_delay > 0:
							actualgear += 1
						shift_assist_delay = GearAssist.shift_delay / 2.0
						shift_assist_step = -4
						
						clutch_in = true
						gas_restricted = true
		
		elif shift_down_pressed:
			shift_down_pressed = false
			if gear > -1:
				if rpm < GearAssist.clutch_out_RPM:
					actualgear -= 1
				else:
					if actualgear == 0 or actualgear == 1:
						actualgear -= 1
						clutch_in = false
					else:
						if shift_assist_delay > 0:
							actualgear -= 1
						shift_assist_delay = GearAssist.shift_delay / 2.0
						shift_assist_step = -2
						
						clutch_in = true
						rev_match = true
						gas_restricted = false
	
	elif GearAssist.assist_level == 2:
		var assistshiftspeed:float = (GearAssist.upshift_RPM / current_gear_ratio) * GearAssist.speed_influence
		var assistdownshiftspeed:float = (GearAssist.down_RPM / absf((GearRatios[gear - 2] * FinalDriveRatio) * RatioMult)) * GearAssist.speed_influence
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = -1
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == -1:
				shift_assist_delay = 60
				actualgear = 0
		if shift_assist_step == 0:
			if rpm < GearAssist.clutch_out_RPM:
				var irga_ca:float = (GearAssist.clutch_out_RPM - rpm) / (GearAssist.clutch_out_RPM - IdleRPM)
				clutch_pedal_real = minf(irga_ca * irga_ca, 1.0)
				
			else:
				clutch_in = false
			if not gear == -1:
				if gear < GearRatios.size() and linear_velocity.length() > assistshiftspeed:
					shift_assist_delay = GearAssist.shift_delay / 2.0
					shift_assist_step = -4
					
					clutch_in = true
					gas_restricted = true
				if gear > 1 and linear_velocity.length() < assistdownshiftspeed:
					shift_assist_delay = GearAssist.shift_delay / 2.0
					shift_assist_step = -2
					
					clutch_in = true
					gas_restricted = false
					rev_match = true
	
	if shift_assist_step == -4 and shift_assist_delay < 0:
		shift_assist_delay = GearAssist.shift_delay / 2.0
		if gear < GearRatios.size():
			actualgear += 1
		shift_assist_step = -3
	elif shift_assist_step == -3 and shift_assist_delay < 0:
		if rpm > GearAssist.clutch_out_RPM:
			clutch_in = false
		if shift_assist_delay < - GearAssist.input_delay:
			shift_assist_step = 0
			gas_restricted = false
	elif shift_assist_step == -2 and shift_assist_delay < 0:
		shift_assist_step = 0
		if gear > -1:
			actualgear -= 1
		if rpm > GearAssist.clutch_out_RPM:
			clutch_in = false
		gas_restricted = false
		rev_match = false
	gear = actualgear

func automatic_transmission() -> void:
	clutch_pedal = (rpm - AutoSettings.engage_rpm_thresh * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh)) ) / AutoSettings.engage_rpm
	
	if not GearAssist.assist_level == 2:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < 1:
				actualgear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > -1:
				actualgear -= 1
	else:
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = -1
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == -1:
				shift_assist_delay = 60
				actualgear = 0
	
	if actualgear == -1:
		current_gear_ratio = ReverseRatio * FinalDriveRatio * RatioMult
	else:
		current_gear_ratio = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
	
	if actualgear > 0:
		var lastratio:float = GearRatios[gear - 2] * FinalDriveRatio * RatioMult
		
		shift_up_pressed = false
		shift_down_pressed = false
		for i:ViVeWheel in powered_wheels:
			if (i.wv / GearAssist.speed_influence) > (AutoSettings.shift_rpm * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh))) / current_gear_ratio:
				shift_up_pressed = true
			elif (i.wv / GearAssist.speed_influence) < ((AutoSettings.shift_rpm - AutoSettings.downshift_thresh) * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh))) / lastratio:
				shift_down_pressed = true
		
		if shift_up_pressed:
			gear += 1
		elif shift_down_pressed:
			gear -= 1
		
		gear = clampi(gear , 1, GearRatios.size())
	else:
		gear = actualgear


func cvt_transmission() -> void:
	clutch_pedal = (rpm - AutoSettings.engage_rpm_thresh * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh)) ) / AutoSettings.engage_rpm
	
	#clutch_pedal = 1
	
	if not GearAssist.assist_level == 2:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < 1:
				actualgear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > -1:
				actualgear -= 1
	else:
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = -1
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == -1:
				shift_assist_delay = 60
				actualgear = 0
	
	gear = actualgear
	var all_wheels_velocity:float = 0.0
	
	for i:ViVeWheel in powered_wheels:
		all_wheels_velocity += i.wv / powered_wheels.size()
	
	cvt_accel -= (cvt_accel - (gas_pedal * CVTSettings.throt_eff_thresh + (1.0 - CVTSettings.throt_eff_thresh))) * CVTSettings.accel_rate
	
	var a:float = maxf(CVTSettings.iteration_3 / ((absf(all_wheels_velocity) / 10.0) * cvt_accel + 1.0), CVTSettings.iteration_4)
	
	current_gear_ratio = (CVTSettings.iteration_1 * 10000000.0) / (absf(all_wheels_velocity) * (rpm * a) + 1.0)
	
	current_gear_ratio = minf(current_gear_ratio, CVTSettings.iteration_2)

func semi_auto_transmission() -> void:
	clutch_pedal = (rpm - AutoSettings.engage_rpm_thresh * (gas_pedal * AutoSettings.throt_eff_thresh + (1.0 - AutoSettings.throt_eff_thresh)) ) / AutoSettings.engage_rpm
	
	if gear > 0:
		current_gear_ratio = GearRatios[gear - 1] * FinalDriveRatio * RatioMult
	elif gear == -1:
		current_gear_ratio = ReverseRatio * FinalDriveRatio * RatioMult
	
	if GearAssist.assist_level < 2:
		if shift_up_pressed:
			shift_up_pressed = false
			if gear < GearRatios.size():
				actualgear += 1
		if shift_down_pressed:
			shift_down_pressed = false
			if gear > -1:
				actualgear -= 1
	else:
		var assistshiftspeed:float = (GearAssist.upshift_RPM / current_gear_ratio) * GearAssist.speed_influence
		var assistdownshiftspeed:float = (GearAssist.down_RPM / absf((GearRatios[gear - 2] * FinalDriveRatio) * RatioMult)) * GearAssist.speed_influence
		if gear == 0:
			if gas_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = 1
			elif brake_pressed:
				shift_assist_delay -= 1
				if shift_assist_delay < 0:
					actualgear = -1
			else:
				shift_assist_delay = 60
		elif linear_velocity.length() < 5:
			if not gas_pressed and gear == 1 or not brake_pressed and gear == -1:
				shift_assist_delay = 60
				actualgear = 0
		if shift_assist_step == 0:
			if gear != -1:
				if gear < GearRatios.size() and linear_velocity.length() > assistshiftspeed:
					actualgear += 1
				if gear > 1 and linear_velocity.length() < assistdownshiftspeed:
					actualgear -= 1
	
	gear = actualgear

func drivetrain() -> void:
	rpm_csm -= (rpm_cs - resistance)
	rpm_cs += rpm_csm * ClutchElasticity
	
	rpm_cs -= rpm_cs * (1.0 - clutch_pedal)
	
	clutch_wobble = ClutchWobble * clutch_pedal * (current_gear_ratio * WobbleRate)
	
	rpm_cs -= (rpm_cs - resistance) * (1.0 / (clutch_wobble + 1.0))
	
	#torquereadout = multivariate(RiseRPM,TorqueRise,BuildUpTorque,EngineFriction,EngineDrag,OffsetTorque,rpm,DeclineRPM,DeclineRate,FloatRate,turbopsi,TurboAmount,EngineCompressionRatio,TurboEnabled,VVTRPM,VVT_BuildUpTorque,VVT_TorqueRise,VVT_RiseRPM,VVT_OffsetTorque,VVT_FloatRate,VVT_DeclineRPM,VVT_DeclineRate,SuperchargerEnabled,SCRPMInfluence,BlowRate,SCThreshold)
	if gear < 0:
		rpm -= ((rpm_cs / clock_mult) * (RevSpeed / magic_2))
	else:
		rpm += ((rpm_cs / clock_mult) * (RevSpeed / magic_2))
	
	#I think this is here for testing
	if false:
		rpm = 7000.0
		Locking = 0.0
		CoastLocking = 0.0
		Centre_Locking = 0.0
		Centre_CoastLocking = 0.0
		Preload = 1.0
		Centre_Preload = 1.0
		ClutchFloatReduction = 0.0
	
	gear_stress = (absf(resistance) * StressFactor) * clutch_pedal
	ds_weight_2 = DSWeight / (current_gear_ratio * 0.9 + 0.1)
	
	whine_pitch = absf(rpm / current_gear_ratio) * 1.5
	
	if resistance > 0.0:
		differential_lock_influence = absf(resistance / ds_weight_2) * (CoastLocking / 100.0) + Preload
	else:
		differential_lock_influence = absf(resistance / ds_weight_2) * (Locking / 100.0) + Preload
	
	differential_lock_influence = clampf(differential_lock_influence, 0.0, 1.0)
	
	if wv_difference > 0.0:
		center_differential_lock_influence = absf(wv_difference) * (Centre_CoastLocking / 10.0) + Centre_Preload
	else:
		center_differential_lock_influence = absf(wv_difference) * (Centre_Locking / 10.0) + Centre_Preload
	
	center_differential_lock_influence = clampf(center_differential_lock_influence, 0.0, 1.0)
	if powered_wheels.size() < 4:
		center_differential_lock_influence = 0.0
	
	
	var maxd:ViVeWheel = VitaVehicleSimulation.fastest_wheel(powered_wheels)
	#var mind:ViVeWheel = VitaVehicleSimulation.slowest_wheel(powered_wheels)
	
	
	var float_reduction:float = ClutchFloatReduction
	
	if previous_power_bias_total > 0.0:
		float_reduction = ClutchFloatReduction / previous_power_bias_total
	else:
		float_reduction = 0.0
	
	var stabling:float = - (GearRatioRatioThreshold - current_gear_ratio * average_drivewheel_size) * ThresholdStable
	stabling = maxf(stabling, 0.0)
	
	current_stable = ClutchStable + stabling
	current_stable *= (RevSpeed / magic_2)
	
	var what:float
	
	if previous_power_bias_total > 0.0:
		what = (rpm -(((rpm_force * float_reduction) * current_stable) / (ds_weight_2 / previous_power_bias_total)))
	else: #idling?
		what = rpm
	
	if gear < 0.0:
		dist = maxd.wv + what / current_gear_ratio
	else:
		dist = maxd.wv - what / current_gear_ratio
	
	dist *= pow(clutch_pedal, 2.0)
	
	if gear == 0:
		dist = 0.0
	
	wv_difference = 0.0
	average_drivewheel_size = 0.0
	
	#update stats of all the powered wheels
	for i:ViVeWheel in powered_wheels:
		average_drivewheel_size += i.w_size / powered_wheels.size()
		i.live_power_bias = i.W_PowerBias
		wv_difference += ((i.wv - what / current_gear_ratio) / powered_wheels.size()) * pow(clutch_pedal, 2.0)
		if gear < 0:
			i.dist = dist * (1 - center_differential_lock_influence) + (i.wv + what / current_gear_ratio) * center_differential_lock_influence
		else:
			i.dist = dist * (1 - center_differential_lock_influence) + (i.wv - what / current_gear_ratio) * center_differential_lock_influence
		if gear == 0:
			i.dist = 0.0
	
	
	GearAssist.speed_influence = average_drivewheel_size
	resistance = 0.0
	previous_power_bias_total = power_bias_total
	power_bias_total = 0.0
	tcs_weight = 0.0
	stress_total = 0.0

##Applies aerodynamics to the car.
func aerodynamics() -> void:
	var normal_velocity:Vector3 = global_transform.basis.orthonormalized().transposed() * (linear_velocity)
	
	apply_torque_impulse(global_transform.basis.orthonormalized() * ( Vector3((-normal_velocity.length() * 0.3) * LiftAngle, 0.0, 0.0)))
	
	var drag_velocity:Vector3 = (normal_velocity * 0.15)
	var drag_velocity_length:float = normal_velocity.length() * 0.15
	
	#drag_velocity.x = -drag_velocity.x * DragCoefficient
	drag_velocity.x *= -DragCoefficient
	drag_velocity.y = -drag_velocity_length * Downforce - drag_velocity.y * DragCoefficient
	#drag_velocity.z = -drag_velocity.z * DragCoefficient
	drag_velocity.z *= -DragCoefficient
	
	var air_drag_force:Vector3 = global_transform.basis.orthonormalized() * drag_velocity
	
	#if has_node("DRAG_CENTRE"):
	if is_instance_valid(drag_center):
		apply_impulse(air_drag_force, global_transform.basis.orthonormalized() * (drag_center.position))
	else:
		apply_central_impulse(air_drag_force)

func _physics_process(_delta:float) -> void:
	if steering_angles.size() > 0:
		max_steering_angle = 0.0
		
		#for i:float in steering_angles:
		#	max_steering_angle = maxf(max_steering_angle, i)
		
		#sort the values from smaller to larger
		steering_angles.sort() 
		#flip it so the first value is the largest one
		steering_angles.reverse()
		#We have now found the max angle without doing iterations in a time sensitive function :tada:
		max_steering_angle = steering_angles[0]
		
		assistance_factor = 90.0 / max_steering_angle
	
	steering_angles.clear()
	
	#TODO: Set these elsewhere, such as a settings file
	if car_controls.Use_Global_Control_Settings:
		car_controls = VitaVehicleSimulation.universal_controls
		
		GearAssist.assist_level = VitaVehicleSimulation.GearAssistant
	
	velocity = global_transform.basis.orthonormalized().transposed() * (linear_velocity)
	r_velocity = global_transform.basis.orthonormalized().transposed() * (angular_velocity)
	
	if Debug_Mode:
		mass = Weight / 10.0
	
	aerodynamics()
	
	#0.30592 is translation to ViVe units from meters
	#9.806 is gravity constant (because ViVe screws with gravity)
	#60.0 is likely the physics tick, so that the number is per second and not per physics tick
	#gforce = (linear_velocity - past_velocity) * ((0.30592 / 9.806) * physics_tick)
	gforce = (linear_velocity - past_velocity) * ((0.30592 / 9.806) * 60.0)
	past_velocity = linear_velocity
	
	gforce *= global_transform.basis.orthonormalized().transposed()
	
	new_controls()
	#old_controls()

	
	current_gear_ratio = 10.0
	
	shift_assist_delay -= 1
	
	transmission()
	
	gas_pedal = clampf(gas_pedal, 0.0, car_controls.MaxThrottle)
	brake_pedal = clampf(brake_pedal, 0.0, car_controls.MaxBrake)
	handbrake_pull = clampf(handbrake_pull, 0.0, car_controls.MaxHandbrake)
	steer = clampf(steer, -1.0, 1.0)
	
	
	#I graphed this function in a calculator, and it only curves significantly if max_steering_angle > 200
	#I've tried it, this calculation is functionally redundant, but imma leave it in because Authenticity:tm:
	#var uhh:float = pow((max_steering_angle / 90.0), 2.0) * 0.5
	
	#var steeroutput:float = steer * (absf(steer) * (uhh) + (1.0 - uhh))
	var steeroutput:float = steer * absf(steer) #without the redundant calculation
	
	if not is_zero_approx(steeroutput):
		steering_geometry = Vector3(-Steer_Radius / steeroutput, 0.0, AckermannPoint)
	else:
		steering_geometry = Vector3(0.0, 0.0, AckermannPoint)
	
	abs_pump -= 1    
	
	if abs_pump < 0:
		brake_allowed += ABS.pump_force
	else:
		brake_allowed -= ABS.pump_force
	
	brake_allowed = clampf(brake_allowed, 0.0, 1.0)
	
	brake_line = maxf(brake_pedal * brake_allowed, 0.0)
	
	lim_del -= 1
	
	if lim_del < 0:
		throttle -= (throttle - (gas_pedal / (tcs_weight * clutch_pedal + 1.0))) * (ThrottleResponse / clock_mult)
	else:
		throttle -= throttle * (ThrottleResponse / clock_mult)
	
	if rpm > RPMLimit:
		if throttle > ThrottleLimit:
			throttle = ThrottleLimit
			lim_del = LimiterDelay
	elif rpm < IdleRPM:
		throttle = maxf(throttle, ThrottleIdle)
	
	#var stab:float = 300.0
	
	#Determine power/torque output on specific rpm values, taking into account turbo and supercharger.
	
	if TurboEnabled:
		var throttle_spooling:float = (throttle - SpoolThreshold) / (1 - SpoolThreshold)
		
		if boosting > throttle_spooling:
			boosting = throttle_spooling
		else:
			boosting -= (boosting - throttle_spooling) * TurboEfficiency
		 
		turbo_psi += (boosting * rpm) / ((TurboSize / Compressor) * 60.9)
		
		turbo_psi = clampf(turbo_psi - (turbo_psi * BlowoffRate), -TurboVacuum, MaxPSI)
	
	elif SuperchargerEnabled:
		sc_rpm = rpm * SCRPMInfluence
		turbo_psi = clampf((sc_rpm / 10000.0) * BlowRate - SCThreshold, 0.0, MaxPSI)
	
	else:
		turbo_psi = 0.0
	
	#Wouldn't this be the other way around...?
	vvt = rpm > VVTRPM
	
	var torque:float = 0.0
	
	var torque_local:ViVeCarTorque
	if vvt:
		torque_local = torque_vvt
	else:
		torque_local = torque_norm
	
	var increased_rpm:float = maxf(rpm - torque_local.RiseRPM, 0.0)
	var reduced_rpm:float = maxf(rpm - torque_local.DeclineRPM, 0.0)
	
	torque = (rpm * torque_local.BuildUpTorque + torque_local.OffsetTorque + pow(increased_rpm, 2.0) * (torque_local.TorqueRise / 10000000.0)) * throttle
	
	torque += ( (turbo_psi * TurboAmount) * (EngineCompressionRatio * magic_1) )
	
	#Apply rpm reductions to the torque
	torque /= (reduced_rpm * (reduced_rpm * torque_local.DeclineSharpness + (1.0 - torque_local.DeclineSharpness))) * (torque_local.DeclineRate / 10000000.0) + 1.0
	
	torque /= pow(rpm, 2.0) * (torque_local.FloatRate / 10000000.0) + 1.0
	
	rpm_force = (rpm / (pow(rpm, 2.0) / (EngineFriction / clock_mult) + 1.0))
	if rpm < DeadRPM:
		torque = 0.0
		rpm_force /= 5.0
		stalled = 1.0 - rpm / DeadRPM
	else:
		stalled = 0.0
	
	rpm_force += (rpm * (EngineDrag / clock_mult))
	rpm_force -= (torque / clock_mult)
	rpm -= rpm_force * RevSpeed
	
	drivetrain()

func _process(_delta:float) -> void:
	if Debug_Mode:
		update_wheel_arrays()
		
		front_load = 0.0
		total_load = 0.0
		
		for front_wheel:ViVeWheel in front_wheels:
			front_load += front_wheel.directional_force.y
			total_load += front_wheel.directional_force.y
		for rear_wheel:ViVeWheel in rear_wheels:
			front_load -= rear_wheel.directional_force.y
			total_load += rear_wheel.directional_force.y
		
		if total_load > 0:
			weight_dist[0] = (front_load / total_load) * 0.5 + 0.5
			weight_dist[1] = 1.0 - weight_dist[0]
		
		readout_torque = multivariate()

const multivariation_inputs:PackedStringArray = [
"RiseRPM","TorqueRise","BuildUpTorque","EngineFriction",
"EngineDrag","OffsetTorque","RPM","DeclineRPM","DeclineRate",
"FloatRate","PSI","TurboAmount","EngineCompressionRatio",
"TEnabled","VVTRPM","VVT_BuildUpTorque","VVT_TorqueRise",
"VVT_RiseRPM","VVT_OffsetTorque","VVT_FloatRate",
"VVT_DeclineRPM","VVT_DeclineRate","SCEnabled",
"SCRPMInfluence","BlowRate","SCThreshold",
"DeclineSharpness","VVT_DeclineSharpness"
]

##Determine power/torque output on specific rpm values.
func multivariate() -> float:
	var psi:float = turbo_psi
	
	var return_torque:float = 0.0
	
	if SuperchargerEnabled:
		var maxpsi:float = psi
		var scrpm:float = rpm * SCRPMInfluence
		psi = clampf((scrpm / 10000.0) * BlowRate - SCThreshold, 0.0, maxpsi)
	
	if not SuperchargerEnabled and not TurboEnabled:
		psi = 0.0
	
	var torque_local:ViVeCarTorque 
	if rpm > VVTRPM:
		torque_local = torque_vvt
	else:
		torque_local = torque_norm
	
	var increased_rpm:float = maxf(rpm - torque_local.RiseRPM, 0.0)
	var reduced_rpm:float = maxf(rpm - torque_local.DeclineRPM, 0.0)
	
	return_torque = (rpm * torque_local.BuildUpTorque + torque_local.OffsetTorque)
	
	return_torque += (psi * TurboAmount) * (EngineCompressionRatio * magic_1)
	#+ pow(increased_rpm, 2.0) * (torque_local.TorqueRise / 10000000.0)) * throttle
	return_torque += pow(increased_rpm, 2.0) * (torque_local.TorqueRise / 10000000.0) * throttle
	
	return_torque /= (reduced_rpm * (reduced_rpm * torque_local.DeclineSharpness + (1.0 - torque_local.DeclineSharpness))) * (torque_local.DeclineRate / 10000000.0) + 1.0
	
	return_torque /= pow(rpm, 2.0) * (torque_local.FloatRate / 10000000.0) + 1.0
	
	return_torque -= rpm / (pow(rpm, 2.0) / EngineFriction + 1.0)
	return_torque -= rpm * EngineDrag
	
	return return_torque

