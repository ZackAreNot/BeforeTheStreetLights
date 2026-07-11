@tool
extends Path2D

@export_category("Editor Track Guide")
@export var guide_color: Color = Color(0.1, 0.95, 1.0, 0.95)
@export var guide_outline_color: Color = Color(0.02, 0.08, 0.1, 0.9)
@export_range(1.0, 12.0, 0.5) var guide_width: float = 3.0
@export var auto_smooth: bool = true
@export var show_guide_in_game: bool = false

var _last_control_points := PackedVector2Array()


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	_last_control_points = _get_control_points()
	queue_redraw()


func _process(_delta: float) -> void:
	if curve == null:
		return

	var current_points := _get_control_points()
	if current_points != _last_control_points:
		if auto_smooth:
			_smooth_handles()
		_last_control_points = current_points
	queue_redraw()


func _draw() -> void:
	if curve == null or (not Engine.is_editor_hint() and not show_guide_in_game):
		return

	var baked_points := curve.get_baked_points()
	if baked_points.size() >= 2:
		draw_polyline(baked_points, guide_outline_color, guide_width + 3.0, true)
		draw_polyline(baked_points, guide_color, guide_width, true)


func _get_control_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	if curve == null:
		return points
	for index in range(curve.point_count):
		points.append(curve.get_point_position(index))
	return points


func _smooth_handles() -> void:
	if curve == null or curve.point_count < 2:
		return

	for index in range(curve.point_count):
		var previous := curve.get_point_position(maxi(index - 1, 0))
		var next := curve.get_point_position(mini(index + 1, curve.point_count - 1))
		var tangent := (next - previous) * 0.18
		curve.set_point_in(index, -tangent if index > 0 else Vector2.ZERO)
		curve.set_point_out(index, tangent if index < curve.point_count - 1 else Vector2.ZERO)
