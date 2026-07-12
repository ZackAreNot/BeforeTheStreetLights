extends Node

const TIMELINES: PackedStringArray = [
	"res://dialogic/timelines/map1_poster_comment.dtl",
	"res://dialogic/timelines/map1_closed_shop_comment.dtl",
	"res://dialogic/timelines/bimo_intro.dtl",
	"res://dialogic/timelines/bimo_repeat.dtl",
	"res://dialogic/timelines/shopkeeper_cable.dtl",
	"res://dialogic/timelines/shopkeeper_repeat.dtl",
	"res://dialogic/timelines/bu_rami_intro.dtl",
	"res://dialogic/timelines/bu_rami_after.dtl",
	"res://dialogic/timelines/bu_rami_repeat.dtl",
	"res://dialogic/timelines/tara_conversation.dtl",
	"res://dialogic/timelines/tara_repeat.dtl",
	"res://dialogic/timelines/dr_seno_intro.dtl",
	"res://dialogic/timelines/dr_seno_after.dtl",
	"res://dialogic/timelines/dr_seno_repeat.dtl",
	"res://dialogic/timelines/festival_epilogue.dtl"
]

func _ready() -> void:
	for path: String in TIMELINES:
		var timeline: DialogicTimeline = load(path) as DialogicTimeline
		if timeline == null:
			_fail("Could not load timeline " + path)
			return
		timeline.process()
		if timeline.events.is_empty():
			_fail("Timeline has no events " + path)
			return

	var tara_timeline: DialogicTimeline = load(
		"res://dialogic/timelines/tara_conversation.dtl"
	) as DialogicTimeline
	tara_timeline.process()
	var choice_count: int = 0
	for event: DialogicEvent in tara_timeline.events:
		if event.event_name == "Choice":
			choice_count += 1
	if choice_count != 3:
		_fail("Expected 3 Tara choices, found " + str(choice_count))
		return

	var area_scene: PackedScene = load(
		"res://scenes/areas/area_01_arrival.tscn"
	) as PackedScene
	var area: Node = area_scene.instantiate()
	add_child(area)
	await get_tree().process_frame
	await get_tree().process_frame
	if not DialogueBridge.start_dialogue("bimo_intro"):
		_fail("DialogueBridge refused bimo_intro")
		return
	await get_tree().create_timer(1.5).timeout
	if not DialogueBridge.is_dialogue_active():
		_fail("Dialog ended before the first line could be inspected")
		return
	if not Dialogic.Styles.has_active_layout_node():
		_fail("Dialogic did not create an active layout")
		return
	var layout: Node = Dialogic.Styles.get_layout_node()
	if layout.get_node_or_null("Example") == null or layout.get_node("Example").visible:
		_fail("Dialogue used Dialogic's fallback bubble instead of a speaker anchor")
		return

	var capture: Image = get_viewport().get_texture().get_image()
	var capture_result: Error = capture.save_png(
		ProjectSettings.globalize_path("res://tmp/dialogue_ui.png")
	)
	if capture_result != OK:
		_fail("Could not save dialogue screenshot")
		return
	if not await _finish_dialogue_normally():
		_fail("Bimo timeline did not finish through normal input")
		return
	print("DIALOGUE_SMOKE_OK timelines=", TIMELINES.size(), " tara_choices=", choice_count)
	area.queue_free()
	await get_tree().create_timer(0.3).timeout
	PauseMenu.quit_game()

func _finish_dialogue_normally() -> bool:
	for _advance_attempt: int in range(80):
		if not DialogueBridge.is_dialogue_active():
			return true
		Dialogic.Inputs.handle_input()
		await get_tree().create_timer(0.12).timeout
	return not DialogueBridge.is_dialogue_active()

func _fail(message: String) -> void:
	push_error("DIALOGUE_SMOKE_FAILED: " + message)
	get_tree().quit(1)
