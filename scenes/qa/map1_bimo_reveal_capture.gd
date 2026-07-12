extends Node

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _ready() -> void:
	var scene := TEST_SCENE.instantiate()
	(scene.get_node("OpeningCutscene") as Node).set("play_on_ready", false)
	var reveal := scene.get_node("BimoRevealCutscene") as Node
	reveal.set("camera_pan_duration", 0.6)
	reveal.set("camera_return_duration", 0.6)
	reveal.set("look_right_duration", 0.2)
	reveal.set("exclamation_duration", 0.7)
	add_child(scene)
	await get_tree().process_frame
	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	player.progress = float(reveal.get("trigger_progress"))
	reveal.call("start_reveal")
	await get_tree().create_timer(1.05).timeout
	_save_capture("res://tmp/map1_bimo_reveal_exclamation.png")
	await reveal.reveal_finished

	player.progress = 2160.0
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_capture("res://tmp/map1_bimo_reveal_prompt.png")
	get_tree().quit()


func _save_capture(path: String) -> void:
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("MAP1_BIMO_REVEAL_CAPTURE_FAILED")
