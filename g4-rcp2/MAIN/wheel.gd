extends RayCast3D
##A class representing the wheel of a [ViVeCar].
##Each wheel independently calculates its suspension and other values every physics process frame.
class_name ViVeWheel

@export var RealismOptions:Dictionary = {
}

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
@export var TyreSettings:ViVeTyreSettings = ViVeTyreSettings.new()
##The [TyreCompoundSettings] for this wheel.
@export var CompoundSettings:TyreCompoundSettings = TyreCompoundSettings.new()
##Represents information about the axle the [ViVeWheel] is attached to in the car.
@export var AxleSettings:ViVeWheelAxle = ViVeWheelAxle.new()

@export_group("Alignment")
##Camber Angle.
@export var Camber:float = 0.0
##Caster Angle.
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
@onready var differed_wheel:ViVeWheel = null
##The paired wheel for sway bar calculations
@onready var sway_bar_wheel:ViVeWheel = null
##The paired wheel for solidifying axles
@onready var solidify_axles_wheel:ViVeWheel = null

const rigidity:float = 0.67
#I don't know what these are. Any ideas are welcome!
const magic_number_a:float = 1.15296
const magic_number_b:float = 0.1475
const magic_number_c:float = 1.3558
const magic_number_d:float = 0.003269

##Distance, seems like it's probably something else given the codes relation to the clutch.
var dist:float = 0.0
##Wheel size.
var w_size:float = 1.0
##Size read of the wheel. This is w_size but capped to 1.0 or lower.
var w_size_read:float = 1.0
##Weight read of the wheel. Seems to be (unintentionally) a constant?
##Fuethermore, this should [i]never[/i] be 0.
var w_weight_read:float = 0.0
##Weight of the wheel. This is w_size but to the power of 2.
var w_weight:float = 0.0
##Maximum grip of the tyre
var tyre_maxgrip:float = 0.0


##Velocity of the wheel(?)
var wv:float = 0.0
##Velocity of the wheel distributed(?)
var wv_ds:float = 0.0
##Velocity of the wheel differed(?)
var wv_diff:float = 0.0
##Appears to be constant, so possibly not fully implemented?
var effectiveness:float = 0.0
##Only ever set in suspension calculation.
var angle:float = 0.0

var snap:float = 0.0
##Absolute velocity of the wheel(?)
var absolute_wv:float = 0.0
##Absolute velocity of the wheel when braking(?)
var absolute_wv_brake:float = 0.0
##Absolute velocity of the wheel when differed(?)
var absolute_wv_diff:float = 0.0
##Output wheel velocity?
var output_wv:float = 0.0
##Seemingly related to [snap]?
var offset:float = 0.0
##If this wheel is a driving wheel (as dictated by the parent [ViVeCar], this value gets set to [W_PowerBias] by the parent [ViVeCar].
##Otherwise, it stays at 0.
var live_power_bias:float = 0.0
##Seems tied to [wv]
var wheelpower:float = 0.0
##This is set to [wheelpower] and is used in differed calculations.
var wheelpower_global:float = 0.0
##This is related to the [grip] of the wheel, and is tied to the stress var on the parent [ViVeCar].
var stress:float = 0.0

##This value is clamped between -1 and 1
var rolldist:float = 0.0

var rd:float = 0.0

var c_camber:float = 0.0

var cambered:float = 0.0
##The volume of the wheel rolling/skidding.
var roll_vol:float = 0.0

##The skidding volume.
##Specifically related to the volume of peel2.
var skid_volume:float = 0.0

var velocity:Vector3 = Vector3.ZERO

var velocity2:Vector3 = Vector3.ZERO
##This is compensation for the forward velocity/grip on a slope being affected by the [tyre_stiffness].
var compensate:float = 0.0
##The axle position (of the geometry).
##This is exposed for use in differed calculations, and is updated right before said calculations.
var axle_position:float = 0.0

var ground_bump:float = 0.0

var ground_bump_up:bool = false

var ground_bump_frequency:float = 0.0

var surface_vars:ViVeSurfaceVars = ViVeSurfaceVars.new()
##The last collision point reported by the underlying RayCast3D
var hitposition:Vector3 = Vector3.ZERO

