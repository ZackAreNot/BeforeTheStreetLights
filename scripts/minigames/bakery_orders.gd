extends Control

const DESIGN_SIZE := Vector2(1920.0, 1080.0)
const TRAY_HOME := Vector2(540.0, 809.0)
const TRAY_HIDDEN := Vector2(540.0, 1125.0)
const CASH_HOME := Vector2(1218.0, 812.0)
const CASH_HIDDEN := Vector2(1218.0, 1110.0)
const OPEN_BAG_HOME := Vector2(422.0, 824.0)
const OPEN_BAG_HIDDEN := Vector2(422.0, 1110.0)
const CLOSED_BAG_HOME := Vector2(718.0, 750.0)
const CLOSED_BAG_HIDDEN := Vector2(718.0, 1095.0)
const DRAWER_HOME := Vector2(1259.0, 809.0)
const DRAWER_HIDDEN := Vector2(1259.0, 1095.0)
const CUSTOMER_BODY_BASE := Vector2(715.0, 537.0)
const CUSTOMER_HEAD_BASE := Vector2(888.0, 196.0)
const CUSTOMER_ENTRANCE_START := Vector2(1280.0, 0.0)
const CUSTOMER_EXIT_END := Vector2(-1500.0, 0.0)
const QUEUE_HOME := Vector2(620.0, 0.0)
const QUEUE_HIDDEN := Vector2(1500.0, 0.0)

const REQUIRED: Dictionary = {
	"donat": 2,
	"onde": 2,
	"sus": 1,
	"lemper": 1,
}

const FOOD_CATALOG: Dictionary = {
	"pastel": {
		"name": "Pastel",
		"price": 7000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/Pastel.png"),
	},
	"onde": {
		"name": "Onde-onde",
		"price": 5000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/OndeOnde.png"),
	},
	"lemper": {
		"name": "Lemper",
		"price": 4000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/Lemper.png"),
	},
	"kue_lapis": {
		"name": "Kue lapis",
		"price": 2000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/KueLapis.png"),
	},
	"dadar_gulung": {
		"name": "Dadar gulung",
		"price": 3000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/DadarGulung.png"),
	},
	"donat": {
		"name": "Donat kentang",
		"price": 5000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/Donut.png"),
	},
	"kue_lupis": {
		"name": "Kue lupis",
		"price": 8000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/KueLupis.png"),
	},
	"muffin": {
		"name": "Muffin stroberi",
		"price": 12000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/Muffin.png"),
	},
	"kue_lumpur": {
		"name": "Kue lumpur",
		"price": 6000,
		"texture": preload("res://assets/minigames/MinigameTokoKue/food/KueLumpur.png"),
	},
}

const CUSTOMERS: Array[Dictionary] = [
	{
		"order": ["pastel", "pastel", "onde"],
		"cash": 20000,
		"arrival": "Sore. Yang ini dibungkus, ya.",
		"ready": "Ini uangnya.",
		"thanks": "Pas. Makasih, ya.",
	},
	{
		"order": ["lemper", "kue_lapis", "dadar_gulung"],
		"cash": 20000,
		"arrival": "Titip bungkus semuanya, ya.",
		"ready": "Aku bayar pakai ini.",
		"thanks": "Makasih. Pas kok.",
	},
	{
		"order": ["donat", "kue_lupis", "muffin", "kue_lumpur"],
		"cash": 50000,
		"arrival": "Yang ini semua buat dibawa pulang.",
		"ready": "Ini, ya.",
		"thanks": "Sip, kembaliannya pas.",
	},
]

const DENOMINATIONS: Array[int] = [10000, 5000, 2000, 1000]

enum Phase {
	CUSTOMER_ENTERING,
	PACKING,
	SEALING_BAG,
	TAKING_CASH,
	MAKING_CHANGE,
	CUSTOMER_LEAVING,
	CLEARING_TRAY,
	SHIFT_COMPLETE,
}

@export_range(0.25, 4.0, 0.05) var animation_speed: float = 1.0
@export_range(200.0, 700.0, 10.0) var customer_walk_speed: float = 400.0
@export_range(0.5, 2.0, 0.05) var customer_walk_motion_strength: float = 1.0

