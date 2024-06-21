extends RayCast3D
##A class representing the wheel of a [ViVeCar].
##Each wheel independently calculates its suspension and other values every physics process frame.
class_name ViVeWheel

##Allows this wheel to steer.
@export var Steer:bool = true
@export_group("Differed Calculations")
##Finds a wheel to correct itself to another, in favour of differential mechanics. 
##Both wheels need to have their properties proposed to each other.
@export var Differed_Wheel_Path:NodePath = ""
##Connects a sway bar to the opposing axle. 
##Both wheels should have their properties proposed to each other.
@export var SwayBarConnection:NodePath = ""

@export var Solidify_Axles:NodePath = NodePath()
@export_group("")

##Power Bias (when driven).
@export var W_PowerBias:float = 1.0
##The [ViVeTyreSettings] for this wheel.
@export var TyreSettings:ViVeTyreSettings = ViVeTyreSettings.new():
	set(new_settings):
		TyreSettings = new_settings
		TyreSettings.wheel_parent = self
		set_physical_stats()
##The [TyreCompoundSettings] for this wheel.
@export var CompoundSettings:TyreCompoundSettings = TyreCompoundSettings.new():
	set(new_settings):
		CompoundSettings = new_settings
		CompoundSettings.wheel_parent = self
		set_physical_stats()
##Represents information about the axle the [ViVeWheel] is attached to in the car.
@export var AxleSettings:ViVeWheelAxle = ViVeWheelAxle.new()
##The wheel suspension values for this [ViVeWheel].
@export var Suspension:ViVeWheelSuspension = ViVeWheelSuspension.new()

@export_group("Alignment")
##Camber angle, in degrees.
@export var Camber:float = 0.0
##Caster angle, in degrees.
@export var Caster:float = 0.0
##Toe-in Angle.
@export var Toe:float = 0.0

@export_group("Suspension")
##Spring Force.
@export var S_Stiffness:float = 47.0
##Compression Dampening.
@export var S_Damping:float = 3.5
##Rebound Dampening.
@export var S_ReboundDamping:float = 3.5
##Suspension Deadzone.
@export var S_RestLength:float = 0.0
##Compression Barrier.
@export var S_MaxCompression:float = 0.5
##Anti-roll Stiffness.
@export var AR_Stiff:float = 0.5
##Anti-roll Reformation Rate.
@export var AR_Elast:float = 0.1
##Used in calculating suspension.
@export var A_InclineArea:float = 0.2
##Used in calculating suspension.
@export var A_ImpactForce:float = 1.5

@export_group("Braking and Handbraking")
##Brake force/torque.
@export var B_Torque:float = 15.0
##Brake bias.
@export var B_Bias:float = 1.0
##Leave this at 1.0 unless you have a heavy vehicle with large wheels, set it higher depending on how big it is.
@export var B_Saturation:float = 1.0
##Handbrake Bias. 
##The handbrake input value is multiplied by this:
##a value over 1 increases effectiveness, and a value lower than 1 makes it fractionally as effective.
@export var HB_Bias:float = 0.0

@export_group("Extras")
##Allows the Anti-lock Braking System to monitor this wheel.
@export var ContactABS:bool = true

@export var ESP_Role:String = ""
##@experimental
####Allows the BTCS to monitor this wheel.
@export var ContactBTCS:bool = false
##@experimental
####Allows the TTCS to monitor this wheel.
@export var ContactTTCS:bool = false

##The parent [ViVeCar]
@onready var car:ViVeCar = get_parent()
##The base node for debugging geometry.
@onready var geometry:MeshInstance3D = $"geometry"

@onready var velo_1:Marker3D = $"velocity"
@onready var velo_2:Marker3D = $"velocity2"
@onready var velo_1_step:Marker3D = $"velocity/step"
@onready var velo_2_step:Marker3D = $"velocity2/step"
@onready var anim:Marker3D = $"animation"

@onready var anim_camber:Marker3D = $"animation/camber"

@onready var anim_camber_wheel:Marker3D = $"animation/camber/wheel"
##The paired wheel for differed calculations
@onready var differed_wheel_node:ViVeWheel = null
##The paired wheel for sway bar calculations
@onready var sway_bar_wheel:ViVeWheel = null
##The paired wheel for solidifying axles
@onready var solidify_axles_wheel:ViVeWheel = null

