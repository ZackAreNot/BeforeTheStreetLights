extends Node2D

@export var dialogue_id: String = ""
@export var interaction_distance: float = 260.0
@export var show_interaction_guide: bool = false
@export var prompt_fps: float = 12.0
@export var prompt_frame_count: int = 31
@export var bob_amount: float = 43.0
@export var bob_speed: float = 2.4

@onready var prompt: Sprite2D = $InteractionPrompt

var _player: Node2D
var _elapsed_time := 0.0
var _player_is_near := false
var _player_was_in_range := false
var _base_prompt_position := Vector2.ZERO
var _base_prompt_scale := Vector2.ONE


func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Node2D
	_base_prompt_position = prompt.position
	_base_prompt_scale = prompt.scale


func _process(delta: float) -> void:
	_elapsed_time += delta
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
		return

	var dialogue_bridge := get_node_or_null("/root/DialogueBridge")
	var dialogue_active := (
		dialogue_bridge != null
		and bool(dialogue_bridge.call("is_dialogue_active"))
	)
	var guide := get_tree().get_first_node_in_group(&"map1_control_guide")
	var guide_ready := guide == null or bool(guide.call("is_completed"))
	var player_in_range := (
		guide_ready
		and absf(_player.global_position.x - global_position.x) <= interaction_distance
	)
	if player_in_range and not _player_was_in_range and show_interaction_guide and guide != null:
		guide.call("show_interaction_guide")
	_player_was_in_range = player_in_range
	var guide_blocking := guide != null and bool(guide.call("is_interaction_blocked"))
	_player_is_near = (
		player_in_range
		and not guide_blocking
		and not dialogue_active
	)

	prompt.visible = guide_ready and not dialogue_active
	prompt.frame = int(_elapsed_time * prompt_fps) % maxi(prompt_frame_count, 1)
	prompt.position = _base_prompt_position + Vector2(
		0.0,
		sin(_elapsed_time * bob_speed) * bob_amount
	)
	var emphasis := 1.12 if _player_is_near else 1.0
	prompt.scale = _base_prompt_scale * emphasis
	prompt.modulate.a = 1.0 if _player_is_near else 0.82

	if _player_is_near and Input.is_action_just_pressed("interact"):
		get_viewport().set_input_as_handled()
		_start_comment()


func _start_comment() -> bool:
	if dialogue_id.is_empty():
		return false
	var dialogue_bridge := get_node_or_null("/root/DialogueBridge")
	if dialogue_bridge == null or bool(dialogue_bridge.call("is_dialogue_active")):
		return false
	return bool(dialogue_bridge.call("start_dialogue", dialogue_id))


func _is_guide_completed() -> bool:
	var guide := get_tree().get_first_node_in_group(&"map1_control_guide")
	return guide == null or bool(guide.call("is_completed"))