@onready var design_canvas: Control = $DesignCanvas
@onready var customer_root: Control = $DesignCanvas/CustomerRoot
@onready var customer_visual: Control = $DesignCanvas/CustomerRoot/CustomerVisual
@onready var customer_body: TextureRect = $DesignCanvas/CustomerRoot/CustomerVisual/Body
@onready var customer_head: TextureRect = $DesignCanvas/CustomerRoot/CustomerVisual/Head
@onready var queue_customer_root: Control = $DesignCanvas/QueueCustomerRoot
@onready var queue_customer_visual: Control = $DesignCanvas/QueueCustomerRoot/QueueCustomerVisual
@onready var queue_customer_body: TextureRect = $DesignCanvas/QueueCustomerRoot/QueueCustomerVisual/Body
@onready var queue_customer_head: TextureRect = $DesignCanvas/QueueCustomerRoot/QueueCustomerVisual/Head
@onready var comment_bubble: Control = $DesignCanvas/CommentBubble
@onready var comment_label: Label = $DesignCanvas/CommentBubble/CommentLabel
@onready var order_tray: TextureButton = $DesignCanvas/OrderTray
@onready var food_items: Control = $DesignCanvas/OrderTray/FoodItems
@onready var open_bag: TextureButton = $DesignCanvas/OpenBag
@onready var closed_bag: TextureRect = $DesignCanvas/ClosedBag
@onready var customer_cash: TextureButton = $DesignCanvas/CustomerCash
@onready var cash_drawer: Control = $DesignCanvas/CashDrawer
@onready var undo_button: TextureButton = $DesignCanvas/CashDrawer/UndoButton
@onready var monitor_customer_label: Label = $DesignCanvas/MonitorUI/CustomerLabel
@onready var monitor_total_label: Label = $DesignCanvas/MonitorUI/TotalValue
@onready var monitor_cash_label: Label = $DesignCanvas/MonitorUI/CashValue
@onready var monitor_change_label: Label = $DesignCanvas/MonitorUI/ChangeValue
@onready var monitor_items_label: Label = $DesignCanvas/MonitorUI/ItemsLabel
@onready var monitor_status: ColorRect = $DesignCanvas/MonitorUI/StatusLight
@onready var completion_layer: Control = $DesignCanvas/CompletionLayer
@onready var completion_title: Label = $DesignCanvas/CompletionLayer/Panel/Title
@onready var completion_detail: Label = $DesignCanvas/CompletionLayer/Panel/Detail
@onready var finish_button: Button = $DesignCanvas/CompletionLayer/Panel/FinishButton

@onready var denomination_buttons: Dictionary = {
	10000: $DesignCanvas/CashDrawer/Money10K,
	5000: $DesignCanvas/CashDrawer/Money5K,
	2000: $DesignCanvas/CashDrawer/Money2K,
	1000: $DesignCanvas/CashDrawer/Money1K,
}

@onready var denomination_count_labels: Dictionary = {
	10000: $DesignCanvas/CashDrawer/Count10K,
	5000: $DesignCanvas/CashDrawer/Count5K,
	2000: $DesignCanvas/CashDrawer/Count2K,
	1000: $DesignCanvas/CashDrawer/Count1K,
}

var phase: int = Phase.CUSTOMER_ENTERING
var customer_index: int = 0
var current_order: PackedStringArray = PackedStringArray()
var current_cash: int = 0
var current_total: int = 0
var selected_change: int = 0
var packed_count: int = 0
var items_in_motion: int = 0
var finished: bool = false

var counts: Dictionary = {
	"donat": 0,
	"onde": 0,
	"sus": 0,
	"lemper": 0,
}

var _packed_food_ids: PackedStringArray = PackedStringArray()
var _change_history: Array[int] = []
var _denomination_counts: Dictionary = {}
var _food_buttons: Array[TextureButton] = []
var _hover_tweens: Dictionary = {}
var _comment_serial: int = 0
var _customer_bob_time: float = 0.0
var _queue_bob_time: float = 1.7
var _customer_is_walking: bool = false
var _queue_customer_is_walking: bool = false
var _customer_walk_blend: float = 0.0
var _queue_walk_blend: float = 0.0
var _open_bag_shown: bool = false
var _tray_attention_tween: Tween


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("151713"))
	resized.connect(_layout_design_canvas)
	_connect_interactions()
	_register_static_hover_targets()
	_layout_design_canvas()
	_reset_scene_visuals()
	call_deferred("_begin_shift")


func _process(delta: float) -> void:
	_customer_bob_time += delta
	_queue_bob_time += delta
	_customer_walk_blend = move_toward(
		_customer_walk_blend,
		1.0 if _customer_is_walking else 0.0,
		delta * 4.5
	)
	_queue_walk_blend = move_toward(
		_queue_walk_blend,
		1.0 if _queue_customer_is_walking else 0.0,
		delta * 4.5
	)
	if customer_root.visible:
		_animate_customer_parts(
			customer_body,
			customer_head,
			_customer_bob_time,
			1.0,
			_customer_walk_blend
		)
	if queue_customer_root.visible:
		_animate_customer_parts(
			queue_customer_body,
			queue_customer_head,
			_queue_bob_time,
			0.72,
			_queue_walk_blend
		)


