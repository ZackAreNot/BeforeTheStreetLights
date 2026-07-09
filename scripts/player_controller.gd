extends CharacterBody2D

@export var walk_speed: float = 220.0
@export var sprint_speed: float = 310.0
@export var jump_velocity: float = -420.0
@export var acceleration: float = 1600.0
@export var friction: float = 1800.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var facing: float = 1.0
var animation_time: float = 0.0

@onready var body_visual: Polygon2D = $Body
@onready var hoodie: Polygon2D = $Hoodie
@onready var head_visual: Polygon2D = $HeadVisual
@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	var target_speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		facing = sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	_flip_placeholder_visuals()
	_update_player_visuals(direction, delta)
	move_and_slide()

func _flip_placeholder_visuals() -> void:
	body_visual.scale.x = facing
	hoodie.scale.x = facing
	head_visual.scale.x = facing
	sprite.scale.x = abs(sprite.scale.x) * facing

func _update_player_visuals(direction: float, delta: float) -> void:
	var moving: bool = absf(direction) > 0.01
	_update_sprite_frame(moving, delta)
	_update_placeholder_pose(moving)

func _update_sprite_frame(moving: bool, delta: float) -> void:
	if moving and is_on_floor():
		animation_time += delta * 10.0
		sprite.frame = 8 + (int(animation_time) % 8)
	else:
		animation_time = 0.0
		sprite.frame = 0

func _update_placeholder_pose(moving: bool) -> void:
	var tired_tint: Color = Color(0.24, 0.31, 0.34, 1)
	hoodie.color = tired_tint if not moving else Color(0.10, 0.25, 0.28, 1)
	body_visual.rotation = sin(Time.get_ticks_msec() * 0.012) * 0.025 if moving and is_on_floor() else 0.0
	head_visual.position.y = sin(Time.get_ticks_msec() * 0.006) * 1.5 if moving else 0.0
