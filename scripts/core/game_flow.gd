extends Node

signal location_changed(location_name: String)
signal objective_changed(objective_text: String)
signal inventory_changed(items: PackedStringArray)
signal prompt_changed(prompt_text: String, is_visible: bool)
signal message_requested(speaker_name: String, message_text: String)
signal progress_changed

const LOADING_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/loading_screen.tscn")
const MAIN_MENU_SCENE: String = "res://scenes/main.tscn"
const ENDING_SCENE: String = "res://scenes/ui/prototype_ending.tscn"
const PRODUCTION_MAP1_SCENE: String = "res://scenes/new_maps/map1/map1_layering_test.tscn"
const ENTRY_SIDE_DEFAULT: int = 0
const ENTRY_SIDE_LEFT: int = 1
const ENTRY_SIDE_RIGHT: int = 2
const ENTRY_SIDE_INTERACTION: int = 3
const PRODUCTION_MAP_SCENES: Dictionary = {
	"map1_production": "res://scenes/new_maps/map1/map1_layering_test.tscn",
	"map2_production": "res://scenes/new_maps/map2/map2.tscn",
	"map3_production": "res://scenes/new_maps/map3/map3.tscn",
	"map3_park_production": "res://scenes/new_maps/map3/map3_park.tscn",
	"map4_production": "res://scenes/new_maps/map4/map4.tscn",
	"map5_production": "res://scenes/new_maps/map5/map5.tscn"
}
const AREA_SCENES: Dictionary = {
	"area_01_arrival": "res://scenes/areas/area_01_arrival.tscn",
	"area_02_electric": "res://scenes/areas/area_02_electric_street.tscn",
	"area_03_shops": "res://scenes/areas/area_03_bakery_flower.tscn",
	"area_04_clinic": "res://scenes/areas/area_04_clinic_hill.tscn",
	"area_05_festival": "res://scenes/areas/area_05_festival_park.tscn"
}
const MINIGAME_SCENES: Dictionary = {
	"bakery": "res://scenes/minigames/bakery_orders.tscn",
	"clinic": "res://scenes/minigames/clinic_form.tscn",
	"cable": "res://scenes/minigames/cable_puzzle.tscn",
	"breathing": "res://scenes/minigames/breathing.tscn"
}

var flags: Dictionary = {}
var inventory: PackedStringArray = PackedStringArray()
var current_area_id: String = ""
var return_area_id: String = ""
var minigame_return_position: Vector2 = Vector2.ZERO
var minigame_return_facing: float = 1.0
var has_minigame_return_state: bool = false
var pending_area_entry_side: int = ENTRY_SIDE_DEFAULT
var transition_busy: bool = false
var loading_screen: Node
var pending_dialogue_id: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	loading_screen = LOADING_SCREEN_SCENE.instantiate()
	add_child(loading_screen)

func start_new_game() -> void:
	flags.clear()
	inventory.clear()
	current_area_id = ""
	clear_minigame_return_state()
	pending_area_entry_side = ENTRY_SIDE_DEFAULT
	pending_dialogue_id = ""
	inventory_changed.emit(inventory)
	current_area_id = "map1_production"
	transition_to_scene(PRODUCTION_MAP1_SCENE)

func enter_area(area_id: String, location_name: String) -> void:
	current_area_id = area_id
	location_changed.emit(location_name)
	objective_changed.emit(get_area_objective(area_id))
	inventory_changed.emit(inventory)
	progress_changed.emit()

func go_to_area(area_id: String, entry_side: int = ENTRY_SIDE_DEFAULT) -> void:
	var scene_path := str(PRODUCTION_MAP_SCENES.get(area_id, AREA_SCENES.get(area_id, "")))
	if scene_path.is_empty():
		push_error("Unknown area id: " + area_id)
		return
	current_area_id = area_id
	pending_area_entry_side = entry_side
	transition_to_scene(scene_path)

func consume_area_entry_side(area_id: String) -> int:
	if area_id != current_area_id:
		return ENTRY_SIDE_DEFAULT
	var entry_side: int = pending_area_entry_side
	pending_area_entry_side = ENTRY_SIDE_DEFAULT
	return entry_side

func start_minigame(minigame_id: String) -> void:
	if not MINIGAME_SCENES.has(minigame_id):
		push_error("Unknown minigame id: " + minigame_id)
		return
	if transition_busy:
		return
	return_area_id = current_area_id
	capture_minigame_return_state()
	transition_to_scene(str(MINIGAME_SCENES[minigame_id]))

func complete_minigame(minigame_id: String, return_to_area: bool = true) -> void:
	set_flag("minigame_" + minigame_id + "_complete", true)
	match minigame_id:
		"bakery":
			add_inventory_item("Kardus makanan")
			pending_dialogue_id = "bu_rami_after"
		"clinic":
			add_inventory_item("Kotak P3K")
			add_inventory_item("Kartu bantuan")
			pending_dialogue_id = "dr_seno_after"
		"cable":
			set_flag("festival_lights_connected", true)
		"breathing":
			set_flag("nara_breathed", true)
	if return_to_area:
		return_to_current_area()

