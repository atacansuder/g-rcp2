extends Control

var currentrpm:float = 0.0
var currentpsi:float = 0.0

export var Turbo_Visible:float = false
export var Max_PSI:float = 13.0
export var RPM_Range:float = 9000.0
export var Redline:float = 7000.0

var generated:Array = []

func _ready():
	$turbo.visible = Turbo_Visible
	$turbo/maxpsi.text = str(int(Max_PSI))
	if generated.size() > 0:
		for i in generated:
			i.queue_free()
		generated.clear()
	
	var lowangle = -120
	var highangle = 120
	
	var maximum:float = int(RPM_Range / 1000.0)
	var red:float = Redline / 1000.0 - 0.001
	
	for i in range(maximum + 1):
		var dist:float = float(i) / float(maximum)
		var dist2:float = (float(i) + 0.25) / float(maximum)
		var dist3:float = (float(i) + 0.5) / float(maximum)
		var dist4:float = (float(i) + 0.75) / float(maximum)
		
		var d:ColorRect = $tacho/major.duplicate(true)
		$tacho.add_child(d)
		d.rect_rotation = lowangle * (1.0 - dist) + highangle * dist
		d.visible = true
		d.get_node("tetx").text = str(i)
		d.get_node("tetx").rect_rotation = - d.rect_rotation
		generated.append(d)
		
		if float(i) > red:
			d.color = Color.red
		
		if len(d.get_node("tetx").text) > 1:
			d.get_node("tetx").rect_position.y += 5
		
		if not i == maximum:
			d = $tacho/minor.duplicate(true)
			$tacho.add_child(d)
			d.rect_rotation = lowangle * (1.0 - dist2) + highangle * dist2
			d.visible = true
			generated.append(d)
			if float(i + 0.25) > red:
				d.color = Color.red
			
			d = $tacho/minor.duplicate(true)
			$tacho.add_child(d)
			d.rect_rotation = lowangle * (1.0 - dist3) + highangle * dist3
			d.visible = true
			generated.append(d)
			if float(i + 0.5) > red:
				d.color = Color.red
			
			d = $tacho/minor.duplicate(true)
			$tacho.add_child(d)
			d.rect_rotation = lowangle * (1.0 - dist4) + highangle * dist4
			d.visible = true
			generated.append(d)
			if float(i + 0.75) > red:
				d.color = Color.red

func _process(delta):
	$tacho/needle.rect_rotation = -120.0 + 240.0 * (abs(currentrpm) / RPM_Range)
	
	$turbo/needle.rect_rotation = max(-90.0 + 180.0 * (currentpsi / Max_PSI), -90.0)

