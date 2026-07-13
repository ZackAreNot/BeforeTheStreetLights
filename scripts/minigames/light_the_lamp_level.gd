extends Control

@export_category("Fuse Box")
@export var board_rotation_speed: float = 0.50
@export var board_rotation_acceleration: float = 2.8
@export var board_rotation_deceleration: float = 4.8

@export_category("Stable Cable")
@export_range(24, 52, 1) var particle_count: int = 32
@export var minimum_cable_length: float = 100.0
@export var maximum_cable_length: float = 465.0
@export var initial_cable_length: float = 145.0
@export var cable_adjust_speed: float = 120.0
@export_range(8, 30, 1) var solver_iterations: int = 10
@export_range(1, 4, 1) var physics_substeps: int = 2
@export_range(0.85, 1.0, 0.001) var motion_damping: float = 0.935
@export_range(0.0, 0.16, 0.001) var bend_stiffness: float = 0.08
@export var gravity_acceleration: float = 980.0
@export var plug_gravity_multiplier: float = 1.55
@export var maximum_particle_step: float = 16.0
@export var cable_collision_radius: float = 3.5
@export var plug_collision_radius: float = 24.0
@export var obstacle_skin: float = 1.25
@export var contact_hysteresis: float = 8.0
@export var contact_release_margin: float = 5.0
@export var target_snap_distance: float = 42.0
@export var minimum_length_cm: int = 30
@export var maximum_length_cm: int = 102

@onready var board: AnimatableBody2D = $Board
@onready var frame_collision: CollisionPolygon2D = $Board/FrameCollision
@onready var cable_anchor: Marker2D = $Board/CableAnchor
@onready var bulb_off: Sprite2D = $Board/BulbOff
@onready var bulb_on: Sprite2D = $Board/BulbOn
@onready var target_area: Area2D = $Board/PowerSocket/Target
@onready var warm_wash: ColorRect = $WarmWash
@onready var rope_outline: Line2D = $RopeSystem/RopeOutline
@onready var rope_inner: Line2D = $RopeSystem/RopeInner
@onready var plug: Node2D = $RopeSystem/PlugHead
@onready var plug_cable_point: Marker2D = $RopeSystem/PlugHead/CablePoint
@onready var meter_label: Label = $UILayer/HUD/LengthMeter/LengthLabel
@onready var meter_panel: Panel = $UILayer/HUD/LengthMeter
@onready var completion: Control = $UILayer/Completion
@onready var restart_button: Button = $UILayer/Completion/ResultBand/RestartButton

var obstacle_shapes: Array[CollisionShape2D] = []
var rope_positions: PackedVector2Array = PackedVector2Array()
var rope_previous: PackedVector2Array = PackedVector2Array()
var cable_length: float = 0.0
var rope_ready: bool = false
var solved: bool = false
var board_rotation_velocity: float = 0.0
var obstacle_contact_normals: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.25, 0.34, 0.38, 1.0))
	minimum_cable_length = minf(minimum_cable_length, maximum_cable_length - 1.0)
	initial_cable_length = clampf(
		initial_cable_length,
		minimum_cable_length,
		maximum_cable_length
	)
	cable_length = initial_cable_length
	obstacle_shapes = [
		$Board/CentralBlockCollision as CollisionShape2D,
		$Board/RightBlockCollision as CollisionShape2D,
		$Board/ButtonCollision as CollisionShape2D,
		$Board/GearCollision as CollisionShape2D
	]
	restart_button.pressed.connect(_restart_level)
	completion.modulate.a = 0.0
	completion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_initialize_rope")


func _physics_process(delta: float) -> void:
	if not rope_ready:
		return
	if not solved:
		_handle_controls(delta)
		_simulate_rope(minf(delta, 1.0 / 30.0))
	_update_rope_visual()
	if not solved:
		_check_target_connection()


func _initialize_rope() -> void:
	rope_positions.clear()
	rope_previous.clear()
	obstacle_contact_normals.clear()
	obstacle_contact_normals.resize(particle_count * obstacle_shapes.size())
	obstacle_contact_normals.fill(Vector2.ZERO)
	var anchor_position: Vector2 = cable_anchor.global_position
	var down_direction: Vector2 = Vector2.DOWN.rotated(board.global_rotation)
	var rest_length: float = cable_length / float(particle_count - 1)
	for index: int in range(particle_count):
		var point: Vector2 = anchor_position + down_direction * rest_length * float(index)
		rope_positions.append(point)
		rope_previous.append(point)
	rope_ready = true
	for _settle_step: int in range(12):
		_simulate_rope(1.0 / 120.0)
	_update_length_meter()
	_update_rope_visual()

