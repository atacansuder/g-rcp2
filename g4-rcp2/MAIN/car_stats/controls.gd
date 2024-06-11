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
##The asthetic name of the control preset
@export var ControlMapName:String = "Default"
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
@export var ActionNameSteerLeft:StringName = &"left"
##Action name for steering right by button.
@export var ActionNameSteerRight:StringName = &"right"
## Digital steering response rate.
@export var KeyboardSteerSpeed:float = 0.025
## Digital steering centering rate.
@export var KeyboardReturnSpeed:float = 0.05
## Digital return rate when steering from an opposite direction. 
@export var KeyboardCompensateSpeed:float = 0.1

## Reduces steering rate based on the vehicle’s speed.
##This helps with understeer.
@export var SteerAmountDecay:float = 0.015
## Enable Steering Assistance.
@export var EnableSteeringAssistance:bool = false
## Drift Help. The higher the value, the more the car will automatically center itself when drifting.
@export var SteeringAssistance:float = 1.0
## Drift Stability Help.
@export var SteeringAssistanceAngular:float = 0.12
##@experimental Simulate rack and pinion steering physics.
@export var LooseSteering:bool = false

#In C++, none of these will be indepenent variables: The setgets will map directly to their structs.
@export_group("Throttle")
##Action name for throttle.
@export var ActionNameThrottle:StringName = &"gas":
	set(new_name):
		ActionNameThrottle = new_name
		throttle_button.name = new_name
##If throttle is from a digital source (button).
@export var IsThrottleDigital:bool = true:
	set(new_value):
		IsThrottleDigital = new_value
		throttle_button.digital = new_value
## Throttle pressure rate.
@export var OnThrottleRate:float = 0.2:
	set(new_rate):
		OnThrottleRate = new_rate
		throttle_button.on_rate = new_rate
## Throttle depress rate.
@export var OffThrottleRate:float = 0.2:
	set(new_rate):
		OffThrottleRate = new_rate
		throttle_button.off_rate = new_rate
## Maximum throttle amount.
@export var MaxThrottle:float = 1.0:
	set(new_max):
		MaxThrottle = new_max
		throttle_button.maximum = new_max
@export_group("Brake")
##Action name for braking.
@export var ActionNameBrake:StringName = &"brake":
	set(new_name):
		ActionNameBrake = new_name
		brake_button.name = new_name
##If braking is from a digital source (button).
@export var IsBrakeDigital:bool = true:
	set(new_value):
		IsBrakeDigital = new_value
		brake_button.digital = new_value
## Brake pressure rate.
@export var OnBrakeRate:float = 0.05:
	set(new_rate):
		OnBrakeRate = new_rate
		brake_button.on_rate = new_rate
## Brake depress rate.
@export var OffBrakeRate:float = 0.1:
	set(new_rate):
		OffBrakeRate = new_rate
		brake_button.off_rate = new_rate
## Maximum brake_pressed amount.
@export var MaxBrake:float = 1.0:
	set(new_max):
		MaxBrake = new_max
		brake_button.maximum = new_max
@export_group("Handbrake")
##Action name for handbraking.
@export var ActionNameHandbrake:StringName = &"handbrake":
	set(new_name):
		ActionNameHandbrake = new_name
		handbrake_button.name = new_name
##If handbrake is from a digital source (button).
@export var IsHandbrakeDigital:bool = true:
	set(new_value):
		IsHandbrakeDigital = new_value
		handbrake_button.digital = new_value
## Handbrake pull rate.
@export var OnHandbrakeRate:float = 0.2:
	set(new_rate):
		OnHandbrakeRate = new_rate
		handbrake_button.on_rate = new_rate
## Handbrake push rate.
@export var OffHandbrakeRate:float = 0.2:
	set(new_rate):
		OffHandbrakeRate = new_rate
		handbrake_button.off_rate = new_rate
## Maximum handbrake amount.
@export var MaxHandbrake:float = 1.0:
	set(new_max):
		MaxHandbrake = new_max
		handbrake_button.maximum = new_max
@export_group("Clutch")
##Action name for clutching.
@export var ActionNameClutch:StringName = &"clutch":
	set(new_name):
		ActionNameClutch = new_name
		clutch_button.name = new_name
##If clutch is from a digital source (button).
@export var IsClutchDigital:bool = true:
	set(new_value):
		IsClutchDigital = new_value
		clutch_button.digital = new_value
## Clutch release rate.
@export var OnClutchRate:float = 0.2:
	set(new_rate):
		OnClutchRate = new_rate
		clutch_button.on_rate = new_rate
