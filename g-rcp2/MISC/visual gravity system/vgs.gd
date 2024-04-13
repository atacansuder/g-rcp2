extends Control

export var Scale:float = 1.0
export var MaxG:float = 0.75

export var gforce:Vector2 = Vector2(0,0)

onready var wheel = $wheel.duplicate()

var glength:float = 0.0

var appended = []

func _ready():
	$wheel.queue_free()
	
func clear():
	for i in appended:
		i.queue_free()
	appended = []
	
	
func append_wheel(position,settings,node):
	var w_size:float = ((abs(int(settings["Width (mm)"])) * ((abs(int(settings["Aspect Ratio"])) * 2.0) / 100.0) + abs(int(settings["Rim Size (in)"])) * 25.4) * 0.003269) / 2.0
	var width:float = (abs(int(settings["Width (mm)"])) * 0.003269) / 2.0
	
	var w = wheel.duplicate()
	add_child(w)
	w.pos = -Vector2(position.x,position.z)*2.0
	w.setting = settings
	w.node = node
	
	w.scale.x = (width * 2.0) / (Scale / 2.0)
	w.scale.y = w_size / (Scale / 2.0)
	
	appended.append(w)

func _physics_process(delta):
	
	for i in appended:
		i.position = rect_size / 2
		i.position += ((i.pos * (64.0 / Scale)) / 9.806)
		
		i.get_node("slippage").scale.y = max((i.node.slip_percpre) * 0.8, 0.0)
		
		i.rotation = -i.node.rotation.y
		
		i.self_modulate = Color.white
		if i.get_node("slippage").scale.y > 0.8:
			i.get_node("slippage").scale.y = 0.8
			if abs(i.node.wv * i.node.w_size) > i.node.velocity.length():
				i.self_modulate = Color.red
	
	glength = max(gforce.abs().length() / Scale - 1.0, 0.0)
	if gforce.abs().length() > MaxG:
		$centre/Circle.modulate = Color.khaki
	else:
		$centre/Circle.modulate = Color.orange
	
	gforce /= glength + 1.0
	
	$centre.position = rect_size / 2 + gforce * (64.0 / Scale)
	$field.position = rect_size / 2
	
