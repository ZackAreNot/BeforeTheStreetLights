extends TextureRect

@export var cable_id: String = ""

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG

func _get_drag_data(_at_position: Vector2) -> Variant:
	if bool(get_meta("connected", false)):
		return null
	var payload: Dictionary = {
		"cable_id": cable_id,
		"source": self
	}
	var preview: TextureRect = TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(78.0, 128.0)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.self_modulate = self_modulate
	preview.modulate.a = 0.9
	set_drag_preview(preview)
	return payload

