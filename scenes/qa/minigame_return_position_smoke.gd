extends Node

const AREA_ID := "area_03_shops"
const AREA_SCENE: PackedScene = preload(
	"res://scenes/areas/area_03_bakery_flower.tscn"
)

func _ready() -> void:
	GameFlow.clear_minigame_return_state()
	var area: Node = AREA_SCENE.instantiate()
	add_child(area)
	await get_tree().process_frame

	var player: CharacterBody2D = area.get_node("Actors/Player") as CharacterBody2D
	var expected_position := Vector2(2034.0, 620.0)
	player.global_position = expected_position
	player.set("facing", -1.0)
	GameFlow.return_area_id = AREA_ID
	GameFlow.capture_minigame_return_state(player)

	player.global_position = Vector2(120.0, 620.0)
	player.set("facing", 1.0)
	if GameFlow.restore_minigame_return_state("area_04_clinic", player):
		_fail("A different area consumed the return position")
		return
	if not player.global_position.is_equal_approx(Vector2(120.0, 620.0)):
		_fail("A different area changed the player position")
		return

	if not GameFlow.restore_minigame_return_state(AREA_ID, player):
		_fail("The source area did not restore the return position")
		return
	if not player.global_position.is_equal_approx(expected_position):
		_fail("Player returned to %s instead of %s" % [
			player.global_position,
			expected_position
		])
		return
	if not is_equal_approx(float(player.get("facing")), -1.0):
		_fail("Player facing direction was not restored")
		return
	if GameFlow.restore_minigame_return_state(AREA_ID, player):
		_fail("The return position could be consumed more than once")
		return

	print("MINIGAME_RETURN_POSITION_SMOKE_OK position=", player.global_position)
	get_tree().quit()

func _fail(message: String) -> void:
	push_error("MINIGAME_RETURN_POSITION_SMOKE_FAILED: " + message)
	get_tree().quit(1)