func _handle_controls(delta: float) -> void:
	var rotation_axis: float = Input.get_axis("move_left", "move_right")
	var target_rotation_velocity: float = rotation_axis * board_rotation_speed
	var rotation_acceleration: float = (
		board_rotation_acceleration
		if not is_zero_approx(rotation_axis)
		else board_rotation_deceleration
	)
	board_rotation_velocity = move_toward(
		board_rotation_velocity,
		target_rotation_velocity,
		rotation_acceleration * delta
	)
	if not is_zero_approx(board_rotation_velocity):
		board.rotation = wrapf(
			board.rotation + board_rotation_velocity * delta,
			-PI,
			PI
		)

	var retract_pressed: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var extend_pressed: bool = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var length_axis: float = 0.0
	if retract_pressed and not extend_pressed:
		length_axis = -1.0
	elif extend_pressed and not retract_pressed:
		length_axis = 1.0
	if not is_zero_approx(length_axis):
		cable_length = clampf(
			cable_length + length_axis * cable_adjust_speed * delta,
			minimum_cable_length,
			maximum_cable_length
		)
		_update_length_meter()


func _simulate_rope(delta: float) -> void:
	var substep_delta: float = delta / float(physics_substeps)
	for _substep: int in range(physics_substeps):
		_integrate_particles(substep_delta)
		var rest_length: float = cable_length / float(rope_positions.size() - 1)
		for _iteration: int in range(solver_iterations):
			rope_positions[0] = cable_anchor.global_position
			_solve_bend_constraints()
			_solve_distance_constraints(rest_length)
			_project_rope_collisions()
		rope_positions[0] = cable_anchor.global_position
		rope_previous[0] = rope_positions[0]


func _integrate_particles(delta: float) -> void:
	var gravity_step: Vector2 = Vector2.DOWN * gravity_acceleration * delta * delta
	rope_positions[0] = cable_anchor.global_position
	rope_previous[0] = rope_positions[0]
	for index: int in range(1, rope_positions.size()):
		var current: Vector2 = rope_positions[index]
		var displacement: Vector2 = (current - rope_previous[index]) * motion_damping
		if displacement.length() > maximum_particle_step:
			displacement = displacement.normalized() * maximum_particle_step
		rope_previous[index] = current
		var gravity_multiplier: float = plug_gravity_multiplier if index == rope_positions.size() - 1 else 1.0
		rope_positions[index] = current + displacement + gravity_step * gravity_multiplier


func _solve_distance_constraints(rest_length: float) -> void:
	for index: int in range(rope_positions.size() - 1):
		var first: Vector2 = rope_positions[index]
		var second: Vector2 = rope_positions[index + 1]
		var difference: Vector2 = second - first
		var distance: float = difference.length()
		if distance < 0.0001:
			difference = Vector2.DOWN
			distance = 1.0
		var correction: Vector2 = difference * ((distance - rest_length) / distance)
		if index == 0:
			second -= correction
		else:
			first += correction * 0.5
			second -= correction * 0.5
		rope_positions[index] = first
		rope_positions[index + 1] = second


func _solve_bend_constraints() -> void:
	for index: int in range(1, rope_positions.size() - 1):
		var midpoint: Vector2 = (
			rope_positions[index - 1] + rope_positions[index + 1]
		) * 0.5
		rope_positions[index] += (
			midpoint - rope_positions[index]
		) * bend_stiffness


func _project_rope_collisions() -> void:
	for index: int in range(1, rope_positions.size()):
		var radius: float = plug_collision_radius if index == rope_positions.size() - 1 else cable_collision_radius
		var original: Vector2 = rope_positions[index]
		var corrected_local: Vector2 = _keep_inside_frame_local(
			board.to_local(original),
			radius
		)
		for obstacle_index: int in range(obstacle_shapes.size()):
			corrected_local = _push_out_of_obstacle_local(
				corrected_local,
				obstacle_shapes[obstacle_index],
				radius,
				index,
				obstacle_index
			)
		var corrected: Vector2 = board.to_global(corrected_local)
		var collision_correction: Vector2 = corrected - original
		if collision_correction.length_squared() > 0.0001:
			rope_positions[index] = corrected
			rope_previous[index] += collision_correction


