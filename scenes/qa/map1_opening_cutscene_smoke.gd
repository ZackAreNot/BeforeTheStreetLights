extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := TEST_SCENE.instantiate()
	var opening := scene.get_node("OpeningCutscene") as Node
	opening.set("play_on_ready", false)
	opening.set("initial_zoom", 0.35)
	root.add_child(scene)
	await process_frame

	opening.call("start_opening")
	await process_frame
	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var player_camera := scene.get_node("RoadTrack/MaleTrackPlayer/Camera2D") as Camera2D
	var cutscene_camera := scene.get_node("CutsceneCamera") as Camera2D
	var taxi_path := scene.get_node("TaxiRoadTrack/TaxiPathFollow") as PathFollow2D
	var taxi := scene.get_node("TaxiRoadTrack/TaxiPathFollow/TaxiVisual") as Node2D
	if player.visible or bool(player.get("_controls_enabled")):
		push_error("MAP1_OPENING_CUTSCENE_START_STATE_FAILED")
		quit(1)
		return
	if not taxi.visible:
		push_error("MAP1_OPENING_TAXI_NOT_VISIBLE")
		quit(1)
		return
	var expected_initial_zoom := Vector2.ONE * float(opening.get("initial_zoom"))
	if not cutscene_camera.zoom.is_equal_approx(expected_initial_zoom):
		push_error("MAP1_OPENING_MANUAL_ZOOM_SETTING_FAILED")
		quit(1)
		return
	var expected_initial_center := opening.call(
		"_get_bottom_left_anchored_center", expected_initial_zoom
	) as Vector2
	if not cutscene_camera.global_position.is_equal_approx(expected_initial_center):
		push_error("MAP1_OPENING_BOTTOM_LEFT_ZOOM_ANCHOR_FAILED")
		quit(1)
		return

	await opening.opening_finished
	if not player.visible or not bool(player.get("_controls_enabled")):
		push_error("MAP1_OPENING_CUTSCENE_END_STATE_FAILED")
		quit(1)
		return
	if taxi.visible:
		push_error("MAP1_OPENING_TAXI_DID_NOT_LEAVE")
		quit(1)
		return
	if not is_equal_approx(player.progress, 850.0):
		push_error("MAP1_OPENING_NARA_EXIT_POSITION_FAILED")
		quit(1)
		return
	if not is_equal_approx(taxi_path.progress, 2800.0):
		push_error("MAP1_OPENING_TAXI_DEPARTURE_POSITION_FAILED")
		quit(1)
		return
	if is_zero_approx((taxi.get_node("RearWheel") as Sprite2D).rotation):
		push_error("MAP1_OPENING_TAXI_WHEELS_DID_NOT_ANIMATE")
		quit(1)
		return
	if not player_camera.enabled or cutscene_camera.enabled:
		push_error("MAP1_OPENING_CAMERA_HANDOFF_FAILED")
		quit(1)
		return
	if scene.get_viewport().get_camera_2d() != player_camera:
		push_error("MAP1_OPENING_GAMEPLAY_CAMERA_NOT_CURRENT")
		quit(1)
		return
	if not is_zero_approx(player_camera.rotation) or not is_zero_approx(cutscene_camera.rotation):
		push_error("MAP1_OPENING_CAMERA_ROTATION_RESET_FAILED")
		quit(1)
		return
	print("MAP1_OPENING_CUTSCENE_SMOKE_OK")
	quit()
