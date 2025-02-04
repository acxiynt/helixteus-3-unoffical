extends Node2D

onready var game = get_node("/root/Game")

var dimensions:float

const DIST_MULT = 200.0
var obj_btns:Array = []
var overlays:Array = []
var rsrcs:Array = []
onready var bldg_overlay_timer = $BuildingOverlayTimer
var discovered_gal:Array = []
var curr_bldg_overlay:int = 0

func _ready():
	rsrcs.resize(len(game.galaxy_data))
	var conquered = true
	for g_i in game.galaxy_data:
		if g_i.empty():
			continue
		conquered = conquered and g_i.has("conquered")
		var galaxy_btn = TextureButton.new()
		var galaxy = Sprite.new()
		galaxy_btn.texture_normal = game.galaxy_textures[g_i.type]
		self.add_child(galaxy)
		galaxy.add_child(galaxy_btn)
		obj_btns.append(galaxy_btn)
		galaxy_btn.connect("mouse_entered", self, "on_galaxy_over", [g_i.l_id])
		galaxy_btn.connect("mouse_exited", self, "on_galaxy_out")
		galaxy_btn.connect("pressed", self, "on_galaxy_click", [g_i.id, g_i.l_id])
		var radius = pow(g_i["system_num"] / game.GALAXY_SCALE_DIV, 0.5)
		galaxy_btn.rect_position = Vector2(-galaxy_btn.texture_normal.get_width(), -galaxy_btn.texture_normal.get_height()) / 2.0 * radius
		galaxy_btn.rect_scale.x = radius
		galaxy_btn.rect_scale.y = radius
		galaxy.rotation = g_i.rotation
		if g_i.has("modulate"):
			galaxy_btn.modulate = g_i.modulate
		galaxy.position = g_i["pos"]
		dimensions = max(dimensions, g_i.pos.length())
		Helper.add_overlay(galaxy, self, "galaxy", g_i, overlays)
		if g_i.has("GS"):
			var GS_marker:Sprite = Sprite.new()
			GS_marker.scale *= 2.0
			GS_marker.texture = preload("res://Graphics/Effects/spotlight_8.png")
			galaxy.add_child(GS_marker)
			var rsrc
			var prod:float
			var rsrc_mult:float = 1.0
			match g_i.GS:
				"ME":
					rsrc_mult = pow(game.maths_bonus.IRM, game.infinite_research.MEE) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.5, 0.9, 1), Data.rsrc_icons.ME, g_i.l_id, radius * 10.0)
				"PP":
					rsrc_mult = pow(game.maths_bonus.IRM, game.infinite_research.EPE) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.8, 0, 1), Data.rsrc_icons.PP, g_i.l_id, radius * 10.0)
				"RL":
					rsrc_mult = pow(game.maths_bonus.IRM, game.infinite_research.RLE) * game.u_i.time_speed
					rsrc = add_rsrc(g_i.pos, Color(0, 0.8, 0, 1), Data.rsrc_icons.RL, g_i.l_id, radius * 10.0)
			if rsrc:
				rsrc.set_text("%s/%s" % [Helper.format_num(g_i.prod_num * rsrc_mult), tr("S_SECOND")])
		if g_i.has("discovered") and not g_i.has("GS"):
			discovered_gal.append(g_i)
	if conquered:
		game.u_i.cluster_data[game.c_c].conquered = true
	if game.overlay_data.cluster.visible:
		Helper.toggle_overlay(obj_btns, overlays, true)
	if len(discovered_gal) > 0:
		bldg_overlay_timer.start(0.05)

