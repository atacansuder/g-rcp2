extends RayCast

class_name ViVeWheel

export var RealismOptions = {
}

export var Steer:bool = true
export var Differed_Wheel = ""
export var SwayBarConnection = ""

export var W_PowerBias:float = 1.0
export var TyreSettings:Dictionary = {
	"GripInfluence": 1.0,
	"Width (mm)": 185.0,
	"Aspect Ratio": 60.0,
	"Rim Size (in)": 14.0
	}
export var TyrePressure = 30.0
export var Camber:float = 0.0
export var Caster:float = 0.0
export var Toe:float = 0.0

export var CompoundSettings = {
	"OptimumTemp": 50.0,
	"Stiffness": 1.0,
	"TractionFactor": 1.0,
	"DeformFactor": 1.0,
	"ForeFriction": 0.125,
	"ForeStiffness": 0.0,
	"GroundDragAffection": 1.0,
	"BuildupAffection": 1.0,
	"CoolRate": 0.000075}

export var S_Stiffness:float = 47.0
export var S_Damping:float = 3.5
export var S_ReboundDamping:float = 3.5
export var S_RestLength:float = 0.0
export var S_MaxCompression:float = 0.5
export var A_InclineArea:float = 0.2
export var A_ImpactForce:float = 1.5
export var AR_Stiff:float = 0.5
export var AR_Elast:float = 0.1
export var B_Torque:float = 15.0
export var B_Bias:float = 1.0
export var B_Saturation:float = 1.0 # leave this at 1.0 unless you have a heavy vehicle with large wheels, set it higher depending on how big it is
export var HB_Bias:float = 0.0
export var A_Geometry1:float = 1.15
export var A_Geometry2:float = 1.0
export var A_Geometry3:float = 0.0
export var A_Geometry4:float = 0.0
export var Solidify_Axles = NodePath()
export var ContactABS:bool = true
export var ESP_Role = ""
export var ContactBTCS:bool = false
export var ContactTTCS:bool = false


onready var car = get_parent()

var dist:float = 0.0
var w_size:float = 1.0
var w_size_read:float = 1.0
var w_weight_read:float = 0.0
var w_weight:float = 0.0
var wv:float = 0.0
var wv_ds:float = 0.0
var wv_diff:float = 0.0
var c_tp:float = 0.0
var effectiveness:float = 0.0

var angle:float = 0.0
var snap:float = 0.0
var absolute_wv:float = 0.0
var absolute_wv_brake:float = 0.0
var absolute_wv_diff:float = 0.0
var output_wv:float = 0.0
var offset:float = 0.0
var c_p:float = 0.0
var wheelpower:float = 0.0
var wheelpower_global:float = 0.0
var stress:float = 0.0
var rolldist:float = 0.0
var rd:float = 0.0
var c_camber:float = 0.0
var cambered:float = 0.0

var rollvol:float = 0.0
var sl:float = 0.0
var skvol:float = 0.0
var skvol_d:float = 0.0
var velocity = Vector3.ZERO
var velocity2 = Vector3.ZERO
var compress:float = 0.0
var compensate:float = 0.0
var axle_position:float = 0.0

var heat_rate:float = 1.0
var wear_rate:float = 1.0

var ground_bump:float = 0.0
var ground_bump_up:bool = false
var ground_bump_frequency:float = 0.0
var ground_bump_frequency_random:float = 1.0
var ground_bump_height:float = 0.0

var ground_friction:float = 1.0
var ground_stiffness:float = 1.0
var fore_friction:float = 0.0
var fore_stiffness:float = 0.0
var drag:float = 0.0
var ground_builduprate:float = 0.0
var ground_dirt:bool = false
var hitposition:Vector3 = Vector3.ZERO

var cache_tyrestiffness:float = 0.0
var cache_friction_action:float = 0.0

func _ready():
	c_tp = TyrePressure

func power():
	if not c_p == 0:
		dist *= (car.clutchpedal*car.clutchpedal) / (car.currentstable)
		var dist_cache:float = dist
		
		var tol:float = (.1475/1.3558) * car.ClutchGrip
		
		dist_cache = clamp(dist_cache, -tol, tol)
		
		var dist2:float = dist_cache
		
		car.dsweight += c_p
		car.stress += stress*c_p
		
		if car.dsweightrun>0.0:
			if car.rpm>car.DeadRPM:
				wheelpower -= (((dist2/car.ds_weight)/(car.dsweightrun/2.5))*c_p)/w_weight
			car.resistance += (((dist_cache*(10.0))/car.dsweightrun)*c_p)