func _keep_inside_frame_local(board_point: Vector2, radius: float) -> Vector2:
	var local_point: Vector2 = frame_collision.transform.affine_inverse() * board_point
	if (
		absf(local_point.x) <= 300.0 - radius
		and absf(local_point.y) <= 145.0 - radius
	):
		return board_point
	var polygon: PackedVector2Array = frame_collision.polygon
	var inside: bool = Geometry2D.is_point_in_polygon(local_point, polygon)
	var closest_point: Vector2 = polygon[0]
	var closest_distance_squared: float = INF
	for index: int in range(polygon.size() - 1):
		var edge_point: Vector2 = Geometry2D.get_closest_point_to_segment(
			local_point,
			polygon[index],
			polygon[index + 1]
		)
		var distance_squared: float = local_point.distance_squared_to(edge_point)
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			closest_point = edge_point

	var closest_distance: float = sqrt(closest_distance_squared)
	if inside and closest_distance >= radius:
		return board_point
	var inward_direction: Vector2 = (Vector2.ZERO - closest_point).normalized()
	if inward_direction.length_squared() < 0.5:
		inward_direction = Vector2.UP
	if inside:
		local_point += inward_direction * (radius - closest_distance + 0.35)
	else:
		local_point = closest_point + inward_direction * (radius + 0.35)
	return frame_collision.transform * local_point


func _push_out_of_obstacle(
	world_point: Vector2,
	obstacle: CollisionShape2D,
	radius: float,
	particle_index: int = -1,
	obstacle_index: int = -1
) -> Vector2:
	var corrected_local: Vector2 = _push_out_of_obstacle_local(
		board.to_local(world_point),
		obstacle,
		radius,
		particle_index,
		obstacle_index
	)
	return board.to_global(corrected_local)


func _push_out_of_obstacle_local(
	board_point: Vector2,
	obstacle: CollisionShape2D,
	radius: float,
	particle_index: int = -1,
	obstacle_index: int = -1
) -> Vector2:
	if obstacle.shape == null:
		return board_point
	var local_point: Vector2 = obstacle.transform.affine_inverse() * board_point
	var clearance: float = radius + obstacle_skin
	var contact_key: int = -1
	if particle_index >= 0 and obstacle_index >= 0:
		contact_key = particle_index * obstacle_shapes.size() + obstacle_index
	if obstacle.shape is RectangleShape2D:
		var rectangle: RectangleShape2D = obstacle.shape as RectangleShape2D
		local_point = _push_out_of_rectangle(
			local_point,
			rectangle.size * 0.5,
			clearance,
			contact_key,
			obstacle,
			particle_index
		)
	elif obstacle.shape is CircleShape2D:
		var circle: CircleShape2D = obstacle.shape as CircleShape2D
		var minimum_distance: float = circle.radius + clearance
		if local_point.length_squared() < minimum_distance * minimum_distance:
			var push_direction: Vector2 = local_point.normalized()
			if push_direction.length_squared() < 0.5:
				push_direction = _get_cached_contact_normal(contact_key)
			if push_direction.length_squared() < 0.5:
				push_direction = Vector2.RIGHT
			_set_cached_contact_normal(contact_key, push_direction)
			local_point = push_direction * (minimum_distance + 0.2)
		elif local_point.length() > minimum_distance + contact_release_margin:
			_clear_cached_contact(contact_key)
	return obstacle.transform * local_point


func _push_out_of_rectangle(
	local_point: Vector2,
	half_size: Vector2,
	clearance: float,
	contact_key: int,
	obstacle: CollisionShape2D,
	particle_index: int
) -> Vector2:
	var closest_point: Vector2 = Vector2(
		clampf(local_point.x, -half_size.x, half_size.x),
		clampf(local_point.y, -half_size.y, half_size.y)
	)
	var from_surface: Vector2 = local_point - closest_point
	var distance_from_surface: float = from_surface.length()

	# Outside points use the true rounded corner of an expanded rectangle.
	if distance_from_surface > 0.0001:
		if distance_from_surface >= clearance:
			if distance_from_surface > clearance + contact_release_margin:
				_clear_cached_contact(contact_key)
			return local_point
		var rounded_normal: Vector2 = from_surface / distance_from_surface
		_set_cached_contact_normal(contact_key, rounded_normal)
		return closest_point + rounded_normal * (clearance + 0.2)

	var contact_normal: Vector2 = _get_cached_contact_normal(contact_key)
	if contact_normal.length_squared() < 0.5 and particle_index >= 0:
		var previous_board_point: Vector2 = board.to_local(
			rope_previous[particle_index]
		)
		var previous_local: Vector2 = (
			obstacle.transform.affine_inverse() * previous_board_point
		)
		var previous_closest: Vector2 = Vector2(
			clampf(previous_local.x, -half_size.x, half_size.x),
			clampf(previous_local.y, -half_size.y, half_size.y)
		)
		contact_normal = (previous_local - previous_closest).normalized()

	var nearest_normal: Vector2
	var nearest_distance: float
	var distance_x: float = half_size.x - absf(local_point.x)
	var distance_y: float = half_size.y - absf(local_point.y)
	if distance_x < distance_y:
		nearest_normal = Vector2(_nonzero_sign(local_point.x), 0.0)
		nearest_distance = distance_x
	else:
		nearest_normal = Vector2(0.0, _nonzero_sign(local_point.y))
		nearest_distance = distance_y

	if contact_normal.length_squared() >= 0.5:
		contact_normal = _cardinal_normal(contact_normal)
		var cached_exit_distance: float = _distance_to_face(
			local_point,
			half_size,
			contact_normal
		)
		if cached_exit_distance > nearest_distance + contact_hysteresis:
			contact_normal = nearest_normal
	else:
		contact_normal = nearest_normal

	_set_cached_contact_normal(contact_key, contact_normal)
	if not is_zero_approx(contact_normal.x):
		local_point.x = contact_normal.x * (half_size.x + clearance + 0.2)
	else:
		local_point.y = contact_normal.y * (half_size.y + clearance + 0.2)
	return local_point


