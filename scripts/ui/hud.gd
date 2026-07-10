extends CanvasLayer

@onready var objective_label: Label = $ObjectivePanel/Margin/Content/ObjectiveLabel
@onready var location_label: Label = $LocationLabel
@onready var inventory_label: Label = $InventoryPanel/Margin/InventoryLabel
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var prompt_panel: PanelContainer = $PromptPanel
@onready var prompt_label: Label = $PromptPanel/PromptLabel
@onready var message_panel: PanelContainer = $MessagePanel
@onready var speaker_label: Label = $MessagePanel/Margin/Content/Speaker
@onready var message_label: Label = $MessagePanel/Margin/Content/Message
@onready var message_timer: Timer = $MessageTimer

func _ready() -> void:
	prompt_panel.visible = false
	message_panel.visible = false
	GameFlow.location_changed.connect(set_location)
	GameFlow.objective_changed.connect(set_objective)
	GameFlow.inventory_changed.connect(_on_inventory_changed)
	GameFlow.prompt_changed.connect(_on_prompt_changed)
	GameFlow.message_requested.connect(show_message)
	DialogueBridge.dialogue_started.connect(_on_dialogue_started)
	DialogueBridge.dialogue_finished.connect(_on_dialogue_finished)
	_on_inventory_changed(GameFlow.get_inventory())

func set_location(location_name: String) -> void:
	location_label.text = location_name

func set_objective(objective_text: String) -> void:
	objective_label.text = objective_text

func _on_inventory_changed(items: PackedStringArray) -> void:
	if items.is_empty():
		inventory_label.text = "Barang festival: -"
	else:
		inventory_label.text = "Barang festival: " + "  |  ".join(items)

func _on_prompt_changed(prompt_text: String, is_visible: bool) -> void:
	prompt_label.text = prompt_text
	prompt_panel.visible = is_visible and not prompt_text.is_empty()

func show_message(speaker_name: String, message_text: String) -> void:
	speaker_label.text = speaker_name
	message_label.text = message_text
	message_panel.visible = true
	message_timer.start()

func _on_message_timer_timeout() -> void:
	message_panel.visible = false

func _on_dialogue_started(_dialogue_id: String) -> void:
	inventory_panel.hide()
	prompt_panel.hide()
	message_panel.hide()

func _on_dialogue_finished(_dialogue_id: String) -> void:
	inventory_panel.show()
