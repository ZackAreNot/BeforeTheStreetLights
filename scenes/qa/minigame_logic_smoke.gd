extends Node

func _ready() -> void:
	if not await _test_bakery():
		return
	if not await _test_clinic():
		return
	if not await _test_cables():
		return
	if not await _test_light_the_lamp():
		return
	if not await _test_breathing():
		return
	await get_tree().create_timer(0.15).timeout
	await get_tree().process_frame
	print("MINIGAME_LOGIC_SMOKE_OK bakery clinic cable light_the_lamp breathing")
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

func _test_light_the_lamp() -> bool:
	var game: Control = (
		load("res://scenes/minigames/light_the_lamp_level_01.tscn") as PackedScene
	).instantiate() as Control
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: AnimatableBody2D = game.get_node("Board") as AnimatableBody2D
	var plug: Node2D = game.get_node("RopeSystem/PlugHead") as Node2D
	var central_collision: CollisionShape2D = game.get_node(
		"Board/CentralBlockCollision"
	) as CollisionShape2D
	var central_rectangle: RectangleShape2D = (
		central_collision.shape as RectangleShape2D
	)
	var initial_plug_local: Vector2 = central_collision.to_local(plug.global_position)
	var initial_top_boundary: float = (
		-central_rectangle.size.y * 0.5
		- float(game.get("plug_collision_radius"))
		- float(game.get("obstacle_skin"))
	)
	if initial_top_boundary - initial_plug_local.y < 24.0:
		_fail("Light-the-lamp plug starts too close to the central block")
		return false
	var meter_label: Label = game.get_node(
		"UILayer/HUD/LengthMeter/LengthLabel"
	) as Label
	if meter_label.text != "39/102 cm":
		_fail("Light-the-lamp cable does not start at 39/102 cm")
		return false
	var corner_start: Vector2 = Vector2(
		central_rectangle.size.x * 0.5 + 1.0,
		central_rectangle.size.y * 0.5 + 1.0
	)
	var rounded_corner_world: Vector2 = game.call(
		"_push_out_of_obstacle",
		central_collision.to_global(corner_start),
		central_collision,
		float(game.get("cable_collision_radius"))
	) as Vector2
	var rounded_corner_local: Vector2 = central_collision.to_local(rounded_corner_world)
	if rounded_corner_local.x <= corner_start.x or rounded_corner_local.y <= corner_start.y:
		_fail("Light-the-lamp square corner collision is not rounded")
		return false
	var start_rotation: float = board.rotation
	var start_length: float = float(game.get("cable_length"))
	var extend_event: InputEventKey = InputEventKey.new()
	extend_event.keycode = KEY_S
	extend_event.pressed = true
	Input.parse_input_event(extend_event)
	for _wait_frame: int in range(12):
		await get_tree().physics_frame
		if Input.is_key_pressed(KEY_S):
			break
	Input.action_press("move_right")
	for _frame: int in range(18):
		await get_tree().physics_frame
	Input.action_release("move_right")
	var extend_release: InputEventKey = InputEventKey.new()
	extend_release.keycode = KEY_S
	extend_release.pressed = false
	Input.parse_input_event(extend_release)
	for _wait_frame: int in range(12):
		await get_tree().physics_frame
		if not Input.is_key_pressed(KEY_S):
			break
	if board.rotation <= start_rotation:
		_fail("Light-the-lamp fuse box did not rotate from horizontal input")
		return false
	if float(game.get("cable_length")) <= start_length + 10.0:
		_fail("Light-the-lamp cable did not extend from S input")
		return false
	var retract_event: InputEventKey = InputEventKey.new()
	retract_event.keycode = KEY_W
	retract_event.pressed = true
	Input.parse_input_event(retract_event)
	for _wait_frame: int in range(12):
		await get_tree().physics_frame
		if Input.is_key_pressed(KEY_W):
			break
	var retract_start_length: float = float(game.get("cable_length"))
	for _frame: int in range(18):
		await get_tree().physics_frame
	var retract_release: InputEventKey = InputEventKey.new()
	retract_release.keycode = KEY_W
	retract_release.pressed = false
	Input.parse_input_event(retract_release)
	if float(game.get("cable_length")) >= retract_start_length - 10.0:
		_fail(
			"Light-the-lamp cable did not retract from W input (%.2f -> %.2f)"
			% [retract_start_length, float(game.get("cable_length"))]
		)
		return false
	for _frame: int in range(24):
		await get_tree().physics_frame
	var positions: PackedVector2Array = game.get("rope_positions") as PackedVector2Array
	var rest_length: float = float(game.get("cable_length")) / float(positions.size() - 1)
	var maximum_error: float = 0.0
	for index: int in range(positions.size() - 1):
		maximum_error = maxf(
			maximum_error,
			absf(positions[index].distance_to(positions[index + 1]) - rest_length)
		)
	if maximum_error > 4.0:
		_fail("Light-the-lamp cable constraints became unstable")
		return false
	var target: Area2D = game.get_node("Board/PowerSocket/Target") as Area2D
	positions[positions.size() - 1] = target.global_position
	game.set("rope_positions", positions)
	game.call("_update_rope_visual")
	game.call("_check_target_connection")
	await get_tree().create_timer(1.2).timeout
	var bulb_on: Sprite2D = game.get_node("Board/BulbOn") as Sprite2D
	if not bool(game.get("solved")) or bulb_on.modulate.a < 0.95:
		_fail("Light-the-lamp level did not illuminate after reaching the socket")
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
