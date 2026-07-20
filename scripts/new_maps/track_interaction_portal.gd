extends Node2D

@export_category("Destination")
@export var target_area_id: String = ""
@export_enum("Default", "Left", "Right", "Interaction") var target_entry_side: int = 3

@export_category("Interaction")
@export var interaction_distance: float = 300.0
@export var prompt_fps: float = 12.0
@export var prompt_frame_count: int = 31
@export var bob_amount: float = 12.0
@export var bob_speed: float = 2.4

@onready var prompt: Sprite2D = $InteractionPrompt

var _player: PathFollow2D
var _game_flow: Node
var _elapsed_time := 0.0
var _transition_requested := false
var _base_prompt_position := Vector2.ZERO
var _base_prompt_scale := Vector2.ONE


func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as PathFollow2D
	_game_flow = get_node_or_null("/root/GameFlow")
	_base_prompt_position = prompt.position
	_base_prompt_scale = prompt.scale


func _process(delta: float) -> void:
	_elapsed_time += delta
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as PathFollow2D
		return

	var dialogue_bridge := get_node_or_null("/root/DialogueBridge")
	var dialogue_active := (
		dialogue_bridge != null
		and bool(dialogue_bridge.call("is_dialogue_active"))
	)
	var transition_busy := (
		_transition_requested
		or _game_flow == null
		or bool(_game_flow.get("transition_busy"))
	)
	var player_can_interact := bool(_player.get("_controls_enabled"))
	var player_is_near := (
		not transition_busy
		and not dialogue_active
		and player_can_interact
		and _player.global_position.distance_to(global_position) <= interaction_distance
	)

	prompt.visible = not transition_busy and not dialogue_active
	prompt.frame = int(_elapsed_time * prompt_fps) % maxi(prompt_frame_count, 1)
	prompt.position = _base_prompt_position + Vector2(
		0.0,
		sin(_elapsed_time * bob_speed) * bob_amount
	)
	prompt.scale = _base_prompt_scale * (1.12 if player_is_near else 1.0)
	prompt.modulate.a = 1.0 if player_is_near else 0.82

	if player_is_near and Input.is_action_just_pressed("interact"):
		get_viewport().set_input_as_handled()
		_request_transition()


func _request_transition() -> void:
	if target_area_id.is_empty() or _game_flow == null:
		return
	_transition_requested = true
	_player.call("set_controls_enabled", false)
	_game_flow.call("go_to_area", target_area_id, target_entry_side)
