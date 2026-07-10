extends TextureRect

signal plug_received(source: TextureRect, socket: TextureRect, cable_id: String)

@export var cable_id: String = ""

func _ready() -> void:
	add_to_group("cable_sockets")
	mouse_default_cursor_shape = Control.CURSOR_CAN_DROP

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not bool(get_meta("connected", false)) and data is Dictionary and data.has("cable_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var payload: Dictionary = data as Dictionary
	var source: TextureRect = payload.get("source") as TextureRect
	if source == null:
		return
	plug_received.emit(source, self, str(payload.get("cable_id", "")))

