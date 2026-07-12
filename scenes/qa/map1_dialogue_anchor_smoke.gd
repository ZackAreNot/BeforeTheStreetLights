extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := TEST_SCENE.instantiate()
	(scene.get_node("OpeningCutscene") as Node).set("play_on_ready", false)
	root.add_child(scene)
	await process_frame

	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var visual_pivot := player.get_node("VisualPivot") as Node2D
	var anchor := visual_pivot.get_node("NaraDialogueAnchor") as Marker2D
	var platform := scene.get_node("OneWayPlatforms/BrickOneWayPlatform") as Node2D
	_set_player_at_world_x(scene, player, 3940.0)
	await process_frame
	var ground_anchor_position := anchor.global_position
	var platform_offset := float(platform.call(
		"surface_y_at_world_x",
		player.global_position.x
	)) - player.global_position.y
	player.set("_floor_offset", platform_offset)
	player.set("_active_platform", platform)
	visual_pivot.position.y = platform_offset
	await process_frame
	if anchor.global_position.y >= ground_anchor_position.y + platform_offset * 0.5:
		push_error("MAP1_DIALOGUE_ANCHOR_DID_NOT_FOLLOW_PLATFORM")
		quit(1)
		return

	var door := scene.get_node(
		"InspectableObjects/ClosedShopPoint/DoorInspection"
	) as Node2D
	for property_info: Dictionary in door.get_property_list():
		if str(property_info.get("name")) == "nara_dialogue_y_offset":
			push_error("MAP1_DIALOGUE_ANCHOR_STILL_USES_DOOR_SPECIFIC_OFFSET")
			quit(1)
			return

	var original_local_position := anchor.position
	if not bool(door.call("_start_comment")):
		push_error("MAP1_DIALOGUE_ANCHOR_DOOR_COMMENT_DID_NOT_START")
		quit(1)
		return
	await process_frame
	if not anchor.position.is_equal_approx(original_local_position):
		push_error("MAP1_DIALOGUE_ANCHOR_WAS_MUTATED_BY_INTERACTION")
		quit(1)
		return

	var dialogic := root.get_node_or_null("Dialogic")
	if dialogic != null:
		dialogic.call("end_timeline", true)
	await create_timer(0.2).timeout
	print("MAP1_DIALOGUE_ANCHOR_SMOKE_OK")
	quit()


func _set_player_at_world_x(scene: Node, player: PathFollow2D, world_x: float) -> void:
	var track := scene.get_node("RoadTrack") as Path2D
	player.progress = track.curve.get_closest_offset(
		track.to_local(Vector2(world_x, player.global_position.y))
	)
