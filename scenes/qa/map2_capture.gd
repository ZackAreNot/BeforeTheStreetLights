extends Node

const MAP2_SCENE := preload("res://scenes/new_maps/map2/map2.tscn")


func _ready() -> void:
	var map2 := MAP2_SCENE.instantiate()
	add_child(map2)
	await get_tree().create_timer(0.6).timeout
	var capture := get_viewport().get_texture().get_image()
	var result := capture.save_png(
		ProjectSettings.globalize_path("res://tmp/map2_layout.png")
	)
	if result != OK:
		push_error("MAP2_CAPTURE_FAILED")
		get_tree().quit(1)
		return
	print("MAP2_CAPTURE_OK")
	get_tree().quit()