func _animate_customer_parts(
	body: TextureRect,
	head: TextureRect,
	time: float,
	intensity: float,
	walk_blend: float
) -> void:
	var idle_body_position := CUSTOMER_BODY_BASE + Vector2(
		0.0,
		sin(time * 1.85) * 4.5 * intensity
	)
	var idle_body_rotation: float = sin(time * 0.92) * 0.004 * intensity
	var idle_head_position := CUSTOMER_HEAD_BASE + Vector2(
		sin(time * 0.73 + 0.4) * 3.5 * intensity,
		sin(time * 1.85 + 0.62) * 8.0 * intensity
	)
	var idle_head_rotation: float = sin(time * 1.18 + 0.3) * 0.018 * intensity

	var stride: float = time * 5.4
	var body_sway: float = sin(stride * 0.5)
	var step_lift: float = absf(sin(stride))
	var walk_strength: float = intensity * customer_walk_motion_strength
	var walk_body_position := CUSTOMER_BODY_BASE + Vector2(
		body_sway * 6.0,
		-step_lift * 11.0
	) * walk_strength
	var walk_body_rotation: float = body_sway * 0.018 * walk_strength
	var walk_head_position := CUSTOMER_HEAD_BASE + Vector2(
		body_sway * 8.0 + sin(stride + 0.35) * 3.0,
		-step_lift * 11.0 + sin(stride + 0.55) * 5.0
	) * walk_strength
	var walk_head_rotation: float = (
		body_sway * 0.03 + sin(stride + 0.45) * 0.012
	) * walk_strength
	var landing: float = pow(1.0 - step_lift, 3.0)
	var walk_body_scale := Vector2(
		1.0 + landing * 0.012 * walk_strength,
		1.0 - landing * 0.012 * walk_strength
	)

	body.position = idle_body_position.lerp(walk_body_position, walk_blend)
	body.rotation = lerpf(idle_body_rotation, walk_body_rotation, walk_blend)
	body.scale = Vector2.ONE.lerp(walk_body_scale, walk_blend)
	head.position = idle_head_position.lerp(walk_head_position, walk_blend)
	head.rotation = lerpf(idle_head_rotation, walk_head_rotation, walk_blend)


func _layout_design_canvas() -> void:
	var available_size: Vector2 = size
	if available_size.x <= 1.0 or available_size.y <= 1.0:
		available_size = get_viewport_rect().size
	var canvas_scale: float = minf(
		available_size.x / DESIGN_SIZE.x,
		available_size.y / DESIGN_SIZE.y
	)
	design_canvas.scale = Vector2.ONE * canvas_scale
	design_canvas.position = (available_size - DESIGN_SIZE * canvas_scale) * 0.5


