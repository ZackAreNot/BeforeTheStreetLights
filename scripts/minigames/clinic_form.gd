extends Control

var patients: Array[Dictionary] = [
	{
		"name": "Mira",
		"quote": "Sudah beberapa minggu aku sulit tidur dan sulit fokus. Belakangan kepala juga sering sakit.",
		"type": 3,
		"duration": 2,
		"symptoms": PackedStringArray(["Sulit tidur", "Sulit fokus", "Sakit kepala"])
	},
	{
		"name": "Danu",
		"quote": "Tiga hari ini aku pusing dan mudah lelah setelah kerja bakti. Tidak ada keluhan lain.",
		"type": 1,
		"duration": 1,
		"symptoms": PackedStringArray(["Pusing", "Mudah lelah"])
	},
	{
		"name": "Sari",
		"quote": "Sudah beberapa minggu aku sering cemas dan menarik diri. Badanku tidak sakit, tapi rasanya berat.",
		"type": 2,
		"duration": 2,
		"symptoms": PackedStringArray(["Cemas", "Menarik diri"])
	}
]

@onready var patient_name: Label = $Layout/PatientPanel/PatientName
@onready var patient_quote: Label = $Layout/PatientPanel/PatientQuote
@onready var patient_number: Label = $Layout/PatientPanel/PatientNumber
@onready var type_option: OptionButton = $Layout/FormPanel/FormMargin/Form/TypeOption
@onready var duration_option: OptionButton = $Layout/FormPanel/FormMargin/Form/DurationOption
@onready var feedback_label: Label = $Layout/FormPanel/FormMargin/Form/FeedbackLabel
@onready var submit_button: Button = $Layout/FormPanel/FormMargin/Form/SubmitButton
@onready var symptom_checks: Array[CheckBox] = [
	$Layout/FormPanel/FormMargin/Form/SymptomGrid/Sleep,
	$Layout/FormPanel/FormMargin/Form/SymptomGrid/Focus,
	$Layout/FormPanel/FormMargin/Form/SymptomGrid/Headache,
	$Layout/FormPanel/FormMargin/Form/SymptomGrid/Dizzy,
	$Layout/FormPanel/FormMargin/Form/SymptomGrid/Tired,
	$Layout/FormPanel/FormMargin/Form/SymptomGrid/Anxious,
	$Layout/FormPanel/FormMargin/Form/SymptomGrid/Withdrawn
]

var patient_index: int = 0
var finished: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.76, 0.79, 0.77, 1.0))
	type_option.add_item("Pilih jenis keluhan")
	type_option.add_item("Fisik")
	type_option.add_item("Mental / emosional")
	type_option.add_item("Keduanya")
	duration_option.add_item("Pilih durasi")
	duration_option.add_item("Beberapa hari")
	duration_option.add_item("Beberapa minggu")
	_show_patient()

func _show_patient() -> void:
	var patient: Dictionary = patients[patient_index]
	patient_name.text = str(patient["name"])
	patient_quote.text = "\"" + str(patient["quote"]) + "\""
	patient_number.text = "PASIEN %d / %d" % [patient_index + 1, patients.size()]
	type_option.select(0)
	duration_option.select(0)
	for symptom_check: CheckBox in symptom_checks:
		symptom_check.button_pressed = false
	feedback_label.text = "Catat hanya keluhan yang disebutkan pasien."

func _on_submit_button_pressed() -> void:
	if finished:
		submit_button.disabled = true
		GameFlow.complete_minigame("clinic")
		return
	var patient: Dictionary = patients[patient_index]
	if type_option.selected != int(patient["type"]) or duration_option.selected != int(patient["duration"]):
		feedback_label.text = "Baca lagi ceritanya. Kita mencatat, bukan menebak."
		return
	var expected_symptoms: PackedStringArray = patient["symptoms"] as PackedStringArray
	var selected_symptoms: PackedStringArray = _get_selected_symptoms()
	if not _same_symptoms(expected_symptoms, selected_symptoms):
		feedback_label.text = "Ada keluhan yang terlewat atau tidak disebutkan."
		return
	patient_index += 1
	if patient_index >= patients.size():
		finished = true
		patient_number.text = "SEMUA FORMULIR TERCATAT"
		patient_name.text = "Terima kasih"
		patient_quote.text = "Kesehatan bukan cuma soal tubuh. Keluhan yang didengar dengan serius adalah awal yang penting."
		feedback_label.text = "Kotak P3K untuk festival sudah disiapkan."
		submit_button.text = "KEMBALI KE KLINIK"
		_set_form_enabled(false)
		return
	_show_patient()

func _get_selected_symptoms() -> PackedStringArray:
	var selected: PackedStringArray = PackedStringArray()
	for symptom_check: CheckBox in symptom_checks:
		if symptom_check.button_pressed:
			selected.append(symptom_check.text)
	selected.sort()
	return selected

func _same_symptoms(expected: PackedStringArray, selected: PackedStringArray) -> bool:
	var expected_sorted: PackedStringArray = expected.duplicate()
	expected_sorted.sort()
	return expected_sorted == selected

func _set_form_enabled(is_enabled: bool) -> void:
	type_option.disabled = not is_enabled
	duration_option.disabled = not is_enabled
	for symptom_check: CheckBox in symptom_checks:
		symptom_check.disabled = not is_enabled
