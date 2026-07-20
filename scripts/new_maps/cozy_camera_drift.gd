extends Camera2D

@export_category("Slow Camera Drift")
@export var drift_amplitude := Vector2(16.0, 34.0)
@export_range(0.1, 2.0, 0.01) var drift_speed: float = 1.0
@export_range(0.1, 8.0, 0.1) var drift_response: float = 3.0
@export_range(0.0, 1.0, 0.01) var max_roll_degrees: float = 0.14
@export var drift_enabled: bool = true

@export_category("Terrain Follow")
@export_range(0.1, 20.0, 0.1) var terrain_recenter_speed: float = 5.0

var _base_offset: Vector2
var _current_drift := Vector2.ZERO
var _elapsed_time: float = 0.0
var _terrain_compensation_y := 0.0
var _terrain_compensation_held := false


func _ready() -> void:
	_base_offset = position


func _process(delta: float) -> void:
	_elapsed_time += delta
	var target_drift := _sample_drift(_elapsed_time) if drift_enabled else Vector2.ZERO
	var response_weight := 1.0 - exp(-drift_response * delta)
	_current_drift = _current_drift.lerp(target_drift, response_weight)
	if not _terrain_compensation_held:
		var terrain_weight := 1.0 - exp(-terrain_recenter_speed * delta)
		_terrain_compensation_y = lerpf(_terrain_compensation_y, 0.0, terrain_weight)
		if absf(_terrain_compensation_y) < 0.01:
			_terrain_compensation_y = 0.0
	position = _base_offset + _current_drift + Vector2(0.0, _terrain_compensation_y)
	var roll_ratio := _current_drift.x / maxf(drift_amplitude.x, 1.0)
	rotation = lerp_angle(rotation, deg_to_rad(roll_ratio * max_roll_degrees), response_weight)


func _sample_drift(time: float) -> Vector2:
	var scaled_time := time * drift_speed
	var horizontal := (
		sin(scaled_time * 0.43 + 1.2) * 0.52
		+ sin(scaled_time * 1.07 + 4.8) * 0.30
		+ sin(scaled_time * 0.17 + 2.1) * 0.18
	)
	var vertical := (
		sin(scaled_time * 0.78 + 3.4) * 0.50
		+ sin(scaled_time * 1.63 + 0.7) * 0.30
		+ sin(scaled_time * 0.29 + 5.2) * 0.20
	)
	return Vector2(horizontal * drift_amplitude.x, vertical * drift_amplitude.y)


func reset_drift() -> void:
	_current_drift = Vector2.ZERO
	_terrain_compensation_y = 0.0
	_terrain_compensation_held = false
	position = _base_offset
	rotation = 0.0


func set_base_camera_position(base_position: Vector2) -> void:
	_base_offset = base_position
	position = _base_offset + _current_drift + Vector2(0.0, _terrain_compensation_y)


func preserve_parent_vertical_motion(parent_delta_y: float) -> void:
	_terrain_compensation_y -= parent_delta_y
	_terrain_compensation_held = true


func set_terrain_compensation_held(held: bool) -> void:
	_terrain_compensation_held = held
