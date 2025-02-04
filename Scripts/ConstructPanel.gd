extends "GenericPanel.gd"

var basic_bldgs:Array = ["ME", "PP", "RL", "MM", "SP", "AE", "PC", "NC", "EC"]
var storage_bldgs:Array = ["MS", "B", "NSF", "ESF"]
var production_bldgs:Array = ["SC", "GF", "SE", "AMN", "SPR"]
var support_bldgs:Array = ["GH", "CBD"]
var vehicles_bldgs:Array = ["RCC", "SY", "PCC"]

func _ready():
	var added_buildings = Mods.added_buildings
	for key in added_buildings:
		match added_buildings[key].type:
			"basic":
				basic_bldgs.append(key)
			"storage":
				storage_bldgs.append(key)
			"production":
				production_bldgs.append(key)
			"support":
				support_bldgs.append(key)
			"vehicles":
				vehicles_bldgs.append(key)
	
	type = PanelType.CONSTRUCT
	tab = "Basic"
	$Title.text = tr("CONSTRUCT")
	for btn_str in ["Basic", "Storage", "Production", "Support", "Vehicles"]:
		var btn = preload("res://Scenes/AdvButton.tscn").instance()
		btn.name = btn_str
		btn.button_text = tr(btn_str.to_upper())
		btn.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		btn.connect("pressed", self, "_on_btn_pressed", [btn_str])
		$VBox/Tabs.add_child(btn)
	buy_hbox.visible = false
	refresh()

func _on_btn_pressed(btn_str:String):
	var btn_str_l:String = btn_str.to_lower()
	var btn_str_u:String = btn_str.to_upper()
	tab = btn_str
	change_tab(btn_str)
	for bldg in self["%s_bldgs" % btn_str_l]:
		var item = item_for_sale_scene.instance()
		item.get_node("SmallButton").text = tr("CONSTRUCT")
		item.item_name = bldg
		item.item_dir = "Buildings"
		var txt:String = ""
		var time_speed:float = game.u_i.time_speed if Data.path_1.has(bldg) and Data.path_1[bldg].has("time_based") else 1.0
		item.get_node("New").visible = game.new_bldgs.has(bldg) and game.new_bldgs[bldg]
		if bldg == "SP":
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_SP_production(game.planet_data[game.c_p].temperature, Data.path_1[bldg].value * Helper.get_IR_mult(bldg) * time_speed), true)]
		elif bldg == "AE":
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Helper.get_AE_production(game.planet_data[game.c_p].pressure, Data.path_1[bldg].value * Helper.get_IR_mult(bldg) * time_speed), true)]
		elif bldg in ["PC", "NC"]:
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value / game.planet_data[game.c_p].pressure * time_speed, true)]
		elif bldg in ["MS", "NSF", "ESF"]:
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(round(Data.path_1[bldg].value * Helper.get_IR_mult(bldg)))]
		elif bldg == "B":
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(round(Data.path_1[bldg].value * Helper.get_IR_mult(bldg) * game.u_i.charge))]
		elif Data.path_1.has(bldg):
			txt = (Data.path_1[bldg].desc + "\n") % [Helper.format_num(Data.path_1[bldg].value * Helper.get_IR_mult(bldg) * time_speed, true)]
		if Data.path_2.has(bldg):
			if Data.path_2[bldg].has("is_value_integer"):
				txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(round(Data.path_2[bldg].value * Helper.get_IR_mult(bldg)))]
			else:
				txt += (Data.path_2[bldg].desc + "\n") % [Helper.format_num(Data.path_2[bldg].value * Helper.get_IR_mult(bldg), true)]
		if Data.path_3.has(bldg):
			if bldg == "CBD":
				txt += Data.path_3[bldg].desc.format({"n":Data.path_3[bldg].value}) + "\n"
			else:
				txt += (Data.path_3[bldg].desc + "\n") % [Data.path_3[bldg].value]
		item.item_desc = "%s\n\n%s" % [tr("%s_DESC" % bldg), txt]
		item.costs = Data.costs[bldg].duplicate(true)
		for cost in item.costs:
			item.costs[cost] *= game.engineering_bonus.BCM
		if bldg == "GH":
			item.costs.energy = round(item.costs.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
		if item.costs.has("time"):
			if game.subjects.dimensional_power.lv >= 1:
				item.costs.time = 0.2
			else:
				item.costs.time /= game.u_i.time_speed
		item.parent = "construct_panel"
		item.add_to_group("bldgs")
		grid.add_child(item)
	for bldg in get_tree().get_nodes_in_group("bldgs"):
		if bldg.item_name == "ME":
			bldg.visible = true
		else:
			bldg.visible = game.new_bldgs.has(bldg.item_name)

func set_item_info(_name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	.set_item_info(_name, desc, costs, _type, _dir)
	desc_txt.text = ""
	var icons = []
	var has_icon = Data.desc_icons.has(_name)
	if has_icon:
		icons = Helper.flatten(Data.desc_icons[_name])
	game.add_text_icons(desc_txt, desc, icons, 22)

func _on_Buy_pressed():
	get_item(item_name, null, null)

func get_item(_name, _type, _dir):
	if _name == "" or game.c_v != "planet":
		return
	yield(get_tree().create_timer(0.01), "timeout")
	game.toggle_panel(game.construct_panel)
	game.put_bottom_info(tr("CLICK_TILE_TO_CONSTRUCT"), "building", "cancel_building")
	var base_cost = Data.costs[_name].duplicate(true)
	for cost in base_cost:
		base_cost[cost] *= game.engineering_bonus.BCM
	if _name == "GH":
		base_cost.energy = round(base_cost.energy * (1 + abs(game.planet_data[game.c_p].temperature - 273) / 10.0))
	game.view.obj.construct(_name, base_cost)
	if game.tutorial and game.tutorial.tut_num in [3, 5]:
		game.tutorial.fade(0.15, false)

func refresh():
	if game.c_v == "planet":
		$VBox/Tabs/Production.visible = game.show.has("stone")
		$VBox/Tabs/Support.visible = game.stats_univ.bldgs_built >= 18
		$VBox/Tabs/Vehicles.visible = game.show.has("vehicles_button")
		for btn_str in ["Basic", "Storage", "Production", "Support", "Vehicles"]:
			$VBox/Tabs.get_node(btn_str + "/Label/Notification").visible = false
			for bldg in self[btn_str.to_lower() + "_bldgs"]:
				if bldg in game.new_bldgs.keys() and game.new_bldgs[bldg]:
					$VBox/Tabs.get_node(btn_str + "/Label/Notification").visible = true
					break
		if $VBox/Tabs.get_node(tab).visible:
			$VBox/Tabs.get_node(tab)._on_Button_pressed()
			_on_btn_pressed(tab)
		else:
			$VBox/Tabs.get_node("Basic")._on_Button_pressed()
			_on_btn_pressed("Basic")

func _on_close_button_pressed():
	if not game.tutorial or game.tutorial and not game.tutorial.BG_blocked:
		._on_close_button_pressed()
