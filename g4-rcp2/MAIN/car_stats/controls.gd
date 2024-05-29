extends Resource
##A class that handles and controls the car's control options.
class_name ViVeCarControls

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

## @depreciated
## Applies all control settings globally. This also affects cars that were already spawned.
@export var Use_Global_Control_Settings:bool = false
##Action name for shifting up.
@export var ActionNameShiftUp:StringName = &"shiftup"
##Action name for shifting down.
@export var ActionNameShiftDown:StringName = &"shiftdown"
@export_group("Steering")
##If true, analog steering will be used
@export var UseAnalogSteering:bool = false

@export_subgroup("Analog")
## Steering amplification on analog steering.
@export var SteerSensitivity:float = 1.0

@export_subgroup("Digital")
##Action name for steering left by button.
@export var Steer_Left_Button:StringName = &"left"
##Action name for steering right by button.
@export var Steer_Right_Button:StringName = &"right"
## Digital steering response rate.
@export var KeyboardSteerSpeed:float = 0.025
## Digital steering centring rate.
@export var KeyboardReturnSpeed:float = 0.05
## Digital return rate when steering from an opposite direction.
@export var KeyboardCompensateSpeed:float = 0.1

## Reduces steering rate based on the vehicle’s speed.
@export var SteerAmountDecay:float = 0.015 # understeer help
## Enable Steering Assistance
@export var EnableSteeringAssistance:bool = false
## Drift Help. The higher the value, the more the car will automatically center itself when drifting.
@export var SteeringAssistance:float = 1.0
## Drift Stability Help.
@export var SteeringAssistanceAngular:float = 0.12
##@experimental Simulate rack and pinion steering physics.
@export var LooseSteering:bool = false

@export_group("Throttle")
##Action name for throttle.
@export var ActionNameThrottle:StringName = &"gas"
##If throttle is from a digital source (button).
@export var IsThrottleDigital:bool = true
## Throttle pressure rate.
@export var OnThrottleRate:float = 0.2
## Throttle depress rate.
@export var OffThrottleRate:float = 0.2
## Maximum throttle amount.
@export var MaxThrottle:float = 1.0
@export_group("Brake")
##Action name for braking.
@export var ActionNameBrake:StringName = &"brake"
##If braking is from a digital source (button).
@export var IsBrakeDigital:bool = true
## Brake pressure rate.
@export var OnBrakeRate:float = 0.05
## Brake depress rate.
@export var OffBrakeRate:float = 0.1
## Maximum brake amount.
@export var MaxBrake:float = 1.0
@export_group("Handbrake")
##Action name for handbraking.
@export var ActionNameHandbrake:StringName = &"handbrake"
##If handbrake is from a digital source (button).
@export var IsHandbrakeDigital:bool = true
## Handbrake pull rate.
@export var OnHandbrakeRate:float = 0.2
## Handbrake push rate.
@export var OffHandbrakeRate:float = 0.2
## Maximum handbrake amount.
@export var MaxHandbrake:float = 1.0
@export_group("Clutch")
##Action name for clutching.
@export var ActionNameClutch:StringName = &"clutch"
##If clutch is from a digital source (button).
@export var IsClutchDigital:bool = true
## Clutch release rate.
@export var OnClutchRate:float = 0.2
## Clutch engage rate.
@export var OffClutchRate:float = 0.2
## Maxiumum clutch amount.
@export var MaxClutch:float = 1.0

#An internal handler for buttons so that it's easier to handle them.
#When ViVe gets ported to C++, this will become an internal struct
class ButtonWrapper:
	extends Resource
	static var clock_mult:float = 1.0
	var name:StringName
	var strength:float
	var digital:bool
	var on_rate:float
	var off_rate:float
	var minimum:float #unused
	var maximum:float
	
	func poll() -> float:
		if digital:
			poll_digital_ease(Input.is_action_pressed(name))
		else:
			strength = Input.get_action_strength(name)
		strength = clampf(strength, minimum, maximum)
		return strength
	
	func poll_digital_ease(pressed:bool) -> float:
		if pressed:
			strength += on_rate / clock_mult
		else:
			strength -= off_rate / clock_mult
		return strength

