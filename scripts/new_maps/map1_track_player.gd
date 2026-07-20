extends PathFollow2D

@export_category("Movement")
@export var walk_speed: float = 430.0
@export var run_speed: float = 680.0
@export_range(0.0, 1.0, 0.05) var slope_alignment: float = 1.0
@export var slope_rotation_speed: float = 10.0

@export_category("Jump")
@export var jump_velocity: float = 850.0
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
@onready var gameplay_camera: Camera2D = get_node_or_null("Camera2D") as Camera2D

var _animation_name: StringName = &"idle"
var _animation_time: float = 0.0
var _air_offset: float = 0.0
var _vertical_velocity: float = 0.0
var _floor_offset: float = 0.0
var _active_platform: Node2D
var _controls_enabled := true
var _base_sprite_scale := Vector2(6.5, 6.5)
var _expression_tween: Tween


func _ready() -> void:
	loop = false
	rotates = false
	_base_sprite_scale = sprite.scale
	_set_animation(&"idle")
	_align_to_track(1.0)


func _process(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right") if _controls_enabled else 0.0
	var is_running: bool = Input.is_action_pressed("sprint") and not is_zero_approx(direction)
	var speed: float = run_speed if is_running else walk_speed
	_start_jump_if_requested()
	var track_y_before_movement: float = global_position.y

	if not is_zero_approx(direction):
		if _is_grounded():
			progress += direction * speed * delta
			progress = clampf(progress, 0.0, get_parent().curve.get_baked_length())
		else:
			_move_airborne_horizontally(direction, speed, delta)
		sprite.flip_h = direction < 0.0

	_preserve_airborne_world_height(track_y_before_movement)
	_update_jump(delta)
	_update_camera_terrain_compensation()
	if _air_offset < 0.0:
		_set_animation(&"jump" if _vertical_velocity < 0.0 else &"fall")
	elif not is_zero_approx(direction):
		_set_animation(&"run" if is_running else &"walk")
	else:
		_set_animation(&"idle")

	_align_to_track(1.0 - exp(-slope_rotation_speed * delta))
	_advance_animation(delta)


func _start_jump_if_requested() -> void:
	if _controls_enabled and Input.is_action_just_pressed("jump") and _is_grounded():
		_vertical_velocity = -jump_velocity


func _move_airborne_horizontally(direction: float, speed: float, delta: float) -> void:
	var path := get_parent() as Path2D
	if path == null or path.curve == null:
		return
	var curve := path.curve
	var curve_length: float = curve.get_baked_length()
	var current_track_position: Vector2 = curve.sample_baked(progress)
	var start_x: float = curve.sample_baked(0.0).x
	var end_x: float = curve.sample_baked(curve_length).x
	var target_x := clampf(
		current_track_position.x + direction * speed * delta,
		minf(start_x, end_x),
		maxf(start_x, end_x)
	)
	progress = _find_progress_for_track_x(curve, target_x, curve_length)


func _find_progress_for_track_x(curve: Curve2D, target_x: float, curve_length: float) -> float:
	var low := 0.0
	var high := curve_length
	var increasing := curve.sample_baked(curve_length).x >= curve.sample_baked(0.0).x
	for _iteration in range(18):
		var middle := (low + high) * 0.5
		var middle_x := curve.sample_baked(middle).x
		if (middle_x < target_x) == increasing:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5


func _preserve_airborne_world_height(previous_track_y: float) -> void:
	if _air_offset >= 0.0 and is_zero_approx(_vertical_velocity):
		return
	# Keep the jump arc in world space while the PathFollow crosses stepped terrain.
	var track_y_delta: float = global_position.y - previous_track_y
	_air_offset -= track_y_delta
	if gameplay_camera != null and gameplay_camera.has_method("preserve_parent_vertical_motion"):
		gameplay_camera.call("preserve_parent_vertical_motion", track_y_delta)


func _update_camera_terrain_compensation() -> void:
	if gameplay_camera != null and gameplay_camera.has_method("set_terrain_compensation_held"):
		gameplay_camera.call("set_terrain_compensation_held", not _is_grounded())


func _update_jump(delta: float) -> void:
	_update_platform_support()
	var previous_total_offset := _floor_offset + _air_offset
	if not is_zero_approx(_vertical_velocity) or _air_offset < 0.0:
		_vertical_velocity += gravity * delta
		_air_offset += _vertical_velocity * delta
		var landed_on_platform := false
		if _vertical_velocity > 0.0:
			landed_on_platform = _try_land_on_one_way_platform(previous_total_offset)
		if not landed_on_platform and _floor_offset + _air_offset >= 0.0:
			_floor_offset = 0.0
			_air_offset = 0.0
			_vertical_velocity = 0.0
			_active_platform = null

	visual_pivot.position.y = _floor_offset + _air_offset


func _is_grounded() -> bool:
	return is_zero_approx(_air_offset) and is_zero_approx(_vertical_velocity)


func _update_platform_support() -> void:
	if not _is_grounded() or not is_instance_valid(_active_platform):
		return
	if _platform_contains_player(_active_platform):
		_floor_offset = _platform_surface_y(_active_platform) - global_position.y
		return

	_air_offset = _floor_offset
	_floor_offset = 0.0
	_vertical_velocity = 0.0
	_active_platform = null


func _try_land_on_one_way_platform(previous_total_offset: float) -> bool:
	if _vertical_velocity <= 0.0:
		return false
	for platform_variant in get_tree().get_nodes_in_group("map1_one_way_platform"):
		var platform := platform_variant as Node2D
		if not is_instance_valid(platform) or not _platform_contains_player(platform):
			continue
		var platform_offset := _platform_surface_y(platform) - global_position.y
		var current_total_offset := _floor_offset + _air_offset
		if previous_total_offset <= platform_offset and current_total_offset >= platform_offset:
			_floor_offset = platform_offset
			_air_offset = 0.0
			_vertical_velocity = 0.0
			_active_platform = platform
			return true
	return false


func _platform_contains_player(platform: Node2D) -> bool:
	return platform.has_method("contains_world_x") and bool(
		platform.call("contains_world_x", global_position.x)
	)


func _platform_surface_y(platform: Node2D) -> float:
	return float(platform.call("surface_y_at_world_x", global_position.x))


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled


func play_shock() -> void:
	_play_sprite_emphasis(Vector2(1.16, 0.84), 0.34)


func play_talk(duration: float = 1.0) -> void:
	_play_sprite_emphasis(Vector2(1.04, 0.96), duration)


func play_overwhelmed(duration: float = 1.0) -> void:
	_play_sprite_emphasis(Vector2(0.9, 1.1), duration)


func play_holding_item(duration: float = 1.0) -> void:
	_play_sprite_emphasis(Vector2(1.08, 0.92), duration)


func play_sitting(duration: float = 1.0) -> void:
	_play_sprite_emphasis(Vector2(1.16, 0.72), duration)


func _play_sprite_emphasis(multiplier: Vector2, duration: float) -> void:
	if _expression_tween != null and _expression_tween.is_valid():
		_expression_tween.kill()
	sprite.scale = _base_sprite_scale
	_expression_tween = create_tween()
	_expression_tween.tween_property(
		sprite,
		"scale",
		_base_sprite_scale * multiplier,
		0.09
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_expression_tween.tween_property(
		sprite,
		"scale",
		_base_sprite_scale,
		0.16
	).set_delay(maxf(duration - 0.16, 0.05)).set_trans(Tween.TRANS_SINE)


func _align_to_track(weight: float) -> void:
	var path := get_parent() as Path2D
	if path == null or path.curve == null:
		return

	var curve_length: float = path.curve.get_baked_length()
	var sample_radius: float = 24.0
	var before := path.curve.sample_baked(clampf(progress - sample_radius, 0.0, curve_length))
	var after := path.curve.sample_baked(clampf(progress + sample_radius, 0.0, curve_length))
	var track_angle: float = (after - before).angle() * slope_alignment
	if _is_grounded() and is_instance_valid(_active_platform) and _active_platform.has_method("surface_angle"):
		track_angle = float(_active_platform.call("surface_angle"))
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
