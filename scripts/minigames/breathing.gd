extends Control

enum BreathPhase {
	INHALE,
	EXHALE
}

const PHASE_DURATION: float = 2.8
const REQUIRED_ACCURACY: float = 0.58
const TOTAL_CYCLES: int = 3

@onready var breath_circle: TextureRect = $BreathCircle
@onready var instruction_label: Label = $InstructionLabel
@onready var cycle_label: Label = $CycleLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var thought_layer: Control = $Thoughts

var phase: BreathPhase = BreathPhase.INHALE
var phase_time: float = 0.0
var correct_time: float = 0.0
var completed_cycles: int = 0
var completed: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_update_phase_interface()

func _process(delta: float) -> void:
	if completed:
		return
	phase_time += delta
	var progress: float = clampf(phase_time / PHASE_DURATION, 0.0, 1.0)
	var should_hold: bool = phase == BreathPhase.INHALE
	var input_matches: bool = Input.is_action_pressed("jump") == should_hold
	if input_matches:
		correct_time += delta
	var visual_progress: float = progress if phase == BreathPhase.INHALE else 1.0 - progress
	var circle_scale: float = lerpf(0.72, 1.24, visual_progress)
	breath_circle.scale = Vector2(circle_scale, circle_scale)
	progress_bar.value = progress * 100.0
	thought_layer.modulate.a = lerpf(0.85, 0.22, float(completed_cycles) / float(TOTAL_CYCLES))
	if phase_time >= PHASE_DURATION:
		_finish_phase()

func _finish_phase() -> void:
	var accuracy: float = correct_time / PHASE_DURATION
	if accuracy < REQUIRED_ACCURACY:
		feedback_label.text = "Tidak apa-apa. Coba ikuti ritmenya sekali lagi."
		phase_time = 0.0
		correct_time = 0.0
		return
	if phase == BreathPhase.INHALE:
		phase = BreathPhase.EXHALE
	else:
		completed_cycles += 1
		if completed_cycles >= TOTAL_CYCLES:
			_complete_breathing()
			return
		phase = BreathPhase.INHALE
	phase_time = 0.0
	correct_time = 0.0
	feedback_label.text = "Bagus. Tidak perlu terburu-buru."
	_update_phase_interface()

func _update_phase_interface() -> void:
	cycle_label.text = "NAPAS %d / %d" % [completed_cycles + 1, TOTAL_CYCLES]
	if phase == BreathPhase.INHALE:
		instruction_label.text = "TARIK NAPAS"
		feedback_label.text = "Tahan SPACE saat lingkaran membesar."
	else:
		instruction_label.text = "BUANG NAPAS"
		feedback_label.text = "Lepaskan SPACE saat lingkaran mengecil."

func _complete_breathing() -> void:
	completed = true
	instruction_label.text = "AKU CAPEK, BIM."
	cycle_label.text = ""
	feedback_label.text = "Oke. Mau duduk dulu?"
	progress_bar.value = 100.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(thought_layer, "modulate:a", 0.0, 0.8)
	tween.tween_property(breath_circle, "modulate:a", 0.25, 0.8)
	await tween.finished
	await get_tree().create_timer(0.8).timeout
	GameFlow.complete_minigame("breathing")

