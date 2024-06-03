@tool
extends Node

class_name ViVeSimulation
#This is VitaVehicleSimulation

enum GearAssist {
	Manual = 0,
	Semi_manual = 1,
	Auto = 2,
}

var GearAssistant:int = 2 # 0 = manual, 1 = semi-manual, 2 = auto

@export var universal_controls:ViVeCarControls = ViVeCarControls.new()

func fastest_wheel(array:Array[ViVeWheel]) -> ViVeWheel:
	var val:float = 0.0
	var obj:ViVeWheel
	
	for i:ViVeWheel in array:
		val = maxf(val, absf(i.absolute_wv))
		if val == absf(i.absolute_wv):
			obj = i
	return obj

func slowest_wheel(array:Array[ViVeWheel]) -> ViVeWheel:
	var val:float = 10000000000000000000000000000000000.0
	var obj:ViVeWheel
	
	for i:ViVeWheel in array:
		val = minf(val, absf(i.absolute_wv))
		
		if val == absf(i.absolute_wv):
			obj = i
	
	return obj

