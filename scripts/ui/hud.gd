extends CanvasLayer

@onready var objective_label: Label = $ObjectivePanel/ObjectiveLabel
@onready var location_label: Label = $LocationLabel

func _ready() -> void:
	set_location("Taxi Stop")
	set_objective("Tujuan: Jalan ke kanan dan kenali alur Kota Ranting.")

func set_location(location_name: String) -> void:
	location_label.text = location_name

func set_objective(objective_text: String) -> void:
	objective_label.text = objective_text
