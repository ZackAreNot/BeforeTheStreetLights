extends Node2D

const ENTRY_SIDE_DEFAULT := 0
const ENTRY_SIDE_LEFT := 1
const ENTRY_SIDE_RIGHT := 2

@export_category("Map Identity")
@export var area_id: String = ""
@export var location_name: String = "Kota Ranting"

@export_category("Path Player")
@export var player_path: NodePath = ^"RoadTrack/MaleTrackPlayer"
@export var entry_inset: float = 220.0
@export var exit_distance: float = 48.0

@export_category("Camera Override")
@export var override_camera_zoom := false
@export_range(0.2, 1.0, 0.01) var gameplay_camera_zoom: float = 0.58
@export_range(-900.0, 0.0, 5.0) var gameplay_camera_offset_y: float = -360.0

@export_category("Connected Maps")
@export var left_target_area_id: String = ""
@export_enum("Default", "Left", "Right") var left_target_entry_side: int = 0
@export var right_target_area_id: String = ""
@export_enum("Default", "Left", "Right") var right_target_entry_side: int = 0

var _entry_side: int = 0
var _transition_requested := false
var _player: PathFollow2D
var _game_flow: Node


func _enter_tree() -> void:
	_game_flow = get_node_or_null("/root/GameFlow")
	if _game_flow != null:
		_entry_side = int(_game_flow.call("consume_area_entry_side", area_id))
	if _entry_side == ENTRY_SIDE_DEFAULT:
		return
	var opening := get_node_or_null("OpeningCutscene")
	if opening != null:
		opening.set("play_on_ready", false)


func _ready() -> void:
	_player = get_node_or_null(player_path) as PathFollow2D
	if _player == null:
		push_error("Path world map is missing its PathFollow2D player: " + str(player_path))
		set_process(false)
		return

	_apply_camera_settings()
	_apply_entry_side()
	if _entry_side != ENTRY_SIDE_DEFAULT:
		_prepare_returned_map()
	if _game_flow != null:
		_game_flow.call("enter_area", area_id, location_name)


func _process(_delta: float) -> void:
	if (
		_transition_requested
		or _game_flow == null
		or bool(_game_flow.get("transition_busy"))
		or not _player_can_exit()
	):
		return
	var track := _player.get_parent() as Path2D
	if track == null or track.curve == null:
		return

	var track_length := track.curve.get_baked_length()
	if not left_target_area_id.is_empty() and _player.progress <= exit_distance:
		_request_transition(left_target_area_id, left_target_entry_side)
	elif (
		not right_target_area_id.is_empty()
		and _player.progress >= track_length - exit_distance
	):
		_request_transition(right_target_area_id, right_target_entry_side)


func _apply_entry_side() -> void:
	var track := _player.get_parent() as Path2D
	if track == null or track.curve == null:
		return
	var track_length := track.curve.get_baked_length()
	match _entry_side:
		ENTRY_SIDE_LEFT:
			_player.progress = minf(entry_inset, track_length)
			_set_facing(false)
		ENTRY_SIDE_RIGHT:
			_player.progress = maxf(track_length - entry_inset, 0.0)
			_set_facing(true)


func _apply_camera_settings() -> void:
	if not override_camera_zoom:
		return
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.zoom = Vector2.ONE * gameplay_camera_zoom
		var base_position := Vector2(camera.position.x, gameplay_camera_offset_y)
		if camera.has_method("set_base_camera_position"):
			camera.call("set_base_camera_position", base_position)
		else:
			camera.position = base_position
		camera.set("drift_enabled", true)


func _prepare_returned_map() -> void:
	_player.visible = true
	_player.call("set_controls_enabled", true)
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.enabled = true
		camera.make_current()
		camera.reset_smoothing()
		if camera.has_method("reset_drift"):
			camera.call("reset_drift")
		camera.set("drift_enabled", true)

	var taxi := get_node_or_null("TaxiRoadTrack/TaxiPathFollow/TaxiVisual") as CanvasItem
	if taxi != null:
		taxi.visible = false
	var cutscene_camera := get_node_or_null("CutsceneCamera") as Camera2D
	if cutscene_camera != null:
		cutscene_camera.enabled = false

	# The opening guide is only for the first arrival and must not block Map 1
	# interactions when the player returns from Map 2.
	var guide := get_node_or_null("ControlGuide")
	if guide != null:
		guide.set("_completed", true)
		var panel := guide.get_node_or_null("PanelRoot") as CanvasItem
		if panel != null:
			panel.visible = false
		var interaction_panel := guide.get_node_or_null("InteractionGuideRoot") as CanvasItem
		if interaction_panel != null:
			interaction_panel.visible = false


func _player_can_exit() -> bool:
	var dialogue_bridge := get_node_or_null("/root/DialogueBridge")
	if dialogue_bridge != null and bool(dialogue_bridge.call("is_dialogue_active")):
		return false
	return bool(_player.get("_controls_enabled"))


func _request_transition(target_area_id: String, target_entry_side: int) -> void:
	_transition_requested = true
	_player.call("set_controls_enabled", false)
	_game_flow.call("go_to_area", target_area_id, target_entry_side)


func _set_facing(face_left: bool) -> void:
	var sprite := _player.get_node_or_null("VisualPivot/MaleSprite") as Sprite2D
	if sprite != null:
		sprite.flip_h = face_left
