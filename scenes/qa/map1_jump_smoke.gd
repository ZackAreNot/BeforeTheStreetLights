extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame

	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var visual_pivot := player.get_node("VisualPivot") as Node2D

	Input.action_press("jump")
	player.call("_update_jump", 0.1)
	Input.action_release("jump")
	assert(visual_pivot.position.y < 0.0, "Jump must lift the foot pivot above the road track.")
	await process_frame

	for step in range(20):
		player.call("_update_jump", 0.1)
	assert(is_zero_approx(visual_pivot.position.y), "Jump must land exactly back on the road track.")

	print("MAP1_JUMP_SMOKE_OK")
	quit()