var tyre_stiffness:float

var tyre_stiffness_2:float

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
##Cached value of "physics/common/physics_ticks_per_second", for compensating for varying physics ticks.
var physics_tick:float = 60

var tol:float = 0.0

func _ready() -> void:
	physics_tick = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0)
	if Differed_Wheel_Path:
		differed_wheel = car.get_node(Differed_Wheel_Path)
	if SwayBarConnection:
		sway_bar_wheel = car.get_node(SwayBarConnection)
	if Solidify_Axles:
		solidify_axles_wheel = car.get_node(Solidify_Axles)
	
	set_physical_stats()

##Apply power. This function only does something if the wheel is a drive wheel,
##according to the settings of the parent ViVeCar
func power() -> void:
	if not is_zero_approx(live_power_bias):
		dist *= pow(car.car_controls.clutchpedal, 2.0) / (car.current_stable)
		
		var dist2:float = clampf(dist, -tol, tol)
		
		car._dsweight += live_power_bias
		car.stress_total += stress * live_power_bias
		
		if car.ds_weight_run > 0.0:
			if car.rpm > car.DeadRPM:
				wheelpower -= (((dist2 / car.ds_weight) / (car.ds_weight_run / 2.5)) * live_power_bias) / w_weight
			car.resistance += (((dist2 * (10.0)) / car.ds_weight_run) * live_power_bias)

##This "borrows" computations from a paired wheel in order to save on computation bandwidth.
func diffs() -> void:
	if car.locked > 0.0 and is_instance_valid(differed_wheel):
		snap = absf(differed_wheel.wheelpower_global) / (car.locked * 16.0) + 1.0
		absolute_wv = output_wv + (offset * snap)
		
		var distanced2:float = absf(absolute_wv - differed_wheel.absolute_wv_diff) / (car.locked * 16.0)
		distanced2 += absf(differed_wheel.wheelpower_global) / (car.locked * 16.0)
		
		distanced2 = maxf(distanced2, snap)
		
		distanced2 += 1.0 / cache_tyrestiffness
		if distanced2 > 0.0:
			wheelpower += -((absolute_wv_diff - differed_wheel.absolute_wv_diff) / distanced2)

##Run logic for the Sway Bar connection, if one is properly set.
func sway_bar() -> void:
	if is_instance_valid(sway_bar_wheel): 
		rolldist = clampf(rd - sway_bar_wheel.rd, -1.0, 1.0)

##Factor in the effects of braking and/or handbraking to the velocity of the wheel.
func apply_braking() -> void:
	var total_brake_effect:float = minf(car.brake_line * B_Bias + car.car_controls.handbrakepull * HB_Bias, 1.0)
	#Get brake power by multiplying the total_brake_effect factor by the brake force, 
	#and dividing that result by the weight of the wheel
	var brake_power:float = (B_Torque * total_brake_effect) / w_weight_read
	
	if not car.actualgear == 0:
		if car.ds_weight_run > 0.0:
			brake_power += ((car.stalled * (live_power_bias / car.ds_weight)) * car.car_controls.clutchpedal) * (((5.0 / car.RevSpeed) / (car.ds_weight_run / 2.5)) / w_weight_read)
	if brake_power > 0.0:
		if absf(absolute_wv) > 0.0:
			var distanced:float = absf(absolute_wv) / brake_power
			distanced = maxf(distanced - car.brake_line, snap * (w_size_read / B_Saturation))
			#wheelpower += - absolute_wv / distanced
			wheelpower -= absolute_wv / distanced
		else:
			#wheelpower += -absolute_wv
			wheelpower -= absolute_wv
	
	wheelpower_global = wheelpower

