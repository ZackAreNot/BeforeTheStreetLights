extends Node

signal dialogue_started(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)

const DIALOGUES: Dictionary = {
	"bimo_intro": {
		"timeline": "res://dialogic/timelines/bimo_intro.dtl",
		"repeat_timeline": "res://dialogic/timelines/bimo_repeat.dtl",
		"completion_flag": "met_bimo"
	},
	"shopkeeper_cable": {
		"timeline": "res://dialogic/timelines/shopkeeper_cable.dtl",
		"repeat_timeline": "res://dialogic/timelines/shopkeeper_repeat.dtl",
		"completion_flag": "cable_collected",
		"inventory_item": "Kabel lampu"
	},
	"bu_rami_bakery": {
		"timeline": "res://dialogic/timelines/bu_rami_intro.dtl",
		"repeat_timeline": "res://dialogic/timelines/bu_rami_repeat.dtl",
		"completion_minigame": "bakery",
		"followup_minigame": "bakery"
	},
	"bu_rami_after": {
		"timeline": "res://dialogic/timelines/bu_rami_after.dtl"
	},
	"tara_conversation": {
		"timeline": "res://dialogic/timelines/tara_conversation.dtl",
		"repeat_timeline": "res://dialogic/timelines/tara_repeat.dtl",
		"completion_flag": "tara_invited"
	},
	"dr_seno_clinic": {
		"timeline": "res://dialogic/timelines/dr_seno_intro.dtl",
		"repeat_timeline": "res://dialogic/timelines/dr_seno_repeat.dtl",
		"completion_minigame": "clinic",
		"followup_minigame": "clinic"
	},
	"dr_seno_after": {
		"timeline": "res://dialogic/timelines/dr_seno_after.dtl"
	},
	"festival_epilogue": {
		"timeline": "res://dialogic/timelines/festival_epilogue.dtl",
		"completion_flag": "story_complete",
		"show_ending": true
	}
}

var active_dialogue_id: String = ""
var active_config: Dictionary = {}
var active_player: Node
var active_is_repeat: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.Text.text_started.connect(_on_text_started)

func start_dialogue(dialogue_id: String) -> bool:
	if not active_dialogue_id.is_empty() or GameFlow.transition_busy:
		return false
	if not DIALOGUES.has(dialogue_id):
		push_error("Unknown dialogue id: " + dialogue_id)
		return false

	var config: Dictionary = (DIALOGUES[dialogue_id] as Dictionary).duplicate(true)
	active_is_repeat = _is_completed(config) and config.has("repeat_timeline")
	var timeline_path: String = str(config.get(
		"repeat_timeline" if active_is_repeat else "timeline",
		""
	))
	if timeline_path.is_empty() or not Dialogic.timeline_exists(timeline_path):
		push_error("Dialogue timeline could not be loaded: " + timeline_path)
		active_is_repeat = false
		return false

	active_dialogue_id = dialogue_id
	active_config = config
	active_player = get_tree().get_first_node_in_group("player")
	_set_player_controls(false)
	GameFlow.set_prompt("", false)
	dialogue_started.emit(dialogue_id)
	Dialogic.start(timeline_path)
	return true

func is_dialogue_active() -> bool:
	return not active_dialogue_id.is_empty()

func _is_completed(config: Dictionary) -> bool:
	if config.has("completion_flag"):
		return GameFlow.has_flag(str(config["completion_flag"]))
	if config.has("completion_minigame"):
		return GameFlow.is_minigame_complete(str(config["completion_minigame"]))
	return false

func _on_timeline_ended() -> void:
	if active_dialogue_id.is_empty():
		return

	var finished_id: String = active_dialogue_id
	var finished_config: Dictionary = active_config.duplicate(true)
	var was_repeat: bool = active_is_repeat
	active_dialogue_id = ""
	active_config.clear()
	active_is_repeat = false
	_set_player_controls(true)
	active_player = null

	if not was_repeat:
		if finished_config.has("completion_flag"):
			GameFlow.set_flag(str(finished_config["completion_flag"]), true)
		if finished_config.has("inventory_item"):
			GameFlow.add_inventory_item(str(finished_config["inventory_item"]))

	dialogue_finished.emit(finished_id)
	await get_tree().process_frame
	if not was_repeat and finished_config.has("followup_minigame"):
		GameFlow.start_minigame(str(finished_config["followup_minigame"]))
	elif bool(finished_config.get("show_ending", false)):
		GameFlow.show_ending()

func _on_dialogic_signal(argument: Variant) -> void:
	if not argument is String:
		return
	var command: String = str(argument)
	if command.begins_with("choice:tara:"):
		var choice_id: String = command.trim_prefix("choice:tara:")
		GameFlow.set_flag("tara_choice_" + choice_id, true)
		return
	if not command.begins_with("anim:") or not is_instance_valid(active_player):
		return

	var animation_name: String = command.trim_prefix("anim:")
	match animation_name:
		"shock":
			active_player.call("play_shock")
		"overwhelmed":
			active_player.call("play_overwhelmed", 2.0)
		"holding_item":
			active_player.call("play_holding_item", 2.2)
		"sitting":
			active_player.call("play_sitting", 20.0)

func _on_text_started(info: Dictionary) -> void:
	if not is_instance_valid(active_player):
		return
	var character: Resource = info.get("character") as Resource
	if character != null and str(character.get("display_name")) == "Nara":
		active_player.call("play_talk", 1.4)

func _set_player_controls(enabled: bool) -> void:
	if is_instance_valid(active_player) and active_player.has_method("set_controls_enabled"):
		active_player.call("set_controls_enabled", enabled)