func _connect_interactions() -> void:
	order_tray.pressed.connect(_on_order_tray_pressed)
	open_bag.pressed.connect(_on_open_bag_pressed)
	customer_cash.pressed.connect(_on_customer_cash_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	for value: int in DENOMINATIONS:
		var button: TextureButton = denomination_buttons[value] as TextureButton
		button.pressed.connect(_on_denomination_pressed.bind(value, button))


func _register_static_hover_targets() -> void:
	_register_hover(order_tray, 1.015)
	_register_hover(open_bag, 1.045)
	_register_hover(customer_cash, 1.06)
	_register_hover(undo_button, 1.08)
	for value: int in DENOMINATIONS:
		_register_hover(denomination_buttons[value] as TextureButton, 1.045)


func _reset_scene_visuals() -> void:
	comment_bubble.visible = false
	completion_layer.visible = false
	customer_root.visible = false
	queue_customer_root.visible = false
	_customer_is_walking = false
	_queue_customer_is_walking = false
	_customer_walk_blend = 0.0
	_queue_walk_blend = 0.0
	order_tray.position = TRAY_HIDDEN
	open_bag.position = OPEN_BAG_HIDDEN
	open_bag.visible = false
	closed_bag.position = CLOSED_BAG_HIDDEN
	closed_bag.visible = false
	customer_cash.position = CASH_HIDDEN
	customer_cash.visible = false
	cash_drawer.position = DRAWER_HIDDEN
	_set_button_enabled(order_tray, false)
	_set_button_enabled(open_bag, false)
	_set_button_enabled(customer_cash, false)
	_set_change_controls_enabled(false)
	_reset_monitor()


func _begin_shift() -> void:
	await get_tree().create_timer(_duration(0.35)).timeout
	_start_customer(0)


func _start_customer(next_index: int) -> void:
	customer_index = next_index
	phase = Phase.CUSTOMER_ENTERING
	finished = false
	var customer: Dictionary = CUSTOMERS[customer_index]
	current_order = PackedStringArray(customer["order"] as Array)
	current_cash = int(customer["cash"])
	current_total = _calculate_order_total(current_order)
	selected_change = 0
	packed_count = 0
	items_in_motion = 0
	_packed_food_ids.clear()
	_change_history.clear()
	_open_bag_shown = false
	for value: int in DENOMINATIONS:
		_denomination_counts[value] = 0
	_clear_food_buttons()
	_reset_monitor()
	_update_denomination_counts()

	var current_start: Vector2 = CUSTOMER_ENTRANCE_START if customer_index == 0 else QUEUE_HOME
	customer_root.visible = true
	customer_root.position = current_start
	customer_root.modulate = Color.WHITE
	customer_visual.scale = Vector2.ONE if customer_index == 0 else Vector2(0.82, 0.82)
	customer_visual.modulate = Color.WHITE if customer_index == 0 else Color(0.78, 0.78, 0.72, 0.72)
	customer_body.position = CUSTOMER_BODY_BASE
	customer_head.position = CUSTOMER_HEAD_BASE
	customer_body.rotation = 0.0
	customer_head.rotation = 0.0
	_customer_bob_time = float(customer_index) * 0.7

	queue_customer_root.visible = true
	queue_customer_root.position = QUEUE_HIDDEN
	queue_customer_root.modulate = Color.WHITE
	queue_customer_visual.scale = Vector2(0.82, 0.82)
	queue_customer_visual.modulate = Color(0.7, 0.7, 0.66, 0.64)
	queue_customer_body.position = CUSTOMER_BODY_BASE
	queue_customer_head.position = CUSTOMER_HEAD_BASE
	queue_customer_body.rotation = 0.0
	queue_customer_head.rotation = 0.0

	order_tray.position = TRAY_HIDDEN
	order_tray.visible = true
	customer_cash.position = CASH_HIDDEN
	customer_cash.visible = true
	customer_cash.modulate = Color.WHITE
	customer_cash.scale = Vector2.ONE
	open_bag.visible = false
	closed_bag.visible = false
	cash_drawer.position = DRAWER_HIDDEN
	_set_button_enabled(order_tray, false)
	_set_button_enabled(open_bag, false)
	_set_button_enabled(customer_cash, false)
	_set_change_controls_enabled(false)

	_customer_is_walking = true
	_queue_customer_is_walking = true
	var active_walk_duration: float = _walk_duration(current_start, Vector2.ZERO)
	var queue_walk_delay: float = _duration(0.35)
	var queue_walk_duration: float = _walk_duration(QUEUE_HIDDEN, QUEUE_HOME)
	var entrance: Tween = create_tween().set_parallel(true)
	entrance.tween_property(
		customer_root,
		"position",
		Vector2.ZERO,
		active_walk_duration
	).set_trans(Tween.TRANS_LINEAR)
	entrance.tween_property(customer_visual, "scale", Vector2.ONE, _duration(1.35)).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN_OUT)
	entrance.tween_property(customer_visual, "modulate", Color.WHITE, _duration(1.1))
	entrance.tween_property(
		queue_customer_root,
		"position",
		QUEUE_HOME,
		queue_walk_duration
	).set_delay(queue_walk_delay).set_trans(Tween.TRANS_LINEAR)
	entrance.tween_callback(_stop_customer_walk).set_delay(active_walk_duration)
	entrance.tween_callback(_stop_queue_customer_walk).set_delay(
		queue_walk_delay + queue_walk_duration
	)
	await entrance.finished
	_show_comment(str(customer["arrival"]), 2.4)
	await get_tree().create_timer(_duration(0.42)).timeout

	_spawn_food_buttons()
	var counter_arrival: Tween = create_tween().set_parallel(true)
	counter_arrival.tween_property(order_tray, "position", TRAY_HOME, _duration(0.76)).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	counter_arrival.tween_property(customer_cash, "position", CASH_HOME, _duration(0.72)).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT)
	await counter_arrival.finished
	phase = Phase.PACKING
	_set_food_buttons_enabled(true)


func _spawn_food_buttons() -> void:
	_clear_food_buttons()
	var centers: Array[Vector2] = _food_centers_for_count(current_order.size())
	for index: int in range(current_order.size()):
		var food_id: String = current_order[index]
		var data: Dictionary = FOOD_CATALOG[food_id]
		var texture: Texture2D = data["texture"] as Texture2D
		var button := TextureButton.new()
		button.name = "Food_%02d_%s" % [index, food_id]
		button.texture_normal = texture
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		button.size = _food_button_size(texture)
		button.position = centers[index] - button.size * 0.5
		button.pivot_offset = button.size * 0.5
		button.tooltip_text = str(data["name"])
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.set_meta("food_id", food_id)
		button.pressed.connect(_on_food_pressed.bind(button))
		food_items.add_child(button)
		_food_buttons.append(button)
		_register_hover(button, 1.1)