const rigidity:float = 0.67
#I don't know what these are. Any ideas are welcome!
const magic_number_a:float = 1.15296


##This appears to be for some sort of conversion between radians and degrees.
const conversion_1: float = 90.0
##This is used to get around several "divide by 0" errors in code
const div_by_0_fix:float = 1.0

##The expected variable name for the ViVeSurfaceVariables variable in 
##whatever surface this wheel comes into contact with.
const external_ground_vars:StringName = &"ground_vars"

#identifiers for the performance singleton
const perf_stress:StringName = &"Stress"
const perf_wv:StringName = &"Wheel Spin Velocity"
const perf_suspension:StringName = &"Suspension Force"

#These are all values that usually don't need to be calculated repeatedly

##This is a multiplier so that values can flip to match the side of the car the wheel is on.
var car_side:float = signf(position.x)
##This is Toe * car_side
var relative_toe:float = 0.0
##Wheel size.
var w_size:float = 1.0
##Size read of the wheel. This is w_size but capped to 1.0 or higher.
var w_size_read:float = 1.0
##Weight of the wheel. This is w_size squared.
var w_weight:float = 0.0
##Weight read of the wheel. This is w_weight but capped to 1.0 or higher.
var w_weight_read:float = 0.0
##Maximum grip of the tyre.
var tyre_maxgrip:float = 0.0
##Cached value of "physics/common/physics_ticks_per_second", for compensating for varying physics ticks.
var physics_tick:float = 60.0
##The power tolerance on differential distributed power. This is computed using some magic numbers and ClutchGrip
var diff_dist_power_tolerance:float = 0.0
##The name of the wheel in the Performance singleton
var wheel_name:StringName

#values that are used and changed repeatedly at runtime

##This is the result of the fastest wheel's raw wheel velocity, 
##given the current drivetrain RPM, being distributed to this 
##wheel's raw wheel velocity, also given the current drivetrain RPM.
var distributed_differential_power:float = 0.0
##Velocity of the wheel(?)
var wv:float = 0.0
##Velocity of the wheel differed(?)
var wv_diff:float = 0.0
##This is related to the runtime computed stiffness of the tyre.
##Appears to be constant, so possibly not fully implemented?
var effectiveness:float = 0.0
##Only ever set in suspension calculation.
##It's in radians.
var angle:float = 0.0
##Related to the differential wheel
var differed_wheel_lock:float = 0.0
##Absolute velocity of the wheel(?)
var absolute_wv:float = 0.0
##Used in differential calculations
var output_wv_diff:float = 0.0
##[wv] from the last frame.
var output_wv:float = 0.0

##This is likely some value closely related to tyre deflection or the contact patch.
##Also closely related to differentials.
var offset:float = 0.0
##If this wheel is a driving wheel (as dictated by the parent [ViVeCar], this value gets set to [W_PowerBias] by the parent [ViVeCar].
##Otherwise, it stays at 0.
var live_power_bias:float = 0.0
##Seems tied to [wv]
var wheelpower:float = 0.0
##This is set to the absolute value of [wheelpower] after braking calculations are applied, and is used in differentials.
var global_abs_wheelpower:float = 0.0
##This is related to the [grip] of the wheel, and is tied to the stress_total var on the parent [ViVeCar].
var stress:float = 0.0
##Set in SwayBar calculations using [suspension_compression], and is used in calculating some values for suspension().
##This value is clamped between -1 and 1
var sway_bar_compression_offset:float = 0.0
##Some sort of compression factor, set during suspension() and used in sway bar calculations.
var suspension_compression:float = 0.0
##The Camber with Caster values properly factored into it.
##This is in degrees.
var camber_w_caster:float = 0.0
##Appears to be a counterbalance angle to camber_w_caster.
##This is in degrees.
var cambered:float = 0.0


##The volume of the wheel rolling/skidding.
var roll_vol:float = 0.0
##The skidding volume.
##Specifically related to the volume of peel2.
var skid_volume:float = 0.0

