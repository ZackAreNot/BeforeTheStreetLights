extends Node

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _ready() -> void:
	var scene := TEST_SCENE.instantiate()
	(scene.get_node("OpeningCutscene") as Node).set("play_on_ready", false)
	add_child(scene)
	var track := scene.get_node("RoadTrack") as Path2D
	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var platform := scene.get_node("OneWayPlatforms/BrickOneWayPlatform") as Node2D
	player.progress = track.curve.get_closest_offset(
		track.to_local(Vector2(platform.global_position.x, player.global_position.y))
	)
	await get_tree().process_frame
	var platform_offset: float = float(platform.call(
		"surface_y_at_world_x", player.global_position.x
	)) - player.global_position.y
	player.set("_floor_offset", platform_offset)
	player.set("_active_platform", platform)
	player.get_node("VisualPivot").position.y = platform_offset

	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(ProjectSettings.globalize_path("res://tmp/map1_one_way_platform.png"))
	if result != OK:
		push_error("MAP1_ONE_WAY_PLATFORM_CAPTURE_FAILED")
	get_tree().quit()
