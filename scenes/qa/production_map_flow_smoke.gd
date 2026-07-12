extends SceneTree

const MAP1_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")
const MAP2_SCENE := preload("res://scenes/new_maps/map2/map2.tscn")
const ENTRY_SIDE_LEFT := 1
const ENTRY_SIDE_RIGHT := 2


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_flow := root.get_node("GameFlow")
	game_flow.set("transition_busy", false)

	var map1 := MAP1_SCENE.instantiate()
	(map1.get_node("OpeningCutscene") as Node).set("play_on_ready", false)
	root.add_child(map1)
	await process_frame
	assert(str(map1.get("area_id")) == "map1_production")
	assert(str(map1.get("right_target_area_id")) == "map2_production")
	assert(int(map1.get("right_target_entry_side")) == ENTRY_SIDE_LEFT)
	map1.queue_free()
	await process_frame

	game_flow.set("current_area_id", "map2_production")
	game_flow.set("pending_area_entry_side", ENTRY_SIDE_LEFT)
	var map2 := MAP2_SCENE.instantiate()
	root.add_child(map2)
	await process_frame

	var track := map2.get_node("RoadTrack") as Path2D
	var player := map2.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var camera := player.get_node("Camera2D") as Camera2D
	var layer2_root := map2.get_node("MapLayer2") as Node2D
	var layer3_root := map2.get_node("MapLayer3") as Node2D
	var layer2 := map2.get_node("MapLayer2/Map2Layer2") as Sprite2D
	var layer3 := map2.get_node("MapLayer3/Map2Layer3") as Sprite2D
	assert(track.curve.point_count >= 10, "Map 2 needs an editable road contour.")
	assert(is_equal_approx(player.progress, 220.0), "Map 2 left entry spawn is incorrect.")
	assert(bool(map2.get("override_camera_zoom")), "Map 2 camera zoom must remain editable from the root inspector.")
	assert(camera.zoom.is_equal_approx(Vector2.ONE * float(map2.get("gameplay_camera_zoom"))), "Map 2 camera did not apply its root zoom setting.")
	assert(is_equal_approx(float((camera.get("_base_offset") as Vector2).y), float(map2.get("gameplay_camera_offset_y"))), "Map 2 camera did not apply its editable vertical offset.")
	assert(bool(camera.get("drift_enabled")), "Map 2 handheld camera drift must remain enabled.")
	assert(layer2.position.is_equal_approx(Vector2(270, 108)), "Map 2 layer 2 alignment changed.")
	assert(layer3.position.is_equal_approx(Vector2(0, 1623)), "Map 2 layer 3 alignment changed.")
	assert(layer2_root.z_index > player.z_index, "Map 2 poles must render in front of the player.")
	assert(layer3_root.z_index > layer2_root.z_index, "Map 2 bottom foreground must be the top world layer.")
	assert(str(map2.get("left_target_area_id")) == "map1_production")
	assert(int(map2.get("left_target_entry_side")) == ENTRY_SIDE_RIGHT)
	map2.queue_free()
	await process_frame

	game_flow.set("current_area_id", "map1_production")
	game_flow.set("pending_area_entry_side", ENTRY_SIDE_RIGHT)
	var returned_map1 := MAP1_SCENE.instantiate()
	root.add_child(returned_map1)
	await process_frame
	var returned_player := returned_map1.get_node(
		"RoadTrack/MaleTrackPlayer"
	) as PathFollow2D
	var returned_track := returned_map1.get_node("RoadTrack") as Path2D
	var expected_progress := returned_track.curve.get_baked_length() - 220.0
	assert(is_equal_approx(returned_player.progress, expected_progress), "Map 1 right return spawn is incorrect.")
	assert(not bool(returned_map1.get_node("OpeningCutscene").get("play_on_ready")), "Taxi opening must not replay after returning from Map 2.")
	assert(not returned_map1.get_node("TaxiRoadTrack/TaxiPathFollow/TaxiVisual").visible, "Taxi must remain hidden on Map 1 return.")
	assert(bool(returned_map1.get_node("ControlGuide").get("_completed")), "Opening guide must not repeat on Map 1 return.")

	print("PRODUCTION_MAP_FLOW_SMOKE_OK")
	quit()
