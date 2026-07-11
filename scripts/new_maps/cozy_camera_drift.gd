extends Camera2D

@export_category("Slow Camera Drift")
@export var drift_amplitude := Vector2(16.0, 34.0)
@export_range(0.1, 2.0, 0.01) var drift_speed: float = 1.0
@export_range(0.1, 8.0, 0.1) var drift_response: float = 3.0
@export_range(0.0, 1.0, 0.01) var max_roll_degrees: float = 0.14
@export var drift_enabled: bool = true

var _base_offset: Vector2
var _current_drift := Vector2.ZERO
var _elapsed_time: float = 0.0


func _ready() -> void:
	_base_offset = position


func _process(delta: float) -> void:
	_elapsed_time += delta
	var target_drift := _sample_drift(_elapsed_time) if drift_enabled else Vector2.ZERO
	var response_weight := 1.0 - exp(-drift_response * delta)
	_current_drift = _current_drift.lerp(target_drift, response_weight)
	position = _base_offset + _current_drift
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