func _food_centers_for_count(item_count: int) -> Array[Vector2]:
	if item_count <= 3:
		return [Vector2(195.0, 88.0), Vector2(455.0, 92.0), Vector2(326.0, 191.0)]
	return [
		Vector2(125.0, 86.0),
		Vector2(265.0, 92.0),
		Vector2(420.0, 88.0),
		Vector2(325.0, 192.0),
	]


func _food_button_size(texture: Texture2D) -> Vector2:
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	var visual_scale: float = minf(1.28, 170.0 / maxf(texture_size.x, 1.0))
	visual_scale = minf(visual_scale, 130.0 / maxf(texture_size.y, 1.0))
	return Vector2(
		maxf(texture_size.x * visual_scale, 112.0),
		maxf(texture_size.y * visual_scale, 96.0)
	)


func _on_food_pressed(button: TextureButton) -> void:
	if phase != Phase.PACKING or button.disabled:
		return
	_set_button_enabled(button, false)
	var food_id: String = str(button.get_meta("food_id", ""))
	if food_id.is_empty() or not FOOD_CATALOG.has(food_id):
		return
	if not _open_bag_shown:
		_open_bag_shown = true
		_show_open_bag()

	packed_count += 1
	items_in_motion += 1
	_packed_food_ids.append(food_id)
	_update_monitor()

	var vanish: Tween = create_tween().set_parallel(true)
	vanish.tween_property(button, "modulate:a", 0.0, _duration(0.16))
	vanish.tween_property(button, "scale", Vector2.ONE * 0.82, _duration(0.16)).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	await vanish.finished
	if packed_count == 1:
		await get_tree().create_timer(_duration(0.24)).timeout

	var above_bag := Vector2(30.0 - button.size.x * 0.5, -44.0 - button.size.y * 0.5)
	var inside_bag := Vector2(30.0 - button.size.x * 0.5, 142.0 - button.size.y * 0.5)
	button.position = above_bag
	button.scale = Vector2.ONE * 0.74
	button.rotation = 0.08
	button.modulate.a = 0.0
	var reappear: Tween = create_tween().set_parallel(true)
	reappear.tween_property(button, "modulate:a", 1.0, _duration(0.14))
	reappear.tween_property(button, "scale", Vector2.ONE * 0.82, _duration(0.14))
	await reappear.finished

	var drop: Tween = create_tween().set_parallel(true)
	drop.tween_property(button, "position", inside_bag, _duration(0.42)).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	drop.tween_property(button, "rotation", -0.12, _duration(0.42))
	drop.tween_property(button, "scale", Vector2.ONE * 0.42, _duration(0.42))
	drop.tween_property(button, "modulate:a", 0.0, _duration(0.18)).set_delay(
		_duration(0.24)
	)
	await drop.finished
	items_in_motion -= 1
	button.visible = false
	if packed_count >= current_order.size() and items_in_motion == 0:
		phase = Phase.SEALING_BAG
		_set_button_enabled(open_bag, true)
		_pulse_control(open_bag, 1.055)


func _show_open_bag() -> void:
	open_bag.visible = true
	open_bag.position = OPEN_BAG_HIDDEN
	open_bag.modulate.a = 0.0
	open_bag.scale = Vector2(0.94, 0.94)
	var bag_tween: Tween = create_tween().set_parallel(true)
	bag_tween.tween_property(open_bag, "position", OPEN_BAG_HOME, _duration(0.62)).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	bag_tween.tween_property(open_bag, "modulate:a", 1.0, _duration(0.32))
	bag_tween.tween_property(open_bag, "scale", Vector2.ONE, _duration(0.5))


func _on_open_bag_pressed() -> void:
	if phase != Phase.SEALING_BAG:
		return
	phase = Phase.TAKING_CASH
	_set_button_enabled(open_bag, false)
	var close_tween: Tween = create_tween().set_parallel(true)
	close_tween.tween_property(open_bag, "scale", Vector2(0.72, 0.58), _duration(0.32)).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_IN)
	close_tween.tween_property(open_bag, "modulate:a", 0.0, _duration(0.28))
	await close_tween.finished
	open_bag.visible = false

	closed_bag.visible = true
	closed_bag.position = CLOSED_BAG_HIDDEN
	closed_bag.modulate.a = 0.0
	closed_bag.scale = Vector2(0.94, 0.94)
	var sealed_arrival: Tween = create_tween().set_parallel(true)
	sealed_arrival.tween_property(closed_bag, "position", CLOSED_BAG_HOME, _duration(0.65)).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	sealed_arrival.tween_property(closed_bag, "modulate:a", 1.0, _duration(0.34))
	sealed_arrival.tween_property(closed_bag, "scale", Vector2.ONE, _duration(0.52))
	await sealed_arrival.finished
	_set_button_enabled(customer_cash, true)
	_pulse_control(customer_cash, 1.075)
	_show_comment(str(CUSTOMERS[customer_index]["ready"]), 2.3)


