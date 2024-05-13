extends RayCast3D
##A class representing the wheel of a [ViVeCar].
##Each wheel independently calculates its suspension and other values every physics process frame.
class_name ViVeWheel

@export var RealismOptions:Dictionary = {
}
##Allows this wheel to steer.
@export var Steer:bool = true
##Finds a wheel to correct itself to another, in favour of differential mechanics. 
##Both wheels need to have their properties proposed to each other.
@export var Differed_Wheel:NodePath = ""
##Connects a sway bar to the opposing axle. 
##Both wheels should have their properties proposed to each other.
@export var SwayBarConnection:NodePath = ""

##Power Bias (when driven).
@export var W_PowerBias:float = 1.0

@export var TyreSettings:ViVeTyreSettings = ViVeTyreSettings.new()
##Tyre Pressure PSI (hypothetical).
@export var TyrePressure:float = 30.0
##Camber Angle.
@export var Camber:float = 0.0
##Caster Angle.
@export var Caster:float = 0.0
##Toe-in Angle.
@export var Toe:float = 0.0

@export var CompoundSettings:TyreCompoundSettings = TyreCompoundSettings.new()
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
@export var A_InclineArea:float = 0.2
@export var A_ImpactForce:float = 1.5
##Anti-roll Stiffness.
@export var AR_Stiff:float = 0.5
##Anti-roll Reformation Rate.
@export var AR_Elast:float = 0.1
##Brake Force.
@export var B_Torque:float = 15.0
##Brake Bias.
@export var B_Bias:float = 1.0
##
##Leave this at 1.0 unless you have a heavy vehicle with large wheels, set it higher depending on how big it is.
@export var B_Saturation:float = 1.0
##Handbrake Bias.
@export var HB_Bias:float = 0.0
##Axle Vertical Mounting Position.
@export var A_Geometry1:float = 1.15
##Camber Gain Factor.
@export var A_Geometry2:float = 1.0
##Axle lateral mounting position, affecting camber gain. 
##High negative values may mount them outside.
@export var A_Geometry3:float = 0.0

@export var A_Geometry4:float = 0.0

@export var Solidify_Axles:NodePath = NodePath()
##Allows the Anti-lock Braking System to monitor this wheel.
@export var ContactABS:bool = true

@export var ESP_Role:String = ""

@export var ContactBTCS:bool = false

@export var ContactTTCS:bool = false

@onready var car:ViVeCar = get_parent()
@onready var geometry:MeshInstance3D = $"geometry"

@onready var velo_1:Marker3D = $"velocity"
@onready var velo_2:Marker3D = $"velocity2"
@onready var velo_1_step:Marker3D = $"velocity/step"
@onready var velo_2_step:Marker3D = $"velocity2/step"
@onready var anim:Marker3D = $"animation"
@onready var anim_camber:Marker3D = $"animation/camber"
@onready var anim_camber_wheel:Marker3D = $"animation/camber/wheel"

const rigidity:float = 0.67

##Distance, seems like it's probably something else given the codes relation to the clutch.
var dist:float = 0.0
##Wheel size.
var w_size:float = 1.0
##Size read of the wheel. This is w_size but capped to 1.0 or lower.
var w_size_read:float = 1.0
##Weight read of the wheel. Seems to be (unintentionally) a constant?
var w_weight_read:float = 0.0
##Weight of the wheel. This is w_size but to the power of 2.
var w_weight:float = 0.0
##Velocity of the wheel(?)
var wv:float = 0.0
##Velocity of the wheel distributed(?)
var wv_ds:float = 0.0
##Velocity of the wheel differed(?)
var wv_diff:float = 0.0

var c_tp:float = 0.0

var effectiveness:float = 0.0

var angle:float = 0.0

var snap:float = 0.0
##Absolute velocity of the wheel(?)
var absolute_wv:float = 0.0
##Absolute velocity of the wheel when braking(?)
var absolute_wv_brake:float = 0.0
##Absolute velocity of the wheel when differed(?)
var absolute_wv_diff:float = 0.0

var output_wv:float = 0.0

var offset:float = 0.0
##Current power? Set to W_PowerBias in ViVeCar
var c_p:float = 0.0

var wheelpower:float = 0.0

