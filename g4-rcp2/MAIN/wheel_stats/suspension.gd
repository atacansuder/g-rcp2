extends Resource
##A resource for suspension values for a ViVeWheel
class_name ViVeWheelSuspension

##Spring Force.
#S_Stiffness
@export var SpringStiffness:float = 47.0
##Compression Dampening.
#S_Damping
@export var CompressionDampening:float = 3.5
##Rebound Dampening.
#S_ReboundDamping
@export var ReboundDampening:float = 3.5
##Suspension Deadzone.
#S_RestLength
@export var Deadzone:float = 0.0
##Compression Barrier.
#S_MaxCompression
@export var MaxCompression:float = 0.5
##Anti-roll Stiffness.
#AR_Stiff
@export var AntiRollStiffness:float = 0.5
##Anti-roll Reformation Rate.
#AR_Elast
@export var AntiRoolElasticity:float = 0.1
##Used in calculating suspension.
@export var InclineArea:float = 0.2
##Used in calculating suspension.
@export var ImpactForce:float = 1.5
