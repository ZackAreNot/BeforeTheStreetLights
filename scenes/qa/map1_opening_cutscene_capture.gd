extends Node

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _ready() -> void:
	var scene := TEST_SCENE.instantiate()
	var opening := scene.get_node("OpeningCutscene") as Node
	opening.set("initial_zoom", 0.35)
	opening.connect(
		"camera_handoff_ready",
		_save_capture.bind("res://tmp/map1_opening_before_handoff.png")
	)
	add_child(scene)
	await RenderingServer.frame_post_draw
	_save_capture("res://tmp/map1_opening_first_frame.png")
	# Taxi has reached the bus stop and Nara has just appeared by this point.
	await get_tree().create_timer(5.0).timeout
	_save_capture("res://tmp/map1_opening_cutscene.png")
	await get_tree().create_timer(2.45).timeout
	_save_capture("res://tmp/map1_opening_focus_pan.png")
	await get_tree().create_timer(1.0).timeout
	_save_capture("res://tmp/map1_opening_zoom_in.png")
	# The handoff has completed and player control is restored.
	await opening.opening_finished
	await RenderingServer.frame_post_draw
	_save_capture("res://tmp/map1_opening_gameplay.png")
	get_tree().quit()


func _save_capture(path: String) -> void:
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("MAP1_OPENING_CUTSCENE_CAPTURE_FAILED")
