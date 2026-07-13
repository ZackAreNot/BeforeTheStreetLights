extends Node

const MAP2_SCENE := preload("res://scenes/new_maps/map2/map2.tscn")


func _ready() -> void:
	var map2 := MAP2_SCENE.instantiate()
	add_child(map2)
	var track := map2.get_node("RoadTrack") as Path2D
	var player := map2.get_node("RoadTrack/MaleTrackPlayer") as PathFollow2D
	var seller := map2.get_node("ElectricShopkeeper") as Node2D
	player.progress = track.curve.get_closest_offset(
		track.to_local(Vector2(seller.global_position.x - 420.0, seller.global_position.y))
	)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	await get_tree().create_timer(0.6).timeout
	_save_capture("res://tmp/map2_shopkeeper.png")
	get_tree().quit()


func _save_capture(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("MAP2_SHOPKEEPER_CAPTURE_FAILED")
