extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")
const LOADING_SCENE := preload("res://scenes/ui/loading_screen.tscn")


func _ready() -> void:
	var menu := MAIN_SCENE.instantiate()
	add_child(menu)
	var loading := LOADING_SCENE.instantiate()
	add_child(loading)
	await get_tree().process_frame

	loading.call("begin")
	await get_tree().create_timer(0.22).timeout
	_save_capture("res://tmp/loading_transition_closing.png")
	await get_tree().create_timer(0.34).timeout
	_save_capture("res://tmp/loading_transition_nara.png")

	loading.call("end")
	await get_tree().create_timer(0.88).timeout
	_save_capture("res://tmp/loading_transition_opening.png")
	await get_tree().create_timer(0.8).timeout
	get_tree().quit()


func _save_capture(path: String) -> void:
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("LOADING_TRANSITION_CAPTURE_FAILED")
