extends CharacterBody2D

@export var walk_speed: float = 220.0
@export var sprint_speed: float = 310.0
@export var jump_velocity: float = -420.0
@export var acceleration: float = 1600.0
@export var friction: float = 1800.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var facing: float = 1.0
var current_animation: String = ""
var action_animation: String = ""
var action_animation_remaining: float = 0.0
var controls_enabled: bool = true

@onready var visual: Node2D = $NaraVisual
@onready var animation_player: AnimationPlayer = $NaraVisual/AnimationPlayer

func _ready() -> void:
	_play_animation("idle")

func _physics_process(delta: float) -> void:
	var direction: float = 0.0
	if controls_enabled:
		direction = Input.get_axis("move_left", "move_right")
	var target_speed: float = walk_speed
	if Input.is_action_pressed("sprint"):
		target_speed = sprint_speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if controls_enabled and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		facing = 1.0 if direction > 0.0 else -1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	_flip_visuals()
	_update_animation(direction, delta)
	move_and_slide()

func _flip_visuals() -> void:
	visual.scale.x = absf(visual.scale.x) * facing

func _update_animation(direction: float, delta: float) -> void:
	if action_animation_remaining > 0.0 and is_on_floor():
		action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
		_play_animation(action_animation)
		return
	if not is_on_floor():
		if velocity.y < 0.0:
			_play_animation("jump")
		else:
			_play_animation("fall")
		return
	if absf(direction) > 0.01:
		if Input.is_action_pressed("sprint"):
			_play_animation("run")
		else:
			_play_animation("walk")
		return
	if GameFlow.has_flag("festival_lights_connected"):
		_play_animation("tired_idle")
	else:
		_play_animation("idle")

func _play_animation(animation_name: String) -> void:
	if current_animation == animation_name or not animation_player.has_animation(animation_name):
		return
	current_animation = animation_name
	animation_player.stop()
	animation_player.play("RESET")
	animation_player.advance(0.0)
	animation_player.play(animation_name, 0.08)

func play_interact() -> void:
	action_animation = "interact"
	action_animation_remaining = 0.55
	current_animation = ""

func play_talk(duration: float = 1.2) -> void:
	action_animation = "talk"
	action_animation_remaining = duration
	current_animation = ""

func play_shock() -> void:
	action_animation = "shock"
	action_animation_remaining = 0.35
	current_animation = ""

func play_overwhelmed(duration: float = 1.2) -> void:
	action_animation = "overwhelmed"
	action_animation_remaining = duration
	current_animation = ""

func play_holding_item(duration: float = 1.5) -> void:
	_play_action_pose("holding_item", duration)

func play_sitting(duration: float = 3.0) -> void:
	_play_action_pose("sitting", duration)

func _play_action_pose(animation_name: String, duration: float) -> void:
	action_animation = animation_name
	action_animation_remaining = duration
	current_animation = ""

func set_controls_enabled(is_enabled: bool) -> void:
	controls_enabled = is_enabled
	if not controls_enabled:
		velocity.x = 0.0
