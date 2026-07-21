extends SceneTree

const STACK_SCENE := preload("res://scenes/visual/post_process_stack.tscn")
const MAP_SCENES: Array[PackedScene] = [
	preload("res://scenes/new_maps/map1/map1_layering_test.tscn"),
	preload("res://scenes/new_maps/map2/map2.tscn"),
	preload("res://scenes/new_maps/map3/map3.tscn"),
	preload("res://scenes/new_maps/map3/map3_park.tscn"),
	preload("res://scenes/new_maps/map4/map4.tscn"),
	preload("res://scenes/new_maps/map5/map5.tscn"),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stack := STACK_SCENE.instantiate() as CanvasLayer
	root.add_child(stack)
	await process_frame

	_assert_effect(stack, "ColorGrade", true)
	_assert_effect(stack, "SoftBloom", false)
	stack.set("use_soft_bloom", true)
	stack.set("use_ambient_haze", true)
	stack.set("use_subtle_grain", true)
	stack.set("use_oled_color", true)
	stack.set("use_amoled_punch", true)
	stack.set("use_atmospheric_wind", true)
	_assert_effect(stack, "SoftBloom", true)
	_assert_effect(stack, "AmbientHaze", true)
	_assert_effect(stack, "SubtleGrain", true)
	_assert_effect(stack, "OLEDColor", true)
	_assert_effect(stack, "AMOLEDPunch", true)
	_assert_effect(stack, "AtmosphericWind", true)

	stack.set("bloom_strength", 0.125)
	var bloom := stack.get_node("SoftBloom") as ColorRect
	var bloom_material := bloom.material as ShaderMaterial
	assert(is_equal_approx(float(bloom_material.get_shader_parameter("intensity")), 0.125))
	stack.set("oled_strength", 0.64)
	stack.set("amoled_strength", 0.61)
	stack.set("wind_strength", 1.15)
	_assert_shader_parameter(stack, "OLEDColor", "strength", 0.64)
	_assert_shader_parameter(stack, "AMOLEDPunch", "strength", 0.61)
	_assert_shader_parameter(stack, "AtmosphericWind", "strength", 1.15)

	stack.set("effects_enabled", false)
	for effect_name: String in [
		"FilmicTone",
		"ColorGrade",
		"AmbientHaze",
		"SoftBloom",
		"SubtleGrain",
		"SoftVignette",
		"OLEDColor",
		"AMOLEDPunch",
		"AtmosphericWind",
	]:
		_assert_effect(stack, effect_name, false)
	stack.queue_free()
	await process_frame

	for packed_map: PackedScene in MAP_SCENES:
		var map_instance := packed_map.instantiate()
		var map_stack := map_instance.get_node("CozyPostProcess") as CanvasLayer
		assert(map_stack != null, "Map is missing the reusable post-process stack.")
		assert(map_stack.get_script().resource_path.ends_with("post_process_stack.gd"))
		var color_grade := map_stack.get_node("ColorGrade") as ColorRect
		assert(color_grade.material is ShaderMaterial)
		map_instance.free()

	print("POST_PROCESS_STACK_SMOKE_OK effects=9 maps=6 toggles=ok parameters=ok")
	quit(0)


func _assert_effect(stack: CanvasLayer, effect_name: String, expected: bool) -> void:
	var effect := stack.get_node(effect_name) as ColorRect
	var buffer := stack.get_node(effect_name + "Buffer") as BackBufferCopy
	assert(effect.visible == expected, effect_name + " visibility does not match its checkbox.")
	assert(buffer.visible == expected, effect_name + " buffer does not match its checkbox.")


func _assert_shader_parameter(
	stack: CanvasLayer,
	effect_name: String,
	parameter_name: String,
	expected: float
) -> void:
	var effect := stack.get_node(effect_name) as ColorRect
	var shader_material := effect.material as ShaderMaterial
	assert(is_equal_approx(float(shader_material.get_shader_parameter(parameter_name)), expected))
