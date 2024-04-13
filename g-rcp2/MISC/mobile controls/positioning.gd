extends TouchScreenButton

onready var default_pos:Vector2 = position / get_parent().base_resolution
onready var default_size:Vector2 = scale / get_parent().base_resolution

func _ready():
	re_scale() 

func re_scale() -> void:
	position = default_pos * OS.get_real_window_size()
	scale = default_size * OS.get_real_window_size()

func press(state):
	if state:
		Input.action_press(name)
	else:
		Input.action_release(name)
