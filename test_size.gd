extends SceneTree
func _init():
	var img1 = Image.load_from_file("res://assets/NewMaps/Map1/NewMap1.png")
	var img2 = Image.load_from_file("res://assets/NewMaps/Map1/NewMap1Layer2.png")
	var img3 = Image.load_from_file("res://assets/NewMaps/Map1/NewMap1Layer3.png")
	print("Map1 Size: ", img1.get_size())
	print("Layer2 Size: ", img2.get_size())
	print("Layer3 Size: ", img3.get_size())
	quit()
