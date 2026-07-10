extends CanvasLayer

@onready var fade_root: Control = $FadeRoot
@onready var nara_texture: TextureRect = $FadeRoot/NaraTexture
@onready var loading_label: Label = $FadeRoot/LoadingLabel

var elapsed: float = 0.0
var base_nara_y: float = 0.0
var fade_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	base_nara_y = nara_texture.position.y
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	elapsed += delta
	nara_texture.position.y = base_nara_y + sin(elapsed * 2.4) * 5.0
	var dot_count: int = int(elapsed * 2.2) % 4
	loading_label.text = "MEMUAT" + ".".repeat(dot_count)

func begin() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	elapsed = 0.0
	visible = true
	fade_root.modulate.a = 0.0
	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(fade_root, "modulate:a", 1.0, 0.18)

func end() -> void:
	if not visible:
		return
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(fade_root, "modulate:a", 0.0, 0.22)
	fade_tween.finished.connect(_hide_after_fade)

func _hide_after_fade() -> void:
	visible = false
