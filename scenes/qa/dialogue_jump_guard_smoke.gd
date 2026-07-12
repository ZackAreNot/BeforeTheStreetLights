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
	var dialogue_bridge := root.get_node("DialogueBridge")
	dialogue_bridge.set("active_dialogue_id", "jump_guard_test")
	dialogue_bridge.set("active_config", {})
	dialogue_bridge.set("active_player", player)
	player.call("set_controls_enabled", false)

	Input.action_press(&"jump")
	dialogue_bridge.call("_on_timeline_ended")
	await process_frame
	await process_frame
	assert(not bool(player.get("_controls_enabled")), "Controls were restored while dialogue Space was still held.")
	assert(is_zero_approx(float(player.get("_vertical_velocity"))), "Dialogue Space leaked into jump velocity.")

	Input.action_release(&"jump")
	await process_frame
	await process_frame
	assert(bool(player.get("_controls_enabled")), "Controls were not restored after dialogue Space was released.")
	assert(is_zero_approx(float(player.get("_air_offset"))), "Player jumped after the dialogue ended.")

	print("DIALOGUE_JUMP_GUARD_SMOKE_OK")
	quit()
