extends Control

const CABLE_COLORS: Dictionary = {
	"merah": Color(0.82, 0.24, 0.25, 1.0),
	"hijau": Color(0.25, 0.69, 0.42, 1.0),
	"biru": Color(0.28, 0.42, 0.80, 1.0)
}

@onready var cable_lines: Node2D = $CableLines
@onready var feedback_label: Label = $Header/FeedbackLabel
@onready var progress_label: Label = $Header/ProgressLabel
@onready var pressure_overlay: ColorRect = $PressureOverlay
@onready var pressure_words: Control = $PressureWords

var connected_ids: PackedStringArray = PackedStringArray()
var solved: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.88, 0.84, 0.75, 1.0))
	pressure_overlay.modulate.a = 0.0
	pressure_words.modulate.a = 0.0
	var sockets: Array[Node] = get_tree().get_nodes_in_group("cable_sockets")
	for socket_node: Node in sockets:
		if socket_node.has_signal("plug_received"):
			socket_node.connect("plug_received", _on_plug_received)
	_update_progress()

func _on_plug_received(source: TextureRect, socket: TextureRect, dragged_id: String) -> void:
	if solved:
		return
	var socket_id: String = str(socket.get("cable_id"))
	if dragged_id != socket_id:
		feedback_label.text = "Warnanya tidak cocok. Coba lihat penanda di atas soket."
		return
	if connected_ids.has(dragged_id):
		return
	connected_ids.append(dragged_id)
	source.set_meta("connected", true)
	socket.set_meta("connected", true)
	source.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source.modulate.a = 0.45
	socket.modulate.a = 0.75
	_draw_connection(source, socket, dragged_id)
	feedback_label.text = "Satu jalur menyala. Suara di sekitar mulai terasa jauh."
	_update_progress()
	_update_pressure()
	if connected_ids.size() == CABLE_COLORS.size():
		_start_overload()

func _draw_connection(source: TextureRect, socket: TextureRect, cable_id: String) -> void:
	var line: Line2D = Line2D.new()
	line.width = 16.0
	line.default_color = CABLE_COLORS[cable_id] as Color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var source_center: Vector2 = source.global_position + source.size * 0.5
	var socket_center: Vector2 = socket.global_position + socket.size * 0.5
	var local_source: Vector2 = cable_lines.to_local(source_center)
	var local_socket: Vector2 = cable_lines.to_local(socket_center)
	var middle_y: float = (local_source.y + local_socket.y) * 0.5
	line.points = PackedVector2Array([
		local_source,
		Vector2(local_source.x, middle_y),
		Vector2(local_socket.x, middle_y),
		local_socket
	])
	cable_lines.add_child(line)

func _update_progress() -> void:
	progress_label.text = "%d / %d jalur" % [connected_ids.size(), CABLE_COLORS.size()]

func _update_pressure() -> void:
	var ratio: float = float(connected_ids.size()) / float(CABLE_COLORS.size())
	pressure_overlay.modulate.a = ratio * 0.48
	pressure_words.modulate.a = maxf(0.0, (ratio - 0.28) * 1.25)

func _start_overload() -> void:
	solved = true
	feedback_label.text = "Semua tersambung... tapi Nara tidak bisa mendengar apa-apa lagi."
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pressure_overlay, "modulate:a", 0.92, 0.85)
	tween.tween_property(pressure_words, "modulate:a", 1.0, 0.55)
	await tween.finished
	await get_tree().create_timer(0.65).timeout
	GameFlow.finish_cable_and_start_breathing()
