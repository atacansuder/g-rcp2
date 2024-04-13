extends Control

var car

func setcar():
	car = get_parent().get_node(get_parent().car)

func _ready():
	for i in $scroll/container.get_children():
		i.pressed = misc_graphics_settings.get(i.var_name)
		i.get_node("amount").text = str(i.pressed)

func _process(delta):
	#Patchwork fix, but should generally improve performance until a better fix is implemented
	if not visible: 
		return
	
	for i in $scroll/container.get_children():
		misc_graphics_settings.set(i.var_name,i.pressed)
		i.get_node("amount").text = str(i.pressed)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		visible = false
	elif Input.is_action_just_pressed("toggle_fs"):
		if $scroll/container/_FULLSCREEN.pressed:
			$scroll/container/_FULLSCREEN.pressed = false
		else:
			$scroll/container/_FULLSCREEN.pressed = true


func _on_Button_pressed():
	get_parent().get_node("open graphics").release_focus()
	if visible:
		visible = false
	else:
		Input.action_press("ui_cancel")
		yield(get_tree().create_timer(0.1), "timeout")
		Input.action_release("ui_cancel")
		visible = true
