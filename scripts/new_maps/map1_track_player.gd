extends PathFollow2D

@export_category("Movement")
@export var walk_speed: float = 430.0
@export var run_speed: float = 680.0
@export_range(0.0, 1.0, 0.05) var slope_alignment: float = 1.0
@export var slope_rotation_speed: float = 10.0

@export_category("Jump")
@export var jump_velocity: float = 720.0
@export var gravity: float = 1500.0

@export_category("Animation")
@export var idle_texture: Texture2D
@export var walk_texture: Texture2D
@export var run_texture: Texture2D
@export var jump_texture: Texture2D
@export var fall_texture: Texture2D
@export_range(1, 24, 1) var ground_frame_count: int = 10
@export_range(1, 24, 1) var jump_frame_count: int = 6
@export_range(1, 24, 1) var fall_frame_count: int = 4
@export var idle_fps: float = 7.0
@export var walk_fps: float = 10.0
@export var run_fps: float = 13.0
@export var air_fps: float = 10.0

@onready var visual_pivot: Node2D = $VisualPivot
@onready var sprite: Sprite2D = $VisualPivot/MaleSprite

var _animation_name: StringName = &"idle"
var _animation_time: float = 0.0
var _air_offset: float = 0.0
var _vertical_velocity: float = 0.0


func _ready() -> void:
	loop = false
	rotates = false
	_set_animation(&"idle")
	_align_to_track(1.0)


func _process(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	var is_running: bool = Input.is_action_pressed("sprint") and not is_zero_approx(direction)
	var speed: float = run_speed if is_running else walk_speed

	if not is_zero_approx(direction):
		progress += direction * speed * delta
		progress = clampf(progress, 0.0, get_parent().curve.get_baked_length())
		sprite.flip_h = direction < 0.0

	_update_jump(delta)
	if _air_offset < 0.0:
		_set_animation(&"jump" if _vertical_velocity < 0.0 else &"fall")
	elif not is_zero_approx(direction):
		_set_animation(&"run" if is_running else &"walk")
	else:
		_set_animation(&"idle")

	_align_to_track(1.0 - exp(-slope_rotation_speed * delta))
	_advance_animation(delta)


func _update_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_zero_approx(_air_offset):
		_vertical_velocity = -jump_velocity

	if not is_zero_approx(_vertical_velocity) or _air_offset < 0.0:
		_vertical_velocity += gravity * delta
		_air_offset += _vertical_velocity * delta
		if _air_offset >= 0.0:
			_air_offset = 0.0
			_vertical_velocity = 0.0

	visual_pivot.position.y = _air_offset


func _align_to_track(weight: float) -> void:
	var path := get_parent() as Path2D
	if path == null or path.curve == null:
		return

	var curve_length: float = path.curve.get_baked_length()
	var sample_radius: float = 24.0
	var before := path.curve.sample_baked(clampf(progress - sample_radius, 0.0, curve_length))
	var after := path.curve.sample_baked(clampf(progress + sample_radius, 0.0, curve_length))
	var track_angle: float = (after - before).angle() * slope_alignment
	visual_pivot.rotation = lerp_angle(visual_pivot.rotation, track_angle, weight)


func _set_animation(next_animation: StringName) -> void:
	if _animation_name == next_animation and sprite.texture != null:
		return

	_animation_name = next_animation
	_animation_time = 0.0
	match _animation_name:
		&"walk":
			sprite.texture = walk_texture
			sprite.hframes = ground_frame_count
		&"run":
			sprite.texture = run_texture
			sprite.hframes = ground_frame_count
		&"jump":
			sprite.texture = jump_texture
			sprite.hframes = jump_frame_count
		&"fall":
			sprite.texture = fall_texture
			sprite.hframes = fall_frame_count
		_:
			sprite.texture = idle_texture
			sprite.hframes = ground_frame_count
	sprite.frame = 0


func _advance_animation(delta: float) -> void:
	var fps: float = idle_fps
	if _animation_name == &"walk":
		fps = walk_fps
	elif _animation_name == &"run":
		fps = run_fps
	elif _animation_name == &"jump" or _animation_name == &"fall":
		fps = air_fps

	_animation_time += delta
	sprite.frame = int(_animation_time * fps) % sprite.hframes