func _physics_process(_delta:float) -> void:
	
	
	var sign_pos:float = signf(position.x)
	if is_zero_approx(sign_pos):
		sign_pos = 1.0
	
	#Do steer rotation things if this wheel is a steering wheel
	if Steer and absf(car.car_controls.steer) > 0:
		var last_translation:Vector3 = position
		var last_transform:Transform3D = global_transform
		
		#The y value should be 0; this use case works
		#because it never gets set to anything other than 0
		assert(is_zero_approx(car.steering_geometry.y), "steering_geometry.y is not zero")
		look_at_from_position(position, car.steering_geometry)
		
		global_transform.origin = last_transform.origin
		
		if car.car_controls.steer > 0.0:
			rotate_y( -deg_to_rad(90.0))
		else:
			rotate_y(deg_to_rad(90.0))
		
		var roter:float = global_rotation.y
		
		look_at(Vector3(car.Steer_Radius, 0.0, car.steering_geometry.z))
		
		#This set keeps the car from launching into orbit (idk why)
		global_transform.origin = last_transform.origin
		
		rotate_y(deg_to_rad(90.0))
		
		car.steering_angles.append(global_rotation_degrees.y)
		
		rotation_degrees = Vector3.ZERO
		rotation = Vector3.ZERO
		
		rotation.y = roter
		
		#rotation_degrees.y += - (Toe * sign_pos)
		rotation_degrees.y += -Toe
		
		position = last_translation
	else:
		#rotation_degrees = Vector3(0.0, -(Toe * sign_pos), 0.0)
		rotation_degrees = Vector3(0.0, -Toe, 0.0)
	
	#c_camber = Camber + Caster * rotation.y * float(position.x > 0.0) - Caster * rotation.y * float(position.x < 0.0)
	c_camber = Camber + (Caster * rotation.y * signf(position.x))
	
	directional_force = Vector3.ZERO
	velo_1.position = Vector3.ZERO
	
	#You don't [i]really[/i] need this to be run under normal circumstances (see the desc of set_physical_stats),
	#so it's disabled unless debug is on.
	if car.Debug_Mode:
		set_physical_stats()
	
	#Sync positions. Without this, the car is very bouncy for some reason
	velo_2.global_position = geometry.global_position
	velo_1_step.global_position = velocity_last
	velo_2_step.global_position = velocity2_last
	velocity_last = velo_1.global_position
	velocity2_last = velo_2.global_position
	
	#60 here is likely the physics tick per second
	velocity = -velo_1_step.position * 60.0
	velocity2 = -velo_2_step.position * 60.0
	
	velo_1.rotation = Vector3.ZERO
	velo_2.rotation = Vector3.ZERO
	
	# VARS
	
	sway_bar()
	
	#moved to set_physical_stats
	#tyre_maxgrip = TyreSettings.GripInfluence / CompoundSettings.TractionFactor
	#tyre_stiffness_2 = absi(TyreSettings.Width_mm) / (absf(TyreSettings.Aspect_Ratio) / 1.5)
	
	var speed_deform_factor:float = (Vector2(velocity.x, velocity.z).length() / 50.0 + 0.5) * CompoundSettings.DeformFactor
	
	speed_deform_factor /= surface_vars.ground_stiffness + surface_vars.fore_stiffness * CompoundSettings.ForeStiffness
	speed_deform_factor = maxf(speed_deform_factor, 1.0)
	
	var tyre_stiffness:float = ((tyre_stiffness_2 / speed_deform_factor) * ((TyreSettings.AirPressure / 30.0) * 0.1 + 0.9) ) * CompoundSettings.Stiffness + effectiveness
	
	tyre_stiffness = maxf(tyre_stiffness, 1.0)
	
	cache_tyrestiffness = tyre_stiffness
	
	absolute_wv = output_wv + (offset * snap) - compensate * magic_number_a
	absolute_wv_brake = output_wv + ((offset / w_size_read) * snap) - compensate * magic_number_a
	absolute_wv_diff = output_wv
	
	wheelpower = 0.0
	
	apply_braking()
	
	power()
	diffs()
	
	snap = 1.0
	offset = 0.0
	
	var grip:float
	
	var gravity_incline:Vector3
	
	var dist_force:Vector2
	
	
	# WHEEL
	if is_colliding():
		#Apply ground surface variables
		var collider:Node3D = get_collider()
		if "ground_vars" in collider:
			var extern_surf:ViVeSurfaceVars = collider.get("ground_vars")
			surface_vars = extern_surf
			surface_vars.drag = extern_surf.drag * pow(CompoundSettings.GroundDragAffection, 2.0)
			surface_vars.ground_builduprate = extern_surf.ground_builduprate * CompoundSettings.BuildupAffection
			surface_vars.ground_bump_frequency_random = extern_surf.ground_bump_frequency_random + 1.0
		
		var ground_bump_randi:float = randf_range(ground_bump_frequency / surface_vars.ground_bump_frequency_random, ground_bump_frequency * surface_vars.ground_bump_frequency_random) * (velocity.length() * 0.001)
		
		if ground_bump_up:
			ground_bump -= ground_bump_randi
			if ground_bump < 0.0:
				ground_bump = 0.0
				ground_bump_up = false
		else:
			ground_bump += ground_bump_randi
			if ground_bump > 1.0:
				ground_bump = 1.0
				ground_bump_up = true
		
		
		hitposition = get_collision_point()
		
		#Y force is dictated by suspension
		directional_force.y = suspension()
		
		# FRICTION
		
		#Grip is the result of gravity multiplied by the tyre grip, 
		#times the ground and fore friction times the compound fore friction
		grip = (directional_force.y * tyre_maxgrip) * (surface_vars.ground_friction + surface_vars.fore_friction * CompoundSettings.ForeFriction)
		stress = grip
		
		wv += (wheelpower * (1.0 - (1.0 / tyre_stiffness)))
		
		#the distribution of the wheel's velocity(?)
		var dist_v:Vector2 = Vector2(velocity2.x, velocity2.z - (wv * w_size))
		#A version of dist_v used in force calculations
		#dist_force = dist_v / (surface_vars.drag + 1.0)
		dist_force = dist_v
		dist_force.y = dist_v.y / (surface_vars.drag + 1.0)
		
		offset = clampf(dist_v.y / w_size, -grip, grip)
		
		gravity_incline = (geometry.global_transform.basis.orthonormalized().transposed() * Vector3.UP)
		
		compensate = gravity_incline.z * (directional_force.y / tyre_stiffness)
		
		dist_v.x -= (gravity_incline.x * (directional_force.y / tyre_stiffness)) * 1.1
		
		slip_perc = dist_v
		
		dist_v *= tyre_stiffness
		
		dist_v.x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		#calculate the grip of the tire
		if grip > 0:
			var dist_v_squared:Vector2 = dist_v * dist_v
			var slipraw:float = sqrt(dist_v_squared.y + dist_v_squared.x)
			var slip:float = slipraw / grip
			
			slipraw = maxf(slipraw / CompoundSettings.TractionFactor, tyre_stiffness * (grip / tyre_stiffness))
			
			var ok:float = minf(((slipraw / tyre_stiffness) / grip) / w_size, 1.0)
			snap = minf(ok * w_weight_read, 1.0)
			
			slip_percpre = slip / tyre_stiffness
			
			slip /= slip * surface_vars.ground_builduprate + 1
			slip = maxf(slip - CompoundSettings.TractionFactor, 0.0)
			
			if absf(dist_v.y) / (tyre_stiffness / 3.0) > (car.ABS.threshold / grip) * pow(surface_vars.ground_friction, 2.0) and car.ABS.enabled and absf(velocity.z) > car.ABS.speed_pre_active and ContactABS:
				car.abs_pump = car.ABS.pump_time
				if absf(dist_v.x) / (tyre_stiffness / 3.0) > (car.ABS.lat_thresh / grip) * pow(surface_vars.ground_friction, 2.0):
					car.abs_pump = car.ABS.lat_pump_time
			
			var force_v:Vector2 = force_smoothing(- dist_v / (slip + 1.0))
			cache_friction_action = force_v.y * ok
			
			wv -= cache_friction_action
			wv += (wheelpower * (1.0 / tyre_stiffness))
			
			roll_vol = velocity.length() * grip
			
			#Volume calculation?
			var new_slip_sk:float = sqrt(pow(dist_v.x * 2.0, 2.0) + dist_v_squared.y) / grip
			new_slip_sk /= slip * surface_vars.ground_builduprate + 1
			new_slip_sk = maxf(new_slip_sk - CompoundSettings.TractionFactor, 0.0)
			skid_volume = maxf(new_slip_sk - tyre_stiffness, 0.0) / 4.0
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
		# FRICTION
		if is_instance_valid(differed_wheel):
			dist_force.y = velocity2.z - ((wv * (1.0 - car.locked) + differed_wheel.wv_diff * car.locked) * w_size) / (surface_vars.drag + 1)
		
		dist_force.x -= (gravity_incline.x * (directional_force.y / tyre_stiffness)) * 1.1
		
		slip_perc = dist_force
		
		dist_force *= tyre_stiffness
		
		dist_force.x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		if grip > 0:
			var dist_force_squared:Vector2 = dist_force * dist_force
			var slipraw:float = sqrt(dist_force_squared.y + dist_force_squared.x)
			
			var slip:float = slipraw / grip
			
			slip /= slip * surface_vars.ground_builduprate + 1.0
			slip = maxf(slip - CompoundSettings.TractionFactor, 0.0)
			
			slip_perc2 = slip
			
			var force_v:Vector2 = force_smoothing(- dist_force / (slip + 1.0))
			
			directional_force = Vector3(force_v.x, directional_force.y, force_v.y)
	else:
		geometry.position = target_position
	
	output_wv = wv
	anim_camber_wheel.rotate_x(deg_to_rad(wv))
	
	geometry.position.y += w_size
	
	var inned:float = (absf(cambered) + AxleSettings.Geometry4) / 90.0
	
	inned *= inned - AxleSettings.Geometry4 / 90.0
	geometry.position.x = -inned * position.x
	anim_camber.rotation.z = - (deg_to_rad(c_camber * signf(position.x)) - deg_to_rad(cambered * signf(position.x)) * AxleSettings.Camber_Gain)
	
	var g:float
	
	axle_position = geometry.position.y
	if not is_instance_valid(solidify_axles_wheel):
		g = (geometry.position.y + (absf(target_position.y) - AxleSettings.Vertical_Mount)) / (absf(position.x) + AxleSettings.Lateral_Mount_Pos + 1.0)
		g /= absf(g) + 1.0
		cambered = (g * 90.0) - AxleSettings.Geometry4
	else:
		g = (geometry.position.y - solidify_axles_wheel.axle_position) / (absf(position.x) + 1.0)
		g /= absf(g) + 1.0
		cambered = (g * 90.0)
	
	anim.position = geometry.position
	
	#apply forces
	var forces:Vector3 = velo_2.global_transform.basis.orthonormalized() * directional_force
	
	car.apply_impulse(forces, hitposition - car.global_transform.origin)
	
	# torque
	
	#var torqed:float = (wheelpower * w_weight) / 4.0
	
	#wv_ds = wv
	
	#car.apply_impulse(geometry.global_transform.origin - car.global_transform.origin + velo_1.global_transform.basis.orthonormalized() * (Vector3(0,0,1)), velo_2.global_transform.basis.orthonormalized() * (Vector3(0,1,0)) * torqed)
	#car.apply_impulse(geometry.global_transform.origin - car.global_transform.origin - velo_2.global_transform.basis.orthonormalized() * (Vector3(0,0,1)), velo_2.global_transform.basis.orthonormalized() * (Vector3(0,1,0)) * -torqed)


