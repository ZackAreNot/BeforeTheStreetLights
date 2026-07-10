extends TextureRect

signal food_dropped(food_id: String)

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_CAN_DROP

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("food_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var payload: Dictionary = data as Dictionary
	food_dropped.emit(str(payload.get("food_id", "")))

