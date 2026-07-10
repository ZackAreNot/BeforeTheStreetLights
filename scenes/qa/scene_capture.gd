extends Node

func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() < 2:
		_fail("scene_capture requires a scene path and output path")
		return
	var packed_scene: PackedScene = load(arguments[0]) as PackedScene
	if packed_scene == null:
		_fail("Could not load scene " + arguments[0])
		return
	var instance: Node = packed_scene.instantiate()
	add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var image: Image = get_viewport().get_texture().get_image()
	var result: Error = image.save_png(ProjectSettings.globalize_path(arguments[1]))
	if result != OK:
		_fail("Could not save screenshot " + arguments[1])
		return
	print("SCENE_CAPTURE_OK ", arguments[0])
	get_tree().quit()

func _fail(message: String) -> void:
	push_error("SCENE_CAPTURE_FAILED: " + message)
	get_tree().quit(1)
