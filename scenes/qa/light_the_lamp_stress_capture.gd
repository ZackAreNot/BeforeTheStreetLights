extends Node

const LIGHT_SCENE := preload("res://scenes/minigames/light_the_lamp_level_01.tscn")

var game: Control
var board: AnimatableBody2D
var previous_plug_position: Vector2
var maximum_plug_jump: float = 0.0
var previous_rope_positions: PackedVector2Array = PackedVector2Array()
var maximum_particle_jump: float = 0.0


func _ready() -> void:
	game = LIGHT_SCENE.instantiate() as Control
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.set("target_snap_distance", -1.0)
	board = game.get_node("Board") as AnimatableBody2D
	previous_plug_position = (
		game.get_node("RopeSystem/PlugHead") as Node2D
	).global_position
	previous_rope_positions = (
		game.get("rope_positions") as PackedVector2Array
	).duplicate()
	await get_tree().create_timer(0.2).timeout
	if not (await _save_capture("res://tmp/light_lamp_stress_01_start.png")):
		return

	await _run_motion(145.0, 330.0, 0.0, 0.48, 120)
	if not (await _save_capture("res://tmp/light_lamp_stress_02_wrap.png")):
		return
	await _run_motion(330.0, 465.0, 0.48, -0.68, 120)
	if not (await _save_capture("res://tmp/light_lamp_stress_03_long.png")):
		return
	await _run_motion(465.0, 300.0, -0.68, 0.22, 100)
	if not (await _save_capture("res://tmp/light_lamp_stress_04_retract.png")):
		return

	for _frame: int in range(150):
		await get_tree().physics_frame
		_track_plug_jump()
	if not (await _save_capture("res://tmp/light_lamp_stress_05_settled.png")):
		return

	var maximum_constraint_error: float = _get_maximum_constraint_error()
	if maximum_constraint_error > 4.0:
		_fail("constraint error %.2f px" % maximum_constraint_error)
		return
	if maximum_plug_jump > 18.0:
		_fail("plug jumped %.2f px in one frame" % maximum_plug_jump)
		return
	if maximum_particle_jump > 18.0:
		_fail("a cable particle jumped %.2f px in one frame" % maximum_particle_jump)
		return
	print(
		"LIGHT_THE_LAMP_STRESS_OK plug_jump=%.2f particle_jump=%.2f constraint_error=%.2f"
		% [maximum_plug_jump, maximum_particle_jump, maximum_constraint_error]
	)
	get_tree().quit()


func _run_motion(
	start_length: float,
	end_length: float,
	start_rotation: float,
	end_rotation: float,
	frame_count: int
) -> void:
	for frame: int in range(frame_count):
		var weight: float = float(frame + 1) / float(frame_count)
		game.set("cable_length", lerpf(start_length, end_length, weight))
		game.call("_update_length_meter")
		board.rotation = lerp_angle(start_rotation, end_rotation, weight)
		await get_tree().physics_frame
		_track_plug_jump()


func _track_plug_jump() -> void:
	var current_position: Vector2 = (
		game.get_node("RopeSystem/PlugHead") as Node2D
	).global_position
	maximum_plug_jump = maxf(
		maximum_plug_jump,
		previous_plug_position.distance_to(current_position)
	)
	previous_plug_position = current_position
	var current_rope_positions: PackedVector2Array = (
		game.get("rope_positions") as PackedVector2Array
	)
	if current_rope_positions.size() == previous_rope_positions.size():
		for index: int in range(current_rope_positions.size()):
			maximum_particle_jump = maxf(
				maximum_particle_jump,
				previous_rope_positions[index].distance_to(current_rope_positions[index])
			)
	previous_rope_positions = current_rope_positions.duplicate()


func _get_maximum_constraint_error() -> float:
	var positions: PackedVector2Array = game.get("rope_positions") as PackedVector2Array
	var rest_length: float = float(game.get("cable_length")) / float(positions.size() - 1)
	var maximum_error: float = 0.0
	for index: int in range(positions.size() - 1):
		maximum_error = maxf(
			maximum_error,
			absf(positions[index].distance_to(positions[index + 1]) - rest_length)
		)
	return maximum_error


func _save_capture(path: String) -> bool:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_fail("could not save " + path)
		return false
	return true


func _fail(message: String) -> void:
	push_error("LIGHT_THE_LAMP_STRESS_FAILED: " + message)
	get_tree().quit(1)
