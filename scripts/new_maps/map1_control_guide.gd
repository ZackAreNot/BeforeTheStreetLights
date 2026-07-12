extends CanvasLayer

signal guide_completed
signal interaction_guide_completed

@export var show_after_opening: bool = true

@onready var panel_root: Control = $PanelRoot
@onready var interaction_panel_root: Control = $InteractionGuideRoot

var _completed := false
var _interaction_completed := false
var _player: Node
var _transition: Tween


func _ready() -> void:
	panel_root.visible = false
	interaction_panel_root.visible = false
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		_completed = true
		return

	_player = get_tree().get_first_node_in_group(&"player")
	var opening := get_node_or_null("../OpeningCutscene")
	if show_after_opening and opening != null:
		opening.connect("opening_finished", _show_guide, CONNECT_ONE_SHOT)
	else:
		_show_guide.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if panel_root.visible:
		get_viewport().set_input_as_handled()
		_dismiss_guide()
	elif interaction_panel_root.visible:
		get_viewport().set_input_as_handled()
		_dismiss_interaction_guide()


func is_completed() -> bool:
	return _completed


func is_interaction_blocked() -> bool:
	return panel_root.visible or interaction_panel_root.visible


func show_interaction_guide() -> void:
	if not _completed or _interaction_completed or interaction_panel_root.visible:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
	if is_instance_valid(_player) and _player.has_method("set_controls_enabled"):
		_player.call("set_controls_enabled", false)

	interaction_panel_root.visible = true
	interaction_panel_root.modulate.a = 0.0
	interaction_panel_root.scale = Vector2(0.9, 0.9)
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(
		interaction_panel_root,
		"modulate:a",
		1.0,
		0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition.tween_property(
		interaction_panel_root,
		"scale",
		Vector2.ONE,
		0.26
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_guide() -> void:
	if _completed:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
	if is_instance_valid(_player) and _player.has_method("set_controls_enabled"):
		_player.call("set_controls_enabled", false)

	panel_root.visible = true
	panel_root.modulate.a = 0.0
	panel_root.scale = Vector2(0.9, 0.9)
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(panel_root, "modulate:a", 1.0, 0.22).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	_transition.tween_property(panel_root, "scale", Vector2.ONE, 0.28).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _dismiss_guide() -> void:
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(panel_root, "modulate:a", 0.0, 0.16).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN)
	_transition.tween_property(panel_root, "scale", Vector2(0.96, 0.96), 0.16).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN)
	await _transition.finished
	panel_root.visible = false
	_completed = true
	if is_instance_valid(_player) and _player.has_method("set_controls_enabled"):
		_player.call("set_controls_enabled", true)
	guide_completed.emit()


func _dismiss_interaction_guide() -> void:
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(
		interaction_panel_root,
		"modulate:a",
		0.0,
		0.16
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition.tween_property(
		interaction_panel_root,
		"scale",
		Vector2(0.96, 0.96),
		0.16
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _transition.finished
	interaction_panel_root.visible = false
	_interaction_completed = true
	if is_instance_valid(_player) and _player.has_method("set_controls_enabled"):
		_player.call("set_controls_enabled", true)
	interaction_guide_completed.emit()
