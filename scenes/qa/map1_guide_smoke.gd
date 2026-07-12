extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := TEST_SCENE.instantiate()
	(scene.get_node("OpeningCutscene") as Node).set("play_on_ready", false)
	root.add_child(scene)
	await process_frame

	var guide := scene.get_node("ControlGuide") as CanvasLayer
	var panel := guide.get_node("PanelRoot") as Control
	var interaction_panel := guide.get_node("InteractionGuideRoot") as Control
	assert(bool(guide.call("is_completed")), "Headless guide must not lock player controls.")
	assert(not panel.visible, "Headless guide panel must remain hidden.")
	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	guide.set("_completed", false)
	guide.call("_show_guide")
	await process_frame
	assert(panel.visible, "Control guide panel did not open.")
	assert(not bool(player.get("_controls_enabled")), "Control guide did not lock movement.")
	guide.call("_dismiss_guide")
	await guide.guide_completed
	assert(not panel.visible, "Control guide panel did not close.")
	assert(bool(player.get("_controls_enabled")), "Control guide did not restore movement.")

	var poster_art := scene.get_node(
		"InspectableObjects/PosterPoint/PosterArtwork"
	) as Sprite2D
	var poster := scene.get_node(
		"InspectableObjects/PosterPoint/PosterInspection"
	) as Node2D
	var door := scene.get_node(
		"InspectableObjects/ClosedShopPoint/DoorInspection"
	) as Node2D
	assert(
		poster_art.texture.resource_path.ends_with("assets/Guide/Poster1.png"),
		"Poster1 asset is not connected."
	)
	assert(str(poster.get("dialogue_id")) == "map1_poster_comment")
	assert(str(door.get("dialogue_id")) == "map1_closed_shop_comment")

	var poster_prompt := poster.get_node("InteractionPrompt") as Sprite2D
	var door_prompt := door.get_node("InteractionPrompt") as Sprite2D
	assert(poster_prompt.hframes == 5 and poster_prompt.vframes == 7)
	assert(door_prompt.hframes == poster_prompt.hframes)
	assert(door_prompt.vframes == poster_prompt.vframes)
	assert(is_equal_approx(float(poster.get("prompt_scale")), float(door.get("prompt_scale"))))
	var first_frame := poster_prompt.frame
	poster.call("_process", 0.2)
	assert(poster_prompt.frame != first_frame, "Interaction prompt animation did not advance.")

	var track := scene.get_node("RoadTrack") as Path2D
	var poster_point := scene.get_node("InspectableObjects/PosterPoint") as Node2D
	player.progress = track.curve.get_closest_offset(
		track.to_local(Vector2(poster_point.global_position.x, player.global_position.y))
	)
	poster.call("_process", 0.05)
	assert(interaction_panel.visible, "Poster did not open the contextual interaction guide.")
	assert(not bool(player.get("_controls_enabled")), "Interaction guide did not lock movement.")
	assert(not bool(poster.get("_player_is_near")), "Poster remained active behind its guide.")
	guide.call("_dismiss_interaction_guide")
	await guide.interaction_guide_completed
	assert(not interaction_panel.visible, "Interaction guide did not close.")
	assert(bool(player.get("_controls_enabled")), "Interaction guide did not restore movement.")
	poster.call("_process", 0.05)
	assert(bool(poster.get("_player_is_near")), "Poster interaction range did not activate.")

	assert(bool(poster.call("_start_comment")), "Poster comment dialogue did not start.")
	await process_frame
	var dialogue_bridge := root.get_node("DialogueBridge")
	assert(str(dialogue_bridge.get("active_dialogue_id")) == "map1_poster_comment")
	var layout := dialogue_bridge.get("active_layout") as Node
	assert(is_instance_valid(layout), "Poster comment did not create a dialogue bubble layout.")
	var registered_characters := layout.get("registered_characters") as Dictionary
	assert(not registered_characters.is_empty(), "Nara dialogue anchor was not registered.")

	var dialogic := root.get_node_or_null("Dialogic")
	if dialogic != null:
		dialogic.call("end_timeline", true)
	await create_timer(0.2).timeout
	var door_timeline := load(
		"res://dialogic/timelines/map1_closed_shop_comment.dtl"
	) as DialogicTimeline
	assert(door_timeline != null, "Closed shop comment timeline could not be loaded.")
	door_timeline.process()
	assert(not door_timeline.events.is_empty(), "Closed shop comment timeline is empty.")
	scene.queue_free()
	await process_frame
	print("MAP1_GUIDE_SMOKE_OK")
	quit()
