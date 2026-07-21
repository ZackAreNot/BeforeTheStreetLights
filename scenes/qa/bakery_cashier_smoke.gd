extends SceneTree

const BAKERY_SCENE := preload("res://scenes/minigames/bakery_orders.tscn")

const PHASE_PACKING := 1
const PHASE_SEALING_BAG := 2
const PHASE_MAKING_CHANGE := 4
const PHASE_CLEARING_TRAY := 6
const PHASE_SHIFT_COMPLETE := 7


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := BAKERY_SCENE.instantiate() as Control
	game.set("animation_speed", 4.0)
	root.add_child(game)

	for customer_index: int in range(3):
		if not await _wait_for_phase(game, PHASE_PACKING):
			_fail("Customer %d never reached packing." % (customer_index + 1))
			return
		if int(game.get("customer_index")) != customer_index:
			_fail("Unexpected customer index during packing.")
			return

		var food_buttons: Array = (game.get("_food_buttons") as Array).duplicate()
		for button_variant: Variant in food_buttons:
			game.call("_on_food_pressed", button_variant as TextureButton)
		if not await _wait_for_phase(game, PHASE_SEALING_BAG):
			_fail("Customer %d food packing did not finish." % (customer_index + 1))
			return
		if int(game.get("packed_count")) != food_buttons.size():
			_fail("Packed food count is incorrect.")
			return

		game.call("_on_open_bag_pressed")
		var cash_button := game.get_node("DesignCanvas/CustomerCash") as TextureButton
		if not await _wait_for_button_enabled(cash_button):
			_fail("Cash never became interactive.")
			return
		game.call("_on_customer_cash_pressed")

		var ten_button := game.get_node("DesignCanvas/CashDrawer/Money10K") as TextureButton
		if not await _wait_for_button_enabled(ten_button):
			_fail("Cash drawer never opened.")
			return
		if int(game.get("phase")) != PHASE_MAKING_CHANGE:
			_fail("Cash drawer opened outside the change phase.")
			return

		if customer_index == 0:
			game.call("_on_denomination_pressed", 10000, ten_button)
			if int(game.get("selected_change")) != 10000:
				_fail("Overpayment selection was not recorded.")
				return
			game.call("_on_undo_pressed")
			if int(game.get("selected_change")) != 0:
				_fail("Undo did not remove the last denomination.")
				return

		var change_sequences: Array[Array] = [
			[1000],
			[10000, 1000],
			[10000, 5000, 2000, 2000],
		]
		for value_variant: Variant in change_sequences[customer_index]:
			var value: int = int(value_variant)
			var button: TextureButton = _button_for_value(game, value)
			game.call("_on_denomination_pressed", value, button)

		if not await _wait_for_phase(game, PHASE_CLEARING_TRAY, 4.0):
			_fail("Customer %d did not leave after exact change." % (customer_index + 1))
			return
		game.call("_on_order_tray_pressed")

	if not await _wait_for_phase(game, PHASE_SHIFT_COMPLETE):
		_fail("Shift did not finish after the third tray was cleared.")
		return
	if not bool(game.get("finished")):
		_fail("Finished flag was not set.")
		return

	print("BAKERY_CASHIER_SMOKE_OK customers=3 undo=ok exact_change=ok")
	quit(0)


func _button_for_value(game: Control, value: int) -> TextureButton:
	var node_name: String = {
		10000: "Money10K",
		5000: "Money5K",
		2000: "Money2K",
		1000: "Money1K",
	}[value]
	return game.get_node("DesignCanvas/CashDrawer/" + node_name) as TextureButton


func _wait_for_phase(game: Control, expected_phase: int, timeout: float = 3.0) -> bool:
	var elapsed: float = 0.0
	while elapsed < timeout:
		if int(game.get("phase")) == expected_phase:
			return true
		await process_frame
		elapsed += 1.0 / 60.0
	return false


func _wait_for_button_enabled(button: BaseButton, timeout: float = 2.0) -> bool:
	var elapsed: float = 0.0
	while elapsed < timeout:
		if not button.disabled:
			return true
		await process_frame
		elapsed += 1.0 / 60.0
	return false


func _fail(message: String) -> void:
	push_error("BAKERY_CASHIER_SMOKE_FAILED: " + message)
	quit(1)
