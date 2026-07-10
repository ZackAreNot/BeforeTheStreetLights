extends Control

@onready var replay_button: Button = $Actions/ReplayButton

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.025, 0.03, 0.06, 1.0))
	replay_button.grab_focus()

func _on_replay_pressed() -> void:
	GameFlow.start_new_game()

func _on_menu_pressed() -> void:
	GameFlow.back_to_menu()
