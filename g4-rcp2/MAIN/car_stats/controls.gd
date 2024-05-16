extends Resource
##A class that handles and controls the car's control options.
class_name ViVeCarControls

##Which control type the car is going to be associated with.
enum ControlType {
	##Use the keyboard and mouse for control.
	CONTROLS_KEYBOARD_MOUSE,
	##Use the touchscreen for control.
	CONTROLS_TOUCH,
	##Use a connected game controller for control.
	CONTROLS_JOYPAD,
}
##Which ControlType is being used.
@export_enum("Keyboard and Mouse", "Keyboard", "Touch controls (Gyro)", "Joypad") var control_type:int = 0
## @depreciated
## Applies all control settings globally. This also affects cars that were already spawned.
@export var Use_Global_Control_Settings:bool = false
@export_group("Steering")
##Uses your cursor to steer the vehicle if keyboard and mouse controls are active.
@export var UseMouseSteering:bool = false
## @depreciated
## Uses your accelerometre to steer, typically on mobile devices that have them.
@export var UseAccelerometreSteering :bool = false
## Steering amplification on mouse and accelerometre steering.
@export var SteerSensitivity:float = 1.0
## Reduces steering rate based on the vehicle’s speed.
@export var SteerAmountDecay:float = 0.015 # understeer help
## Enable Steering Assistance
@export var EnableSteeringAssistance:bool = false
## Drift Help. The higher the value, the more the car will automatically center itself when drifting.
@export var SteeringAssistance:float = 1.0
## Drift Stability Help.
@export var SteeringAssistanceAngular:float = 0.12
##@experimental Simulate rack and pinion steering physics.
@export var LooseSteering :bool = false
@export_subgroup("Keyboard Steering")
## Keyboard steering response rate.
@export var KeyboardSteerSpeed:float = 0.025
## Keyboard steering centring rate.
@export var KeyboardReturnSpeed:float = 0.05
## Return rate when steering from an opposite direction.
@export var KeyboardCompensateSpeed:float = 0.1

@export_group("Digital to Analog")
@export_subgroup("Throttle")
## Throttle pressure rate.
@export var OnThrottleRate:float = 0.2
## Throttle depress rate.
@export var OffThrottleRate:float = 0.2
## Maximum throttle amount.
@export var MaxThrottle:float = 1.0
@export_subgroup("Brake")
## Brake pressure rate.
@export var OnBrakeRate:float = 0.05
## Brake depress rate.
@export var OffBrakeRate:float = 0.1
## Maximum brake amount.
@export var MaxBrake:float = 1.0
@export_subgroup("Handbrake")
## Handbrake pull rate.
@export var OnHandbrakeRate:float = 0.2
## Handbrake push rate.
@export var OffHandbrakeRate:float = 0.2
## Maximum handbrake amount.
@export var MaxHandbrake:float = 1.0
@export_subgroup("Clutch")
## Clutch release rate.
@export var OnClutchRate:float = 0.2
## Clutch engage rate.
@export var OffClutchRate:float = 0.2
## Maxiumum clutch amount.
@export var MaxClutch:float = 1.0

var clock_mult:float = 1.0
var gear:int = 0

var clutchin:bool = false
var gasrestricted:bool = false
var revmatch:bool = false
var gaspedal:float = 0.0
var brakepedal:float = 0.0
var handbrakepull:float = 0.0
var clutchpedal:float = 0.0
var steer:float = 0.0
var steer2:float = 0.0
var steer_velocity:float = 0.0
var assistance_factor:float = 0.0

var su:bool = false
var sd:bool = false
var gas:bool = false
var brake:bool = false
var handbrake:bool = false
var right:bool = false
var left:bool = false
var clutch:bool = false

var GearAssist:ViVeGearAssist = ViVeGearAssist.new()

var velocity:Vector3
var rvelocity:Vector3 = Vector3(0,0,0)
var linear_velocity:Vector3

var front_left:ViVeWheel
var front_right:ViVeWheel