var velocity:Vector3 = Vector3.ZERO
##Used in calculating various tyre deformation variables
var velocity2:Vector3 = Vector3.ZERO
##This is compensation for the forward velocity/grip on a slope being affected by the [tyre_stiffness].
var compensate:float = 0.0
##The axle position (of the geometry).
##This is exposed for use in differed calculations, and is updated right before said calculations.
var axle_position:float = 0.0
##This is the effective bumpiness of the ground, given the car's speed.
##This randomly fluctuates between 0 and 1.
var ground_bumpiness:float = 0.0
##Used to fluctuate [ground_bumpiness].
var ground_bumping_up:bool = false

##The [ViVeSurfaceVars] recieved from the ground, with certain values edited at
##the time of recieving.
var surface_vars:ViVeSurfaceVars = ViVeSurfaceVars.new()
##The last collision point reported by the underlying RayCast3D
var hitposition:Vector3 = Vector3.ZERO

var tyre_stiffness:float

##This is [tyre_stiffness] from the previous frame.
var cache_tyrestiffness:float = 0.0
##This is a cached value of the vertical friction applied on the tyre.
var cache_friction_action:float = 0.0
##The directional force of the tire. 
##This is the "sum" that is used to apply physics impulses to the car.
var directional_force:Vector3 = Vector3.ZERO
##Used in calculating tyre smoke and tyre tracks
var slip_perc:Vector2 = Vector2.ZERO
##Used in calculating tyre smoke.
var slip_perc2:float = 0.0
##Has a direct play in steering input calculations.
var slip_percpre:float = 0.0

var velocity_last:Vector3 = Vector3.ZERO

var velocity2_last:Vector3 = Vector3.ZERO
##Set to true when the wheel registers itself to the performance singleton
var debug_registered:bool = false

var elasticity:float

var damping:float

var damping_rebound:float


func _ready() -> void:
	physics_tick = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0)
	
	if Differed_Wheel_Path:
		differed_wheel_node = car.get_node(Differed_Wheel_Path)
		if not is_instance_valid(differed_wheel_node):
			push_error("Wheel ", self.name,": Differed Wheel set, but could not be found")
	
	if SwayBarConnection:
		sway_bar_wheel = car.get_node(SwayBarConnection)
		if not is_instance_valid(sway_bar_wheel):
			push_error("Wheel ", self.name,": SwayBarConnection set, but could not be found")
	
	if Solidify_Axles:
		solidify_axles_wheel = car.get_node(Solidify_Axles)
		if not is_instance_valid(solidify_axles_wheel):
			push_error("Wheel ", self.name,": SolidifyAxles set, but could not be found")
	
	set_physical_stats()

func register_debug() -> void:
	wheel_name = car.car_name + &": " + name
	if debug_registered:
		return
	
	Performance.add_custom_monitor(wheel_name + &"/" + perf_stress, get, ["stress"])
	#Performance.add_custom_monitor(wheel_name + &"/" + perf_suspension, suspension)
	Performance.add_custom_monitor(wheel_name + &"/" + perf_wv, get, ["wv"])
	#Performance.add_custom_monitor(wheel_name + &"/", get, [""])
	
	debug_registered = true

func _exit_tree() -> void:
	Performance.remove_custom_monitor(wheel_name + &"/" + perf_stress)
	#Performance.remove_custom_monitor(wheel_name + &"/" + perf_suspension)
	Performance.remove_custom_monitor(wheel_name + &"/" + perf_wv)
	#Performance.remove_custom_monitor(wheel_name + &"/" + perf_stress)

##Apply power. 
func power() -> void:
	distributed_differential_power *= pow(car.clutch_contact_percent, 2.0) / (car.current_clutch_stability)
	
	var tolerated_dist_diff_power:float = clampf(distributed_differential_power, -diff_dist_power_tolerance, diff_dist_power_tolerance)
	
	car.power_bias_total += live_power_bias
	car.stress_total += stress * live_power_bias
	
	if car.previous_power_bias_total > 0.0:
		if car.rpm > car.DeadRPM:
			const local_magic_number:float = 2.5
			#slow down the wheel by the effects of the driveshaft weight 
			#(which in itself is divided by the overall power of all the powered wheels rolling), 
			#and its own weight
			wheelpower -= (((tolerated_dist_diff_power / car.current_gear_driveshaft_inertia) / (car.previous_power_bias_total / local_magic_number)) * live_power_bias) / w_weight
		
		car.resistance += (((tolerated_dist_diff_power * 10.0) / car.previous_power_bias_total) * live_power_bias)


