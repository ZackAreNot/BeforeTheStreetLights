extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var objective_label: Label
var location_label: Label
var player: CharacterBody2D

func _ready() -> void:
	_build_background()
	_build_world_collision()
	_build_location_markers()
	_build_ui()
	_spawn_player()
	_set_objective("Tujuan: Jalan ke kanan dan kenali alur Kota Ranting.")

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(120, 500)
	add_child(player)

func _build_background() -> void:
	RenderingServer.set_default_clear_color(Color(0.58, 0.73, 0.80, 1))
	_add_rect("SkyGradientWarm", Vector2(-300, -220), Vector2(5800, 940), Color(0.62, 0.77, 0.82, 1), -100)
	_add_rect("DistantHill", Vector2(-300, 350), Vector2(5800, 260), Color(0.36, 0.50, 0.42, 1), -80)
	_add_rect("StreetBack", Vector2(-300, 456), Vector2(5800, 270), Color(0.32, 0.34, 0.35, 1), -70)

	for i in range(9):
		var x := 220 + i * 560
		_add_building(Vector2(x, 345), Vector2(250, 190), Color(0.48, 0.38, 0.32, 1), "Shop%d" % i)
		_add_lamp_post(x + 310, 405)

	_add_sign(Vector2(250, 305), "Taxi Stop")
	_add_sign(Vector2(850, 305), "Toko Listrik")
	_add_sign(Vector2(1460, 305), "Toko Kue Bu Rami")
	_add_sign(Vector2(2150, 305), "Toko Bunga Tara")
	_add_sign(Vector2(2930, 305), "Klinik St. Ranting")
	_add_sign(Vector2(3920, 305), "Taman Festival")

func _build_world_collision() -> void:
	_add_ground(Vector2(2500, 610), Vector2(5600, 120), "MainGround")
	_add_platform(Vector2(1330, 450), Vector2(320, 28), "ShopStep")
	_add_platform(Vector2(2240, 430), Vector2(250, 28), "FlowerShopStep")
	_add_platform(Vector2(3300, 470), Vector2(360, 28), "ClinicStep")

func _build_location_markers() -> void:
	var markers := [
		{"name": "Taxi Stop", "x": 180, "objective": "Tujuan: Temui Bimo di jalan utama."},
		{"name": "Jalan Utama", "x": 620, "objective": "Tujuan: Ambil kabel lampu di Toko Listrik."},
		{"name": "Toko Listrik", "x": 1040, "objective": "Tujuan: Lanjut ke toko kue untuk makanan festival."},
		{"name": "Toko Kue Bu Rami", "x": 1660, "objective": "Tujuan: Bantu Bu Rami, lalu cari Tara."},
		{"name": "Toko Bunga Tara", "x": 2380, "objective": "Tujuan: Setelah bicara Tara, pergi ke klinik."},
		{"name": "Klinik St. Ranting", "x": 3180, "objective": "Tujuan: Ambil P3K, lalu ke taman festival."},
		{"name": "Taman Festival", "x": 4180, "objective": "Tujuan: Area puzzle kabel dan ending nanti dibuat di sini."},
	]

	for marker in markers:
		var area := Area2D.new()
		area.name = "%sMarker" % marker["name"].replace(" ", "")
		area.position = Vector2(marker["x"], 500)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(360, 180)
		shape.shape = rect
		area.add_child(shape)
		area.body_entered.connect(_on_location_entered.bind(marker["name"], marker["objective"]))
		add_child(area)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var objective_panel := ColorRect.new()
	objective_panel.position = Vector2(24, 24)
	objective_panel.size = Vector2(510, 56)
	objective_panel.color = Color(0.06, 0.07, 0.08, 0.72)
	canvas.add_child(objective_panel)

	objective_label = Label.new()
	objective_label.position = Vector2(40, 39)
	objective_label.size = Vector2(480, 30)
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.74, 1))
	canvas.add_child(objective_label)

	location_label = Label.new()
	location_label.position = Vector2(24, 90)
	location_label.size = Vector2(420, 34)
	location_label.add_theme_font_size_override("font_size", 24)
	location_label.add_theme_color_override("font_color", Color(0.10, 0.12, 0.13, 1))
	canvas.add_child(location_label)

	var controls := Label.new()
	controls.position = Vector2(24, 666)
	controls.size = Vector2(680, 28)
	controls.text = "A/D atau Arrow: jalan  |  Shift: jalan cepat  |  Space: lompat kecil  |  E: interaksi nanti"
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color(0.08, 0.09, 0.10, 0.85))
	canvas.add_child(controls)

func _set_objective(text: String) -> void:
	objective_label.text = text

func _on_location_entered(body: Node2D, location_name: String, objective: String) -> void:
	if body != player:
		return
	location_label.text = location_name
	_set_objective(objective)

func _add_building(pos: Vector2, size: Vector2, color: Color, node_name: String) -> void:
	_add_rect(node_name, pos, size, color, -60)
	_add_rect("%sDoor" % node_name, pos + Vector2(size.x * 0.56, size.y * 0.45), Vector2(48, 104), Color(0.13, 0.10, 0.09, 1), -59)
	_add_rect("%sWindowA" % node_name, pos + Vector2(42, 42), Vector2(52, 44), Color(0.95, 0.74, 0.38, 1), -59)
	_add_rect("%sWindowB" % node_name, pos + Vector2(126, 42), Vector2(52, 44), Color(0.95, 0.74, 0.38, 1), -59)

func _add_lamp_post(x: float, y: float) -> void:
	_add_rect("LampPost", Vector2(x, y), Vector2(10, 160), Color(0.10, 0.11, 0.12, 1), -50)
	_add_rect("LampHead", Vector2(x - 20, y - 18), Vector2(50, 18), Color(0.94, 0.72, 0.32, 1), -49)

func _add_sign(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.position = pos
	label.text = text
	label.z_index = -40
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.11, 0.09, 0.07, 1))
	add_child(label)

func _add_ground(pos: Vector2, size: Vector2, node_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)
	_add_rect("%sVisual" % node_name, pos - size * 0.5, size, Color(0.18, 0.19, 0.18, 1), -30)

func _add_platform(pos: Vector2, size: Vector2, node_name: String) -> void:
	_add_ground(pos, size, node_name)

func _add_rect(node_name: String, pos: Vector2, size: Vector2, color: Color, z: int) -> Polygon2D:
	var rect := Polygon2D.new()
	rect.name = node_name
	rect.position = pos
	rect.color = color
	rect.z_index = z
	rect.polygon = PackedVector2Array(
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y)
	)
	add_child(rect)
	return rect
