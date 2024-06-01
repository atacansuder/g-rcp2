extends Resource

##An axle for a [ViVeWheel].
class_name ViVeWheelAxle

#these are originally from ViVeWheel, abstracted for convenience

##Axle vertical mounting position.
#Previously called A_Geometry1.
@export var Vertical_Mount:float = 1.15
##Camber gain factor.
#Previously called A_Geometry2.
@export var Camber_Gain:float = 1.0
##Axle lateral mounting position, affecting camber gain. 
##High negative values may mount them outside.
#Previously called A_Geometry3.
@export var Lateral_Mount_Pos:float = 0.0
##Related to the camber.
@export var Geometry4:float = 0.0