##This runs computations for differentials between two wheels.
func differentials() -> void:
	if car.differential_lock_influence > 0.0 and is_instance_valid(differed_wheel_node):
		var diff_lock_influence_amplified:float = (car.differential_lock_influence * 16.0)
		
		differed_wheel_lock = differed_wheel_node.global_abs_wheelpower / diff_lock_influence_amplified + div_by_0_fix
		
		absolute_wv = output_wv + (offset * differed_wheel_lock)
		
		assert(is_equal_approx(output_wv, output_wv_diff), "These are actually different") #they're not
		
		var distance_2:float = absf(absolute_wv - differed_wheel_node.output_wv_diff) / diff_lock_influence_amplified
		distance_2 += differed_wheel_node.global_abs_wheelpower / diff_lock_influence_amplified
		
		distance_2 = maxf(distance_2, differed_wheel_lock)
		
		distance_2 += 1.0 / cache_tyrestiffness
		if distance_2 > 0.0:
			wheelpower += -((output_wv_diff - differed_wheel_node.output_wv_diff) / distance_2)

##Run logic for the Sway Bar connection, if one is properly set.
func sway_bar() -> void:
	if is_instance_valid(sway_bar_wheel): 
		sway_bar_compression_offset = clampf(suspension_compression - sway_bar_wheel.suspension_compression, -1.0, 1.0)

##Factor in the effects of braking and/or handbraking to the velocity of the wheel.
func apply_braking() -> void:
	var total_brake_effect:float = minf(car.brake_line * B_Bias + car.handbrake_pull * HB_Bias, 1.0)
	#Get brake power by multiplying the total_brake_effect factor by the brake force, 
	#and dividing that result by the weight of the wheel
	var brake_power:float = (B_Torque * total_brake_effect) / w_weight_read
	
	if not car.actualgear == 0:
		if car.previous_power_bias_total > 0.0:
			brake_power += ((car.stalled * (live_power_bias / car.current_gear_driveshaft_inertia)) * car.clutch_contact_percent) * (((5.0 / car.RevSpeed) / (car.previous_power_bias_total / 2.5)) / w_weight_read)
	if brake_power > 0.0:
		#if absf(absolute_wv) > 0.0:
		if not is_zero_approx(absolute_wv):
			var distanced:float = absf(absolute_wv) / brake_power
			distanced -= car.brake_line
			distanced = maxf(distanced, differed_wheel_lock * (w_size_read / B_Saturation))
			#wheelpower += - absolute_wv / distanced
			wheelpower -= absolute_wv / distanced
		else:
			#wheelpower += -absolute_wv
			wheelpower -= absolute_wv
	
	global_abs_wheelpower = absf(wheelpower)

