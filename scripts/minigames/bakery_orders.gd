extends Control

const REQUIRED: Dictionary = {
	"donat": 2,
	"onde": 2,
	"sus": 1,
	"lemper": 1
}

var counts: Dictionary = {
	"donat": 0,
	"onde": 0,
	"sus": 0,
	"lemper": 0
}

@onready var drop_box: TextureRect = $Layout/WorkArea/DropBox
@onready var feedback_label: Label = $Layout/WorkArea/FeedbackLabel
@onready var next_button: Button = $Layout/Sidebar/NextButton
@onready var progress_label: Label = $Layout/Sidebar/ProgressLabel
@onready var count_labels: Dictionary = {
	"donat": $Layout/Sidebar/OrderList/DonatRow/Count,
	"onde": $Layout/Sidebar/OrderList/OndeRow/Count,
	"sus": $Layout/Sidebar/OrderList/SusRow/Count,
	"lemper": $Layout/Sidebar/OrderList/LemperRow/Count
}

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.12, 0.075, 0.055, 1.0))
	drop_box.food_dropped.connect(_on_food_dropped)
	next_button.disabled = true
	_update_interface()

func _on_food_dropped(food_id: String) -> void:
	if not REQUIRED.has(food_id):
		return
	var current_count: int = int(counts[food_id])
	var required_count: int = int(REQUIRED[food_id])
	if current_count >= required_count:
		feedback_label.text = "Yang itu sudah cukup. Kardusnya bukan kos-kosan kue."
		return
	counts[food_id] = current_count + 1
	feedback_label.text = "Pas. Bu Rami mengangguk dari balik etalase."
	_update_interface()

func _update_interface() -> void:
	var total_ready: int = 0
	var total_required: int = 0
	for food_id: String in REQUIRED:
		var current_count: int = int(counts[food_id])
		var required_count: int = int(REQUIRED[food_id])
		var count_label: Label = count_labels[food_id] as Label
		count_label.text = "%d / %d" % [current_count, required_count]
		total_ready += current_count
		total_required += required_count
	progress_label.text = "%d dari %d makanan siap" % [total_ready, total_required]
	next_button.disabled = not _is_complete()
	if not next_button.disabled:
		feedback_label.text = "Pesanan lengkap. Orang capek memang suka lupa lapar."

func _is_complete() -> bool:
	for food_id: String in REQUIRED:
		if int(counts[food_id]) < int(REQUIRED[food_id]):
			return false
	return true

func _on_next_button_pressed() -> void:
	if not _is_complete():
		return
	next_button.disabled = true
	GameFlow.complete_minigame("bakery")