func diffs():
	if car.locked>0.0:
		if not Differed_Wheel == "":
			var d_w = car.get_node(Differed_Wheel)
			snap = abs(d_w.wheelpower_global) / (car.locked * 16.0) + 1.0
			absolute_wv = output_wv+(offset*snap)
			var distanced2:float = abs(absolute_wv - d_w.absolute_wv_diff) / (car.locked * 16.0)
			distanced2 += abs(d_w.wheelpower_global) / (car.locked * 16.0)
			distanced2 = max(distanced2, snap)
			
			distanced2 += 1.0 / cache_tyrestiffness
			if distanced2 > 0.0:
				wheelpower += -((absolute_wv_diff - d_w.absolute_wv_diff) / distanced2)

func sway():
	if not SwayBarConnection == "":
		var linkedwheel = car.get_node(SwayBarConnection)
		rolldist = rd - linkedwheel.rd


var directional_force:Vector3 = Vector3.ZERO
var slip_perc:Vector2 = Vector2.ZERO
var slip_perc2:float = 0.0
var slip_percpre:float = 0.0

var velocity_last:Vector3 = Vector3.ZERO
var velocity2_last:Vector3 = Vector3.ZERO

func _physics_process(_delta):
	var last_translation = translation
	
	if Steer and abs(car.steer)>0:
		#var form1:float = 0.0
		#var form2 = car.steering_geometry[1] - translation.x
		var lasttransform = global_transform
		
		look_at_from_position(translation, Vector3(car.steering_geometry[0], 0, car.steering_geometry[1]), Vector3.UP)
		global_transform = lasttransform
		if car.steer > 0:
			rotate_object_local(Vector3.UP, - deg2rad(90.0))
		else:
			rotate_object_local(Vector3.UP, deg2rad(90.0))
		var roter:float = global_rotation.y
		
		look_at_from_position(translation,Vector3(car.Steer_Radius, 0, car.steering_geometry[1]), Vector3.UP)
		global_transform = lasttransform
		rotate_object_local(Vector3.UP,deg2rad(90.0))
		var roter_estimateed = rad2deg(global_rotation.y)
		
		get_parent().steering_angles.append(roter_estimateed)
		
		rotation_degrees = Vector3.ZERO
		
		rotation.y = roter

		rotation_degrees += Vector3(0,-((Toe * (float(translation.x > 0)) - Toe * float(translation.x < 0))),0)
	else:
		rotation_degrees = Vector3(0,-((Toe * (float(translation.x > 0)) - Toe * float(translation.x < 0))),0)
	
	translation = last_translation
	
	c_camber = Camber + Caster * rotation.y * float(translation.x > 0.0) - Caster * rotation.y * float(translation.x < 0.0)
	
	directional_force = Vector3.ZERO
	
	$velocity.translation = Vector3.ZERO

	
	w_size = ((abs(int(TyreSettings["Width (mm)"])) * ((abs(int(TyreSettings["Aspect Ratio"])) * 2.0) / 100.0) + abs(int(TyreSettings["Rim Size (in)"])) * 25.4) * 0.003269) / 2.0
	w_weight = pow(w_size, 2.0)
	
	w_size_read = max(w_size, 1.0)
	
	w_weight_read = max(w_weight_read, 1.0) #Looks like this could be skipped by placing this in the setter function
	
	$velocity2.global_translation = $geometry.global_translation
	
	$velocity/step.global_translation = velocity_last
	$velocity2/step.global_translation = velocity2_last
	velocity_last = $velocity.global_translation
	velocity2_last = $velocity2.global_translation
	
	velocity = -$velocity/step.translation * 60.0
	velocity2 = -$velocity2/step.translation * 60.0

	$velocity.rotation = Vector3.ZERO
	$velocity2.rotation = Vector3.ZERO

	# VARS
	var elasticity = S_Stiffness
	var damping = S_Damping
	var damping_rebound = S_ReboundDamping
	
	var swaystiff = AR_Stiff
	var swayelast = AR_Elast
	
	var s:float = clamp(rolldist, -1.0, 1.0)
	
	
	elasticity *= swayelast *  s  + 1.0
	damping *= swaystiff * s  + 1.0
	damping_rebound *= swaystiff * s + 1.0
	
	elasticity = max(elasticity, 0.0)
	
	damping = max(damping, 0.0)
	
	damping_rebound = max(damping_rebound, 0.0)
	
	
	sway()
	
	var tyre_maxgrip = TyreSettings["GripInfluence"]/CompoundSettings["TractionFactor"]
	
	
	var tyre_stiffness2 = abs(int(TyreSettings["Width (mm)"]))/(abs(int(TyreSettings["Aspect Ratio"]))/1.5)
	
	var deviding = (Vector2(velocity.x,velocity.z).length()/50.0 +0.5)*CompoundSettings["DeformFactor"]
	
	deviding /= ground_stiffness +fore_stiffness*CompoundSettings["ForeStiffness"]
	if deviding<1.0:
		deviding = 1.0
	tyre_stiffness2 /= deviding
	
	
	var tyre_stiffness = (tyre_stiffness2*((c_tp/30.0)*0.1 +0.9) )*CompoundSettings["Stiffness"] +effectiveness
	tyre_stiffness = max(tyre_stiffness, 1.0)
	
	cache_tyrestiffness = tyre_stiffness
	
	absolute_wv = output_wv+(offset*snap) -compensate*1.15296
	absolute_wv_brake = output_wv+((offset/w_size_read)*snap) -compensate*1.15296
	absolute_wv_diff = output_wv
	
	wheelpower = 0.0

	var braked = car.brakeline*B_Bias + car.handbrakepull*HB_Bias
	braked = min(braked, 1.0)
	
	var bp = (B_Torque*braked)/w_weight_read
	
	if not car.actualgear == 0:
		if car.dsweightrun>0.0:
			bp += ((car.stalled*(c_p/car.ds_weight))*car.clutchpedal)*(((500.0/(car.RevSpeed*100.0))/(car.dsweightrun/2.5))/w_weight_read)
	if bp>0.0:
		if abs(absolute_wv)>0.0:
			var distanced = abs(absolute_wv)/bp
			distanced -= car.brakeline
			if distanced<snap*(w_size_read/B_Saturation):
				distanced = snap*(w_size_read/B_Saturation)
			wheelpower += -absolute_wv/distanced
		else:
			wheelpower += -absolute_wv
	
	wheelpower_global = wheelpower
	
	power()
	diffs()
	
	snap = 1.0
	offset = 0.0
	
	# WHEEL
	if is_colliding():
		if "drag" in get_collider():
			drag = get_collider().get("drag")*CompoundSettings["GroundDragAffection"]*CompoundSettings["GroundDragAffection"]
		if "ground_friction" in get_collider():
			ground_friction = get_collider().get("ground_friction")
		if "fore_friction" in get_collider():
			fore_friction = get_collider().get("fore_friction")
		if "ground_stiffness" in get_collider():
			ground_stiffness = get_collider().get("ground_stiffness")
		if "fore_stiffness" in get_collider():
			fore_stiffness = get_collider().get("fore_stiffness")
		if "ground_builduprate" in get_collider():
			ground_builduprate = get_collider().get("ground_builduprate")*CompoundSettings["BuildupAffection"]
		if "ground_dirt" in get_collider():
			ground_dirt = get_collider().get("ground_dirt")
		if "ground_bump_frequency" in get_collider():
			ground_bump_frequency = get_collider().get("ground_bump_frequency")
		if "ground_bump_frequency_random" in get_collider():
			ground_bump_frequency_random = get_collider().get("ground_bump_frequency_random") +1.0
		if "ground_bump_height" in get_collider():
			ground_bump_height = get_collider().get("ground_bump_height")
		if "wear_rate" in get_collider():
			wear_rate = get_collider().get("wear_rate")
		if "heat_rate" in get_collider():
			heat_rate = get_collider().get("heat_rate")
		if ground_bump_up:
			ground_bump -= rand_range(ground_bump_frequency/ground_bump_frequency_random,ground_bump_frequency*ground_bump_frequency_random)*(velocity.length()/1000.0)
			if ground_bump<0.0:
				ground_bump = 0.0
				ground_bump_up = false
		else:         
			ground_bump += rand_range(ground_bump_frequency/ground_bump_frequency_random,ground_bump_frequency*ground_bump_frequency_random)*(velocity.length()/1000.0)
			if ground_bump>1.0:
				ground_bump = 1.0
				ground_bump_up = true

		var suspforce = VitaVehicleSimulation.suspension(self,S_MaxCompression,A_InclineArea,A_ImpactForce,S_RestLength, elasticity,damping,damping_rebound, velocity.y,abs(cast_to.y),global_translation,get_collision_point(),car.mass,ground_bump,ground_bump_height)
		compress = suspforce

		# FRICTION
		var grip = (suspforce*tyre_maxgrip)*(ground_friction +fore_friction*CompoundSettings["ForeFriction"])
		stress = grip
		var rigidity:float = 0.67

		var distw = velocity2.z - wv*w_size
		wv += (wheelpower*(1.0-(1.0/tyre_stiffness)))
		var disty = velocity2.z - wv*w_size

		offset = disty/w_size
		
		offset = clamp(offset, -grip, grip)
		
		var distx = velocity2.x
		
		var compensate2 = suspforce
		var grav_incline = $geometry.global_transform.basis.orthonormalized().xform_inv(Vector3.UP).x
		var grav_incline2 = $geometry.global_transform.basis.orthonormalized().xform_inv(Vector3.UP).z
		
		compensate = grav_incline2*(compensate2/tyre_stiffness)
		
		distx -= (grav_incline*(compensate2/tyre_stiffness))*1.1
		
		disty *= tyre_stiffness
		distw *= tyre_stiffness
		distx *= tyre_stiffness
		
		distx -= atan2(abs(wv),1.0)*((angle*10.0)*w_size)
		
		if grip>0:
			
			var slip = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))/grip
			
			slip_percpre = slip/tyre_stiffness
			
			slip /= slip*ground_builduprate +1
			slip -= CompoundSettings["TractionFactor"]
			slip = max(slip, 0)
			
			var slip_sk = sqrt(pow(abs(disty),2.0) + pow(abs((distx)*2.0),2.0))/grip
			slip_sk /= slip*ground_builduprate +1
			slip_sk -= CompoundSettings["TractionFactor"]
			slip_sk = max(slip_sk, 0)
			
			
			var slipw = sqrt(pow(abs(0.0),2.0) + pow(abs(distx),2.0))/grip
			slipw /= slipw*ground_builduprate +1.0
			var forcey = -disty/(slip +1.0)
			var forcex = -distx/(slip +1.0)
			
			if abs(disty) /(tyre_stiffness/3.0)>(car.ABS[0]/grip)*(ground_friction*ground_friction) and car.ABS[3] and abs(velocity.z)>car.ABS[2] and ContactABS:
				car.abspump = car.ABS[1]
				if abs(distx) /(tyre_stiffness/3.0)>(car.ABS[5]/grip)*(ground_friction*ground_friction):
					car.abspump = car.ABS[6]
				
			var yesx = min(abs(forcex), 1.0)
			
			var smoothx = min(yesx*yesx, 1.0)
			
			var yesy = min(abs(forcey), 1.0)
			
			var smoothy = min(yesy*1.0, 1.0)
			
			forcex /= (smoothx*(rigidity) +(1.0-rigidity))
			forcey /= (smoothy*(rigidity) +(1.0-rigidity))
				
			var distyw = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))
			var tr = (grip/tyre_stiffness)
			var afg = tyre_stiffness*tr
			distyw /= CompoundSettings["TractionFactor"]
			distyw = max(distyw, afg)
			
			var ok = min(((distyw/tyre_stiffness)/grip)/w_size, 1.0)
			
			snap = min(ok*w_weight_read, 1.0)
			
			wv -= forcey*ok
			
			cache_friction_action = forcey*ok
			
			wv += (wheelpower*(1.0/tyre_stiffness))
			
			rollvol = velocity.length()*grip
			
			sl = max(slip_sk-tyre_stiffness, 0.0)
			
			skvol = sl/4.0
			
