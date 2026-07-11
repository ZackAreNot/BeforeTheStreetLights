extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := TEST_SCENE.instantiate()
	root.add_child(scene)
	await process_frame

	var track := scene.get_node("RoadTrack") as Path2D
	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var platform := scene.get_node("OneWayPlatforms/BrickOneWayPlatform") as Node2D
	var track_target := track.to_local(Vector2(platform.global_position.x, player.global_position.y))
	player.progress = track.curve.get_closest_offset(track_target)
	await process_frame

	assert(bool(platform.call("contains_world_x", player.global_position.x)), "Player is not above the one-way platform range.")
	var platform_offset: float = float(platform.call("surface_y_at_world_x", player.global_position.x)) - player.global_position.y
	assert(platform_offset < 0.0, "One-way platform must be above the road track.")

	player.set("_floor_offset", 0.0)
	player.set("_air_offset", platform_offset + 8.0)
	player.set("_vertical_velocity", -120.0)
	var passed_from_below := bool(player.call("_try_land_on_one_way_platform", platform_offset + 22.0))
	assert(not passed_from_below, "Player should pass through the platform while jumping upward.")

	player.set("_floor_offset", 0.0)
	player.set("_air_offset", platform_offset + 8.0)
	player.set("_vertical_velocity", 120.0)
	var landed_from_above := bool(player.call("_try_land_on_one_way_platform", platform_offset - 22.0))
	assert(landed_from_above, "Player should land on the platform while falling.")
	assert(is_equal_approx(float(player.get("_floor_offset")), platform_offset), "Player landed at the wrong platform height.")
	assert(is_equal_approx(float(platform.call("surface_angle")), 0.0), "Brick platform should keep the player upright.")

	print("MAP1_ONE_WAY_PLATFORM_SMOKE_OK")
	quit()
