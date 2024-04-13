extends ReflectionProbe


func _process(delta):
	if misc_graphics_settings.reflections:
		visible = true
		global_translation = get_viewport().get_camera().global_translation
		global_translation.y = -get_viewport().get_camera().global_translation.y -50.0
	else:
		visible = false
