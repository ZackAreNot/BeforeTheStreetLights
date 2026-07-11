extends Node

signal opening_finished
signal camera_handoff_ready

@export_category("Opening Sequence")
@export var play_on_ready: bool = true
@export_range(0.214, 0.58, 0.005) var initial_zoom: float = 0.214
@export var taxi_stop_progress: float = 640.0
@export var nara_exit_progress: float = 850.0
@export var taxi_departure_progress: float = 2800.0
@export var camera_transition_duration: float = 2.25

@onready var player: PathFollow2D = $"../RoadTrack/MaleTrackPlayer"
@onready var player_camera: Camera2D = $"../RoadTrack/MaleTrackPlayer/Camera2D"
@onready var taxi_path: PathFollow2D = $"../TaxiRoadTrack/TaxiPathFollow"
@onready var taxi: Node2D = $"../TaxiRoadTrack/TaxiPathFollow/TaxiVisual"
@onready var cutscene_camera: Camera2D = $"../CutsceneCamera"

var _sequence_started := false


func _ready() -> void:
	if not play_on_ready or OS.has_feature("headless"):
		return
	start_opening()


func start_opening() -> void:
	if _sequence_started:
		return
	_sequence_started = true
	_prepare_opening()
	_play_opening()


func _prepare_opening() -> void:
	player.set_controls_enabled(false)
	player.progress = taxi_stop_progress
	player.visible = false
	taxi_path.progress = 0.0
	taxi.visible = true
	taxi.call("set_facing", 1.0)
	taxi.call("set_driving", false)

	player_camera.set("drift_enabled", false)
	player_camera.call("reset_drift")
	cutscene_camera.zoom = Vector2.ONE * initial_zoom
	cutscene_camera.global_position = _get_bottom_left_anchored_center(cutscene_camera.zoom)
	cutscene_camera.rotation = 0.0
	cutscene_camera.enabled = true
	player_camera.enabled = false


func _play_opening() -> void:
	await get_tree().create_timer(0.35).timeout

	taxi.call("set_driving", true)
	var arrive := create_tween()
	arrive.tween_property(taxi_path, "progress", taxi_stop_progress, 3.2).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	await arrive.finished
	taxi.call("set_driving", false)
	await get_tree().create_timer(0.45).timeout

	player.visible = true
	player.progress = taxi_stop_progress
	var disembark := create_tween()
	disembark.tween_property(player, "progress", nara_exit_progress, 0.6).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	await disembark.finished
	await get_tree().create_timer(0.35).timeout

	taxi.call("set_facing", 1.0)
	taxi.call("set_driving", true)
	var depart := create_tween()
	depart.tween_property(taxi_path, "progress", taxi_departure_progress, 2.1).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	await depart.finished
	taxi.call("set_driving", false)

	var start_center := cutscene_camera.global_position
	var start_zoom := cutscene_camera.zoom
	var gameplay_target := _get_gameplay_camera_center()
	var nara_focus := (player.get_node("VisualPivot/MaleSprite") as Sprite2D).global_position
	var focus_transition := create_tween()
	focus_transition.tween_method(
		_update_focus_transition.bind(
			start_center,
			start_zoom,
			gameplay_target,
			player_camera.zoom,
			nara_focus
		),
		0.0,
		1.0,
		camera_transition_duration
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	await focus_transition.finished
	cutscene_camera.global_position = gameplay_target
	cutscene_camera.zoom = player_camera.zoom
	await get_tree().process_frame
	camera_handoff_ready.emit()

	taxi.visible = false
	player_camera.call("reset_drift")
	player_camera.enabled = true
	player_camera.make_current()
	player_camera.reset_smoothing()
	player_camera.force_update_scroll()
	# Keep both cameras alive for one frame so the viewport never falls back to a default view.
	await get_tree().process_frame
	cutscene_camera.enabled = false
	player_camera.set("drift_enabled", true)
	player.set_controls_enabled(true)
	opening_finished.emit()


func _get_gameplay_camera_center() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size * 0.5 / player_camera.zoom
	var desired_center := player_camera.global_position
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


func _get_bottom_left_anchored_center(camera_zoom: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_view := viewport_size * 0.5 / camera_zoom
	return Vector2(
		float(player_camera.limit_left) + half_view.x,
		float(player_camera.limit_bottom) - half_view.y
	)


func _update_focus_transition(
	progress_value: float,
	start_center: Vector2,
	start_zoom: Vector2,
	target_center: Vector2,
	target_zoom: Vector2,
	subject_position: Vector2
) -> void:
	var current_zoom := start_zoom.lerp(target_zoom, progress_value)
	var start_screen_offset := (subject_position - start_center) * start_zoom
	var target_screen_offset := (subject_position - target_center) * target_zoom
	var current_screen_offset := start_screen_offset.lerp(target_screen_offset, progress_value)
	cutscene_camera.zoom = current_zoom
	cutscene_camera.global_position = subject_position - Vector2(
		current_screen_offset.x / current_zoom.x,
		current_screen_offset.y / current_zoom.y
	)
