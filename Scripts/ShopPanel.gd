extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]

func _ready():
	tween = Tween.new()
	add_child(tween)

func _on_Speedups_pressed():
	tab = "speedups"
	$Contents.visible = true
	set_item_visibility("Speedups")
	$Contents/Info.text = tr("SPEED_UP_DESC")
	Helper.set_btn_color($Tabs/Speedups)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Overclocks_pressed():
	tab = "overclocks"
	$Contents.visible = true
	set_item_visibility("Overclocks")
	$Contents/Info.text = tr("OVERCLOCK_DESC")
	Helper.set_btn_color($Tabs/Overclocks)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Pickaxes_pressed():
	tab = "pickaxes"
	$Contents.visible = true
	set_item_visibility("Pickaxes")
	$Contents/Info.text = tr("PICKAXE_DESC")
	Helper.set_btn_color($Tabs/Pickaxes)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = false
	if $Contents/HBoxContainer/Items/Pickaxes.get_child_count() == 0:
		for pickaxe in game.pickaxe_info.keys():
			var pickaxe_info = game.pickaxe_info[pickaxe]
			var pickaxe_item = item_for_sale_scene.instance()
			pickaxe_item.get_node("SmallButton").text = tr("BUY")
			pickaxe_item.item_name = pickaxe
			pickaxe_item.item_dir = "Pickaxes"
			pickaxe_item.item_desc = tr(pickaxe.to_upper() + "_DESC")
			pickaxe_item.costs = pickaxe_info.costs
			pickaxe_item.parent = "shop_panel"
			$Contents/HBoxContainer/Items/Pickaxes.add_child(pickaxe_item)

func set_item_visibility(type:String):
	for other_type in $Contents/HBoxContainer/Items.get_children():
		other_type.visible = false
	remove_costs()
	$Contents/HBoxContainer/Items.get_node(type).visible = true
	$Contents/HBoxContainer/ItemInfo.visible = false
	item_name = ""

func remove_costs():
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	for child in vbox.get_children():
		if not child is Label:
			vbox.remove_child(child)

var item_costs:Dictionary
var item_name = ""

func set_item_info(name:String, desc:String, costs:Dictionary, _type:String, _dir:String):
	remove_costs()
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = get_item_name(name)
	item_costs = costs
	item_name = name
	if tab == "pickaxes":
		var pickaxe_info = game.pickaxe_info[name]
		desc += ("\n\n" + tr("MINING_SPEED") + ": %s\n" + tr("DURABILITY") + ": %s") % [pickaxe_info.speed, pickaxe_info.durability]
	desc += "\n"
	vbox.get_node("Description").text = desc
	$Contents/HBoxContainer/ItemInfo.visible = true
	Helper.put_rsrc(vbox, 36, costs, false)

func get_item_name(name:String):
	match name:
		"stick":
			return tr("STICK")
		"wooden_pickaxe":
			return tr("WOODEN_PICKAXE")
		"stone_pickaxe":
			return tr("STONE_PICKAXE")
		"lead_pickaxe":
			return tr("LEAD_PICKAXE")
		"copper_pickaxe":
			return tr("COPPER_PICKAXE")
		"iron_pickaxe":
			return tr("IRON_PICKAXE")

func _on_Buy_pressed():
	get_item(item_name, item_costs, null, null)

func get_item(name, costs, _type, _dir):
	if name == "":
		return
	item_name = name
	item_costs = costs
	if game.check_enough(costs):
		if tab == "pickaxes":
			if game.pickaxe != null:
				YNPanel(tr("REPLACE_PICKAXE") % [get_item_name(game.pickaxe.name).to_lower(), get_item_name(name).to_lower()])
			else:
				buy_pickaxe()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

func YNPanel(text:String):
	$ConfirmationDialog.dialog_text = text
	$ConfirmationDialog.popup_centered()
	if not $ConfirmationDialog.is_connected("confirmed", self, "buy_pickaxe"):
		$ConfirmationDialog.connect("confirmed", self, "buy_pickaxe")

func buy_pickaxe_confirm():
	buy_pickaxe()
	$ConfirmationDialog.disconnect("confirmed", self, "buy_pickaxe")

func buy_pickaxe():
	if not game.check_enough(item_costs):
		return
	game.deduct_resources(item_costs)
	if game.c_v == "mining":
		game.mining_HUD.get_node("Pickaxe").visible = true
	game.pickaxe = {"name":item_name, "speed":game.pickaxe_info[item_name].speed, "durability":game.pickaxe_info[item_name].durability}
	game.popup(tr("BUY_PICKAXE") % [get_item_name(item_name).to_lower()], 1.0)
