extends "Panel.gd"

var mod_slot_scene = preload("res://Scenes/ModSlot.tscn")

func _ready():
	tween = Tween.new()
	add_child(tween)
	
	for key in Mods.mod_list:
		var mod = Mods.mod_list[key]
		var mod_slot = mod_slot_scene.instance()
		mod_slot.get_node("Name").text = mod.mod_info.name
		mod_slot.get_node("Version").text = mod.mod_info.version
		mod_slot.get_node("Author").text = mod.mod_info.author
		mod_slot.get_node("Description").text = mod.mod_info.description
		mod_slot.get_node("Load").pressed = !key in Mods.dont_load
		mod_slot.get_node("LoadOrder/Up").connect("pressed", self, "on_up", [key, mod_slot])
		mod_slot.get_node("LoadOrder/Down").connect("pressed", self, "on_down", [key, mod_slot])
		mod_slot.get_node("Load").connect("pressed", self, "on_load", [key, mod_slot])
		$ScrollContainer/VBox.add_child(mod_slot)

func on_up(key, mod_slot):
	var order = Mods.mod_load_order.find(key)
	if !order in [-1, 0]:
		var key2 = Mods.mod_load_order[order - 1]
		Mods.mod_load_order[order] = key2
		Mods.mod_load_order[order - 1] = key
		var config = ConfigFile.new()
		config.load("user://settings.cfg")
		config.set_value("mods", "load_order", Mods.mod_load_order)
		config.save("user://settings.cfg")
		$ScrollContainer/VBox.move_child(mod_slot, order - 1)

func on_down(key, mod_slot):
	var order = Mods.mod_load_order.find(key)
	if !order in [-1, Mods.mod_load_order.size() - 1]:
		var key2 = Mods.mod_load_order[order + 1]
		Mods.mod_load_order[order] = key2
		Mods.mod_load_order[order + 1] = key
		var config = ConfigFile.new()
		config.load("user://settings.cfg")
		config.set_value("mods", "load_order", Mods.mod_load_order)
		config.save("user://settings.cfg")
		$ScrollContainer/VBox.move_child(mod_slot, order + 1)

func on_load(key, mod_slot):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	if mod_slot.get_node("Load").pressed:
		Mods.dont_load.erase(key)
		config.set_value("mods", "dont_load", Mods.dont_load)
	else:
		if Mods.dont_load == []:
			Mods.dont_load = [key]
			config.set_value("mods", "dont_load", Mods.dont_load)
		else:
			Mods.dont_load.append(key)
			config.set_value("mods", "dont_load", Mods.dont_load)
	config.save("user://settings.cfg")
