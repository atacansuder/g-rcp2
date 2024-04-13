extends Spatial

var length:float = 0.0
var width:float = 0.0
var weight:float = 0.0
var dirt:float = 0.0

var wheels:Array = []

func play():
	for i in get_children():
		i.unit_db = linear2db(0.0)
		i.play()

func stop():
	for i in get_children():
		i.stop()

func _ready():
	for i in get_parent().get_children():
		if "TyreSettings" in i:
			wheels.append(i)
	
	play()

func most_skidding(array):
	var val = -10000000000000000000000000000000000.0
	var obj
	for i in array:
		val = max(val, abs(i.skvol))
		
		if val == abs(i.skvol):
			obj = i

	return obj

func _physics_process(delta):
	dirt = 0.0
	for i in wheels:
		dirt += float(i.ground_dirt) / len(wheels)
	
	var wheel = most_skidding(wheels)
	
	length = wheel.skvol/2.0 -1.0
	
	var roll:float = abs(wheel.wv * wheel.w_size) - wheel.velocity.length()
	
	length = min(length, 2.0)
	
	width -= (width - (1.0 - (roll / 10.0 - 1.0))) * 0.05
	
	
	width = clamp(width, 0.0, 1.0)
	
	var total:float = 0.0
	
	for i in wheels:
		total += i.skvol
	
	total /= 10.0
	
	total = min(total, 1.0)
	
	var mult:float = (get_parent().linear_velocity.length() / 5000.0 + 1.0)
#	$roll0.pitch_scale = 1.0 / (get_parent().linear_velocity.length() / 500.0 + 1.0)
	$roll1.pitch_scale = 1.0 / mult
	$roll2.pitch_scale = 1.0 / mult
	$peel0.pitch_scale = 0.95 + length / 8.0 / mult
	$peel1.pitch_scale = 1.0 / mult
	$peel2.pitch_scale = 1.1 - total * 0.1 / mult
	
	var drit:float = min((get_parent().linear_velocity.length() * wheel.stress)/1000.0 -0.1, 0.5)
	
	drit += wheel.skvol/2.0 -0.1
	
	drit = clamp(drit, 0.0, 1.0)
	
	drit *= dirt
	
	for i in get_children():
		if i.name == "dirt":
			i.unit_db = linear2db(drit * 0.3)
			i.max_db = i.unit_db
			i.pitch_scale = 1.0 + length * 0.05 + abs(roll/100.0)
		else:
			var dist:float = pow(abs(i.length - length), 2)
			var dist2:float = pow(abs(i.width - width), 2)
			
			#dist *= abs(dist)
			#dist2 *= abs(dist2)
			
			var vol:float = clamp(1.0 - (dist + dist2), 0.0, 1.0)
			
			i.unit_db = linear2db(((vol * (1.0-dirt))*i.volume)*0.35)
			i.max_db = i.unit_db