func _physics_process(_delta:float) -> void:
	var last_position:Vector3 = position
	
	#Do steer rotation things if this wheel is a steering wheel
	#if Steer and absf(car.effective_steer) > 0:
	if Steer and not is_zero_approx(car.effective_steer):
		
		look_at_from_position(position, Vector3(car.steer_to_direction, rotation.y, car.AckermannPoint), Vector3.UP)
		position = last_position
		
		rotate_y(-(deg_to_rad(90) * signf(car.effective_steer)))
		
		#Using local rotation for literal_steer_rotation *could* be used for some sort of steer centering assist
		
		#this wrap is a fix for the "wheel jitter". I am not sure why it sometimes completely flips 
		#out (literally), but this check does correct it, because it flips to almost if not exactly pi (or -pi).
		var literal_steer_rotation:float = wrapf(global_rotation.y, -3.0, 3.0) #3 is a little less than PI
		
		#calculations for steering_angles
		#look_at_from_position(position, Vector3(car.Steer_Radius, 0.0, car.AckermannPoint), Vector3.UP)
		look_at_from_position(position, Vector3(car.Steer_Radius, rotation.y, car.AckermannPoint), Vector3.UP)
		position = last_position
		
		rotate_y(deg_to_rad(90.0))
		
		car.steering_angles.append(global_rotation_degrees.y)
		
		rotation = Vector3.ZERO
		
		rotation.y = literal_steer_rotation
		
		rotation_degrees.y += relative_toe
	else:
		rotation_degrees = Vector3(0.0, relative_toe, 0.0)
	
	position = last_position
	
	camber_w_caster = Camber + Caster * rotation.y * car_side
	
	directional_force = Vector3.ZERO
	
	#You don't [i]really[/i] need these to be repeatedly calculated under 
	#normal circumstances (see the desc of set_physical_stats), so it's
	#disabled unless debug is on.
	if car.Debug_Mode:
		set_physical_stats()
	
	
	#Sync positions. Without this, the car is very bouncy.
	
	#velo_1 will be where the wheel node is
	velo_1.position = Vector3.ZERO
	#velo_2 will be where the debug geometry is
	velo_2.global_position = geometry.global_position
	
	#velo_1_step is now where velocity_last is, ignoring relative positioning from velo_1
	velo_1_step.global_position = velocity_last
	#velo_1_step is now where velocity2_last is, ignoring relative positioning from velo_2
	velo_2_step.global_position = velocity2_last
	
	#velocity_last is now where velo_1 is globally, ignoring relative positioning from wheel
	velocity_last = velo_1.global_position
	#velocity2_last is now where velo_2 is globally, ignoring relative positioning from wheel
	velocity2_last = velo_2.global_position
	
	#60 here is likely the physics tick per second
	
	#velocity is the negative relative position of velo_1_step, times 60
	velocity = -velo_1_step.position * 60.0
	#velocity2 is the negative relative position of velo_2_step, times 60
	velocity2 = -velo_2_step.position * 60.0
	
	#both rotations are set to 0
	velo_1.rotation = Vector3.ZERO
	velo_2.rotation = Vector3.ZERO
	
	# VARS
	
	elasticity = Suspension.SpringStiffness * (Suspension.AntiRollElasticity * sway_bar_compression_offset + 1.0)
	damping = Suspension.CompressionDampening * (Suspension.AntiRollStiffness * sway_bar_compression_offset + 1.0)
	damping_rebound = Suspension.ReboundDampening * (Suspension.AntiRollStiffness * sway_bar_compression_offset + 1.0)
	
	sway_bar()
	
	#previously "deviding"
	var surface_deform_factor:float = (Vector2(velocity.x, velocity.z).length() / 50.0 + 0.5) * CompoundSettings.DeformFactor
	
	surface_deform_factor /= surface_vars.ground_stiffness + surface_vars.fore_stiffness * CompoundSettings.ForeStiffness
	surface_deform_factor = maxf(surface_deform_factor, 1.0)
	
	tyre_stiffness = ((TyreSettings.static_wheel_stiffness / surface_deform_factor) * ((TyreSettings.AirPressure / 30.0) * 0.1 + 0.9) ) * CompoundSettings.Stiffness + effectiveness
	
	tyre_stiffness = maxf(tyre_stiffness, 1.0)
	
	cache_tyrestiffness = tyre_stiffness
	
	absolute_wv = output_wv + (offset * differed_wheel_lock) - compensate * magic_number_a
	#so, wv from last frame
	output_wv_diff = output_wv
	
	wheelpower = 0.0
	
	apply_braking()
	
	#moving this check into this function (should perform better)
	if not is_zero_approx(live_power_bias):
		power()
	differentials()
	
	differed_wheel_lock = 1.0
	offset = 0.0
	
	var grip:float
	
	var gravity_incline:Vector3
	#the tire scrub, ie. how the contact patch deforms as the tyre is stretched when moving.
	var tire_scrub:Vector2
	
	
	# WHEEL
	if is_colliding():
		#Apply ground surface variables
		var collider:Node3D = get_collider()
		if external_ground_vars in collider:
			var extern_surf:ViVeSurfaceVars = collider.get(external_ground_vars)
			surface_vars = extern_surf
			surface_vars.drag *= pow(CompoundSettings.GroundDragAffection, 2.0)
			surface_vars.ground_builduprate *= CompoundSettings.BuildupAffection
			surface_vars.ground_bump_frequency_random += 1.0
		
		if ground_bumping_up:
			ground_bumpiness -= surface_vars.get_random_bump() * (velocity.length() * 0.001)
			if ground_bumpiness < 0.0:
				ground_bumpiness = 0.0
				ground_bumping_up = false
		else:
			ground_bumpiness += surface_vars.get_random_bump() * (velocity.length() * 0.001)
			if ground_bumpiness > 1.0:
				ground_bumpiness = 1.0
				ground_bumping_up = true
		
		#Y force is dictated by suspension
		var suspension_force:float = suspension()
		#directional_force.y = suspension()
		
		# FRICTION
		
		#Grip is the result of gravity multiplied by the tyre grip, 
		#times the ground and fore friction times the compound fore friction
		grip = (suspension_force * tyre_maxgrip) * (surface_vars.ground_friction + surface_vars.fore_friction * CompoundSettings.ForeFriction)
		stress = grip
		
		#the deformation from the tyre being pressed when factoring in its velocity counteracting that
		var rolling_deformation:Vector2 = Vector2(velocity2.x, velocity2.z - wv * w_size) #distx, disty
		wv += (wheelpower * (1.0 - (1.0 / tyre_stiffness)))
		
		offset = clampf(rolling_deformation.y / w_size, -grip, grip)
		
		tire_scrub = Vector2(velocity2.x, velocity2.z - (wv * w_size) / (surface_vars.drag + div_by_0_fix))
		
		gravity_incline = (geometry.global_transform.basis.orthonormalized().transposed() * Vector3.UP)
		
		compensate = gravity_incline.z * (suspension_force / tyre_stiffness)
		
		rolling_deformation.x -= (gravity_incline.x * (suspension_force / tyre_stiffness)) * 1.1
		
		rolling_deformation *= tyre_stiffness
		
		rolling_deformation.x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		#calculate the grip of the tire
		if grip > 0:
			var slip:float = rolling_deformation.length() / grip
			
			slip_percpre = slip / tyre_stiffness
			
			slip /= slip * surface_vars.ground_builduprate + div_by_0_fix
			slip -= CompoundSettings.TractionFactor
			slip = maxf(slip, 0.0)
			
			#var slip_sk_v:Vector2 = rolling_deformation
			#rolling_deformation.x *= 2
			var slip_sk:float = sqrt(pow(rolling_deformation.y, 2.0) + pow(rolling_deformation.x * 2.0, 2.0)) / grip
			#slip_sk = slip_sk_v.length() / grip
			slip_sk /= slip * surface_vars.ground_builduprate + div_by_0_fix
			slip_sk -= CompoundSettings.TractionFactor
			slip_sk = maxf(slip_sk, 0.0)
			
			if absf(rolling_deformation.y) / (tyre_stiffness / 3.0) > (car.ABS.threshold / grip) * pow(surface_vars.ground_friction, 2.0) and car.ABS.enabled and absf(velocity.z) > car.ABS.speed_pre_active and ContactABS:
				car.abs_pump = car.ABS.pump_time
				if absf(rolling_deformation.x) / (tyre_stiffness / 3.0) > (car.ABS.lat_thresh / grip) * pow(surface_vars.ground_friction, 2.0):
					car.abs_pump = car.ABS.lat_pump_time
			
			var force_v:Vector2 = force_smoothing(-rolling_deformation / (slip + div_by_0_fix))
			
			var distyw:float = rolling_deformation.length()
			
			distyw /= CompoundSettings.TractionFactor
			
			distyw = maxf(distyw, tyre_stiffness * (grip / tyre_stiffness))
			
			var ok:float = minf(((distyw / tyre_stiffness) / grip) / w_size, 1.0)
			
			differed_wheel_lock = minf(ok * w_weight_read, 1.0)
			
			cache_friction_action = force_v.y * ok
			
			wv -= cache_friction_action
			
			wv += (wheelpower * (1.0 / tyre_stiffness))
			
			roll_vol = velocity.length() * grip
			
			#Volume calculation?
			skid_volume = maxf(slip_sk - tyre_stiffness, 0.0) / 4.0
	else:
		wv += wheelpower
		stress = 0.0
		roll_vol = 0.0
		skid_volume = 0.0
		directional_force.y = 0.0
		compensate = 0.0
	
	slip_perc = Vector2.ZERO
	slip_perc2 = 0.0
	
	wv_diff = wv
	# FORCE
	if is_colliding():
		hitposition = get_collision_point()
		directional_force.y = suspension()
		
		tire_scrub = Vector2(velocity2.x, velocity2.z - (wv * w_size) / (surface_vars.drag + div_by_0_fix))
		
		if is_instance_valid(differed_wheel_node):
			tire_scrub.y = velocity2.z - ((wv * (1.0 - car.differential_lock_influence) + differed_wheel_node.wv_diff * car.differential_lock_influence) * w_size) / (surface_vars.drag + div_by_0_fix)
		
		gravity_incline = (geometry.global_transform.basis.orthonormalized().transposed() * Vector3.UP)
		
		tire_scrub.x -= (gravity_incline.x * (directional_force.y / tyre_stiffness)) * 1.1
		
		slip_perc = tire_scrub
		
		tire_scrub *= tyre_stiffness
		
		tire_scrub.x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		if grip > 0:
			var slip:float = sqrt(pow(tire_scrub.y, 2.0) + pow(tire_scrub.x, 2.0)) / grip
			
			assert(is_equal_approx(slip, tire_scrub.length() / grip))
			
			slip /= slip * surface_vars.ground_builduprate + div_by_0_fix
			slip -= CompoundSettings.TractionFactor
			slip = maxf(slip, 0.0)
			
			slip_perc2 = slip
			
			var force_v:Vector2 = force_smoothing(- tire_scrub / (slip + div_by_0_fix))
			
			directional_force.x = force_v.x
			directional_force.z = force_v.y
	else:
		geometry.position = target_position
	
	output_wv = wv
	
	anim_camber_wheel.rotate_x(deg_to_rad(wv))
	
	geometry.position.y += w_size
	
	var inned:float = (absf(cambered) + AxleSettings.Geometry4) / 90
	inned *= inned - AxleSettings.Geometry4 / 90.0
	
	geometry.position.x = -inned * position.x
	
	anim_camber.rotation_degrees.z = -(camber_w_caster - cambered) * car_side
	anim_camber.rotation.z *= AxleSettings.Camber_Gain
	
	axle_position = geometry.position.y
	
	#The x and y offset of the axle added together.
	var axle_offset:float 
	
	if not is_instance_valid(solidify_axles_wheel):
		axle_offset = (geometry.position.y + (absf(target_position.y) - AxleSettings.Vertical_Mount)) / (absf(position.x) + AxleSettings.Lateral_Mount_Pos + div_by_0_fix)
		axle_offset /= absf(axle_offset) + div_by_0_fix
		cambered = (axle_offset * conversion_1) - AxleSettings.Geometry4
		#cambered = (axle_offset * conversion_1) - AxleSettings.Vertical_Mount
		
	else:
		axle_offset = (geometry.position.y - solidify_axles_wheel.axle_position) / (absf(position.x) + div_by_0_fix)
		axle_offset /= absf(axle_offset) + div_by_0_fix
		cambered = (axle_offset * conversion_1)
	
	anim.position = geometry.position
	
	#apply forces
	var forces:Vector3 = velo_2.global_transform.basis.orthonormalized() * directional_force
	
	car.apply_impulse(forces, hitposition - car.global_transform.origin)