var throttle_button:ButtonWrapper = ButtonWrapper.new()
var brake_button:ButtonWrapper = ButtonWrapper.new()
var handbrake_button:ButtonWrapper = ButtonWrapper.new()
var clutch_button:ButtonWrapper = ButtonWrapper.new()

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

var shiftUp:bool = false
var shiftDown:bool = false
var gas:bool = false
var brake:bool = false
var handbrake:bool = false
var right:bool = false
var left:bool = false
var clutch:bool = false

var GearAssist:ViVeGearAssist = ViVeGearAssist.new()

var velocity:Vector3
var rvelocity:Vector3
var linear_velocity:Vector3

var front_left:ViVeWheel
var front_right:ViVeWheel


func _init() -> void:
	ButtonWrapper.clock_mult = ViVeEnvironment.get_singleton().clock_mult
	
	throttle_button.name = ActionNameThrottle
	throttle_button.digital = IsThrottleDigital
	throttle_button.on_rate = OnThrottleRate
	throttle_button.off_rate = OffThrottleRate
	throttle_button.maximum = MaxThrottle
	#throttle_button.minimum = MinThrottle
	
	brake_button.name = ActionNameBrake
	brake_button.digital = IsBrakeDigital
	brake_button.on_rate = OnBrakeRate
	brake_button.off_rate = OffBrakeRate
	brake_button.maximum = MaxBrake
	#throttle_button.minimum = MinBrake
	
	handbrake_button.name = ActionNameHandbrake
	handbrake_button.digital = IsHandbrakeDigital
	handbrake_button.on_rate = OnHandbrakeRate
	handbrake_button.off_rate = OffHandbrakeRate
	handbrake_button.maximum = MaxHandbrake
	#handbrake_button.minimum = MinHandbrake
	
	clutch_button.name = ActionNameClutch
	clutch_button.digital = IsClutchDigital
	clutch_button.on_rate = OnClutchRate
	clutch_button.off_rate = OffClutchRate
	clutch_button.maximum = MaxClutch
	#clutch_button.minimum = MinClutch

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
func apply_assistance_factor(forward_force:float) -> void:
	if EnableSteeringAssistance and assistance_factor > 0.0:
		var maxsteer:float = 1.0 / (forward_force * (SteerAmountDecay / assistance_factor) + 1.0)
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