const suspension_args:String = "own,maxcompression,incline_free,incline_impact,rest,elasticity,damping,damping_rebound,linearz,g_range,located,hit_located,weight,ground_bump,ground_bump_height"
const suspension_inputs:String = "self,S_MaxCompression,A_InclineArea,A_ImpactForce,S_RestLength, elasticity,damping,damping_rebound, velocity.y,abs(cast_to.y),global_translation,get_collision_point(),car.mass,ground_bump,ground_bump_height"

##Calculate suspension, which is the y force on the wheel.
func suspension() -> float:
	var g_range:float = absf(target_position.y)
	geometry.global_position = get_collision_point()
	geometry.position.y = maxf(geometry.position.y - (ground_bump * surface_vars.ground_bump_height), -g_range)
	
	velo_1.global_transform = VitaVehicleSimulation.alignAxisToVector(velo_1.global_transform, get_collision_normal())
	velo_2.global_transform = VitaVehicleSimulation.alignAxisToVector(velo_2.global_transform, get_collision_normal())
	
	#angle = (geometry.rotation_degrees.z - ( - c_camber * positive_pos + c_camber * negative_pos) + ( - cambered * positive_pos + cambered * negative_pos) * AxleSettings.Camber_Gain) / 90.0
	angle = (geometry.rotation_degrees.z - ( - c_camber * signf(position.x)) + ( - cambered * signf(position.x)) * AxleSettings.Camber_Gain) / 90.0
	
