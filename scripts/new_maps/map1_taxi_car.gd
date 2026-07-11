extends Node2D

@export var wheel_rotation_speed: float = 12.0
@export var driving_bob_amount: float = 3.5

@onready var body_bob: Node2D = $BodyBob
@onready var body: Sprite2D = $BodyBob/Body
@onready var rear_wheel: Sprite2D = $RearWheel
@onready var front_wheel: Sprite2D = $FrontWheel

var _base_body_position := Vector2.ZERO
var _elapsed_time := 0.0
var _is_driving := false
var _drive_direction := 1.0


func _ready() -> void:
	_base_body_position = body_bob.position


func _process(delta: float) -> void:
	_elapsed_time += delta
	var bob_amount := driving_bob_amount if _is_driving else 0.8
	var bob_speed := 11.0 if _is_driving else 2.0
	body_bob.position.y = _base_body_position.y + sin(_elapsed_time * bob_speed) * bob_amount
	if _is_driving:
		var spin := _drive_direction * wheel_rotation_speed * delta
		rear_wheel.rotation += spin
		front_wheel.rotation += spin


func set_driving(is_driving: bool) -> void:
	_is_driving = is_driving


func set_facing(direction: float) -> void:
	_drive_direction = signf(direction)
	if is_zero_approx(_drive_direction):
		_drive_direction = 1.0
	# TaxiCar body source faces left; flip it when travelling right.
	body.flip_h = _drive_direction > 0.0
