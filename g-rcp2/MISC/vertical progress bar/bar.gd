extends ColorRect

export var scale:float = 0.0


func _process(delta):
	$ColorRect.rect_pivot_offset.y = rect_size.y
	$ColorRect.rect_scale.y = scale
