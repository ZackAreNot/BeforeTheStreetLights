extends Node

signal dialogue_started(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)

const DIALOGUES: Dictionary = {
	"map1_poster_comment": {
		"timeline": "res://dialogic/timelines/map1_poster_comment.dtl"
	},
	"map1_closed_shop_comment": {
		"timeline": "res://dialogic/timelines/map1_closed_shop_comment.dtl"
	},
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

const SPEAKER_CHARACTER_PATHS: Dictionary = {
	"bimo": "res://dialogic/characters/bimo.dch",
	"bu_rami": "res://dialogic/characters/bu_rami.dch",
	"dr_seno": "res://dialogic/characters/dr_seno.dch",
	"nara": "res://dialogic/characters/nara.dch",
	"penjaga_toko": "res://dialogic/characters/penjaga_toko.dch",
	"tara": "res://dialogic/characters/tara.dch"
}

var active_dialogue_id: String = ""
var active_config: Dictionary = {}
var active_player: Node
var active_layout: Node
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
	var layout: Node = Dialogic.start(timeline_path)
	register_layout_speakers(layout)
	return true

func register_layout_speakers(layout: Node) -> void:
	if not is_instance_valid(layout) or not layout.has_method("register_character"):
		return
	active_layout = layout
	_clear_layout_speaker_references(layout)

	for speaker_id: String in SPEAKER_CHARACTER_PATHS:
		var anchor: Node = get_tree().get_first_node_in_group(
			StringName("dialogue_" + speaker_id)
		)
		if is_instance_valid(anchor):
			layout.call("register_character", SPEAKER_CHARACTER_PATHS[speaker_id], anchor)

	# Lines prefixed with "_" have no character resource. Treat them as
	# Nara's internal narration so Dialogic never displays its debug fallback.
	var nara_anchor: Node = get_tree().get_first_node_in_group(&"dialogue_nara")
	if is_instance_valid(nara_anchor):
		layout.call("register_character", null, nara_anchor)

func release_dialogue_references() -> void:
	_clear_layout_speaker_references(active_layout)
	active_layout = null
	active_player = null
	var persistent_info: Dictionary = Engine.get_meta(
		"dialogic_persistent_style_info",
		{}
	)
	persistent_info.erase("textbubble_registers")
	Engine.set_meta("dialogic_persistent_style_info", persistent_info)

func _clear_layout_speaker_references(layout: Variant) -> void:
	if not is_instance_valid(layout):
		return
	layout.set("registered_characters", {})
	var layout_bubbles: Variant = layout.get("bubbles")
	if layout_bubbles is Array:
		for bubble: Variant in layout_bubbles:
			if is_instance_valid(bubble):
				bubble.set("node_to_point_at", null)
				bubble.set("current_character", null)

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
	_set_player_controls(true)
	release_dialogue_references()
	active_dialogue_id = ""
	active_config.clear()
	active_is_repeat = false

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