var wheelpower_global:float = 0.0

var stress:float = 0.0

var rolldist:float = 0.0

var rolldist_clamped:float = 0.0

var rd:float = 0.0

var c_camber:float = 0.0

var cambered:float = 0.0

var rollvol:float = 0.0

var sl:float = 0.0

var skvol:float = 0.0

var skvol_d:float = 0.0

var velocity:Vector3 = Vector3.ZERO

var velocity2:Vector3 = Vector3.ZERO

var compensate:float = 0.0

var axle_position:float = 0.0

var ground_bump:float = 0.0

var ground_bump_up:bool = false

var ground_bump_frequency:float = 0.0

var surface_vars:ViVeSurfaceVars = ViVeSurfaceVars.new()

var hitposition:Vector3 = Vector3.ZERO

var cache_tyrestiffness:float = 0.0

var cache_friction_action:float = 0.0
##The Force of the tire. 
##X is
##Y is the suspension of the tire
##Z is 
var directional_force:Vector3 = Vector3.ZERO

var slip_perc:Vector2 = Vector2.ZERO

var slip_perc2:float = 0.0

var slip_percpre:float = 0.0

var velocity_last:Vector3 = Vector3.ZERO

var velocity2_last:Vector3 = Vector3.ZERO


func _ready() -> void:
	c_tp = TyrePressure


func power() -> void:
	if not is_zero_approx(c_p):
		dist *= pow(car.car_controls.clutchpedal, 2.0) / (car._currentstable)
		
		const magic_number_1:float = 0.1475
		const magic_number_2:float = 1.3558
		
		var tol:float = (magic_number_1 / magic_number_2) * car.ClutchGrip
		
		var dist2:float = clampf(dist, -tol, tol)
		
		car._dsweight += c_p
		car._stress += stress * c_p
		
		if car._dsweightrun > 0.0:
			if car._rpm > car.DeadRPM:
				wheelpower -= (((dist2 / car._ds_weight) / (car._dsweightrun / 2.5)) * c_p) / w_weight
			car._resistance += (((dist2 * (10.0)) / car._dsweightrun) * c_p)

##This "borrows" computations from a paired wheel in order to save on computations.
func diffs() -> void:
	if car._locked > 0.0:
		if Differed_Wheel: #Non "" NodePath evaluates true
			var d_w:ViVeWheel = car.get_node(Differed_Wheel)
			if is_instance_valid(d_w):
				snap = absf(d_w.wheelpower_global) / (car._locked * 16.0) + 1.0
				absolute_wv = output_wv + (offset * snap)
				var distanced2:float = absf(absolute_wv - d_w.absolute_wv_diff) / (car._locked * 16.0)
				distanced2 += absf(d_w.wheelpower_global) / (car._locked * 16.0)
				distanced2 = maxf(distanced2, snap)
				
				distanced2 += 1.0 / cache_tyrestiffness
				if distanced2 > 0.0:
					wheelpower += -((absolute_wv_diff - d_w.absolute_wv_diff)/distanced2)
				
				


func sway() -> void:
	if SwayBarConnection: #NodePath evaluates true when not empty
		var linkedwheel:ViVeWheel = car.get_node(SwayBarConnection)
		if is_instance_valid(linkedwheel): #Needed to excuse some bootup errors
			rolldist = rd - linkedwheel.rd