#	var incline = (own.get_collision_normal()-own.global_transform.basis.orthonormalized().xform(Vector3(0,1,0))).length()
	var incline:float = (get_collision_normal() - (global_transform.basis.orthonormalized() * Vector3.UP)).length()
	
	incline /= 1 - A_InclineArea
	
	incline = maxf(incline - A_InclineArea, 0.0)
	incline = minf(incline * A_ImpactForce, 1.0)
	
	geometry.position.y = minf(geometry.position.y, - g_range + S_MaxCompression * (1.0 - incline))
	
	var damp_variant:float = maxf(S_ReboundDamping * AR_Stiff * rolldist + 1.0, 0.0)
	
	#linearz is velocity.y
	if velocity.y < 0:
		#damp_variant = S_Damping * (AR_Stiff * (rolldist + 1.0))
		#Serious BS was taken here, as this is the "damping" var from _physics_process
		damp_variant = maxf(S_Damping * AR_Stiff * rolldist + 1.0, 0.0)
	
	var compressed:float = g_range - (global_position - get_collision_point()).length() - (ground_bump * surface_vars.ground_bump_height)
	var compressed2:float =  maxf(compressed - (S_MaxCompression + (ground_bump * surface_vars.ground_bump_height)), 0.0)
	
	var elasticity2:float = (S_Stiffness * AR_Elast * rolldist + 1.0) * (1.0 - incline) + (car.mass) * incline
	var damping2:float = damp_variant * (1.0 - incline) + (car.mass / 10.0) * incline
	
	var suspforce:float = maxf(compressed - S_RestLength, 0.0) * elasticity2 - velocity.y * damping2
	
	if compressed2 > 0.0:
		suspforce -= velocity.y * (car.mass / 10.0)
		suspforce += compressed2 * car.mass
	
	rd = compressed
	
	return maxf(suspforce, 0.0)

