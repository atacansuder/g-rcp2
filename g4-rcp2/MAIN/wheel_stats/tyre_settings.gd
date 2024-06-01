extends Resource
##A [Resource] for tyre settings.
class_name ViVeTyreSettings

##Grip and traction amplification.
@export var GripInfluence:float = 1.0
##Width of the tyre, in nanometers.
@export var Width_mm:int = 185
##Aspect ratios are delivered in percentages. 
##Tire makers calculate the aspect ratio by dividing a tire's height off the rim by its width. 
##If a tire has an aspect ratio of 70, it means the tire's height is 70 percent of its width.
@export_range(0.0, 100.0) var Aspect_Ratio:float = 60.0
##Rim size, in inches(?).
@export var Rim_Size_in:int = 14
##Air pressure of the tire, in PSI (hypothetical).
#previously [TyrePressure]
@export var AirPressure:float = 30.0