## Clutch engage rate.
@export var OffClutchRate:float = 0.2:
	set(new_rate):
		OffClutchRate = new_rate
		clutch_button.off_rate = new_rate
## Maxiumum clutch amount.
@export var MaxClutch:float = 1.0:
	set(new_max):
		MaxClutch = new_max
		clutch_button.maximum = new_max

#An internal class for buttons so that it's easier to handle them.
#When ViVe gets ported to C++, this will become a private struct
class ButtonWrapper:
	extends Resource
	static var clock_mult:float = 1.0
	var name:StringName
	var strength:float
	var digital:bool
	var on_rate:float
	var off_rate:float
	var minimum:float = 0.0 #unused
	var maximum:float = 1.0
	
	func poll(pressed:bool = Input.is_action_pressed(name)) -> float:
		if pressed:
			if digital:
				strength += on_rate / clock_mult
			else: 
				strength = Input.get_action_strength(name)
		else:
			strength -= off_rate / clock_mult
		strength = clampf(strength, minimum, maximum)
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

var shift_up_pressed:bool = false
var shift_down_pressed:bool = false
var gas_pressed:bool = false
var brake_pressed:bool = false
var handbrake_pressed:bool = false
var right:bool = false
var left:bool = false
var clutch_pressed:bool = false

var GearAssist:ViVeGearAssist = ViVeGearAssist.new()

var velocity:Vector3
var rvelocity:Vector3
var linear_velocity:Vector3

var front_left:ViVeWheel
var front_right:ViVeWheel


func _init() -> void:
	clock_mult = 1.0
	#ButtonWrapper.clock_mult = ViVeEnvironment.get_singleton().clock_mult #causes load error
	
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

##Apply loose steering effects.
func loose_steering() -> void:
	steer += steer_velocity
	
	if absf(steer) > 1.0:
		steer_velocity *= -0.5
	for front_wheel:ViVeWheel in [front_left,front_right]:
		steer_velocity += (front_wheel.directional_force.x * 0.00125) * front_wheel.Caster
		steer_velocity -= (front_wheel.stress * 0.0025) * (atan(absf(front_wheel.wv)) * front_wheel.angle)
		
		steer_velocity += steer * (front_wheel.directional_force.z * 0.0005) * front_wheel.Caster
		
		#if front_wheel.position.x > 0:
		#	steer_velocity += front_wheel.directional_force.z * 0.0001
		#else:
		#	steer_velocity -= front_wheel.directional_force.z * 0.0001
		
		steer_velocity += (front_wheel.directional_force.z * 0.0001 * signf(front_wheel.position.x))
		
		
		steer_velocity /= front_wheel.stress / (front_wheel.slip_percpre * (front_wheel.slip_percpre * 100.0) + 1.0) + 1.0

##Apply gear shifting assistance.
func apply_gear_assist() -> void:
	match GearAssist.assist_level:
		2: #automatically go "forwards" regardless of pedal pressed, using the current gear to decide direction.
			if gear == -1: #going in reverse
				gaspedal = throttle_button.poll(brake_pressed or revmatch)
				brakepedal = brake_button.poll(gas_pressed)
			else: #Forward moving gear
				gaspedal = throttle_button.poll((gas_pressed and not gasrestricted) or revmatch)
				brakepedal = brake_button.poll(brake_pressed)
		1: #go forward if gas_pressed is pressed, go backwards if brake_pressed is pressed.
			gaspedal = throttle_button.poll(gas_pressed and not gasrestricted or revmatch)
			brakepedal = brake_button.poll()
		0: #1, but also automatically disable clutch
			gasrestricted = false
			clutchin = false
			revmatch = false
			
			gaspedal = throttle_button.poll(gas_pressed and not gasrestricted or revmatch)
			brakepedal = brake_button.poll()
	
	handbrakepull = handbrake_button.poll()

##Apply the steering assistance in an input implementation 
func apply_assistance_factor(forward_force:float) -> void:
	if EnableSteeringAssistance and assistance_factor > 0.0:
		var max_steer:float = 1.0 / (forward_force * (SteerAmountDecay / assistance_factor) + 1.0)
		var assist_mult:float = SteeringAssistance * assistance_factor
		
		var assist_commence:float = minf(linear_velocity.length() / 10.0, 1.0)
		
		steer = (steer2 * max_steer) - (velocity.normalized().x * assist_commence) * assist_mult + rvelocity.y * assist_mult
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
func steer_analog(steer_axis:float) -> void:
	steer2 = clampf(steer_axis * SteerSensitivity, -1.0, 1.0)
	steer2 *= minf(absf(steer2) + 0.5, 1.0)


