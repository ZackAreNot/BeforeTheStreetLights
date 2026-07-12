extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := TEST_SCENE.instantiate()
	var opening := scene.get_node("OpeningCutscene") as Node
	var reveal := scene.get_node("BimoRevealCutscene") as Node
	opening.set("play_on_ready", false)
	reveal.set("camera_pan_duration", 0.02)
	reveal.set("camera_return_duration", 0.02)
	reveal.set("look_right_duration", 0.01)
	reveal.set("exclamation_duration", 0.01)
	root.add_child(scene)
	await process_frame

	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var player_camera := player.get_node("Camera2D") as Camera2D
	var cutscene_camera := scene.get_node("CutsceneCamera") as Camera2D
	var bimo := scene.get_node("BimoDummy") as Node2D
	var bimo_sprite := bimo.get_node("VisualPivot/MaleSprite") as Sprite2D
	var prompt := bimo.get_node("InteractionPrompt") as Sprite2D
	var bubble := bimo.get_node("CinematicBubble") as Node2D

	if bimo_sprite.flip_h:
		push_error("MAP1_BIMO_MUST_INITIALLY_FACE_RIGHT")
		quit(1)
		return
	if prompt.visible:
		push_error("MAP1_BIMO_PROMPT_MUST_START_LOCKED")
		quit(1)
		return

	reveal.call("start_reveal")
	await process_frame
	if bool(player.get("_controls_enabled")) or not cutscene_camera.enabled:
		push_error("MAP1_BIMO_REVEAL_DID_NOT_TAKE_CAMERA_CONTROL")
		quit(1)
		return

	await reveal.reveal_finished
	if not bimo_sprite.flip_h:
		push_error("MAP1_BIMO_DID_NOT_TURN_LEFT_TOWARD_NARA")
		quit(1)
		return
	if not prompt.visible or not bool(bimo.get("_interaction_prompt_unlocked")):
		push_error("MAP1_BIMO_INTERACTION_PROMPT_WAS_NOT_UNLOCKED")
		quit(1)
		return
	if bubble.visible:
		push_error("MAP1_BIMO_EXCLAMATION_DID_NOT_CLOSE")
		quit(1)
		return
	if not bool(player.get("_controls_enabled")):
		push_error("MAP1_BIMO_REVEAL_DID_NOT_RESTORE_PLAYER_CONTROL")
		quit(1)
		return
	if not player_camera.enabled or cutscene_camera.enabled:
		push_error("MAP1_BIMO_REVEAL_CAMERA_HANDOFF_FAILED")
		quit(1)
		return
	if scene.get_viewport().get_camera_2d() != player_camera:
		push_error("MAP1_BIMO_REVEAL_GAMEPLAY_CAMERA_NOT_CURRENT")
		quit(1)
		return

	print("MAP1_BIMO_REVEAL_SMOKE_OK")
	quit()
