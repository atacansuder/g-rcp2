extends Resource

##Compound settings for tires.
class_name TyreCompoundSettings

##@experimental Optimum tyre temperature for maximum grip effect. (Currently isn't used).
@export var OptimumTemp:float = 50.0

@export var Stiffness:float = 1.0
##Higher value would reduce grip.
@export var TractionFactor:float = 1.0:
	#This is currently the only setting used in this way, thus the only with the trigger here so far.
	set(new_factor):
		TractionFactor = new_factor
		wheel_parent.set_physical_stats()

@export var DeformFactor:float = 1.0

@export var ForeFriction:float = 0.125

@export var ForeStiffness:float = 0.0

@export var GroundDragAffection:float = 1.0
##Increase in grip on loose surfaces.
@export var BuildupAffection:float = 1.0
##@experimental Tyre Cooldown Rate. (Currently isn't used).
@export var CoolRate:float = 0.000075

##Reference to the owning/parent ViVeWheel
var wheel_parent:ViVeWheel

#@export var _CompoundSettings:Dictionary = {
#	"OptimumTemp": 50.0,
#	"Stiffness": 1.0,
#	"TractionFactor": 1.0,
#	"DeformFactor": 1.0,
#	"ForeFriction": 0.125,
#	"ForeStiffness": 0.0,
#	"GroundDragAffection": 1.0,
#	"BuildupAffection": 1.0,
#	"CoolRate": 0.000075}