##Helper function for some recurring duplicate logic.
##Name is based on what I think it's doing.
func force_smoothing(input:Vector2) -> Vector2:
	var force_v:Vector2 = input
	var yes_v:Vector2 = force_v.abs().clamp(-Vector2.INF, Vector2.ONE)
	var smooth_v:Vector2 = Vector2(pow(yes_v.x, 2.0), yes_v.y).clamp(-Vector2.INF, Vector2.ONE)
	force_v /= (smooth_v * rigidity + Vector2(1.0 - rigidity, 1.0 - rigidity))
	return force_v

##This will update various stats like [w_size] and [w_weight]. [br]
##Usually, these stats only need to be set once when the car is loaded,
##since [TyreSettings] and [CompoundSettings] (which are used in calculating these values) usually never change at runtime.
##However, if those are being edited in real time, such as in an editor, these stats need to be re-set.
func set_physical_stats() -> void:
	#25.4 is likely a unit conversion constant
	#w_size = ((absi(TyreSettings.Width_mm) * ((absf(TyreSettings.Aspect_Ratio) * 2.0) * 0.01) + absi(TyreSettings.Rim_Size_in) * 25.4) * magic_number_d) * 0.5
	w_size = TyreSettings.get_size()
	w_weight = pow(w_size, 2.0)
	
	w_size_read = maxf(w_size, 1.0)
	w_weight_read = maxf(w_weight, 1.0) #implied from the above line
	
	tyre_maxgrip = TyreSettings.GripInfluence / CompoundSettings.TractionFactor
	
	#tyre_stiffness_2 = absi(TyreSettings.Width_mm) / (absf(TyreSettings.Aspect_Ratio) / 1.5)
	tyre_stiffness_2 = TyreSettings.get_stiffness()
	
	tol = (magic_number_b / magic_number_c) * car.ClutchGrip
