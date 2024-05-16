extends ScrollContainer

@onready var button:Button = $container/_DEFAULT.duplicate()

const pathh:String = "res://MISC/scene swapper/"
var canclick:bool = true
var literal_cache:Dictionary = {}

func list_files_in_directory(path:String) -> PackedStringArray:
	
	var files:PackedStringArray = []
#	var dir = Directory.new()
	var dir:DirAccess = DirAccess.open(path)
	dir.list_dir_begin()
	
	while true:
		var file:String = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	
	dir.list_dir_end()
	
	return files

func load_and_cache(path:String) -> PackedScene:
	var loaded:PackedScene = null
	
	if path in literal_cache:
		pass
	else:
		literal_cache[path] = load(path)
	
	loaded = literal_cache[path]
	return loaded

func swapmap(naem:String) -> void:
	#world.get_node(current_map).queue_free()
	ViVeEnvironment.get_singleton().scene.queue_free()
	
	var d:Node = load_and_cache(pathh + "scenes/" + naem + "/scene.tscn").instantiate()
	
	ViVeEnvironment.get_singleton().add_child(d)
	ViVeEnvironment.get_singleton().scene = d
	
	await get_tree().create_timer(0.1).timeout
	ViVeEnvironment.get_singleton().car.global_position = Vector3.ZERO
	ViVeEnvironment.get_singleton().car.global_rotation = Vector3.ZERO
	ViVeEnvironment.get_singleton().car.linear_velocity = Vector3.ZERO
	ViVeEnvironment.get_singleton().car.angular_velocity = Vector3.ZERO

func _ready() -> void:
	$container/_DEFAULT.queue_free()
	
	var d:PackedStringArray = list_files_in_directory(pathh + "scenes")
	
	for i:String in d:
		var but:Button = button.duplicate()
		$container.add_child(but)
		but.get_node("mapname").text = i
		but.get_node("icon").texture = load(pathh + "scenes/" + i + "/thumbnail.png")
#		but.connect("pressed", self, "swapmap",[i])
		but.pressed.connect(swapmap.bind(i))
