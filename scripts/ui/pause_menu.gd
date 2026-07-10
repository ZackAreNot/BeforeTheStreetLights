extends CanvasLayer

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/PausePanel/Margin/Content/ResumeButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if overlay.visible:
		get_viewport().set_input_as_handled()
		_set_paused(false)
	elif _can_open():
		get_viewport().set_input_as_handled()
		_set_paused(true)

func _can_open() -> bool:
	if GameFlow.transition_busy or DialogueBridge.is_dialogue_active():
		return false
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return false
	return current_scene.scene_file_path not in [
		"res://scenes/main.tscn",
		"res://scenes/ui/prototype_ending.tscn"
	]

func _set_paused(is_paused: bool) -> void:
	get_tree().paused = is_paused
	overlay.visible = is_paused
	if is_paused:
		resume_button.grab_focus()

func _on_resume_pressed() -> void:
	_set_paused(false)

func _on_menu_pressed() -> void:
	_set_paused(false)
	GameFlow.back_to_menu()

func quit_game() -> void:
	get_tree().paused = false
	DialogueBridge.release_dialogue_references()
	if Dialogic.has_subsystem("Inputs"):
		Dialogic.Inputs.call("_release_references")
	get_tree().quit()
