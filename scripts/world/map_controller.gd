extends Node2D

@export var player_scene: PackedScene
@export var hud_path: NodePath = NodePath("../HUD")
@export var camera_limit_left: int = -120
@export var camera_limit_top: int = -260
@export var camera_limit_right: int = 5200
@export var camera_limit_bottom: int = 860

@onready var actors: Node2D = $Actors
@onready var spawn_point: Marker2D = $SpawnPoints/PlayerSpawn
@onready var markers: Node2D = $Markers

var player: CharacterBody2D
var hud: Node

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.50, 0.30, 0.20, 1.0))
	hud = get_node_or_null(hud_path)
	_spawn_player()
	_connect_location_markers()
	_update_hud("Taxi Stop", "Tujuan: Temui Bimo di jalan utama.")

func _spawn_player() -> void:
	if player_scene == null:
		push_error("Map01 needs a player_scene assigned.")
		return

	player = player_scene.instantiate() as CharacterBody2D
	actors.add_child(player)
	player.global_position = spawn_point.global_position
	_configure_player_camera()

func _configure_player_camera() -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return

	camera.limit_left = camera_limit_left
	camera.limit_top = camera_limit_top
	camera.limit_right = camera_limit_right
	camera.limit_bottom = camera_limit_bottom

func _connect_location_markers() -> void:
	for marker_node in markers.get_children():
		var area: Area2D = marker_node as Area2D
		if area != null:
			area.body_entered.connect(_on_location_marker_entered.bind(area))

func _on_location_marker_entered(body: Node2D, marker: Area2D) -> void:
	if body != player:
		return

	var location_name: String = str(marker.get("location_name"))
	var objective_text: String = str(marker.get("objective_text"))
	_update_hud(location_name, objective_text)

func _update_hud(location_name: String, objective_text: String) -> void:
	if hud == null:
		return

	if hud.has_method("set_location"):
		hud.set_location(location_name)
	if hud.has_method("set_objective"):
		hud.set_objective(objective_text)
