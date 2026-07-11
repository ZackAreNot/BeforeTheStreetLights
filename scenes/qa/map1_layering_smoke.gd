extends SceneTree

const TEST_SCENE := preload("res://scenes/new_maps/map1/map1_layering_test.tscn")


func _init() -> void:
	var scene := TEST_SCENE.instantiate()
	root.add_child(scene)

	var track := scene.get_node("RoadTrack") as Path2D
	var taxi_track := scene.get_node("TaxiRoadTrack") as Path2D
	var player := scene.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var foreground := scene.get_node("Layer2Foreground") as Node2D
	var power_pole_layer := scene.get_node("Layer2Foreground/PowerPoleLayer") as Sprite2D
	var color_grade := scene.get_node("CozyPostProcess/ColorGrade") as ColorRect
	var camera := player.get_node("Camera2D") as Camera2D
	var bimo := scene.get_node("BimoDummy") as Node2D

	assert(track.curve.point_count == 16, "Map 1 road should expose enough editable contour points.")
	assert(taxi_track != track, "Taxi must use a dedicated road track.")
	assert(taxi_track.curve != track.curve, "Taxi track must be editable independently from the pedestrian track.")
	assert(taxi_track.position.y > track.position.y, "Taxi track must sit inside the lower grey road lane.")
	assert(track.curve.get_baked_length() > 5000.0, "Map 1 road curve is unexpectedly short.")
	assert(track.get_script().resource_path.ends_with("editable_track_guide.gd"), "Road track editor guide is missing.")
	assert(color_grade.material is ShaderMaterial, "Map 1 cozy post-process material is missing.")
	assert((color_grade.material as ShaderMaterial).shader.resource_path.ends_with("map1_cozy_grade.gdshader"), "Map 1 cozy shader is not connected.")
	assert(camera.get_script().resource_path.ends_with("cozy_camera_drift.gd"), "Slow camera drift controller is missing.")
	var first_drift := camera.call("_sample_drift", 0.0) as Vector2
	var later_drift := camera.call("_sample_drift", 1.0) as Vector2
	assert(first_drift.distance_to(later_drift) > 5.0, "Camera drift must remain perceptible from second to second.")
	assert((camera.get("drift_amplitude") as Vector2).y > (camera.get("drift_amplitude") as Vector2).x, "Camera drift should favor vertical handheld movement.")
	assert(foreground.z_index > player.z_index, "Foreground layer must render above the player.")
	assert(power_pole_layer.texture.resource_path.ends_with("layer2tianglistrik.png"), "Map 1 foreground power-pole layer is missing.")
	assert(is_equal_approx(power_pole_layer.position.y, 910.0), "Power-pole layer vertical alignment must match FullMap1.")
	assert(bimo.get_script().resource_path.ends_with("map1_bimo_interaction.gd"), "Bimo interaction controller is missing.")
	assert(bimo.position.x < 2627.0 and 2627.0 - bimo.position.x < 400.0, "Bimo must stand just before the second street lamp.")
	assert(bimo.has_node("BimoDialogueAnchor"), "Bimo dialogue bubble anchor is missing.")
	var bimo_sprite := bimo.get_node("VisualPivot/MaleSprite") as Sprite2D
	assert(bimo_sprite.hframes == 10, "Bimo idle sheet must remain animated.")
	assert(is_equal_approx(bimo_sprite.scale.x, 8.5), "Bimo test character scale is incorrect.")
	bimo.call("_snap_to_nara_track")
	var nearest_track_y := INF
	var nearest_horizontal_distance := INF
	for point in track.curve.get_baked_points():
		var world_point := track.to_global(point)
		var horizontal_distance := absf(world_point.x - bimo.global_position.x)
		if horizontal_distance < nearest_horizontal_distance:
			nearest_horizontal_distance = horizontal_distance
			nearest_track_y = world_point.y
	assert(is_equal_approx(bimo.global_position.y, nearest_track_y), "Bimo foot must snap to Nara's track.")
	var visual_pivot := player.get_node("VisualPivot") as Node2D
	var male_sprite := visual_pivot.get_node("MaleSprite") as Sprite2D
	assert(male_sprite.texture.resource_path.contains("male_hero_template"), "The test must use the Dummy male character.")
	assert(is_equal_approx(male_sprite.position.y, -127.5), "Male sprite foot anchor must sit exactly on VisualPivot origin.")
	assert(is_equal_approx(male_sprite.scale.x, 8.5), "Nara test character scale is incorrect.")
	assert(visual_pivot.has_node("FootPivotGuide"), "Editor foot pivot guide is missing.")
	assert((player.get("jump_texture") as Texture2D).resource_path.ends_with("male_hero_template-jump.png"), "Jump animation texture is missing.")
	assert((player.get("fall_texture") as Texture2D).resource_path.ends_with("male_hero_template-fall.png"), "Fall animation texture is missing.")
	assert(player.get_node("Camera2D").get_parent() == player, "Camera must stay outside the rotating visual pivot.")
	assert(player.is_in_group("player"), "Map 1 track player must be available to dialogue interactions.")
	assert(player.has_node("NaraDialogueAnchor"), "Player dialogue bubble anchor is missing.")
	var jump_has_w := false
	for event in InputMap.action_get_events("jump"):
		if event is InputEventKey and (event.keycode == KEY_W or event.physical_keycode == KEY_W):
			jump_has_w = true
	assert(jump_has_w, "Jump action must include the W key.")

	var low_road_y := track.curve.sample_baked(500.0).y
	var hill_road_y := track.curve.sample_baked(track.curve.get_baked_length() - 300.0).y
	assert(hill_road_y < low_road_y - 400.0, "Player movement is not following the uphill road.")

	var hill_progress := track.curve.get_baked_length() - 600.0
	var hill_before := track.curve.sample_baked(hill_progress - 24.0)
	var hill_after := track.curve.sample_baked(hill_progress + 24.0)
	assert((hill_after - hill_before).angle() < -0.1, "Character visual should have an uphill tangent to follow.")

	print("MAP1_LAYERING_SMOKE_OK")
	quit()