func alignAxisToVector(xform:Transform3D, norm:Vector3) -> Transform3D: # i named this literally out of blender
	var new_form:Transform3D = xform
	new_form.basis.y = norm
	new_form.basis.x = -new_form.basis.z.cross(norm)
	new_form.basis = new_form.basis.orthonormalized()
	return new_form

const suspension_args:String = "own,maxcompression,incline_free,incline_impact,rest,elasticity,damping,damping_rebound,linearz,abs_targeted_position,located,hit_located,weight,ground_bumpiness,ground_bump_height"
const suspension_inputs:String = "self,S_MaxCompression,A_InclineArea,A_ImpactForce,S_RestLength, elasticity,damping,damping_rebound, velocity.y,abs(cast_to.y),global_translation,get_collision_point(),car.mass,ground_bumpiness,ground_bump_height"

##Calculate suspension, which is the y force on the wheel.
func suspension() -> float:
	var abs_targeted_position:float = absf(target_position.y)
	
	var ground_bump_scale:float = (ground_bumpiness * surface_vars.ground_bump_height)
	
	geometry.global_position = get_collision_point()
	geometry.position.y -= ground_bump_scale
	geometry.position.y = maxf(geometry.position.y, -abs_targeted_position)
	
	velo_1.global_transform = alignAxisToVector(velo_1.global_transform, get_collision_normal())
	velo_2.global_transform = alignAxisToVector(velo_2.global_transform, get_collision_normal())
	
	#This is reminiscent of the calculation for anim camber
	angle = (geometry.rotation_degrees.z - ((-camber_w_caster - cambered) * car_side) * AxleSettings.Camber_Gain) / conversion_1
	
	var incline:float = (get_collision_normal() - (global_transform.basis.orthonormalized() * Vector3.UP)).length()
	
	#incline /= 1 - A_InclineArea
	incline /= 1.0 - Suspension.InclineArea
	incline -= Suspension.InclineArea
	incline *= Suspension.ImpactForce
	incline = clampf(incline, 0.0, 1.0)
	
	var incline_percent:float = 1.0 - incline
	
	geometry.position.y = minf(geometry.position.y, - abs_targeted_position + Suspension.MaxCompression * incline_percent)
	
	var damp_variant:float = damping_rebound
	
	#linearz is velocity.y
	if velocity.y < 0: #if we are sunken into the ground
		damp_variant = damping
	
	#this sits at around 2.4 to 2.6 on the base car, which is innacurate
	
	var hit_position:float = (global_position - get_collision_point()).length()
	
	
	var compressed:float = abs_targeted_position - hit_position - ground_bump_scale
	#var compressed2:float =  maxf(compressed - (S_MaxCompression + ground_bump_scale), 0.0)
	var compressed2:float =  maxf(compressed - (Suspension.MaxCompression + ground_bump_scale), 0.0)
	
	var tenth_car_body_weight:float = (car.mass / 10.0)
	var elasticity2:float = elasticity * incline_percent + car.mass * incline
	var damping2:float = damp_variant * incline_percent + tenth_car_body_weight * incline
	
	#var suspforce:float = maxf(compressed - S_RestLength, 0.0) * elasticity2
	var suspforce:float = maxf(compressed - Suspension.Deadzone, 0.0) * elasticity2
	
	
	if compressed2 > 0.0:
		suspforce -= (velocity.y * tenth_car_body_weight)
		suspforce += compressed2 * car.mass
	
	suspforce -= velocity.y * damping2
	
	suspension_compression = compressed
	
	return maxf(suspforce, 0.0)