func _cardinal_normal(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(_nonzero_sign(direction.x), 0.0)
	return Vector2(0.0, _nonzero_sign(direction.y))


func _distance_to_face(
	local_point: Vector2,
	half_size: Vector2,
	normal: Vector2
) -> float:
	if normal.x > 0.0:
		return half_size.x - local_point.x
	if normal.x < 0.0:
		return half_size.x + local_point.x
	if normal.y > 0.0:
		return half_size.y - local_point.y
	return half_size.y + local_point.y


func _nonzero_sign(value: float) -> float:
	return 1.0 if value >= 0.0 else -1.0


func _get_cached_contact_normal(contact_key: int) -> Vector2:
	if contact_key < 0 or contact_key >= obstacle_contact_normals.size():
		return Vector2.ZERO
	return obstacle_contact_normals[contact_key]


func _set_cached_contact_normal(contact_key: int, normal: Vector2) -> void:
	if contact_key >= 0 and contact_key < obstacle_contact_normals.size():
		obstacle_contact_normals[contact_key] = normal


func _clear_cached_contact(contact_key: int) -> void:
	if contact_key >= 0 and contact_key < obstacle_contact_normals.size():
		obstacle_contact_normals[contact_key] = Vector2.ZERO


func _update_rope_visual() -> void:
	if rope_positions.size() < 2:
		return
	var final_index: int = rope_positions.size() - 1
	var plug_direction: Vector2 = (
		rope_positions[final_index] - rope_positions[final_index - 1]
	).normalized()
	if plug_direction.length_squared() < 0.5:
		plug_direction = Vector2.DOWN
	var target_rotation: float = plug_direction.angle() - PI * 0.5
	plug.global_rotation = lerp_angle(plug.global_rotation, target_rotation, 0.38)
	plug.global_position = rope_positions[final_index]

	var visual_points: PackedVector2Array = PackedVector2Array()
	for index: int in range(final_index):
		visual_points.append(rope_outline.to_local(rope_positions[index]))
	visual_points.append(rope_outline.to_local(plug_cable_point.global_position))
	rope_outline.points = visual_points
	rope_inner.points = visual_points


func _check_target_connection() -> void:
	if plug.global_position.distance_to(target_area.global_position) <= target_snap_distance:
		_complete_level()


func _update_length_meter() -> void:
	var ratio: float = inverse_lerp(
		minimum_cable_length,
		maximum_cable_length,
		cable_length
	)
	var current_cm: int = clampi(
		roundi(lerpf(float(minimum_length_cm), float(maximum_length_cm), ratio)),
		minimum_length_cm,
		maximum_length_cm
	)
	meter_label.text = "%d/%d cm" % [current_cm, maximum_length_cm]


func _complete_level() -> void:
	if solved:
		return
	solved = true
	bulb_on.scale = bulb_off.scale * 0.86
	completion.mouse_filter = Control.MOUSE_FILTER_STOP

	var light_tween: Tween = create_tween()
	light_tween.set_parallel(true)
	light_tween.set_trans(Tween.TRANS_BACK)
	light_tween.set_ease(Tween.EASE_OUT)
	light_tween.tween_property(bulb_off, "modulate:a", 0.0, 0.2)
	light_tween.tween_property(bulb_on, "modulate:a", 1.0, 0.26)
	light_tween.tween_property(bulb_on, "scale", bulb_off.scale, 0.34)
	light_tween.tween_property(warm_wash, "color:a", 0.12, 0.36)
	light_tween.tween_property(rope_inner, "default_color", Color(0.96, 0.76, 0.25, 1.0), 0.28)
	light_tween.tween_property(meter_panel, "modulate", Color(1.0, 0.9, 0.58, 1.0), 0.28)
	await light_tween.finished

	var result_tween: Tween = create_tween()
	result_tween.set_trans(Tween.TRANS_CUBIC)
	result_tween.set_ease(Tween.EASE_OUT)
	result_tween.tween_property(completion, "modulate:a", 1.0, 0.28)
	await result_tween.finished
	restart_button.grab_focus()


func _restart_level() -> void:
	get_tree().reload_current_scene()
