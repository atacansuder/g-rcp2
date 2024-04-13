extends Node

var reflections:bool = false
var shadows:bool = false
var smoke:bool = false
var use_procedual_sky:bool = false
var fxaa:bool = false
var fs:bool = false


var fs2:bool = false

func _process(delta:float) -> void:
	get_viewport().fxaa = fxaa
	
	if not fs2 == fs:
		fs2 = fs
		fs_toggle()

func fs_toggle() -> void:
	if not fs:
		OS.window_borderless = false
		OS.window_size = Vector2(ProjectSettings.get("display/window/size/width"),ProjectSettings.get("display/window/size/height"))
		OS.window_position = OS.get_screen_size()/2 -Vector2(ProjectSettings.get("display/window/size/width"),ProjectSettings.get("display/window/size/height"))/2
	else:
		OS.window_borderless = true
		OS.window_size = OS.get_screen_size()
		OS.window_size.y += 1
		OS.window_position = Vector2(0,0)
