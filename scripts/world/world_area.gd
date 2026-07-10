extends Node2D

@export var area_id: String = ""
@export var location_name: String = "Kota Ranting"
@export var clear_color: Color = Color(0.36, 0.27, 0.25, 1.0)
@export var camera_limit_left: int = 0
@export var camera_limit_top: int = -360
@export var camera_limit_right: int = 3200
@export var camera_limit_bottom: int = 760

@onready var player: CharacterBody2D = $Actors/Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	RenderingServer.set_default_clear_color(clear_color)
	_configure_camera()
	GameFlow.enter_area(area_id, location_name)
	if hud.has_method("set_location"):
		hud.call("set_location", location_name)
	_update_festival_visuals()
	_start_pending_dialogue()

func _configure_camera() -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = camera_limit_left
	camera.limit_top = camera_limit_top
	camera.limit_right = camera_limit_right
	camera.limit_bottom = camera_limit_bottom

func _update_festival_visuals() -> void:
	if area_id != "area_05_festival":
		return
	var lights_off: CanvasItem = get_node_or_null("Art/FestivalLightsOff") as CanvasItem
	var lights_on: CanvasItem = get_node_or_null("Art/FestivalLightsOn") as CanvasItem
	var vector_glow: CanvasItem = get_node_or_null("Art/VectorWorldGlow") as CanvasItem
	var festival_ready: bool = GameFlow.is_minigame_complete("breathing")
	if lights_off != null:
		lights_off.visible = not festival_ready
	if lights_on != null:
		lights_on.visible = festival_ready
	if vector_glow != null:
		vector_glow.visible = festival_ready

func _start_pending_dialogue() -> void:
	var dialogue_id: String = GameFlow.consume_pending_dialogue()
	if dialogue_id.is_empty():
		return
	await get_tree().create_timer(0.65).timeout
	DialogueBridge.start_dialogue(dialogue_id)
