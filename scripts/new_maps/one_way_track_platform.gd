@tool
extends Node2D

@export_category("One-Way Surface")
@export var surface_start := Vector2(-195.0, 0.0)
@export var surface_end := Vector2(195.0, 0.0)
@export var show_editor_guide: bool = true
@export var guide_color := Color(1.0, 0.73, 0.2, 0.95)


func _ready() -> void:
	queue_redraw()


func contains_world_x(world_x: float) -> bool:
	var start := to_global(surface_start)
	var end := to_global(surface_end)
	return world_x >= minf(start.x, end.x) and world_x <= maxf(start.x, end.x)


func surface_y_at_world_x(world_x: float) -> float:
	var start := to_global(surface_start)
	var end := to_global(surface_end)
	var interpolation := inverse_lerp(start.x, end.x, world_x)
	return lerpf(start.y, end.y, interpolation)


func surface_angle() -> float:
	return to_global(surface_start).angle_to_point(to_global(surface_end))


func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_guide:
		return
	draw_line(surface_start, surface_end, Color(0.06, 0.05, 0.03, 0.95), 12.0, true)
	draw_line(surface_start, surface_end, guide_color, 5.0, true)
	draw_circle(surface_start, 8.0, guide_color)
	draw_circle(surface_end, 8.0, guide_color)