##Helper function for some recurring duplicate logic.
##Name is based on what I think it's doing.
func force_smoothing(input:Vector2) -> Vector2:
	var force_v:Vector2 = input
	#negative Vector2.ONE is a stand in for negative infinity, since the latter
	#can make math functions have a spasm, and these values shouldn't be negative anyways
	var yes_v:Vector2 = force_v.abs().clamp(-Vector2.ONE, Vector2.ONE)
	
	var smooth_v:Vector2 = Vector2(pow(yes_v.x, 2.0), yes_v.y).clamp(-Vector2.ONE, Vector2.ONE)
	var percent_rigidity:float = 1.0 - rigidity
	
	force_v /= (smooth_v * rigidity + Vector2(percent_rigidity, percent_rigidity))
	
	return force_v

##This will update various stats like [w_size] and [w_weight]. [br]
##Usually, these stats only need to be set once when the car is loaded,
##since [TyreSettings] and [CompoundSettings] (which are used in calculating these values) usually never change at runtime.
##However, if those are being edited in real time, such as in an editor, these stats need to be re-set.
func set_physical_stats() -> void:
	car_side = sign(position.x)
	relative_toe = - (Toe * car_side)
	
	w_size = TyreSettings.size
	w_weight = pow(w_size, 2.0)
	
	w_size_read = maxf(w_size, 1.0)
	w_weight_read = maxf(w_weight, 1.0)
	
	tyre_maxgrip = TyreSettings.GripInfluence / CompoundSettings.TractionFactor
	
	const magic_number_b:float = 0.1475
	const magic_number_c:float = 1.3558
	
	if is_instance_valid(car):
		diff_dist_power_tolerance = (magic_number_b / magic_number_c) * car.ClutchGrip