func controls(input_axis:float = 0.0) -> void:
	#poll inputs
	left = Input.is_action_pressed(Steer_Left_Button)
	right = Input.is_action_pressed(Steer_Right_Button)
	shiftUp = Input.is_action_pressed(ActionNameShiftUp)
	shiftDown = Input.is_action_pressed(ActionNameShiftDown)
	gas = Input.is_action_pressed(throttle_button.name)
	brake = Input.is_action_pressed(brake_button.name)
	handbrakepull = handbrake_button.poll()
	clutchpedal = clutch_button.poll()
	
	
	#Something to do with loose steering?
	if not UseAnalogSteering:
		if left:
			steer_velocity -= 0.01
		elif right:
			steer_velocity += 0.01
	
	#loose steering
	if LooseSteering:
		loose_steering()
	
	#gear assistance for applying gas and braking
	match GearAssist.assist_level:
		2: #automatically go "forwards" regardless of pedal pressed, using the current gear to decide direction.
			if gear == -1:
				gaspedal = brake_button.poll()
				brakepedal = throttle_button.poll()
			else:
				throttle_button.poll()
				brakepedal = brake_button.poll()
			
			
			if (gas and not gasrestricted and gear != -1) or (brake and gear == -1) or revmatch:
				pass
			
			gaspedal = throttle_button.poll_digital_ease((gas and not gasrestricted and gear != -1) or (brake and gear == -1) or revmatch)
			brakepedal = brake_button.poll_digital_ease((brake and gear != -1) or (gas and gear == -1))
		1: #go forward if gas is pressed, go backwards if brake is pressed.
			if not gasrestricted or revmatch:
				gaspedal = throttle_button.poll_digital_ease(gas and not gasrestricted or revmatch)
			brakepedal = brake_button.poll()
		0: #1, but also automatically disable clutch
			gasrestricted = false
			clutchin = false
			revmatch = false
			gaspedal = throttle_button.poll_digital_ease(gas and not gasrestricted or revmatch)
			brakepedal = brake_button.poll()
	
	#previously called "going"
	var forward_force:float
	
	#if the car is actively going left or right (and is not stationary)
	if (velocity.x > 0 and steer2 > 0) or (velocity.x < 0 and steer2 < 0):
		forward_force = maxf(velocity.z, 0.0)
	else:
		forward_force = maxf(velocity.z / (absf(velocity.x) + 1.0), 0.0)
	
	#handle steering
	if UseAnalogSteering:
		steer2 = clampf(input_axis * SteerSensitivity, -1.0, 1.0)
		steer2 *= minf(absf(steer2) + 0.5, 1.0)
	else:
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
	
	#steering assistance
	if EnableSteeringAssistance and assistance_factor > 0.0:
		var maxsteer:float = 1.0 / (forward_force * (SteerAmountDecay / assistance_factor) + 1.0)
		var assist_mult:float = SteeringAssistance * assistance_factor
		
		var assist_commence:float = minf(linear_velocity.length() / 10.0, 1.0)
		
		steer = (steer2 * maxsteer) - (velocity.normalized().x * assist_commence) * assist_mult + rvelocity.y * assist_mult
	else:
		steer = steer2

##The control implementation for touchscreen + accelerometer
func controls_touchscreen() -> void:
	gas = Input.is_action_pressed("gas")
	brake = Input.is_action_pressed("brake")
	shiftUp = Input.is_action_just_pressed("shiftup")
	shiftDown = Input.is_action_just_pressed("shiftdown")
	handbrake = Input.is_action_pressed("handbrake")
	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	
	if not UseAnalogSteering:
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
	
	var forward_force:float = maxf(velocity.z / (siding + 1.0), 0.0)
	
	if UseAnalogSteering:
		steer_analog(Input.get_accelerometer().x / 10.0)
	else:
		steer_digital_curve()
	
	apply_assistance_factor(forward_force)

##The control implementation for game controllers (joypads)
func controls_joypad() -> void:
	const joypad_index:int = 0 #This can be switched to anything else later on for splitscreen
	
	shiftUp = Input.is_action_pressed("shiftup")
	shiftDown = Input.is_action_pressed("shiftdown")
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
	
	var forward_force:float = maxf(velocity.z / (siding + 1.0), 0)
	
	steer_analog(Input.get_axis("left", "right"))
	
	apply_assistance_factor(forward_force)

##The control implementation for keyboard and mouse.
##This handles both keyboard alone, and keyboard with mouse steering.
func controls_keyboard_mouse(mouseposx:float = 0.0) -> void:
	if UseAnalogSteering:
		gas = Input.is_action_pressed("gas_mouse")
		brake = Input.is_action_pressed("brake_mouse")
		shiftUp = Input.is_action_just_pressed("shiftup_mouse")
		shiftDown = Input.is_action_just_pressed("shiftdown_mouse")
		handbrake = Input.is_action_pressed("handbrake_mouse")
	else:
		gas = Input.is_action_pressed("gas")
		brake = Input.is_action_pressed("brake")
		shiftUp = Input.is_action_just_pressed("shiftup")
		shiftDown = Input.is_action_just_pressed("shiftdown")
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
	
	var forward_force:float = maxf(velocity.z / (siding + 1.0), 0)
	
	if UseAnalogSteering:
		steer_analog((mouseposx - 0.5) * 2.0)
	else:
		steer_digital_curve()
	
	apply_assistance_factor(forward_force)
