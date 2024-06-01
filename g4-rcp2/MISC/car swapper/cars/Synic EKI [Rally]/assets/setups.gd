extends Control

var setup:int = 0

@export_group("Gravel Tyres")
@export var tire_gravel:ViVeTyreSettings 
@export var compound_gravel:TyreCompoundSettings
@export var axle_gravel:ViVeWheelAxle

@export_group("Tarmac Tyres")
@export var tire_tarmac:ViVeTyreSettings
@export var compound_tarmac:TyreCompoundSettings
@export var axle_tarmac:ViVeWheelAxle

@onready var wheels:Array[ViVeWheel] = [
	get_parent().get_node("fl"),
	get_parent().get_node("fr"),
	get_parent().get_node("rl"),
	get_parent().get_node("rr"),
]

func _on_setup_1_pressed() -> void:
	$setup1.release_focus()
	for i:ViVeWheel in wheels:
		i.get_node("animation/camber/wheel/wheel 1").visible = true
		i.get_node("animation/camber/wheel/wheel 2").visible = false
		i.TyreSettings = tire_gravel
		#i.CompoundSettings.ForeFriction = 1.0
		i.CompoundSettings = compound_gravel
		i.S_ReboundDamping = 12.0
		i.Camber = 0.0
		i.target_position.y = -3.2
		#i.target_position.y = -3.7
		i.W_PowerBias = 1.0
		#i.AxleSettings.Vertical_Mount = 1.2
		i.AxleSettings = axle_gravel
		if i.name.begins_with("f"):
			i.S_Stiffness = 70.0
			i.S_Damping = 4.0
		elif i.name.begins_with("r"):
			i.S_Stiffness = 45.0
			i.S_Damping = 3.0

func _on_setup_2_pressed() -> void:
	$setup2.release_focus()
	for i:ViVeWheel in wheels:
		i.get_node("animation/camber/wheel/wheel 1").visible = false
		i.get_node("animation/camber/wheel/wheel 2").visible = true
		i.TyreSettings = tire_tarmac
		#i.CompoundSettings.ForeFriction = 0.125
		i.CompoundSettings = compound_tarmac
		i.target_position.y = -2.9
		i.S_ReboundDamping = 12.0
		#i.AxleSettings.Vertical_Mount = 1.1
		i.AxleSettings = axle_tarmac
		
		if i.name.begins_with("f"):
			i.S_Stiffness = 110.0
			i.S_Damping = 6.0
			i.Camber = 0.0
			i.W_PowerBias = 0.5
		elif i.name.begins_with("r"):
			i.S_Stiffness = 90.0
			i.S_Damping = 5.0
			i.Camber = -1.0
			i.W_PowerBias = 1.0
