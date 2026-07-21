@tool
extends CanvasLayer

@export_category("Pilih Shader")
## Mematikan seluruh stack tanpa mengubah pilihan shader di bawahnya.
@export var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		_sync_effect_nodes()

## Color grading hangat yang sebelumnya dipakai langsung pada semua map.
@export var use_cozy_grade: bool = true:
	set(value):
		use_cozy_grade = value
		_sync_effect_nodes()

## Highlight lembut untuk lampu, langit, dan area terang tanpa blur berlebihan.
@export var use_soft_bloom: bool = false:
	set(value):
		use_soft_bloom = value
		_sync_effect_nodes()

## Kurva tonal halus untuk bayangan yang lebih terbaca dan highlight yang nyaman.
@export var use_filmic_tone: bool = false:
	set(value):
		use_filmic_tone = value
		_sync_effect_nodes()

## Kabut atmosfer tipis di sekitar garis horizon.
@export var use_ambient_haze: bool = false:
	set(value):
		use_ambient_haze = value
		_sync_effect_nodes()

## Grain sangat tipis agar warna vector tidak terasa terlalu steril.
@export var use_subtle_grain: bool = false:
	set(value):
		use_subtle_grain = value
		_sync_effect_nodes()

## Fokus lembut ke tengah layar. Hindari menumpuk terlalu kuat dengan Cozy Grade.
@export var use_soft_vignette: bool = false:
	set(value):
		use_soft_vignette = value
		_sync_effect_nodes()

## Warna lebih kaya dengan highlight yang tetap lembut seperti layar OLED.
@export var use_oled_color: bool = false:
	set(value):
		use_oled_color = value
		_sync_effect_nodes()

## Hitam lebih dalam dan warna lebih tegas seperti karakter layar AMOLED.
@export var use_amoled_punch: bool = false:
	set(value):
		use_amoled_punch = value
		_sync_effect_nodes()

## Refraksi udara bergerak tipis pada area atas agar lingkungan terasa hidup.
@export var use_atmospheric_wind: bool = false:
	set(value):
		use_atmospheric_wind = value
		_sync_effect_nodes()

@export_category("Kekuatan Shader")
@export_range(0.0, 1.0, 0.01) var cozy_strength: float = 1.0:
	set(value):
		cozy_strength = value
		_set_shader_parameter("ColorGrade", &"effect_strength", value)

@export_range(0.0, 0.35, 0.005) var bloom_strength: float = 0.09:
	set(value):
		bloom_strength = value
		_set_shader_parameter("SoftBloom", &"intensity", value)

@export_range(0.0, 1.0, 0.01) var filmic_strength: float = 0.24:
	set(value):
		filmic_strength = value
		_set_shader_parameter("FilmicTone", &"strength", value)

@export_range(0.0, 0.2, 0.005) var haze_strength: float = 0.045:
	set(value):
		haze_strength = value
		_set_shader_parameter("AmbientHaze", &"amount", value)

@export_range(0.0, 0.04, 0.001) var grain_strength: float = 0.008:
	set(value):
		grain_strength = value
		_set_shader_parameter("SubtleGrain", &"amount", value)

@export_range(0.0, 0.5, 0.01) var vignette_strength: float = 0.14:
	set(value):
		vignette_strength = value
		_set_shader_parameter("SoftVignette", &"strength", value)

@export_range(0.0, 1.0, 0.01) var oled_strength: float = 0.58:
	set(value):
		oled_strength = value
		_set_shader_parameter("OLEDColor", &"strength", value)

@export_range(0.0, 1.0, 0.01) var amoled_strength: float = 0.52:
	set(value):
		amoled_strength = value
		_set_shader_parameter("AMOLEDPunch", &"strength", value)

@export_range(0.0, 3.0, 0.05) var wind_strength: float = 0.7:
	set(value):
		wind_strength = value
		_set_shader_parameter("AtmosphericWind", &"strength", value)


func _ready() -> void:
	_sync_effect_nodes()
	_sync_shader_parameters()


func _sync_effect_nodes() -> void:
	_set_effect_enabled("AtmosphericWindBuffer", "AtmosphericWind", use_atmospheric_wind)
	_set_effect_enabled("FilmicToneBuffer", "FilmicTone", use_filmic_tone)
	_set_effect_enabled("ColorGradeBuffer", "ColorGrade", use_cozy_grade)
	_set_effect_enabled("OLEDColorBuffer", "OLEDColor", use_oled_color)
	_set_effect_enabled("AMOLEDPunchBuffer", "AMOLEDPunch", use_amoled_punch)
	_set_effect_enabled("AmbientHazeBuffer", "AmbientHaze", use_ambient_haze)
	_set_effect_enabled("SoftBloomBuffer", "SoftBloom", use_soft_bloom)
	_set_effect_enabled("SubtleGrainBuffer", "SubtleGrain", use_subtle_grain)
	_set_effect_enabled("SoftVignetteBuffer", "SoftVignette", use_soft_vignette)


func _set_effect_enabled(buffer_name: String, effect_name: String, selected: bool) -> void:
	var is_enabled: bool = effects_enabled and selected
	var buffer := get_node_or_null(NodePath(buffer_name)) as BackBufferCopy
	var effect := get_node_or_null(NodePath(effect_name)) as ColorRect
	if buffer != null:
		buffer.visible = is_enabled
	if effect != null:
		effect.visible = is_enabled


func _sync_shader_parameters() -> void:
	_set_shader_parameter("AtmosphericWind", &"strength", wind_strength)
	_set_shader_parameter("ColorGrade", &"effect_strength", cozy_strength)
	_set_shader_parameter("OLEDColor", &"strength", oled_strength)
	_set_shader_parameter("AMOLEDPunch", &"strength", amoled_strength)
	_set_shader_parameter("SoftBloom", &"intensity", bloom_strength)
	_set_shader_parameter("FilmicTone", &"strength", filmic_strength)
	_set_shader_parameter("AmbientHaze", &"amount", haze_strength)
	_set_shader_parameter("SubtleGrain", &"amount", grain_strength)
	_set_shader_parameter("SoftVignette", &"strength", vignette_strength)


func _set_shader_parameter(effect_name: String, parameter: StringName, value: float) -> void:
	var effect := get_node_or_null(NodePath(effect_name)) as ColorRect
	if effect == null:
		return
	var shader_material := effect.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter(parameter, value)