func on_bldg_overlay_timeout():
	var g_i = discovered_gal[curr_bldg_overlay]
	var bldgs:Dictionary = {}
	var MSs:Dictionary = {}
	var system_data2:Array = game.open_obj("Galaxies", g_i.id)
	for s_i in system_data2:
		if not s_i.has("discovered"):
			continue
		var planet_data2:Array = game.open_obj("Systems", s_i.id)
		for p_i in planet_data2:
			if p_i.empty():
				continue
			if p_i.has("tile_num") and p_i.bldg.has("name"):
				Helper.add_to_dict(bldgs, p_i.bldg.name, p_i.tile_num)
			if p_i.has("MS"):
				Helper.add_to_dict(MSs, p_i.MS, 1)
		for _star in s_i.stars:
			if _star.has("MS"):
				Helper.add_to_dict(MSs, _star.MS, 1)
		#yield(get_tree(), "idle_frame")
	var sc:float = pow(g_i["system_num"] / game.GALAXY_SCALE_DIV, 0.5)
	if not bldgs.empty():
		var grid_panel = preload("res://Scenes/BuildingInfo.tscn").instance()
		grid_panel.get_node("Top").visible = false
		var grid = grid_panel.get_node("PanelContainer/GridContainer")
		grid_panel.rect_scale *= 7.0
		for bldg in bldgs:
			var bldg_count = preload("res://Scenes/EntityCount.tscn").instance()
			grid.add_child(bldg_count)
			bldg_count.get_node("Texture").texture = game.bldg_textures[bldg]
			bldg_count.get_node("Texture").mouse_filter = Control.MOUSE_FILTER_IGNORE
			bldg_count.get_node("Label").text = "x %s" % Helper.format_num(bldgs[bldg])
		add_child(grid_panel)
		grid_panel.add_to_group("Grids")
		grid_panel.name = "Grid_%s" % g_i.l_id
		grid_panel.rect_position.x = g_i.pos.x - grid.rect_size.x / 2.0 * grid_panel.rect_scale.x
		grid_panel.rect_position.y = g_i.pos.y - grid_panel.rect_size.y * grid_panel.rect_scale.y - 170 * sc
	if not MSs.empty():
		var MS_grid_panel = preload("res://Scenes/BuildingInfo.tscn").instance()
		MS_grid_panel.get_node("Bottom").visible = false
		var MS_grid = MS_grid_panel.get_node("PanelContainer/GridContainer")
		MS_grid_panel.rect_scale *= 7.0
		for MS in MSs:
			var MS_count = preload("res://Scenes/EntityCount.tscn").instance()
			MS_grid.add_child(MS_count)
			MS_count.get_node("Texture").texture = load("res://Graphics/Megastructures/%s_0.png" % MS)
			MS_count.get_node("Label").text = "x %s" % Helper.format_num(MSs[MS])
		add_child(MS_grid_panel)
		MS_grid_panel.add_to_group("MSGrids")
		MS_grid_panel.name = "MSGrid_%s" % g_i.l_id
		MS_grid_panel.rect_position.x = g_i.pos.x - MS_grid.rect_size.x / 2.0 * MS_grid_panel.rect_scale.x
		MS_grid_panel.rect_position.y = g_i.pos.y + 170 * sc
	curr_bldg_overlay += 1
	if curr_bldg_overlay >= len(discovered_gal):
		bldg_overlay_timer.stop()

func add_rsrc(v:Vector2, mod:Color, icon, id:int, sc:float = 1):
	var rsrc:ResourceStored = game.rsrc_stored_scene.instance()
	add_child(rsrc)
	rsrc.set_current_bar_visibility(false)
	rsrc.set_icon_texture(icon)
	rsrc.rect_scale *= 5.0
	rsrc.rect_position = v + Vector2(0, 70 * 5.0)
	rsrc.set_modulate(mod)
	rsrcs[id] = rsrc
	return rsrc

func e(n, e):
	return n * pow(10, e)

