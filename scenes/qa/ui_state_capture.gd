extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var menu: Control = (
		load("res://scenes/main.tscn") as PackedScene
	).instantiate() as Control
	add_child(menu)
	await get_tree().process_frame
	menu.call("_on_credits_pressed")
	await get_tree().process_frame
	if not _save_capture("res://tmp/credits_v1.png"):
		return
	menu.queue_free()
	await get_tree().process_frame

	var area: Node = (
		load("res://scenes/areas/area_01_arrival.tscn") as PackedScene
	).instantiate()
	add_child(area)
	await get_tree().process_frame
	PauseMenu.call("_set_paused", true)
	await get_tree().process_frame
	if not _save_capture("res://tmp/pause_v1.png"):
		return
	PauseMenu.call("_set_paused", false)
	print("UI_STATE_CAPTURE_OK credits pause")
	get_tree().quit()

func _save_capture(path: String) -> bool:
	var image: Image = get_viewport().get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("UI_STATE_CAPTURE_FAILED: " + path)
		get_tree().paused = false
		get_tree().quit(1)
		return false
	return true