func finish_cable_and_start_breathing() -> void:
	complete_minigame("cable", false)
	transition_to_scene(str(MINIGAME_SCENES["breathing"]))

func return_to_current_area() -> void:
	var target_area: String = return_area_id
	if target_area.is_empty():
		target_area = current_area_id
	go_to_area(target_area)

func capture_minigame_return_state(player_override: Node2D = null) -> void:
	var player: Node2D = player_override
	if player == null:
		player = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		has_minigame_return_state = false
		return
	minigame_return_position = player.global_position
	minigame_return_facing = float(player.get("facing"))
	has_minigame_return_state = true

func restore_minigame_return_state(area_id: String, player: Node2D) -> bool:
	if (
		not has_minigame_return_state
		or area_id != return_area_id
		or player == null
	):
		return false
	player.global_position = minigame_return_position
	player.set("facing", minigame_return_facing)
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO
	has_minigame_return_state = false
	return_area_id = ""
	return true

func clear_minigame_return_state() -> void:
	return_area_id = ""
	minigame_return_position = Vector2.ZERO
	minigame_return_facing = 1.0
	has_minigame_return_state = false

func show_ending() -> void:
	transition_to_scene(ENDING_SCENE)

func consume_pending_dialogue() -> String:
	var dialogue_id: String = pending_dialogue_id
	pending_dialogue_id = ""
	return dialogue_id

func back_to_menu() -> void:
	transition_to_scene(MAIN_MENU_SCENE)

func transition_to_scene(scene_path: String) -> void:
	if transition_busy:
		return
	transition_busy = true
	set_prompt("", false)
	var covered_signal := Signal(loading_screen, &"covered")
	loading_screen.call("begin")
	await covered_signal

	var packed_scene: PackedScene = null
	var request_error: Error = ResourceLoader.load_threaded_request(scene_path)
	if request_error == OK:
		var progress: Array = []
		var load_status: int = ResourceLoader.load_threaded_get_status(scene_path, progress)
		while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			packed_scene = ResourceLoader.load_threaded_get(scene_path) as PackedScene

	if packed_scene == null:
		packed_scene = load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Could not load scene: " + scene_path)
		var failed_transition_finished := Signal(loading_screen, &"transition_finished")
		loading_screen.call("end")
		await failed_transition_finished
		transition_busy = false
		return

	get_tree().change_scene_to_packed(packed_scene)
	await get_tree().process_frame
	var transition_finished_signal := Signal(loading_screen, &"transition_finished")
	loading_screen.call("end")
	await transition_finished_signal
	transition_busy = false

func set_flag(flag_name: String, value: bool = true) -> void:
	if flag_name.is_empty():
		return
	flags[flag_name] = value
	objective_changed.emit(get_area_objective(current_area_id))
	progress_changed.emit()

func has_flag(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))

func requirements_met(required_flags: PackedStringArray) -> bool:
	for flag_name: String in required_flags:
		if not has_flag(flag_name):
			return false
	return true

func is_minigame_complete(minigame_id: String) -> bool:
	return has_flag("minigame_" + minigame_id + "_complete")

func add_inventory_item(item_name: String) -> void:
	if item_name.is_empty() or inventory.has(item_name):
		return
	inventory.append(item_name)
	inventory_changed.emit(inventory)

func get_inventory() -> PackedStringArray:
	return inventory.duplicate()

func set_prompt(prompt_text: String, is_visible: bool) -> void:
	prompt_changed.emit(prompt_text, is_visible)

func show_message(speaker_name: String, message_text: String) -> void:
	message_requested.emit(speaker_name, message_text)

func get_area_objective(area_id: String) -> String:
	match area_id:
		"map1_production":
			return "Susuri jalan menuju kawasan toko listrik."
		"map2_production":
			return "Jelajahi kawasan toko listrik."
		"map3_production":
			return "Susuri jalan menuju toko bunga Tara."
		"map3_park_production":
			return "Jelajahi taman di balik pagar."
		"map4_production":
			return "Lanjutkan perjalanan menuju klinik."
		"map5_production":
			return "Naiki tangga menuju klinik."
		"area_01_arrival":
			if not has_flag("met_bimo"):
				return "Temui Bimo di halte."
			return "Lanjut ke jalan pertokoan."
		"area_02_electric":
			if not has_flag("cable_collected"):
				return "Ambil kabel lampu di Toko Listrik."
			return "Bawa kabel ke lorong pertokoan."
		"area_03_shops":
			if not is_minigame_complete("bakery"):
				return "Bantu Bu Rami menata pesanan."
			if not has_flag("tara_invited"):
				return "Temui Tara di toko bunga."
			return "Pergi ke Klinik St. Ranting."
		"area_04_clinic":
			if not is_minigame_complete("clinic"):
				return "Bantu dr. Seno mencatat keluhan pasien."
			return "Bawa P3K ke taman festival."
		"area_05_festival":
			if not is_minigame_complete("cable"):
				return "Sambungkan kabel lampu festival."
			if not is_minigame_complete("breathing"):
				return "Berhenti sejenak. Ikuti ritme napas."
			return "Duduk bersama Bimo dan Tara."
	return "Jelajahi Kota Ranting."
