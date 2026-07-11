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
	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_02):
		return
	if not _assert_player_state(Vector2(360, 620), 1.0, "area 2 left entry"):
		return
	_enter_left_exit_zone()
	if not await _wait_for_scene(AREA_01):
		return
	if not _assert_player_state(Vector2(2840, 620), -1.0, "area 1 right entry"):
		return
	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_02):
		return

	GameFlow.set_flag("cable_collected", true)
	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_03):
		return
	if not _assert_player_state(Vector2(360, 620), 1.0, "area 3 left entry"):
		return
	_enter_left_exit_zone()
	if not await _wait_for_scene(AREA_02):
		return
	if not _assert_player_state(Vector2(2840, 620), -1.0, "area 2 right entry"):
		return
	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_03):
		return

	var bakery_return_position := Vector2(2034.0, 620.0)
	_set_player_state(bakery_return_position, -1.0)
	GameFlow.start_minigame("bakery")
	if not await _wait_for_scene("res://scenes/minigames/bakery_orders.tscn"):
		return
	GameFlow.complete_minigame("bakery")
	GameFlow.pending_dialogue_id = ""
	if not await _wait_for_scene(AREA_03):
		return
	if not _assert_player_state(bakery_return_position, -1.0, "bakery"):
		return

	GameFlow.set_flag("tara_invited", true)
	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_04):
		return
	if not _assert_player_state(Vector2(360, 620), 1.0, "area 4 left entry"):
		return
	_enter_left_exit_zone()
	if not await _wait_for_scene(AREA_03):
		return
	if not _assert_player_state(Vector2(2840, 620), -1.0, "area 3 right entry"):
		return
	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_04):
		return

	var clinic_return_position := Vector2(2160.0, 620.0)
	_set_player_state(clinic_return_position, 1.0)
	GameFlow.start_minigame("clinic")
	if not await _wait_for_scene("res://scenes/minigames/clinic_form.tscn"):
		return
	GameFlow.complete_minigame("clinic")
	GameFlow.pending_dialogue_id = ""
	if not await _wait_for_scene(AREA_04):
		return
	if not _assert_player_state(clinic_return_position, 1.0, "clinic"):
		return

	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_05):
		return
	if not _assert_player_state(Vector2(360, 620), 1.0, "area 5 left entry"):
		return
	_enter_left_exit_zone()
	if not await _wait_for_scene(AREA_04):
		return
	if not _assert_player_state(Vector2(2840, 620), -1.0, "area 4 right entry"):
		return
	_enter_right_exit_zone()
	if not await _wait_for_scene(AREA_05):
		return

	var festival_return_position := Vector2(1510.0, 620.0)
	_set_player_state(festival_return_position, -1.0)
	GameFlow.start_minigame("cable")
	if not await _wait_for_scene("res://scenes/minigames/cable_puzzle.tscn"):
		return
	GameFlow.finish_cable_and_start_breathing()
	if not await _wait_for_scene("res://scenes/minigames/breathing.tscn"):
		return
	GameFlow.complete_minigame("breathing")
	if not await _wait_for_scene(AREA_05):
		return
	if not _assert_player_state(festival_return_position, -1.0, "festival"):
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

func _set_player_state(player_position: Vector2, facing: float) -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group(
		&"player"
	) as CharacterBody2D
	player.global_position = player_position
	player.set("facing", facing)

func _enter_right_exit_zone() -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group(
		&"player"
	) as CharacterBody2D
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(3040.0, 620.0)

func _enter_left_exit_zone() -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group(
		&"player"
	) as CharacterBody2D
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(160.0, 620.0)

func _assert_player_state(
	expected_position: Vector2,
	expected_facing: float,
	minigame_name: String
) -> bool:
	var player: CharacterBody2D = get_tree().get_first_node_in_group(
		&"player"
	) as CharacterBody2D
	if player == null:
		_fail("Player was missing after returning from " + minigame_name)
		return false
	if not player.global_position.is_equal_approx(expected_position):
		_fail("%s returned player to %s instead of %s" % [
			minigame_name,
			player.global_position,
			expected_position
		])
		return false
	if not is_equal_approx(float(player.get("facing")), expected_facing):
		_fail(minigame_name + " did not preserve player facing")
		return false
	return true

func _fail(message: String) -> void:
	push_error("TRANSITION_SMOKE_FAILED: " + message)
	get_tree().quit(1)
