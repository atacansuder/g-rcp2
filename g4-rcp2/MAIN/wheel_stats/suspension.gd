extends Resource
##A resource for suspension values for a ViVeWheel
class_name ViVeWheelSuspension

##Spring Force.
@export var SpringStiffness:float = 47.0 #S_Stiffness
##Compression Dampening.
@export var CompressionDampening:float = 3.5 #S_Damping
##Rebound Dampening.
@export var ReboundDampening:float = 3.5 #S_ReboundDamping
##Suspension Deadzone.
@export var Deadzone:float = 0.0 #S_RestLength
##Compression Barrier.
@export var MaxCompression:float = 0.5 #S_MaxCompression
##Anti-roll Stiffness.
@export var AntiRollStiffness:float = 0.5 #AR_Stiff
##Anti-roll Reformation Rate. 
@export var AntiRollElasticity:float = 0.1 #AR_Elast
##Used in calculating suspension.
@export var InclineArea:float = 0.2
##Used in calculating suspension.
@export var ImpactForce:float = 1.5

func get_elasticity(sway_bar_compression_offset:float) -> float:
	return SpringStiffness * (AntiRollElasticity * sway_bar_compression_offset + 1.0)

func get_dampening(sway_bar_compression_offset:float) -> float:
	return CompressionDampening * (AntiRollStiffness * sway_bar_compression_offset + 1.0)

func get_rebound_dampening(sway_bar_compression_offset:float) -> float:
	return ReboundDampening * (AntiRollStiffness * sway_bar_compression_offset + 1.0)