##Apply a natural shift curve for digital inputs on analog values, such as gas and brake.
func digital_button_curve(digital:bool, analog:float, on_rate:float, off_rate:float) -> float:
	if digital:
		analog += on_rate / clock_mult
	else:
		analog -= off_rate / clock_mult
	return analog

##Apply loose steering effects.
func loose_steering() -> void:
	steer += steer_velocity
	
	if absf(steer) > 1.0:
		steer_velocity *= -0.5
	for i:ViVeWheel in [front_left,front_right]:
		steer_velocity += (i.directional_force.x * 0.00125) * i.Caster
		steer_velocity -= (i.stress * 0.0025) * (atan2(absf(i.wv), 1.0) * i.angle)
		
		steer_velocity += steer * (i.directional_force.z * 0.0005) * i.Caster
		
		if i.position.x > 0:
			steer_velocity += i.directional_force.z * 0.0001
		else:
			steer_velocity -= i.directional_force.z * 0.0001
		
		steer_velocity /= i.stress / (i.slip_percpre * (i.slip_percpre * 100.0) + 1.0) + 1.0

##Apply gear shifting assistance.
func apply_gear_assist() -> void:
	match GearAssist.assist_level:
		2:
			gaspedal = digital_button_curve(
			((gas and not gasrestricted and not gear == -1) or (brake and gear == -1) or revmatch),
			gaspedal, OnThrottleRate, OffThrottleRate)
			
			brakepedal = digital_button_curve(
			((brake and not gear == -1) or (gas and gear == -1)),
			brakepedal, OnBrakeRate, OffBrakeRate)
		1:
			gaspedal = digital_button_curve(
				(gas and not gasrestricted or revmatch), 
				gaspedal, OnThrottleRate, OffThrottleRate)
			
			brakepedal = digital_button_curve(
				brake, brakepedal, OnBrakeRate, OffBrakeRate)
		0:
			gasrestricted = false
			clutchin = false
			revmatch = false
			
			gaspedal = digital_button_curve(
				(gas and not gasrestricted or revmatch), 
				gaspedal, OnThrottleRate, OffThrottleRate)
			
			brakepedal = digital_button_curve(brake, brakepedal, OnBrakeRate, OffBrakeRate)
	handbrakepull = digital_button_curve(handbrake, handbrakepull, OnHandbrakeRate, OffHandbrakeRate)

##Apply the steering assistance in an input implementation 
func apply_assistance_factor(going:float) -> void:
	if EnableSteeringAssistance and assistance_factor > 0.0:
		var maxsteer:float = 1.0 / (going * (SteerAmountDecay / assistance_factor) + 1.0)
		var assist_mult:float = SteeringAssistance * assistance_factor
		
		var assist_commence:float = minf(linear_velocity.length() / 10.0, 1.0)
		
		steer = (steer2 * maxsteer) - (velocity.normalized().x * assist_commence) * assist_mult + rvelocity.y * assist_mult
	else:
		steer = steer2

##Apply calculations on digital inputs for steering, so that steering is smooth.
func steer_digital_curve() -> void:
	if right:
		if steer2 > 0:
			steer2 = move_toward(steer2, 1.0, KeyboardSteerSpeed)
		else:
			steer2 = move_toward(steer2, 1.0, KeyboardCompensateSpeed)
	elif left:
		if steer2 < 0:
			steer2 = move_toward(steer2, -1.0, KeyboardSteerSpeed)
		else:
			steer2 = move_toward(steer2, -1.0, KeyboardCompensateSpeed)
	else:
		steer2 = move_toward(steer2, 0.0, KeyboardReturnSpeed)
	steer2 = clampf(steer2, -1.0, 1.0)

##Apply calculations on an analog input for steering.
func steer_analog(input_axis:float) -> void:
	steer2 = clampf(input_axis * SteerSensitivity, -1.0, 1.0)
	steer2 *= minf(absf(steer2) + 0.5, 1.0)

