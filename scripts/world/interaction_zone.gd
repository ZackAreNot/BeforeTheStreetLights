extends Area2D

@export_enum("Message", "Set Flag", "Minigame", "Change Area", "Ending", "Dialogue") var action_type: int = 0
@export var prompt_text: String = "E - Interaksi"
@export var message_speaker: String = "Nara"
@export_multiline var message_text: String = ""
@export_multiline var repeat_message: String = "Sudah selesai."
@export_multiline var blocked_message: String = "Masih ada yang perlu diselesaikan."
@export var flag_to_set: String = ""
@export var inventory_item: String = ""
@export var action_id: String = ""
@export var target_area_id: String = ""
@export var required_flags: PackedStringArray = PackedStringArray()
@export var trigger_automatically: bool = false
@export_enum("Default", "Left", "Right") var target_entry_side: int = 0

var player_inside: bool = false
var player_body: Node2D
var automatic_trigger_used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_inside or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	_execute_action()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	player_body = body
	if trigger_automatically:
		GameFlow.set_prompt("", false)
		if not automatic_trigger_used:
			automatic_trigger_used = true
			_execute_action.call_deferred()
	else:
		GameFlow.set_prompt(prompt_text, true)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	player_body = null
	automatic_trigger_used = false
	GameFlow.set_prompt("", false)

func _execute_action() -> void:
	if (
		not trigger_automatically
		and player_body != null
		and player_body.has_method("play_interact")
	):
		player_body.call("play_interact")
	match action_type:
		0:
			GameFlow.show_message(message_speaker, message_text)
		1:
			_complete_flag_action()
		2:
			_start_minigame()
		3:
			_change_area()
		4:
			_change_to_ending()
		5:
			_start_dialogue()

func _complete_flag_action() -> void:
	if not flag_to_set.is_empty() and GameFlow.has_flag(flag_to_set):
		GameFlow.show_message(message_speaker, repeat_message)
		return
	GameFlow.set_flag(flag_to_set, true)
	GameFlow.add_inventory_item(inventory_item)
	GameFlow.show_message(message_speaker, message_text)

func _start_minigame() -> void:
	if GameFlow.is_minigame_complete(action_id):
		GameFlow.show_message(message_speaker, repeat_message)
		return
	GameFlow.start_minigame(action_id)

func _change_area() -> void:
	if not GameFlow.requirements_met(required_flags):
		GameFlow.show_message(message_speaker, blocked_message)
		return
	GameFlow.go_to_area(target_area_id, target_entry_side)

func _change_to_ending() -> void:
	if not GameFlow.requirements_met(required_flags):
		GameFlow.show_message(message_speaker, blocked_message)
		return
	GameFlow.show_ending()

func _start_dialogue() -> void:
	if not GameFlow.requirements_met(required_flags):
		GameFlow.show_message(message_speaker, blocked_message)
		return
	DialogueBridge.start_dialogue(action_id)