func _physics_process(_delta:float) -> void:
	var last_translation:Vector3 = position
	
	var x_pos:float = float(position.x > 0)
	var x_neg:float = float(position.x < 0)
	
	if Steer and absf(car.car_controls.steer) > 0:
		var lasttransform:Transform3D = global_transform
		
		#The y value should be 0; this use case works
		#because it never gets set to anything other than 0
		assert(is_zero_approx(car._steering_geometry.y), "Y is not zero")
		look_at_from_position(position, car._steering_geometry)
		
		# just making this use origin fixed it. lol
		global_transform.origin = lasttransform.origin
		
		if car.car_controls.steer > 0.0:
			rotate_object_local(Vector3.MODEL_TOP, - deg_to_rad(90.0))
		else:
			rotate_object_local(Vector3.MODEL_TOP, deg_to_rad(90.0))
		
		var roter:float = global_rotation.y
		
		look_at_from_position(position, Vector3(car.Steer_Radius, 0.0, car._steering_geometry.z))
		
		# this one too
		global_transform.origin = lasttransform.origin #This little thing keeps the car from launching into orbit
		
		rotate_object_local(Vector3.MODEL_TOP, deg_to_rad(90.0))
		
		car._steering_angles.append(global_rotation_degrees.y)
		
		rotation_degrees = Vector3.ZERO
		rotation = Vector3.ZERO
		
		rotation.y = roter
		
		#rotation_degrees += Vector3(0, -(Toe * x_pos - Toe * x_neg), 0)
		rotation_degrees.y += -(Toe * x_pos - Toe * x_neg)
	else:
		rotation_degrees = Vector3(0.0,- (Toe * x_pos - Toe * x_neg), 0.0)
	
	#translation = last_translation
	position = last_translation
	
	#c_camber = Camber + Caster * rotation.y * float(translation.x > 0.0) -Caster * rotation.y * float(translation.x < 0.0)
	c_camber = Camber + Caster * rotation.y * float(position.x > 0.0) -Caster * rotation.y * float(position.x < 0.0)
	
	directional_force = Vector3.ZERO
	
	velo_1.position = Vector3.ZERO
	
	
	#w_size = ((absi(TyreSettings.Width_mm) * ((absi(TyreSettings.Aspect_Ratio) * 2.0) * 0.01) + absi(TyreSettings.Rim_Size_in) * 25.4) * 0.003269) * 0.5
	
	w_size = ((TyreSettings.Width_mm * ((TyreSettings.Aspect_Ratio * 2.0) * 0.01) + TyreSettings.Rim_Size_in * 25.4) * 0.003269) * 0.5
	w_weight = pow(w_size, 2.0)
	
	w_size_read = maxf(w_size, 1.0)
	
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
	rolldist_clamped = clampf(rolldist, -1.0, 1.0)
	
	var elasticity:float = maxf(S_Stiffness * AR_Elast * rolldist_clamped + 1.0, 0.0)
	var damping:float = maxf(S_Damping * AR_Stiff * rolldist_clamped + 1.0, 0.0)
	var damping_rebound:float = maxf(S_ReboundDamping * AR_Stiff * rolldist_clamped + 1.0, 0.0)
	
	sway()
	
	var tyre_maxgrip:float = TyreSettings.GripInfluence / CompoundSettings.TractionFactor
	
	#var tyre_stiffness2:float = absi(TyreSettings.Width_mm) / (absi(TyreSettings.Aspect_Ratio) / 1.5)
	var tyre_stiffness2:float = absf(TyreSettings.Width_mm) / (absf(TyreSettings.Aspect_Ratio) / 1.5)
	
	var deviding:float = (Vector2(velocity.x, velocity.z).length() / 50.0 + 0.5) * CompoundSettings.DeformFactor
	
	deviding /= surface_vars.ground_stiffness + surface_vars.fore_stiffness * CompoundSettings.ForeStiffness
	deviding = maxf(deviding, 1.0)
	
	tyre_stiffness2 /= deviding
	
	var tyre_stiffness:float = (tyre_stiffness2 * ((c_tp / 30.0) * 0.1 + 0.9) ) * CompoundSettings.Stiffness + effectiveness
	tyre_stiffness = maxf(tyre_stiffness, 1.0)
	
	cache_tyrestiffness = tyre_stiffness
	
	const magic_number_1:float = 1.15296
	
	absolute_wv = output_wv + (offset * snap) - compensate * magic_number_1
	absolute_wv_brake = output_wv + ((offset / w_size_read) * snap) - compensate * magic_number_1
	absolute_wv_diff = output_wv
	
	wheelpower = 0.0
	
	var braked:float = minf(car._brakeline * B_Bias + car.car_controls.handbrakepull * HB_Bias, 1.0)
	#Get brake power by multiplying the braked factor by the brake force, 
	#and dividing that result by the weight of the wheel
	var bp:float = (B_Torque * braked) / w_weight_read
	
	if not car._actualgear == 0:
		if car._dsweightrun > 0.0:
			bp += ((car._stalled * (c_p / car._ds_weight)) * car.car_controls.clutchpedal) * (((500.0 / (car.RevSpeed * 100.0)) / (car._dsweightrun / 2.5)) / w_weight_read)
	if bp > 0.0:
		if absf(absolute_wv) > 0.0:
			var distanced:float = absf(absolute_wv) / bp
			distanced = maxf(distanced - car._brakeline, snap * (w_size_read / B_Saturation))
			wheelpower += - absolute_wv / distanced
		else:
			wheelpower += -absolute_wv
	
	wheelpower_global = wheelpower
	
	power()
	diffs()
	
	snap = 1.0
	offset = 0.0
	
	var grip:float
	
	var gravity_incline:Vector3
	var dist_force:Vector2
	
	
	# WHEEL
	if is_colliding():
		var collider:Object = get_collider()
		#if collider.is_class("RayCast3D"):
		if "ground_vars" in collider:
			#Retrieve surface variables
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
		grip = (directional_force.y * tyre_maxgrip) * (surface_vars.ground_friction + surface_vars.fore_friction * CompoundSettings.ForeFriction)
		stress = grip
		
		#var r:float = 1.0 - rigidity
		
		#var patch_hardness:float = 1.0
		
		#var distw:float = velocity2.z - wv * w_size
		
		wv += (wheelpower * (1.0 - (1.0 / tyre_stiffness)))
		
		#the distribution of the wheel's velocity(?)
		var dist_v:Vector2 = Vector2(velocity2.x, velocity2.z - (wv * w_size))
		dist_force = dist_v / (surface_vars.drag + 1.0)
		
		offset = clampf(dist_v.y / w_size, -grip, grip)
		
		gravity_incline = (geometry.global_transform.basis.orthonormalized().transposed() * Vector3.UP)
		
		dist_v.x -= (gravity_incline.x * (directional_force.y / tyre_stiffness)) * 1.1
		
		compensate = gravity_incline.z * (directional_force.y / tyre_stiffness)
		
		slip_perc = dist_v
		
		dist_v *= tyre_stiffness
		
		#distx -= atan2(absf(wv), 1.0) * ((angle * 10.0) * w_size)
		dist_v.x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		#calculate the grip of the tire
		if grip > 0:
			var dist_v_squared:Vector2 = dist_v.abs() * dist_v.abs()
			var slipraw:float = sqrt(dist_v_squared.y + dist_v_squared.x)
			var slip:float = slipraw / grip
			
			slipraw = maxf(slipraw / CompoundSettings.TractionFactor, tyre_stiffness * (grip / tyre_stiffness))
			
			var ok:float = minf(((slipraw / tyre_stiffness) / grip) / w_size, 1.0)
			snap = minf(ok * w_weight_read, 1.0)
			
			slip_percpre = slip / tyre_stiffness
			
			slip /= slip * surface_vars.ground_builduprate + 1
			slip = maxf(slip - CompoundSettings.TractionFactor, 0.0)
			
			if absf(dist_v.y) / (tyre_stiffness / 3.0) > (car.ABS.threshold / grip) * pow(surface_vars.ground_friction, 2.0) and car.ABS.enabled and absf(velocity.z) > car.ABS.speed_pre_active and ContactABS:
				car._abspump = car.ABS.pump_time
				if absf(dist_v.x) / (tyre_stiffness / 3.0) > (car.ABS.lat_thresh / grip) * pow(surface_vars.ground_friction, 2.0):
					car._abspump = car.ABS.lat_pump_time
			
			var force_v:Vector2 = force_smoothing(- dist_v / (slip + 1.0))
			cache_friction_action = force_v.y * ok
			
			wv -= cache_friction_action
			wv += (wheelpower * (1.0 / tyre_stiffness))
			
			rollvol = velocity.length() * grip
			
			#Volume calculation?
			var new_slip_sk:float = sqrt(pow(absf(dist_v.x * 2.0), 2.0) + dist_v_squared.y) / grip
			new_slip_sk /= slip * surface_vars.ground_builduprate + 1
			new_slip_sk = maxf(new_slip_sk - CompoundSettings.TractionFactor, 0.0)
			sl = maxf(new_slip_sk - tyre_stiffness, 0.0)
			skvol = sl / 4.0
			
			skvol_d = slip * 25.0
	else:
		wv += wheelpower
		stress = 0.0
		rollvol = 0.0
		sl = 0.0
		skvol = 0.0
		skvol_d = 0.0
		#directional_force.y = 0.0
		compensate = 0.0
	
	slip_perc = Vector2.ZERO
	slip_perc2 = 0.0
	
	wv_diff = wv
	# FORCE
	if is_colliding():
		#Dear reader: 
		#I extensively debugged this next section of code (here till the end of if is_colliding)
		#to make sure it is mathmatically identical to the old code. It does not need to be checked
		#for accuracy, thank you
		
		#hitposition = get_collision_point()
		#Y force is dictated by suspension
		#directional_force.y = suspension() #called earlier in the same frame
		
		# FRICTION
		
		#Grip is the result of gravity multiplied by the tyre grip, 
		#times the ground and fore friction times the compound fore friction
		#var grip:float = (directional_force.y * tyre_maxgrip) * (surface_vars.ground_friction + surface_vars.fore_friction * CompoundSettings.ForeFriction)
		
		#var dist_v:Vector2 = Vector2(velocity2.x, velocity2.z - (wv * w_size) / (surface_vars.drag + 1.0))
		
		
		if  Differed_Wheel: #NodePath will return true if it's not ""
			var differed_wheel:ViVeWheel = car.get_node(Differed_Wheel)
			if is_instance_valid(differed_wheel):
				#dist_v.y = velocity2.z - ((wv * (1.0 - car._locked) + differed_wheel.wv_diff * car._locked) * w_size) / (surface_vars.drag + 1)
				dist_force.y = velocity2.z - ((wv * (1.0 - car._locked) + differed_wheel.wv_diff * car._locked) * w_size) / (surface_vars.drag + 1)
		
		#var grav_incline:float = (geometry.global_transform.basis.orthonormalized().transposed() * Vector3.UP).x
		#var grav_incline:float = gravity_incline.x
		
		
		#dist_v.x -= (grav_incline * (directional_force.y / tyre_stiffness)) * 1.1
		#dist_v.x -= (gravity_incline.x * (directional_force.y / tyre_stiffness)) * 1.1
		dist_force.x -= (gravity_incline.x * (directional_force.y / tyre_stiffness)) * 1.1
		
		
		dist_force *= tyre_stiffness
		
		#dist_v.x -= atan2(absf(wv), 1.0) * ((angle * 10.0) * w_size)
		#dist_v.x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		dist_force.x -= atan(absf(wv)) * ((angle * 10.0) * w_size)
		
		if grip > 0:
			#var dist_v_squared:Vector2 = dist_v.abs() * dist_v.abs()
			var dist_force_squared:Vector2 = dist_force.abs() * dist_force.abs()
			var slipraw:float = sqrt(dist_force_squared.y + dist_force_squared.x)
			
			var slip:float = slipraw / grip
			
			slip /= slip * surface_vars.ground_builduprate + 1.0
			slip = maxf(slip - CompoundSettings.TractionFactor, 0.0)
			
			slip_perc2 = slip
			
			#var force_v:Vector2 = - dist_v / (slip + 1.0)
			var force_v:Vector2 = force_smoothing(- dist_force / (slip + 1.0))
			
			directional_force = Vector3(force_v.x, directional_force.y, force_v.y)
	else:
		geometry.position = target_position
	
	output_wv = wv
	anim_camber_wheel.rotate_x(deg_to_rad(wv))
	
	geometry.position.y += w_size
	
	var inned:float = (absf(cambered) + A_Geometry4) / 90.0
	
	inned *= inned - A_Geometry4 / 90.0
	geometry.position.x = -inned * position.x
	anim_camber.rotation.z = - (deg_to_rad(- c_camber * float(position.x < 0.0) + c_camber * float(position.x > 0.0)) - deg_to_rad( - cambered * float(position.x < 0.0) + cambered * float(position.x > 0.0)) * A_Geometry2)
	var g:float
	
	axle_position = geometry.position.y
	if not Solidify_Axles: #If the NodePath is null
		g = (geometry.position.y + (absf(target_position.y) - A_Geometry1)) / (absf(position.x) + A_Geometry3 + 1.0)
		g /= absf(g) + 1.0
		cambered = (g * 90.0) - A_Geometry4
	else:
		g = (geometry.position.y - get_node(Solidify_Axles).axle_position) / (absf(position.x) + 1.0)
		g /= absf(g) + 1.0
		cambered = (g * 90.0)
	
	anim.position = geometry.position
	
	var forces:Vector3 #= (velo_2.global_transform.basis.orthonormalized() * (Vector3.BACK)) * directional_force.z + (velo_2.global_transform.basis.orthonormalized() * (Vector3.MODEL_LEFT)) * directional_force.x + (velo_2.global_transform.basis.orthonormalized() * (Vector3.MODEL_TOP)) * directional_force.y
	forces = velo_2.global_transform.basis.orthonormalized() * directional_force
	
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
	rolldist_clamped = clampf(rolldist, -1.0, 1.0)
	var g_range:float = absf(target_position.y)
	geometry.global_position = get_collision_point()
	geometry.position.y -= (ground_bump * surface_vars.ground_bump_height)
	
	geometry.position.y = maxf(geometry.position.y, - g_range)
	
	velo_1.global_transform = VitaVehicleSimulation.alignAxisToVector(velo_1.global_transform, get_collision_normal())
	velo_2.global_transform = VitaVehicleSimulation.alignAxisToVector(velo_2.global_transform, get_collision_normal())
	
	var positive_pos:float = float(position.x > 0.0)
	var negative_pos:float = float(position.x < 0.0)
	
	angle = (geometry.rotation_degrees.z - ( - c_camber * positive_pos + c_camber * negative_pos) + ( - cambered * positive_pos + cambered * negative_pos) * A_Geometry2) / 90.0
	