func on_galaxy_over (id:int):
	var g_i = game.galaxy_data[id]
	var tooltip:String = g_i.name if g_i.has("name") else ("%s %s" % [tr("GALAXY"), id])
	var icons = []
	if g_i.has("GS"):
		tooltip += "\n"
		if g_i.GS == "MS":
			icons = [Data.minerals_icon]
			tooltip += Data.path_1.MS.desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult("MS"))
		elif g_i.GS == "B":
			icons = [Data.energy_icon]
			tooltip += Data.path_1.B.desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult("B"))
		elif g_i.GS == "ME":
			icons = [Data.minerals_icon]
			tooltip += Data.path_1.RL.desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult("ME") * game.u_i.time_speed)
		elif g_i.GS == "PP":
			icons = [Data.energy_icon]
			tooltip += Data.path_1.RL.desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult("PP") * game.u_i.time_speed)
		elif g_i.GS == "RL":
			icons = [Data.SP_icon]
			tooltip += Data.path_1.RL.desc % Helper.format_num(g_i.prod_num * Helper.get_IR_mult("RL") * game.u_i.time_speed)
	else:
		tooltip += "\n%s: %s\n%s: %s\n%s: %s nT\n%s: %s" % [tr("SYSTEMS"), g_i.system_num, tr("DIFFICULTY"), g_i.diff, tr("B_STRENGTH"), g_i.B_strength * e(1, 9), tr("DARK_MATTER"), g_i.dark_matter]
	for grid in get_tree().get_nodes_in_group("Grids"):
		if grid.name != "Grid_%s" % g_i.l_id:
			var tween = get_tree().create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
			#grid.visible = false
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		if grid.name != "MSGrid_%s" % g_i.l_id:
			var tween = get_tree().create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
			#grid.visible = false
	game.show_adv_tooltip(tooltip, icons)

func on_galaxy_out ():
	for grid in get_tree().get_nodes_in_group("Grids"):
		#grid.visible = true
		var tween = get_tree().create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		#grid.visible = true
		var tween = get_tree().create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	game.hide_tooltip()

func on_galaxy_click (id:int, l_id:int):
	var g_i:Dictionary = game.galaxy_data[l_id]
	var view = self.get_parent()
	if not view.dragged:
		if g_i.has("GS"):
			if g_i.GS == "TP":
				game.PC_panel.probe_tier = 2
				game.toggle_panel(game.PC_panel)
				game.hide_tooltip()
			return
		if not g_i.has("discovered") and g_i.system_num > 9000:
			game.show_YN_panel("op_galaxy", tr("OP_GALAXY_DESC"), [l_id, id], tr("OP_GALAXY"))
		else:
			game.switch_view("galaxy", {"fn":"set_custom_coords", "fn_args":[["c_g", "c_g_g"], [l_id, id]]})
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient):
	var c_vl = game.overlay_data.cluster.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].system_num)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		1:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("discovered"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		2:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("explored"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		3:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("conquered"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		4:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].diff)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		5:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].B_strength * e(1, 9))
				Helper.set_overlay_visibility(gradient, overlay, offset)
		6:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.galaxy_data[overlay.id].dark_matter)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		7:
			for overlay in overlays:
				if game.galaxy_data[overlay.id].has("GS"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)


func _on_Galaxy_tree_exited():
	queue_free()

var items_collected:Dictionary = {}

func collect_all():
	items_collected.clear()
	var curr_time = OS.get_system_time_msecs()
	var galaxies = game.u_i.cluster_data[game.c_c].galaxies
	var progress:TextureProgress = game.HUD.get_node("Bottom/Panel/CollectProgress")
	progress.max_value = len(galaxies)
	var cond = game.collect_speed_lag_ratio != 0
	for g_ids in galaxies:
		if game.c_v != "cluster":
			break
		if not game.galaxy_data[g_ids.local].has("discovered"):
			progress.value += 1
			continue
		game.system_data = game.open_obj("Galaxies", g_ids.global)
		if game.system_data.empty():
			continue
		for s_ids in game.galaxy_data[g_ids.local].systems:
			var system:Dictionary = game.system_data[s_ids.local]
			if not system.has("discovered"):
				continue
			game.planet_data = game.open_obj("Systems", s_ids.global)
			for p_ids in system.planets:
				var planet:Dictionary = game.planet_data[p_ids.local]
				if planet.empty() or p_ids.local >= len(game.planet_data) or not planet.has("discovered"):
					continue
				if planet.has("tile_num"):
					if planet.bldg.name in ["ME", "PP", "MM", "AE"]:
						Helper.call("collect_%s" % planet.bldg.name, planet, planet, items_collected, curr_time, planet.tile_num)
			Helper.save_obj("Systems", s_ids.global, game.planet_data)
		Helper.save_obj("Galaxies", g_ids.global, game.system_data)
		if cond:
			progress.value += 1
			yield(get_tree().create_timer(0.02 * game.collect_speed_lag_ratio), "timeout")
	game.show_collect_info(items_collected)
	game.HUD.refresh()
