extends Node

const MAP3_SCENE := preload("res://scenes/new_maps/map3/map3.tscn")


func _ready() -> void:
	var map3 := MAP3_SCENE.instantiate()
	add_child(map3)
	await get_tree().create_timer(0.6).timeout
	var image := get_viewport().get_texture().get_image()
	if image.save_png(ProjectSettings.globalize_path("res://tmp/map3_layout.png")) != OK:
		push_error("MAP3_CAPTURE_FAILED")
		get_tree().quit(1)
		return
	print("MAP3_CAPTURE_OK")
	get_tree().quit()
