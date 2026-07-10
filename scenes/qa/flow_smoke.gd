extends Node

const AREA_PATHS: Dictionary = {
	"area_01_arrival": "res://scenes/areas/area_01_arrival.tscn",
	"area_02_electric": "res://scenes/areas/area_02_electric_street.tscn",
	"area_03_shops": "res://scenes/areas/area_03_bakery_flower.tscn",
	"area_04_clinic": "res://scenes/areas/area_04_clinic_hill.tscn",
	"area_05_festival": "res://scenes/areas/area_05_festival_park.tscn"
}

const MINIGAME_PATHS: PackedStringArray = [
	"res://scenes/minigames/bakery_orders.tscn",
	"res://scenes/minigames/clinic_form.tscn",
	"res://scenes/minigames/cable_puzzle.tscn",
	"res://scenes/minigames/breathing.tscn"
]

const UI_PATHS: PackedStringArray = [
	"res://scenes/main.tscn",
	"res://scenes/ui/loading_screen.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/prototype_ending.tscn"
]

func _ready() -> void:
	GameFlow.flags.clear()
	GameFlow.inventory.clear()
	GameFlow.pending_dialogue_id = ""

	for path: String in UI_PATHS:
		if not _resource_is_scene(path):
			return
	for path: String in MINIGAME_PATHS:
		if not _resource_is_scene(path):
			return
		var minigame: Node = (load(path) as PackedScene).instantiate()
		add_child(minigame)
		await get_tree().process_frame
		minigame.queue_free()
		await get_tree().process_frame

	for area_id: String in AREA_PATHS:
		var path: String = str(AREA_PATHS[area_id])
		if not _resource_is_scene(path):
			return
		GameFlow.pending_dialogue_id = ""
		var area: Node = (load(path) as PackedScene).instantiate()
		add_child(area)
		await get_tree().process_frame
		if GameFlow.current_area_id != area_id:
			_fail("Area registered as %s instead of %s" % [GameFlow.current_area_id, area_id])
			return
		area.queue_free()
		await get_tree().process_frame

	if GameFlow.get_area_objective("area_01_arrival") != "Temui Bimo di halte.":
		_fail("Area 1 initial objective is wrong")
		return
	GameFlow.set_flag("met_bimo", true)
	if GameFlow.get_area_objective("area_02_electric") != "Ambil kabel lampu di Toko Listrik.":
		_fail("Area 2 initial objective is wrong")
		return
	GameFlow.set_flag("cable_collected", true)
	GameFlow.add_inventory_item("Kabel lampu")
	GameFlow.set_flag("minigame_bakery_complete", true)
	GameFlow.set_flag("tara_invited", true)
	GameFlow.set_flag("minigame_clinic_complete", true)
	GameFlow.add_inventory_item("Kotak P3K")
	GameFlow.set_flag("minigame_cable_complete", true)
	GameFlow.set_flag("festival_lights_connected", true)
	if GameFlow.get_area_objective("area_05_festival") != "Berhenti sejenak. Ikuti ritme napas.":
		_fail("Festival did not advance to breathing objective")
		return
	GameFlow.set_flag("minigame_breathing_complete", true)
	if GameFlow.get_area_objective("area_05_festival") != "Duduk bersama Bimo dan Tara.":
		_fail("Festival did not advance to ending objective")
		return

	var festival: Node = (
		load(str(AREA_PATHS["area_05_festival"])) as PackedScene
	).instantiate()
	add_child(festival)
	await get_tree().process_frame
	var glow: CanvasItem = festival.get_node("Art/VectorWorldGlow") as CanvasItem
	if not glow.visible:
		_fail("Festival glow stayed hidden after breathing")
		return
	if not GameFlow.get_inventory().has("Kabel lampu"):
		_fail("Inventory did not retain the festival cable")
		return

	print(
		"FLOW_SMOKE_OK areas=", AREA_PATHS.size(),
		" minigames=", MINIGAME_PATHS.size(),
		" inventory=", GameFlow.get_inventory().size()
	)
	get_tree().quit()

func _resource_is_scene(path: String) -> bool:
	if not ResourceLoader.exists(path) or not load(path) is PackedScene:
		_fail("Missing or invalid scene " + path)
		return false
	return true

func _fail(message: String) -> void:
	push_error("FLOW_SMOKE_FAILED: " + message)
	get_tree().quit(1)