func _on_customer_cash_pressed() -> void:
	if phase != Phase.TAKING_CASH:
		return
	phase = Phase.MAKING_CHANGE
	_set_button_enabled(customer_cash, false)
	monitor_cash_label.text = _format_rupiah(current_cash)
	var cash_tween: Tween = create_tween().set_parallel(true)
	cash_tween.tween_property(customer_cash, "position", CASH_HOME + Vector2(0.0, 270.0), _duration(0.52)).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_IN)
	cash_tween.tween_property(customer_cash, "scale", Vector2.ONE * 0.9, _duration(0.52))
	cash_tween.tween_property(customer_cash, "modulate:a", 0.0, _duration(0.28)).set_delay(
		_duration(0.24)
	)

	cash_drawer.position = DRAWER_HIDDEN
	var drawer_tween: Tween = create_tween()
	drawer_tween.tween_interval(_duration(0.12))
	drawer_tween.tween_property(cash_drawer, "position", DRAWER_HOME, _duration(0.66)).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	await drawer_tween.finished
	customer_cash.visible = false
	_set_change_controls_enabled(true)
	_update_monitor()


func _on_denomination_pressed(value: int, button: TextureButton) -> void:
	if phase != Phase.MAKING_CHANGE:
		return
	_change_history.append(value)
	selected_change += value
	_denomination_counts[value] = int(_denomination_counts.get(value, 0)) + 1
	_set_button_enabled(undo_button, true)
	_update_denomination_counts()
	_update_monitor()
	_bounce_money_button(button)

	var required_change: int = current_cash - current_total
	if selected_change > required_change:
		monitor_status.color = Color("cf5c63")
		_show_comment("Eh, kayaknya kembaliannya kebanyakan.", 1.9)
	elif selected_change == required_change:
		phase = Phase.CUSTOMER_LEAVING
		monitor_status.color = Color("82b879")
		_set_change_controls_enabled(false)
		_show_comment(str(CUSTOMERS[customer_index]["thanks"]), 2.0)
		await get_tree().create_timer(_duration(0.72)).timeout
		_finish_current_customer()
	else:
		monitor_status.color = Color("d6b766")


func _on_undo_pressed() -> void:
	if phase != Phase.MAKING_CHANGE:
		return
	if _change_history.is_empty():
		_pulse_control(undo_button, 1.06)
		return
	var removed_value: int = _change_history.pop_back()
	selected_change -= removed_value
	_denomination_counts[removed_value] = maxi(
		int(_denomination_counts.get(removed_value, 0)) - 1,
		0
	)
	_update_denomination_counts()
	_update_monitor()
	monitor_status.color = Color("d6b766")
	_set_button_enabled(undo_button, not _change_history.is_empty())
	_pulse_control(undo_button, 1.1)


func _finish_current_customer() -> void:
	_set_change_controls_enabled(false)
	var take_bag: Tween = create_tween().set_parallel(true)
	take_bag.tween_property(closed_bag, "position", Vector2(925.0, 650.0), _duration(0.62)).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_IN_OUT)
	take_bag.tween_property(closed_bag, "scale", Vector2.ONE * 0.68, _duration(0.62))
	take_bag.tween_property(closed_bag, "modulate:a", 0.0, _duration(0.3)).set_delay(
		_duration(0.32)
	)
	var close_drawer: Tween = create_tween()
	close_drawer.tween_property(cash_drawer, "position", DRAWER_HIDDEN, _duration(0.66)).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_IN)
	await take_bag.finished
	closed_bag.visible = false
	await get_tree().create_timer(_duration(0.2)).timeout
	_hide_comment()

	_customer_is_walking = true
	var exit_tween: Tween = create_tween()
	exit_tween.tween_property(
		customer_root,
		"position",
		CUSTOMER_EXIT_END,
		_walk_duration(customer_root.position, CUSTOMER_EXIT_END)
	).set_trans(Tween.TRANS_LINEAR)
	await exit_tween.finished
	_customer_is_walking = false
	customer_root.visible = false
	phase = Phase.CLEARING_TRAY
	_set_button_enabled(order_tray, true)
	_start_tray_attention()


