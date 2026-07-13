@tool
extends Node2D

@export_category("Dialogue")
@export var dialogue_id: String = ""
@export var interaction_distance: float = 340.0
@export var prompt_text: String = "E - Bicara"

@export_category("Track Placement")
@export var track_path: NodePath = ^"../RoadTrack"
@export var snap_to_track := true
@export var track_foot_offset: float = 0.0

@export_category("Animation")
@export_range(1.0, 12.0, 0.1) var idle_fps: float = 5.0
@export var prompt_fps: float = 12.0
@export var prompt_frame_count: int = 31
@export var prompt_bob_amount: float = 12.0
@export var prompt_bob_speed: float = 2.4

@onready var _sprite: Sprite2D = $VisualPivot/MaleSprite
@onready var _prompt: Node2D = $InteractionPrompt
@onready var _prompt_sprite: Sprite2D = $InteractionPrompt/PromptSprite

var _player: Node2D
var _player_is_near := false
var _idle_time := 0.0
var _prompt_time := 0.0
var _prompt_base_position := Vector2.ZERO
var _prompt_base_scale := Vector2.ONE


func _ready() -> void:
	_snap_to_track()
	if Engine.is_editor_hint():
		return
	_player = get_tree().get_first_node_in_group(&"player") as Node2D
	_prompt_base_position = _prompt.position
	_prompt_base_scale = _prompt.scale


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_snap_to_track()
		return

	_idle_time += delta
	_sprite.frame = int(_idle_time * idle_fps) % maxi(_sprite.hframes, 1)
	_prompt_time += delta
	_prompt_sprite.frame = int(_prompt_time * prompt_fps) % maxi(
		prompt_frame_count,
		1
	)
	_prompt.position = _prompt_base_position + Vector2(
		0.0,
		sin(_prompt_time * prompt_bob_speed) * prompt_bob_amount
	)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
		return

	var dialogue_bridge := get_node_or_null("/root/DialogueBridge")
	var game_flow := get_node_or_null("/root/GameFlow")
	if dialogue_bridge == null or game_flow == null:
		return
	var dialogue_active := bool(dialogue_bridge.call("is_dialogue_active"))
	var player_is_near := (
		absf(_player.global_position.x - global_position.x) <= interaction_distance
		and absf(_player.global_position.y - global_position.y) <= 420.0
		and not dialogue_active
	)
	if player_is_near != _player_is_near:
		_player_is_near = player_is_near
		game_flow.call(
			"set_prompt",
			prompt_text if _player_is_near else "",
			_player_is_near
		)

	_prompt.visible = not dialogue_active
	_prompt.scale = _prompt_base_scale * (1.12 if _player_is_near else 1.0)
	_prompt.modulate.a = 1.0 if _player_is_near else 0.82

	if _player_is_near and Input.is_action_just_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		dialogue_bridge.call("start_dialogue", dialogue_id)


func _exit_tree() -> void:
	if not Engine.is_editor_hint() and _player_is_near:
		var game_flow := get_node_or_null("/root/GameFlow")
		if game_flow != null:
			game_flow.call("set_prompt", "", false)


func _snap_to_track() -> void:
	if not snap_to_track:
		return
	var road_track := get_node_or_null(track_path) as Path2D
	if road_track == null or road_track.curve == null:
		return
	var local_point := road_track.curve.get_closest_point(
		road_track.to_local(global_position)
	)
	var target_y := road_track.to_global(local_point).y + track_foot_offset
	if not is_equal_approx(global_position.y, target_y):
		global_position.y = target_y
