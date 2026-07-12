extends Node

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _ready() -> void:
	var scene := TEST_SCENE.instantiate()
	(scene.get_node("OpeningCutscene") as Node).set("play_on_ready", false)
	add_child(scene)
	var guide := scene.get_node("ControlGuide") as CanvasLayer
	guide.set("_completed", true)
	guide.get_node("PanelRoot").visible = false

	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var camera := player.get_node("Camera2D") as Camera2D
	var poster := scene.get_node("InspectableObjects/PosterPoint/PosterInspection") as Node2D
	_set_player_at_world_x(scene, player, 1600.0)
	camera.reset_smoothing()
	camera.force_update_scroll()
	await get_tree().create_timer(0.35).timeout
	_save_capture("res://tmp/map1_guide_poster.png")

	poster.call("_start_comment")
	await get_tree().create_timer(0.8).timeout
	_save_capture("res://tmp/map1_guide_poster_comment.png")
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic != null:
		dialogic.call("end_timeline", true)
	await get_tree().process_frame

	_set_player_at_world_x(scene, player, 3940.0)
	camera.reset_smoothing()
	camera.force_update_scroll()
	await get_tree().create_timer(0.35).timeout
	_save_capture("res://tmp/map1_guide_closed_shop.png")
	get_tree().quit()


func _set_player_at_world_x(scene: Node, player: PathFollow2D, world_x: float) -> void:
	var track := scene.get_node("RoadTrack") as Path2D
	player.progress = track.curve.get_closest_offset(
		track.to_local(Vector2(world_x, player.global_position.y))
	)


func _save_capture(path: String) -> void:
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(ProjectSettings.globalize_path(path))
	if result != OK:
		push_error("MAP1_GUIDE_CAPTURE_FAILED")
