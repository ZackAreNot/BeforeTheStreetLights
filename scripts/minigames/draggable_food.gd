extends TextureRect

@export var food_id: String = ""
@export var display_name: String = "Makanan"

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	tooltip_text = display_name

func _get_drag_data(_at_position: Vector2) -> Variant:
	var payload: Dictionary = {
		"food_id": food_id,
		"display_name": display_name
	}
	var preview: TextureRect = TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(118.0, 82.0)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate = Color(1.0, 1.0, 1.0, 0.88)
	set_drag_preview(preview)
	return payload

