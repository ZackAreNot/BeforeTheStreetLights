extends Node

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _ready() -> void:
	var scene := TEST_SCENE.instantiate()
	(scene.get_node("OpeningCutscene") as Node).set("play_on_ready", false)
	add_child(scene)
	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	player.progress = 2160.0

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(ProjectSettings.globalize_path("res://tmp/map1_bimo_check.png"))
	if result != OK:
		push_error("MAP1_BIMO_CAPTURE_FAILED")
	get_tree().quit()
