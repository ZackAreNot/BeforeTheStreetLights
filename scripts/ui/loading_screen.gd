class_name SceneLoadingTransition
extends CanvasLayer

signal covered
signal transition_finished

@onready var fade_root: Control = $FadeRoot
@onready var shutter: ColorRect = $FadeRoot/Shutter
@onready var nara_texture: TextureRect = $FadeRoot/NaraTexture

const OPEN_APERTURE := 1.35
const CLOSE_DURATION := 0.38
const MINIMUM_ICON_TIME := 0.68
const OPEN_DURATION := 0.72

var transition_tween: Tween
var pulse_tween: Tween
var covered_at_msec := 0


func _shutter_material() -> ShaderMaterial:
	return shutter.material as ShaderMaterial

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shutter_material().set_shader_parameter("aperture", OPEN_APERTURE)
	visible = false

func begin() -> void:
	_stop_tweens()
	visible = true
	fade_root.modulate = Color.WHITE
	nara_texture.visible = false
	nara_texture.modulate.a = 0.0
	nara_texture.scale = Vector2(0.78, 0.78)
	_shutter_material().set_shader_parameter("aperture", OPEN_APERTURE)
	if DisplayServer.get_name() == "headless":
		_set_aperture(0.0)
		covered_at_msec = Time.get_ticks_msec()
		call_deferred("_emit_covered")
		return

	transition_tween = create_tween()
	transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	transition_tween.tween_method(
		_set_aperture,
		OPEN_APERTURE,
		0.0,
		CLOSE_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition_tween.finished.connect(_on_closed, CONNECT_ONE_SHOT)

func end() -> void:
	if not visible:
		call_deferred("_emit_transition_finished")
		return
	if DisplayServer.get_name() == "headless":
		_set_aperture(OPEN_APERTURE)
		visible = false
		call_deferred("_emit_transition_finished")
		return
	_play_opening()


func _play_opening() -> void:
	var elapsed_covered := float(Time.get_ticks_msec() - covered_at_msec) / 1000.0
	var remaining_icon_time := maxf(MINIMUM_ICON_TIME - elapsed_covered, 0.0)
	if remaining_icon_time > 0.0:
		await get_tree().create_timer(remaining_icon_time, true).timeout

	if pulse_tween != null and pulse_tween.is_valid():
		pulse_tween.kill()
	transition_tween = create_tween()
	transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	transition_tween.set_parallel(true)
	transition_tween.tween_property(nara_texture, "modulate:a", 0.0, 0.14)
	transition_tween.tween_property(nara_texture, "scale", Vector2(1.16, 1.16), 0.14)
	await transition_tween.finished
	nara_texture.visible = false

	transition_tween = create_tween()
	transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	transition_tween.tween_method(
		_set_aperture,
		0.0,
		OPEN_APERTURE,
		OPEN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	visible = false
	transition_finished.emit()


func _on_closed() -> void:
	covered_at_msec = Time.get_ticks_msec()
	_start_nara_pulse()
	covered.emit()


func _emit_covered() -> void:
	covered.emit()


func _emit_transition_finished() -> void:
	transition_finished.emit()


func _start_nara_pulse() -> void:
	nara_texture.visible = true
	nara_texture.modulate.a = 0.22
	nara_texture.scale = Vector2(0.78, 0.78)
	pulse_tween = create_tween()
	pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulse_tween.set_loops()
	pulse_tween.tween_property(nara_texture, "modulate:a", 1.0, 0.18).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	pulse_tween.parallel().tween_property(
		nara_texture,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse_tween.tween_property(nara_texture, "modulate:a", 0.42, 0.22).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.parallel().tween_property(
		nara_texture,
		"scale",
		Vector2(0.88, 0.88),
		0.22
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_aperture(value: float) -> void:
	_shutter_material().set_shader_parameter("aperture", value)


func _stop_tweens() -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	if pulse_tween != null and pulse_tween.is_valid():
		pulse_tween.kill()