#	var incline = (own.get_collision_normal()-own.global_transform.basis.orthonormalized().xform(Vector3(0,1,0))).length()
	var incline:float = (get_collision_normal() - (global_transform.basis.orthonormalized() * Vector3.MODEL_TOP)).length()
	
	incline /= 1 - A_InclineArea
	
	incline = maxf(incline - A_InclineArea, 0.0)
	incline = minf(incline * A_ImpactForce, 1.0)
	
	geometry.position.y = minf(geometry.position.y, - g_range + S_MaxCompression * (1.0 - incline))
	
	var damp_variant:float = maxf(S_ReboundDamping * AR_Stiff * rolldist_clamped + 1.0, 0.0)
	
	#linearz is velocity.y
	if velocity.y < 0:
		#damp_variant = S_Damping * (AR_Stiff * (rolldist_clamped + 1.0))
		#Serious BS was taken here, as this is the "damping" var from _physics_process
		damp_variant = maxf(S_Damping * AR_Stiff * rolldist_clamped + 1.0, 0.0)
	
	
	var compressed:float = g_range - (global_position - get_collision_point()).length() - (ground_bump * surface_vars.ground_bump_height)
	#var compressed2:float = g_range - (global_position - get_collision_point()).length() - (ground_bump * ground_bump_height)
	var compressed2:float = compressed - (S_MaxCompression + (ground_bump * surface_vars.ground_bump_height))
	
	var j:float = maxf(compressed - S_RestLength, 0.0)
	
	compressed2 = maxf(compressed2, 0.0)
	
	var elasticity2:float = (S_Stiffness * AR_Elast * rolldist_clamped + 1.0) * (1.0 - incline) + (car.mass) * incline
	var damping2:float = damp_variant * (1.0 - incline) + (car.mass / 10.0) * incline
	
	var suspforce:float = j * elasticity2
	
	if compressed2 > 0.0:
		suspforce -= velocity.y * (car.mass / 10.0)
		suspforce += compressed2 * car.mass
	
	suspforce -= velocity.y * damping2
	
	rd = compressed
	
	return maxf(suspforce, 0.0)


func force_smoothing(input:Vector2) -> Vector2:
	var force_v:Vector2 = input
	var yes_v:Vector2 = force_v.abs().clamp(-Vector2.INF, Vector2.ONE)
	var smooth_v:Vector2 = Vector2(pow(yes_v.x, 2.0), yes_v.y).clamp(-Vector2.INF, Vector2.ONE)
	force_v /= (smooth_v * rigidity + Vector2(1.0 - rigidity, 1.0 - rigidity))
	return force_v
