extends Node

func _ready() -> void:
	if not await _test_bakery():
		return
	if not await _test_clinic():
		return
	if not await _test_cables():
		return
	if not await _test_breathing():
		return
	await get_tree().create_timer(0.15).timeout
	await get_tree().process_frame
	print("MINIGAME_LOGIC_SMOKE_OK bakery clinic cable breathing")
	get_tree().quit()

func _test_bakery() -> bool:
	var game: Control = (
		load("res://scenes/minigames/bakery_orders.tscn") as PackedScene
	).instantiate() as Control
	add_child(game)
	await get_tree().process_frame
	for food_id: String in ["donat", "donat", "onde", "onde", "sus", "lemper"]:
		game.call("_on_food_dropped", food_id)
	if not bool(game.call("_is_complete")):
		_fail("Bakery order did not complete at 2/2/1/1")
		return false
	game.queue_free()
	await get_tree().process_frame
	return true

func _test_clinic() -> bool:
	var game: Control = (
		load("res://scenes/minigames/clinic_form.tscn") as PackedScene
	).instantiate() as Control
	add_child(game)
	await get_tree().process_frame
	var type_option: OptionButton = game.get_node(
		"Layout/FormPanel/FormMargin/Form/TypeOption"
	) as OptionButton
	var duration_option: OptionButton = game.get_node(
		"Layout/FormPanel/FormMargin/Form/DurationOption"
	) as OptionButton
	var checks: Array[CheckBox] = game.get("symptom_checks") as Array[CheckBox]
	var patients: Array[Dictionary] = game.get("patients") as Array[Dictionary]
	for patient: Dictionary in patients:
		type_option.select(int(patient["type"]))
		duration_option.select(int(patient["duration"]))
		var symptoms: PackedStringArray = patient["symptoms"] as PackedStringArray
		for check: CheckBox in checks:
			check.button_pressed = symptoms.has(check.text)
		game.call("_on_submit_button_pressed")
	if not bool(game.get("finished")):
		_fail("Clinic form did not finish all three patients")
		return false
	game.queue_free()
	await get_tree().process_frame
	return true

func _test_cables() -> bool:
	var game: Control = (
		load("res://scenes/minigames/cable_puzzle.tscn") as PackedScene
	).instantiate() as Control
	add_child(game)
	await get_tree().process_frame
	var node_names: Dictionary = {
		"merah": "Red",
		"hijau": "Green",
		"biru": "Blue"
	}
	for cable_id: String in node_names:
		var title: String = str(node_names[cable_id])
		var plug: TextureRect = game.get_node("PlugTray/" + title + "Plug") as TextureRect
		var socket: TextureRect = game.get_node("SocketBoard/" + title + "Socket") as TextureRect
		if cable_id == "biru":
			GameFlow.transition_busy = true
		game.call("_on_plug_received", plug, socket, cable_id)
	await get_tree().create_timer(1.7).timeout
	GameFlow.transition_busy = false
	if not bool(game.get("solved")) or (game.get("connected_ids") as PackedStringArray).size() != 3:
		_fail("Cable puzzle did not solve after three correct matches")
		return false
	game.queue_free()
	await get_tree().process_frame
	return true

func _test_breathing() -> bool:
	var game: Control = (
		load("res://scenes/minigames/breathing.tscn") as PackedScene
	).instantiate() as Control
	add_child(game)
	await get_tree().process_frame
	game.set("phase_time", 2.8)
	game.set("correct_time", 0.0)
	game.call("_finish_phase")
	if int(game.get("completed_cycles")) != 0:
		_fail("Breathing failure advanced a cycle")
		return false
	for phase_index: int in range(6):
		game.set("phase_time", 2.8)
		game.set("correct_time", 2.8)
		if phase_index == 5:
			GameFlow.return_area_id = "area_05_festival"
			GameFlow.transition_busy = true
		game.call("_finish_phase")
	await get_tree().create_timer(1.8).timeout
	GameFlow.transition_busy = false
	if not bool(game.get("completed")) or int(game.get("completed_cycles")) != 3:
		_fail("Breathing did not complete after three accurate cycles")
		return false
	game.queue_free()
	await get_tree().process_frame
	return true

func _fail(message: String) -> void:
	push_error("MINIGAME_LOGIC_SMOKE_FAILED: " + message)
	get_tree().quit(1)