func controls(steer_axis:float = 0.0) -> void:
	#poll inputs
	gas_pressed = Input.is_action_pressed(throttle_button.name)
	brake_pressed = Input.is_action_pressed(brake_button.name)
	shift_up_pressed = Input.is_action_pressed(ActionNameShiftUp)
	shift_down_pressed = Input.is_action_pressed(ActionNameShiftDown)
	clutch_pressed = Input.is_action_pressed(ActionNameClutch)
	
	left = Input.is_action_pressed(ActionNameSteerLeft)
	right = Input.is_action_pressed(ActionNameSteerRight)
	var steer_direction:float = signf(Input.get_axis(ActionNameSteerLeft, ActionNameSteerRight))
	
	
	handbrakepull = handbrake_button.poll()
	clutchpedal = clutch_button.poll()
	
	#Something to do with loose steering?
	#if left:
	#	steer_velocity -= 0.01
	#elif right:
	#	steer_velocity += 0.01
	steer_velocity += 0.01 * steer_direction
	
	#loose steering
	if LooseSteering:
		loose_steering()
	
	#Controlled is not in scope, so
	var Controlled:bool = true
	
	if not Controlled:
		return
	
	#gear assistance for applying gas and braking
	match GearAssist.assist_level:
		2: #automatically go "forwards" regardless of pedal pressed, using the current gear to decide direction.
			if gear == -1: #going in reverse
				gaspedal = throttle_button.poll(brake_pressed or revmatch)
				brakepedal = brake_button.poll(gas_pressed)
			else: #Forward moving gear
				gaspedal = throttle_button.poll((gas_pressed and not gasrestricted) or revmatch)
				brakepedal = brake_button.poll(brake_pressed)
		1: #go forward if gas_pressed is pressed, go backwards if brake_pressed is pressed.
			gaspedal = throttle_button.poll(gas_pressed and not gasrestricted or revmatch)
			brakepedal = brake_button.poll()
		0: #1, but also automatically disable clutch
			gasrestricted = false
			clutchin = false
			revmatch = false
			
			gaspedal = throttle_button.poll(gas_pressed and not gasrestricted or revmatch)
			brakepedal = brake_button.poll()
	
	handbrakepull = handbrake_button.poll()
	
	#previously called "going"
	var forward_force:float
	
	#if the car is actively going left or right (and is not stationary)
	if (velocity.x > 0 and steer2 > 0) or (velocity.x < 0 and steer2 < 0):
		forward_force = maxf(velocity.z, 0.0)
	else:
		#forward_force = maxf(velocity.z / (absf(velocity.x) + 1.0), 0.0)
		forward_force = maxf(velocity.z / (absf(velocity.x)), 0.0)
	
	#handle steering
	if UseAnalogSteering:
		#analog steering takes steer_axis literally
		
		#apply steering sensitivity
		steer2 = clampf(steer_axis * SteerSensitivity, -1.0, 1.0)
		#???
		steer2 *= minf(absf(steer2) + 0.5, 1.0)
	else:
		#if we need to compensate for steering in the opposite direction of the car's steered direction
		var opposite_compensate:bool = (steer_direction > 0 and steer2 < 0) or (steer_direction < 0 and steer2 > 0)
		
		#if the car is not steering
		if is_zero_approx(steer_direction):
			#move steering towards 0
			steer2 = move_toward(steer2, 0.0, KeyboardReturnSpeed)
		elif opposite_compensate:
			#move steer2 towards the direction of steer_axis, but fast
			steer2 = move_toward(steer2, steer_direction, KeyboardCompensateSpeed)
		 #We're steering normally
		else:
			#move steer2 towards the direction of steer_axis
			steer2 = move_toward(steer2, steer_direction, KeyboardSteerSpeed)
		#clamp it between -1 and 1
		steer2 = clampf(steer2, -1.0, 1.0)
	
	#steering assistance
	if assistance_factor > 0.0:
		var max_steer:float = 1.0 / (forward_force * (SteerAmountDecay / assistance_factor) + 1.0)
		var assist_mult:float = 0.0
		
		if EnableSteeringAssistance:
			assist_mult = SteeringAssistance * assistance_factor
		
		var assist_commence:float = minf(linear_velocity.length() / 10.0, 1.0)
		
		steer = (steer2 * max_steer) - (velocity.normalized().x * assist_commence) * assist_mult + rvelocity.y * assist_mult
	else:
		steer = steer2
