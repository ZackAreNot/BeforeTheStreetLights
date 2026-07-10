extends Node

const AREA_01: String = "res://scenes/areas/area_01_arrival.tscn"
const AREA_02: String = "res://scenes/areas/area_02_electric_street.tscn"
const AREA_03: String = "res://scenes/areas/area_03_bakery_flower.tscn"
const AREA_04: String = "res://scenes/areas/area_04_clinic_hill.tscn"
const AREA_05: String = "res://scenes/areas/area_05_festival_park.tscn"

func run() -> void:
	await get_tree().process_frame
	GameFlow.start_new_game()
	if not await _wait_for_scene(AREA_01):
		return

	GameFlow.set_flag("met_bimo", true)
	GameFlow.go_to_area("area_02_electric")
	if not await _wait_for_scene(AREA_02):
		return

	GameFlow.set_flag("cable_collected", true)
	GameFlow.go_to_area("area_03_shops")
	if not await _wait_for_scene(AREA_03):
		return

	GameFlow.start_minigame("bakery")
	if not await _wait_for_scene("res://scenes/minigames/bakery_orders.tscn"):
		return
	GameFlow.complete_minigame("bakery")
	GameFlow.pending_dialogue_id = ""
	if not await _wait_for_scene(AREA_03):
		return

	GameFlow.set_flag("tara_invited", true)
	GameFlow.go_to_area("area_04_clinic")
	if not await _wait_for_scene(AREA_04):
		return

	GameFlow.start_minigame("clinic")
	if not await _wait_for_scene("res://scenes/minigames/clinic_form.tscn"):
		return
	GameFlow.complete_minigame("clinic")
	GameFlow.pending_dialogue_id = ""
	if not await _wait_for_scene(AREA_04):
		return

	GameFlow.go_to_area("area_05_festival")
	if not await _wait_for_scene(AREA_05):
		return

	GameFlow.start_minigame("cable")
	if not await _wait_for_scene("res://scenes/minigames/cable_puzzle.tscn"):
		return
	GameFlow.finish_cable_and_start_breathing()
	if not await _wait_for_scene("res://scenes/minigames/breathing.tscn"):
		return
	GameFlow.complete_minigame("breathing")
	if not await _wait_for_scene(AREA_05):
		return

	if not GameFlow.is_minigame_complete("bakery"):
		_fail("Bakery progress was lost during transitions")
		return
	if not GameFlow.is_minigame_complete("clinic"):
		_fail("Clinic progress was lost during transitions")
		return
	if not GameFlow.is_minigame_complete("cable"):
		_fail("Cable progress was lost during transitions")
		return
	if not GameFlow.is_minigame_complete("breathing"):
		_fail("Breathing progress was lost during transitions")
		return

	GameFlow.show_ending()
	if not await _wait_for_scene("res://scenes/ui/prototype_ending.tscn"):
		return
	print("TRANSITION_SMOKE_OK menu-route areas=5 minigames=4 ending=1")
	get_tree().quit()

func _wait_for_scene(expected_path: String) -> bool:
	for _frame: int in range(900):
		await get_tree().process_frame
		var current_scene: Node = get_tree().current_scene
		if (
			current_scene != null
			and current_scene.scene_file_path == expected_path
			and not GameFlow.transition_busy
		):
			return true
	_fail("Timed out waiting for " + expected_path)
	return false

func _fail(message: String) -> void:
	push_error("TRANSITION_SMOKE_FAILED: " + message)
	get_tree().quit(1)
