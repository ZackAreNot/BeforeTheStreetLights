extends Control

@onready var start_button: Button = $TitleBlock/StartButton
@onready var credits_button: Button = $TitleBlock/CreditsButton
@onready var exit_button: Button = $TitleBlock/ExitButton
@onready var credits_overlay: Control = $CreditsOverlay
@onready var close_credits_button: Button = $CreditsOverlay/CreditsPanel/Margin/Content/CloseButton

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.04, 0.035, 0.04, 1.0))
	start_button.grab_focus()

func _on_start_pressed() -> void:
	start_button.disabled = true
	credits_button.disabled = true
	exit_button.disabled = true
	GameFlow.start_new_game()

func _on_exit_pressed() -> void:
	PauseMenu.quit_game()

func _on_credits_pressed() -> void:
	_set_main_buttons_enabled(false)
	credits_overlay.show()
	close_credits_button.grab_focus()

func _on_close_credits_pressed() -> void:
	credits_overlay.hide()
	_set_main_buttons_enabled(true)
	credits_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if credits_overlay.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_credits_pressed()

func _set_main_buttons_enabled(enabled: bool) -> void:
	start_button.disabled = not enabled
	credits_button.disabled = not enabled
	exit_button.disabled = not enabled
