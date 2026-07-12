@tool
extends Node2D

@export var dialogue_id: String = "bimo_intro"
@export var interaction_distance: float = 185.0
@export var prompt_text: String = "E - Bicara dengan Bimo"
@export_range(1.0, 12.0, 0.1) var idle_fps: float = 5.0
@export_category("Track Placement")
@export var snap_to_nara_track: bool = true
@export var track_foot_offset: float = 0.0

var _player: Node2D
var _player_is_near := false
var _idle_time := 0.0
var _prompt_time := 0.0
var _interaction_prompt_unlocked := false
var _prompt_base_position := Vector2.ZERO

@onready var _sprite: Sprite2D = $VisualPivot/MaleSprite
@onready var _interaction_prompt: Sprite2D = $InteractionPrompt


func _ready() -> void:
	if snap_to_nara_track:
		_snap_to_nara_track()
	if not Engine.is_editor_hint():
		_player = get_tree().get_first_node_in_group("player") as Node2D
		_prompt_base_position = _interaction_prompt.position
		_interaction_prompt.visible = false


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if snap_to_nara_track:
			_snap_to_nara_track()
		return

	_idle_time += delta
	_sprite.frame = int(_idle_time * idle_fps) % _sprite.hframes
	_prompt_time += delta
	_interaction_prompt.frame = int(_prompt_time * 12.0) % 31
	_interaction_prompt.position = _prompt_base_position + Vector2(
		0.0,
		sin(_prompt_time * 2.4) * 12.0
	)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return

	var dialogue_bridge := get_node_or_null("/root/DialogueBridge")
	var game_flow := get_node_or_null("/root/GameFlow")
	if dialogue_bridge == null or game_flow == null:
		return
	_interaction_prompt.visible = (
		_interaction_prompt_unlocked
		and not bool(dialogue_bridge.call("is_dialogue_active"))
	)

	var should_offer_dialogue := (
		not bool(dialogue_bridge.call("is_dialogue_active"))
		and global_position.distance_to(_player.global_position) <= interaction_distance
	)
	if should_offer_dialogue != _player_is_near:
		_player_is_near = should_offer_dialogue
		game_flow.call("set_prompt", prompt_text if _player_is_near else "", _player_is_near)

	if _player_is_near and Input.is_action_just_pressed("interact"):
		get_viewport().set_input_as_handled()
		dialogue_bridge.call("start_dialogue", dialogue_id)


func set_facing_right(facing_right: bool) -> void:
	_sprite.flip_h = not facing_right


func play_notice() -> void:
	var original_scale := _sprite.scale
	var notice := create_tween()
	notice.tween_property(_sprite, "scale", original_scale * Vector2(1.08, 0.92), 0.1)
	notice.tween_property(_sprite, "scale", original_scale, 0.16).set_trans(Tween.TRANS_BACK)


func unlock_interaction_prompt() -> void:
	_interaction_prompt_unlocked = true
	_interaction_prompt.visible = true


func _exit_tree() -> void:
	if _player_is_near:
		var game_flow := get_node_or_null("/root/GameFlow")
		if game_flow != null:
			game_flow.call("set_prompt", "", false)


func _snap_to_nara_track() -> void:
	var road_track := get_node_or_null("../RoadTrack") as Path2D
	if road_track == null or road_track.curve == null:
		return

	var closest_track_point := Vector2.ZERO
	var closest_horizontal_distance := INF
	for point in road_track.curve.get_baked_points():
		var world_point := road_track.to_global(point)
		var horizontal_distance := absf(world_point.x - global_position.x)
		if horizontal_distance < closest_horizontal_distance:
			closest_horizontal_distance = horizontal_distance
			closest_track_point = world_point

	global_position.y = closest_track_point.y + track_foot_offset