##The control implementation for touchscreen + accelerometer
func controls_touchscreen() -> void:
	gas = Input.is_action_pressed("gas")
	brake = Input.is_action_pressed("brake")
	su = Input.is_action_just_pressed("shiftup")
	sd = Input.is_action_just_pressed("shiftdown")
	handbrake = Input.is_action_pressed("handbrake")
	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	
	if not UseMouseSteering:
		if left:
			steer_velocity -= 0.01
		elif right:
			steer_velocity += 0.01
	
	if LooseSteering:
		loose_steering()
	
	apply_gear_assist()
	
	var siding:float = absf(velocity.x)
	
	#Based on the syntax, I'm unsure if this is doing what it "should" do...?
	if (velocity.x > 0 and steer2 > 0) or (velocity.x < 0 and steer2 < 0):
		siding = 0.0
	
	var going:float = maxf(velocity.z / (siding + 1.0), 0.0)
	
	if UseMouseSteering:
		steer_analog(Input.get_accelerometer().x / 10.0)
	else:
		steer_digital_curve()
	
	apply_assistance_factor(going)

##The control implementation for game controllers (joypads)
func controls_joypad() -> void:
	const joypad_index:int = 0 #This can be switched to anything else later on for splitscreen
	
	su = Input.is_action_pressed("shiftup")
	sd = Input.is_action_pressed("shiftdown")
	gas = Input.is_action_pressed("gas")
	brake = Input.is_action_pressed("brake")
	handbrake = Input.is_action_pressed("handbrake")
	left = Input.is_joy_button_pressed(joypad_index, JOY_BUTTON_DPAD_LEFT)
	right = Input.is_joy_button_pressed(joypad_index, JOY_BUTTON_DPAD_RIGHT)
	
	if left:
		steer_velocity -= 0.01
	elif right:
		steer_velocity += 0.01
	
	gasrestricted = false
	clutchin = false
	revmatch = false
	
	gaspedal = Input.get_action_strength("gas")
	brakepedal = Input.get_action_strength("brake")
	handbrakepull = Input.get_action_strength("handbrake")
	
	var siding:float = absf(velocity.x)
	
	if (velocity.x > 0 and steer2 > 0) or (velocity.x < 0 and steer2 < 0):
		siding = 0.0
	
	var going:float = maxf(velocity.z / (siding + 1.0), 0)
	
	steer_analog(Input.get_axis("left", "right"))
	
	apply_assistance_factor(going)

##The control implementation for keyboard and mouse.
##This handles both keyboard alone, and keyboard with mouse steering.
func controls_keyboard_mouse(mouseposx:float = 0.0) -> void:
	if UseMouseSteering:
		gas = Input.is_action_pressed("gas_mouse")
		brake = Input.is_action_pressed("brake_mouse")
		su = Input.is_action_just_pressed("shiftup_mouse")
		sd = Input.is_action_just_pressed("shiftdown_mouse")
		handbrake = Input.is_action_pressed("handbrake_mouse")
	else:
		gas = Input.is_action_pressed("gas")
		brake = Input.is_action_pressed("brake")
		su = Input.is_action_just_pressed("shiftup")
		sd = Input.is_action_just_pressed("shiftdown")
		handbrake = Input.is_action_pressed("handbrake")
	
	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	
	if left:
		steer_velocity -= 0.01
	elif right:
		steer_velocity += 0.01
	
	if LooseSteering:
		loose_steering()
	
	apply_gear_assist()
	
	var siding:float = absf(velocity.x)
	
	#Based on the syntax, I'm unsure if this is doing what it "should" do...?
	if (velocity.x > 0 and steer2 > 0) or (velocity.x < 0 and steer2 < 0):
		siding = 0.0
	
	var going:float = maxf(velocity.z / (siding + 1.0), 0)
	
	if UseMouseSteering:
		steer_analog((mouseposx - 0.5) * 2.0)
	else:
		steer_digital_curve()
	
	apply_assistance_factor(going)