func _on_order_tray_pressed() -> void:
	if phase != Phase.CLEARING_TRAY:
		return
	phase = Phase.CUSTOMER_ENTERING
	_set_button_enabled(order_tray, false)
	if _tray_attention_tween != null and _tray_attention_tween.is_valid():
		_tray_attention_tween.kill()
	order_tray.scale = Vector2.ONE
	var clear_tween: Tween = create_tween()
	clear_tween.tween_property(order_tray, "position", TRAY_HIDDEN, _duration(0.62)).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_IN)
	await clear_tween.finished
	if customer_index + 1 < CUSTOMERS.size():
		await get_tree().create_timer(_duration(0.38)).timeout
		_start_customer(customer_index + 1)
	else:
		_show_shift_complete()


func _show_shift_complete() -> void:
	phase = Phase.SHIFT_COMPLETE
	finished = true
	completion_layer.visible = true
	completion_layer.modulate.a = 0.0
	var panel: Panel = completion_layer.get_node("Panel") as Panel
	panel.scale = Vector2(0.84, 0.84)
	completion_title.text = "SHIFT SELESAI"
	completion_detail.text = "%d pelanggan terlayani\nSemua hitungan kembali tepat." % CUSTOMERS.size()
	var game_flow: Node = get_node_or_null("/root/GameFlow")
	var has_return_area: bool = (
		game_flow != null and not str(game_flow.get("return_area_id")).is_empty()
	)
	finish_button.text = "KEMBALI" if has_return_area else "ULANGI"
	var finish_tween: Tween = create_tween().set_parallel(true)
	finish_tween.tween_property(completion_layer, "modulate:a", 1.0, _duration(0.24))
	finish_tween.tween_property(panel, "scale", Vector2.ONE, _duration(0.36)).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _on_finish_button_pressed() -> void:
	if not finished:
		return
	finish_button.disabled = true
	var game_flow: Node = get_node_or_null("/root/GameFlow")
	if game_flow != null and not str(game_flow.get("return_area_id")).is_empty():
		game_flow.call("complete_minigame", "bakery")
		return
	_restart_shift()


func _restart_shift() -> void:
	completion_layer.visible = false
	finish_button.disabled = false
	finished = false
	customer_index = 0
	for food_id: String in counts:
		counts[food_id] = 0
	_start_customer(0)


func _calculate_order_total(order: PackedStringArray) -> int:
	var total: int = 0
	for food_id: String in order:
		total += int((FOOD_CATALOG[food_id] as Dictionary)["price"])
	return total


func _update_monitor() -> void:
	monitor_customer_label.text = "%d / %d" % [customer_index + 1, CUSTOMERS.size()]
	var running_total: int = 0
	var item_counts: Dictionary = {}
	var item_order: PackedStringArray = PackedStringArray()
	for food_id: String in _packed_food_ids:
		if not item_counts.has(food_id):
			item_counts[food_id] = 0
			item_order.append(food_id)
		item_counts[food_id] = int(item_counts[food_id]) + 1
		running_total += int((FOOD_CATALOG[food_id] as Dictionary)["price"])
	monitor_total_label.text = _format_rupiah(running_total)
	monitor_change_label.text = _format_rupiah(selected_change)

	var lines := PackedStringArray()
	for food_id: String in item_order:
		var data: Dictionary = FOOD_CATALOG[food_id]
		lines.append("%dx %s" % [int(item_counts[food_id]), str(data["name"])])
	monitor_items_label.text = "\n".join(lines)
	if selected_change <= 0:
		monitor_status.color = Color("798279")


func _reset_monitor() -> void:
	monitor_customer_label.text = "%d / %d" % [customer_index + 1, CUSTOMERS.size()]
	monitor_total_label.text = _format_rupiah(0)
	monitor_cash_label.text = "-"
	monitor_change_label.text = _format_rupiah(0)
	monitor_items_label.text = ""
	monitor_status.color = Color("798279")


func _update_denomination_counts() -> void:
	for value: int in DENOMINATIONS:
		var label: Label = denomination_count_labels[value] as Label
		var count: int = int(_denomination_counts.get(value, 0))
		label.text = "x%d" % count if count > 0 else ""


func _set_food_buttons_enabled(enabled: bool) -> void:
	for button: TextureButton in _food_buttons:
		if is_instance_valid(button) and button.visible:
			_set_button_enabled(button, enabled)


func _set_change_controls_enabled(enabled: bool) -> void:
	for value: int in DENOMINATIONS:
		_set_button_enabled(denomination_buttons[value] as TextureButton, enabled)
	_set_button_enabled(undo_button, enabled and not _change_history.is_empty())