#			skvol *= skvol
			
			skvol_d = slip*25.0
	else:
		wv += wheelpower
		stress = 0.0
		rollvol = 0.0
		sl = 0.0
		skvol = 0.0
		skvol_d = 0.0
		compress = 0.0
		compensate = 0.0
	
	slip_perc = Vector2(0,0)
	slip_perc2 = 0.0
	
	wv_diff = wv
	# FORCE
	if is_colliding():
		hitposition = get_collision_point()
		directional_force.y = VitaVehicleSimulation.suspension(self,S_MaxCompression,A_InclineArea,A_ImpactForce,S_RestLength, elasticity,damping,damping_rebound, velocity.y,abs(cast_to.y),global_translation,get_collision_point(),car.mass,ground_bump,ground_bump_height)

		# FRICTION
		var grip = (directional_force.y*tyre_maxgrip)*(ground_friction +fore_friction*CompoundSettings["ForeFriction"])
		var rigidity:float = 0.67
		var r:float = 1.0-rigidity
		
		var patch_hardness:float = 1.0
		
		
		var disty = velocity2.z - (wv*w_size)/(drag +1.0)
		if not Differed_Wheel == "":
			var d_w = car.get_node(Differed_Wheel)
			disty = velocity2.z - ((wv*(1.0-get_parent().locked) +d_w.wv_diff*get_parent().locked)*w_size)/(drag +1)
		
		var distx = velocity2.x
		
		var compensate2 = directional_force.y
		var grav_incline = $geometry.global_transform.basis.orthonormalized().xform_inv(Vector3.UP).x
		
		distx -= (grav_incline*(compensate2/tyre_stiffness))*1.1
		
		slip_perc = Vector2(distx,disty)
		
		disty *= tyre_stiffness
		distx *= tyre_stiffness
		
		distx -= atan2(abs(wv),1.0)*((angle*10.0)*w_size)
		
		if grip>0:
			
			var slipraw = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))
			if slipraw>grip:
				 slipraw = grip
			
			var slip = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))/grip
			slip /= slip*ground_builduprate +1.0
			slip -= CompoundSettings["TractionFactor"]
			slip = max(slip, 0)
			
			slip_perc2 = slip
				
			var forcey = -disty/(slip +1.0)
			var forcex = -distx/(slip +1.0)
			
			var yesx = min(abs(forcex), 1.0)
			
			var smoothx = min(yesx*yesx, 1.0)
			
			var yesy = min(abs(forcey), 1.0)
			
			var smoothy = min(yesy*1.0, 1.0)
			
			forcex /= (smoothx*(rigidity) +(1.0-rigidity))
			forcey /= (smoothy*(rigidity) +(1.0-rigidity))
				
			directional_force.x = forcex
			directional_force.z = forcey
	else:
		$geometry.translation = cast_to
	
	output_wv = wv
	$animation/camber/wheel.rotate_x(deg2rad(wv))
	
	$geometry.translation.y += w_size
	
	var inned = (abs(cambered)+A_Geometry4)/90.0
	
	inned *= inned -A_Geometry4/90.0
	
	$geometry.translation.x = -inned*translation.x
	
	$animation/camber.rotation.z = -(deg2rad(-c_camber*float(translation.x<0.0) + c_camber*float(translation.x>0.0)) -deg2rad(-cambered*float(translation.x<0.0) + cambered*float(translation.x>0.0))*A_Geometry2)
	
	var g
	
	axle_position = $geometry.translation.y
	
	if Solidify_Axles == "":
		g = ($geometry.translation.y+(abs(cast_to.y) -A_Geometry1))/(abs(translation.x)+A_Geometry3 +1.0)
		g /= abs(g) +1.0
		cambered = (g*90.0) -A_Geometry4
	else:
		g = ($geometry.translation.y - get_node(Solidify_Axles).axle_position)/(abs(translation.x) +1.0)
		g /= abs(g) +1.0
		cambered = (g*90.0)
	
	$animation.translation = $geometry.translation
		
	var forces = $velocity2.global_transform.basis.orthonormalized().xform(Vector3(0,0,1))*directional_force.z + $velocity2.global_transform.basis.orthonormalized().xform(Vector3(1,0,0))*directional_force.x + $velocity2.global_transform.basis.orthonormalized().xform(Vector3.UP)*directional_force.y
	
	car.apply_impulse(hitposition-car.global_transform.origin,forces)
	
	# torque
	
	var torqed = (wheelpower*w_weight)/4.0
	
	wv_ds = wv
	
#	car.apply_impulse($geometry.global_transform.origin-car.global_transform.origin +$velocity2.global_transform.basis.orthonormalized().xform(Vector3(0,0,1)),$velocity2.global_transform.basis.orthonormalized().xform(Vector3.UP)*torqed)
#	car.apply_impulse($geometry.global_transform.origin-car.global_transform.origin -$velocity2.global_transform.basis.orthonormalized().xform(Vector3(0,0,1)),$velocity2.global_transform.basis.orthonormalized().xform(Vector3.UP)*-torqed)

