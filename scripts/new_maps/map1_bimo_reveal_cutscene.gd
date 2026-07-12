extends Node

signal reveal_finished

@export_category("Trigger")
@export var trigger_progress: float = 980.0

@export_category("Camera")
@export var camera_pan_duration: float = 1.35
@export var camera_return_duration: float = 1.25
@export var bimo_camera_offset := Vector2(0.0, -300.0)

@export_category("Timing")
@export var look_right_duration: float = 0.45
@export var exclamation_duration: float = 1.0

@onready var player: PathFollow2D = $"../RoadTrack/MaleTrackPlayer"
@onready var player_camera: Camera2D = $"../RoadTrack/MaleTrackPlayer/Camera2D"
@onready var cutscene_camera: Camera2D = $"../CutsceneCamera"
@onready var bimo: Node2D = $"../BimoDummy"
@onready var bubble: Node2D = $"../BimoDummy/CinematicBubble"
@onready var opening: Node = $"../OpeningCutscene"
@onready var control_guide: CanvasLayer = $"../ControlGuide"

var _opening_ready := false
var _triggered := false
var _running := false


func _ready() -> void:
	bubble.visible = false
	bimo.call("set_facing_right", true)
	if bool(opening.get("play_on_ready")):
		opening.opening_finished.connect(_on_opening_finished, CONNECT_ONE_SHOT)
	else:
		_opening_ready = true


func _process(_delta: float) -> void:
	if (
		_triggered
		or not _opening_ready
		or not bool(control_guide.call("is_completed"))
		or player.progress < trigger_progress
	):
		return
	start_reveal()


func start_reveal() -> void:
	if _triggered or _running:
		return
	_triggered = true
	_running = true
	_play_reveal()


func _play_reveal() -> void:
	player.set_controls_enabled(false)
	player_camera.set("drift_enabled", false)
	player_camera.call("reset_drift")
	bimo.call("set_facing_right", true)

	cutscene_camera.zoom = player_camera.zoom
	cutscene_camera.global_position = _get_clamped_center(
		player.global_position + player_camera.position
	)
	cutscene_camera.rotation = 0.0
	cutscene_camera.enabled = true
	cutscene_camera.make_current()
	await get_tree().process_frame
	player_camera.enabled = false

	var pan_to_bimo := create_tween()
	pan_to_bimo.tween_property(
		cutscene_camera,
		"global_position",
		_get_clamped_center(bimo.global_position + bimo_camera_offset),
		camera_pan_duration
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await pan_to_bimo.finished
	await get_tree().create_timer(look_right_duration).timeout

	bimo.call("set_facing_right", false)
	bimo.call("play_notice")
	await _show_exclamation()

	var return_to_nara := create_tween()
	return_to_nara.tween_property(
		cutscene_camera,
		"global_position",
		_get_clamped_center(player.global_position + player_camera.position),
		camera_return_duration
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await return_to_nara.finished

	player_camera.call("reset_drift")
	player_camera.enabled = true
	player_camera.make_current()
	player_camera.reset_smoothing()
	player_camera.force_update_scroll()
	await get_tree().process_frame
	cutscene_camera.enabled = false
	player_camera.set("drift_enabled", true)
	player.set_controls_enabled(true)
	bimo.call("unlock_interaction_prompt")
	_running = false
	reveal_finished.emit()


func _show_exclamation() -> void:
	bubble.visible = true
	bubble.scale = Vector2(0.2, 0.2)
	bubble.modulate.a = 0.0
	var appear := create_tween().set_parallel(true)
	appear.tween_property(bubble, "scale", Vector2.ONE, 0.18).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	appear.tween_property(bubble, "modulate:a", 1.0, 0.12)
	await appear.finished
	await get_tree().create_timer(exclamation_duration).timeout
	var disappear := create_tween().set_parallel(true)
	disappear.tween_property(bubble, "scale", Vector2(0.72, 0.72), 0.14).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN)
	disappear.tween_property(bubble, "modulate:a", 0.0, 0.14)
	await disappear.finished
	bubble.visible = false


func _get_clamped_center(desired_center: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size * 0.5 / player_camera.zoom
	return Vector2(
		clampf(
			desired_center.x,
			float(player_camera.limit_left) + half_view.x,
			float(player_camera.limit_right) - half_view.x
		),
		clampf(
			desired_center.y,
			float(player_camera.limit_top) + half_view.y,
			float(player_camera.limit_bottom) - half_view.y
		)
	)


func _on_opening_finished() -> void:
	_opening_ready = true
