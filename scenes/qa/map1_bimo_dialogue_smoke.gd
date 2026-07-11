extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	var bimo_sprite := scene.get_node("BimoDummy/VisualPivot/MaleSprite") as Sprite2D
	var first_idle_frame := bimo_sprite.frame
	await create_timer(0.25).timeout
	assert(bimo_sprite.frame != first_idle_frame, "Bimo idle animation did not advance.")

	var dialogue_bridge := root.get_node_or_null("DialogueBridge")
	assert(dialogue_bridge != null, "DialogueBridge autoload is unavailable.")
	assert(bool(dialogue_bridge.call("start_dialogue", "bimo_intro")), "Bimo dialogue did not start.")
	await process_frame

	var layout := dialogue_bridge.get("active_layout") as Node
	assert(is_instance_valid(layout), "Bimo dialogue layout was not created.")
	var registered_characters: Dictionary = layout.get("registered_characters") as Dictionary
	assert(registered_characters.size() >= 2, "Bimo and player bubble anchors were not registered.")

	var dialogic := root.get_node_or_null("Dialogic")
	if dialogic != null:
		dialogic.call("end_timeline", true)
	await process_frame
	scene.queue_free()
	await process_frame

	print("MAP1_BIMO_DIALOGUE_SMOKE_OK")
	quit()