func _set_button_enabled(button: BaseButton, enabled: bool) -> void:
	button.disabled = not enabled
	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	)


func _register_hover(control: Control, hover_multiplier: float) -> void:
	control.pivot_offset = control.size * 0.5
	control.set_meta("hover_multiplier", hover_multiplier)
	control.mouse_entered.connect(_on_hover_entered.bind(control))
	control.mouse_exited.connect(_on_hover_exited.bind(control))


func _on_hover_entered(control: Control) -> void:
	if control is BaseButton and (control as BaseButton).disabled:
		return
	var multiplier: float = float(control.get_meta("hover_multiplier", 1.04))
	_tween_hover_scale(control, Vector2.ONE * multiplier)


func _on_hover_exited(control: Control) -> void:
	_tween_hover_scale(control, Vector2.ONE)


func _tween_hover_scale(control: Control, target_scale: Vector2) -> void:
	var instance_id: int = control.get_instance_id()
	var previous: Tween = _hover_tweens.get(instance_id) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	var hover_tween: Tween = create_tween()
	_hover_tweens[instance_id] = hover_tween
	hover_tween.tween_property(control, "scale", target_scale, _duration(0.13)).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)


func _pulse_control(control: Control, multiplier: float) -> void:
	control.scale = Vector2.ONE
	var pulse: Tween = create_tween()
	pulse.tween_property(control, "scale", Vector2.ONE * multiplier, _duration(0.16)).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	pulse.tween_property(control, "scale", Vector2.ONE, _duration(0.2)).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _bounce_money_button(button: TextureButton) -> void:
	var resting_position: Vector2 = button.position
	var bounce: Tween = create_tween()
	bounce.tween_property(button, "position:y", resting_position.y - 14.0, _duration(0.09)).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	bounce.tween_property(button, "position:y", resting_position.y, _duration(0.12)).set_trans(
		Tween.TRANS_BOUNCE
	).set_ease(Tween.EASE_OUT)


func _start_tray_attention() -> void:
	if _tray_attention_tween != null and _tray_attention_tween.is_valid():
		_tray_attention_tween.kill()
	order_tray.scale = Vector2.ONE
	_tray_attention_tween = create_tween().set_loops()
	_tray_attention_tween.tween_property(order_tray, "scale", Vector2(1.012, 1.012), _duration(0.55)).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	_tray_attention_tween.tween_property(order_tray, "scale", Vector2.ONE, _duration(0.55)).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)


func _show_comment(message: String, duration: float = 2.0) -> void:
	_comment_serial += 1
	var serial: int = _comment_serial
	comment_label.text = message
	comment_bubble.visible = true
	comment_bubble.modulate.a = 0.0
	comment_bubble.scale = Vector2(0.88, 0.88)
	var appear: Tween = create_tween().set_parallel(true)
	appear.tween_property(comment_bubble, "modulate:a", 1.0, _duration(0.14))
	appear.tween_property(comment_bubble, "scale", Vector2.ONE, _duration(0.22)).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(_duration(duration)).timeout
	if serial == _comment_serial:
		_hide_comment()


func _hide_comment() -> void:
	_comment_serial += 1
	if not comment_bubble.visible:
		return
	var hide_tween: Tween = create_tween().set_parallel(true)
	hide_tween.tween_property(comment_bubble, "modulate:a", 0.0, _duration(0.14))
	hide_tween.tween_property(comment_bubble, "scale", Vector2(0.94, 0.94), _duration(0.14))
	await hide_tween.finished
	comment_bubble.visible = false


func _clear_food_buttons() -> void:
	for button: TextureButton in _food_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_food_buttons.clear()


func _format_rupiah(value: int) -> String:
	var digits: String = str(maxi(value, 0))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return "Rp " + digits + grouped


func _duration(seconds: float) -> float:
	return seconds / maxf(animation_speed, 0.01)


func _walk_duration(from_position: Vector2, to_position: Vector2) -> float:
	var distance: float = absf(to_position.x - from_position.x)
	return _duration(distance / maxf(customer_walk_speed, 1.0))


func _stop_customer_walk() -> void:
	_customer_is_walking = false


func _stop_queue_customer_walk() -> void:
	_queue_customer_is_walking = false


# Compatibility with the original bakery smoke test while the new cashier flow
# is exercised through its own state-based checks.
func _on_food_dropped(food_id: String) -> void:
	if not REQUIRED.has(food_id):
		return
	counts[food_id] = mini(int(counts[food_id]) + 1, int(REQUIRED[food_id]))


func _is_complete() -> bool:
	if finished:
		return true
	for food_id: String in REQUIRED:
		if int(counts[food_id]) < int(REQUIRED[food_id]):
			return false
	return true
