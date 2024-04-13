extends Spatial

export var backfire_FuelRichness:float = 0.2
export var backfire_FuelDecay:float = 0.1
export var backfire_Air:float = 0.02
export var backfire_BackfirePrevention:float = 0.1
export var backfire_BackfireThreshold:float = 1.0
export var backfire_BackfireRate:float = 1.0
export var backfire_Volume:float = 0.5


export var WhinePitch = 4
export var WhineVolume:float = 0.4
 
export var BlowOffBounceSpeed:float = 0.0
export var BlowOffWhineReduction:float = 1.0
export var BlowDamping:float = 0.25
export var BlowOffVolume:float = 0.5
export var BlowOffVolume2:float = 0.5
export var BlowOffPitch1:float = 0.5
export var BlowOffPitch2:float = 1.0
export var MaxWhinePitch:float = 1.8
export var SpoolVolume:float = 0.5
export var SpoolPitch:float = 0.5
export var BlowPitch:float = 1.0
export var TurboNoiseRPMAffection:float = 0.25

export var engine_sound = NodePath("../engine_sound")
export(Array,NodePath) var exhaust_particles = []

export var volume:float = 0.25
var blow_psi:float = 0.0
var blow_inertia:float = 0.0

var fueltrace:float = 0.0
var air:float = 0.0
var rand:float = 0.0

func play():
	$blow.stop()
	$spool.stop()
	$whistle.stop()
	$scwhine.stop()
	$whigh.play()
	$wlow.play()

	if get_parent().TurboEnabled:
		$blow.play()
		$spool.play()
		$whistle.play()
	if get_parent().SuperchargerEnabled:
		$scwhine.play()

func stop():
	for i in get_children():
		i.stop()

func _ready():
	play()

func _physics_process(delta):
	fueltrace += (get_parent().throttle)*backfire_FuelRichness
	air = (get_parent().throttle*get_parent().rpm)*backfire_Air +get_parent().turbopsi

	fueltrace -= fueltrace * backfire_FuelDecay
	
	fueltrace = max(fueltrace, 0.0)
	
	if has_node(engine_sound):
		get_node(engine_sound).pitch_influence -= (get_node(engine_sound).pitch_influence - 1.0)*0.5

	if get_parent().rpm>get_parent().DeadRPM:
		if fueltrace > rand_range(air * backfire_BackfirePrevention + backfire_BackfireThreshold, 60.0 / backfire_BackfireRate):
			rand = 0.1
			
			var ft:float = max(fueltrace, 10)
			
			
			$backfire.play()
			
			var yed:float = max(1.5-ft * 0.1, 1.0)
			
			$backfire.pitch_scale = rand_range(yed * 1.25,yed * 1.5)
			$backfire.unit_db = linear2db((ft * backfire_Volume) * 0.1)
			$backfire.max_db = $backfire.unit_db
			get_node(engine_sound).pitch_influence = 0.5
			for i in exhaust_particles:
				get_node(i).emitting = true
		else:
			for i in exhaust_particles:
				get_node(i).emitting = false
	
	var wh:float = max(abs(get_parent().rpm / 10000.0) * WhinePitch, 0.0)
	
	if wh > 0.01:
		$scwhine.unit_db = linear2db(WhineVolume * volume)
		$scwhine.max_db = $scwhine.unit_db
		$scwhine.pitch_scale = wh
	else:
		$scwhine.unit_db = linear2db(0.0)


	var dist:float = blow_psi - get_parent().turbopsi
	blow_psi -= (dist) * BlowOffWhineReduction
	blow_inertia += dist
	blow_inertia -= (blow_inertia - dist) * BlowDamping
	blow_psi -= blow_inertia * BlowOffBounceSpeed
	
	blow_psi = min(blow_psi, get_parent().MaxPSI)
	
	var blowvol:float = clamp(dist, 0.0, 1.0)
	
	var spoolvol:float = clamp(get_parent().turbopsi/10.0, 0.0, 1.0)

	spoolvol += (abs(get_parent().rpm) * (TurboNoiseRPMAffection/1000.0)) * spoolvol
	
	var blow:float = max(linear2db(volume*(blowvol*BlowOffVolume2)), -60.0)
	
	var spool:float = max(linear2db(volume*(spoolvol*SpoolVolume)), -60.0)
	
	$blow.unit_db = blow
	$spool.unit_db = spool
	
	$blow.max_db = $blow.unit_db
	$spool.max_db = $spool.unit_db
	
	var yes:float = clamp(blowvol*BlowOffVolume, 0.0, 1.0)
	var whistle:float = max(linear2db(yes), -60.0)
	
	$whistle.unit_db = whistle
	$whistle.max_db = $whistle.unit_db
	var wps:float = 1.0
	if get_parent().turbopsi > 0.0:
		wps = blowvol * BlowOffPitch2 + get_parent().turbopsi * 0.05 + BlowOffPitch1
	else:
		wps = blowvol * BlowOffPitch2 + BlowOffPitch1
	
	$whistle.pitch_scale = min(wps, MaxWhinePitch)
	$spool.pitch_scale = SpoolPitch + spoolvol * 0.5
	$blow.pitch_scale = BlowPitch
	
	var h:float = clamp(get_parent().whinepitch/200.0, 0.5, 1.0)
	
	var wlow:float = max(linear2db(((get_parent().gearstress * get_parent().GearGap) / 160000.0) * ((1.0 - h) * 0.5)), -60.0)
	$wlow.unit_db = wlow
	$wlow.max_db = $wlow.unit_db
	
	if get_parent().whinepitch/50.0 > 0.0001:
		$wlow.pitch_scale = get_parent().whinepitch / 50.0
	var whigh = max(linear2db(((get_parent().gearstress*get_parent().GearGap) / 80000.0) * 0.5), -60.0)
	
	$whigh.unit_db = whigh
	$whigh.max_db = $whigh.unit_db
	if get_parent().whinepitch/100.0 > 0.0001:
		$whigh.pitch_scale = get_parent().whinepitch/100.0





