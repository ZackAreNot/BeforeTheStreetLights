extends Node

func _ready() -> void:
	var area_scene: PackedScene = load(
		"res://scenes/areas/area_03_bakery_flower.tscn"
	) as PackedScene
	add_child(area_scene.instantiate())
	await get_tree().process_frame
	await get_tree().process_frame
	var timeline: DialogicTimeline = load(
		"res://dialogic/timelines/tara_conversation.dtl"
	) as DialogicTimeline
	timeline.process()
	var question_index: int = -1
	for index: int in range(timeline.events.size() - 1):
		var event: DialogicEvent = timeline.events[index] as DialogicEvent
		var next_event: DialogicEvent = timeline.events[index + 1] as DialogicEvent
		if event.event_name == "Text" and next_event.event_name == "Choice":
			question_index = index
			break
	if question_index < 0:
		push_error("CHOICE_CAPTURE_FAILED: question event not found")
		get_tree().quit(1)
		return
	Dialogic.start(timeline, question_index)
	await get_tree().create_timer(2.2).timeout
	if Dialogic.current_state != Dialogic.States.AWAITING_CHOICE:
		push_error("CHOICE_CAPTURE_FAILED: Tara choices did not open")
		get_tree().quit(1)
		return
	var capture: Image = get_viewport().get_texture().get_image()
	var result: Error = capture.save_png(
		ProjectSettings.globalize_path("res://tmp/tara_choices.png")
	)
	if result != OK:
		push_error("CHOICE_CAPTURE_FAILED: could not save image")
		get_tree().quit(1)
		return
	Dialogic.Choices.select_choice(1)
	for _advance_attempt: int in range(80):
		if Dialogic.current_timeline == null:
			break
		Dialogic.Inputs.handle_input()
		await get_tree().create_timer(0.12).timeout
	print("CHOICE_CAPTURE_OK")
	PauseMenu.quit_game()
