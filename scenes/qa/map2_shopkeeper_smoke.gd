extends SceneTree

const MAP2_SCENE := preload("res://scenes/new_maps/map2/map2.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_flow := root.get_node("GameFlow")
	game_flow.set("transition_busy", false)
	game_flow.set("current_area_id", "map2_production")
	game_flow.set("pending_area_entry_side", 0)
	game_flow.set("flags", {})
	game_flow.set("inventory", PackedStringArray())

	var map2 := MAP2_SCENE.instantiate()
	root.add_child(map2)
	await process_frame
	var track := map2.get_node("RoadTrack") as Path2D
	var player := map2.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var seller := map2.get_node("ElectricShopkeeper") as Node2D
	player.progress = track.curve.get_closest_offset(
		track.to_local(Vector2(seller.global_position.x - 120.0, seller.global_position.y))
	)
	await process_frame
	seller.call("_process", 0.05)
	assert(bool(seller.get("_player_is_near")), "Shopkeeper interaction did not activate near Nara.")

	Input.action_press(&"interact")
	seller.call("_process", 0.05)
	Input.action_release(&"interact")
	await process_frame
	var dialogue_bridge := root.get_node("DialogueBridge")
	assert(str(dialogue_bridge.get("active_dialogue_id")) == "shopkeeper_cable", "Shopkeeper dialogue did not start.")
	assert(not bool(player.get("_controls_enabled")), "Shopkeeper dialogue did not lock player movement.")
	var layout := dialogue_bridge.get("active_layout") as Node
	assert(is_instance_valid(layout), "Shopkeeper dialogue bubble layout is missing.")
	var registered_characters := layout.get("registered_characters") as Dictionary
	assert(not registered_characters.is_empty(), "Shopkeeper dialogue anchor was not registered.")

	var dialogic := root.get_node_or_null("Dialogic")
	if dialogic != null:
		dialogic.call("end_timeline", true)
	await create_timer(0.25).timeout
	print("MAP2_SHOPKEEPER_SMOKE_OK")
	quit()
