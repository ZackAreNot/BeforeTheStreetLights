extends SceneTree

const PRODUCTION_MAP1 := "res://scenes/new_maps/map1/map1_layering_test.tscn"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game_flow := root.get_node("GameFlow")
	game_flow.call("start_new_game")
	var deadline_msec := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline_msec:
		await process_frame
		var active_scene: Node = current_scene
		if (
			active_scene != null
			and active_scene.scene_file_path == PRODUCTION_MAP1
			and not bool(game_flow.get("transition_busy"))
		):
			if str(game_flow.get("current_area_id")) != "map1_production":
				push_error("START_MAP1_FLOW_AREA_ID_FAILED")
				quit(1)
				return
			if not active_scene.has_node("OpeningCutscene"):
				push_error("START_MAP1_FLOW_OPENING_MISSING")
				quit(1)
				return
			print("START_MAP1_FLOW_SMOKE_OK")
			quit()
			return
	var active_path := "<none>" if current_scene == null else current_scene.scene_file_path
	push_error(
		"START_MAP1_FLOW_DID_NOT_OPEN_PRODUCTION_MAP1 current=%s busy=%s area=%s" % [
			active_path,
			str(game_flow.get("transition_busy")),
			str(game_flow.get("current_area_id"))
		]
	)
	quit(1)
