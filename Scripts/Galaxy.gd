extends Node2D

onready var game = get_node("/root/Game")
var star_shader = preload("res://Shaders/Star.shader")

var dimensions:float

const DIST_MULT = 200.0
var obj_btns = []
var overlays = []
var star_texture = [	preload("res://Graphics/Effects/spotlight_4.png"),
						preload("res://Graphics/Effects/spotlight_5.png"),
						preload("res://Graphics/Effects/spotlight_6.png"),
]
onready var bldg_overlay_timer = $BuildingOverlayTimer
var curr_bldg_overlay:int = 0
var discovered_sys:Array

func _ready():
	discovered_sys = []
	for s_i in game.system_data:
		var star:Dictionary = s_i.stars[0]
		for i in range(1, len(s_i.stars)):
			if s_i.stars[i].luminosity > star.luminosity:
				star = s_i.stars[i]
		if game.galaxy_data[game.c_g].has("conquered") and not s_i.has("conquered"):
			s_i.conquered = true
			game.stats_univ.planets_conquered += s_i.planet_num
			game.stats_dim.planets_conquered += s_i.planet_num
			game.stats_global.planets_conquered += s_i.planet_num
		var star_btn = TextureButton.new()
		var system = Sprite.new()
		star_btn.texture_normal = star_texture[int(star.temperature) % 3]
		star_btn.texture_click_mask = preload("res://Graphics/Misc/StarCM.png")
		star_btn.modulate = get_star_modulate(star["class"]) * 1.5
		add_child(system)
		system.add_child(star_btn)
		obj_btns.append(star_btn)
		star_btn.connect("mouse_entered", self, "on_system_over", [s_i.l_id])
		star_btn.connect("mouse_exited", self, "on_system_out")
		star_btn.connect("pressed", self, "on_system_click", [s_i.id, s_i.l_id])
		star_btn.rect_rotation = sin(star.temperature) * 180
		star_btn.rect_position = Vector2(-1024 / 2, -1024 / 2)
		star_btn.rect_pivot_offset = Vector2(1024 / 2, 1024 / 2)
		var radius = pow(star["size"] / game.SYSTEM_SCALE_DIV, 0.35)
		star_btn.rect_scale *= radius
		system.position = s_i["pos"]
		dimensions = max(dimensions, s_i.pos.length())
		Helper.add_overlay(system, self, "system", s_i, overlays)
		if s_i.has("discovered"):
			discovered_sys.append(s_i)
	if game.galaxy_data[game.c_g].has("wormholes"):
		for wh_data in game.galaxy_data[game.c_g].wormholes:
			var blue_line = Line2D.new()
			add_child(blue_line)
			blue_line.add_point(game.system_data[wh_data.from].pos)
			blue_line.add_point(game.system_data[wh_data.to].pos)
			blue_line.width = 2
			blue_line.default_color = Color(0.6, 0.4, 1.0, 1.0)
			blue_line.antialiased = true
	if game.overlay_data.galaxy.visible:
		Helper.toggle_overlay(obj_btns, overlays, true)
	if len(discovered_sys) > 0:
		bldg_overlay_timer.start(0.05)

func on_system_over (l_id:int):
	var s_i = game.system_data[l_id]
	var _name:String
	if s_i.has("name"):
		_name = s_i.name
	else:
		_name = "%s %s" % [tr("SYSTEM"), l_id]
		match len(game.system_data[l_id].stars):
			2:
				_name = "%s %s" % [tr("BINARY_SYSTEM"), l_id]
			3:
				_name = "%s %s" % [tr("TERNARY_SYSTEM"), l_id]
			4:
				_name = "%s %s" % [tr("QUADRUPLE_SYSTEM"), l_id]
			5:
				_name = "%s %s" % [tr("QUINTUPLE_SYSTEM"), l_id]
	for grid in get_tree().get_nodes_in_group("Grids"):
		if grid.name != "Grid_%s" % l_id:
			var tween = get_tree().create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		if grid.name != "MSGrid_%s" % l_id:
			var tween = get_tree().create_tween()
			tween.tween_property(grid, "modulate", Color(1, 1, 1, 0), 0.1)
	game.show_tooltip("%s\n%s: %s\n%s: %s" % [_name, tr("PLANETS"), s_i.planet_num, tr("DIFFICULTY"), Helper.format_num(s_i.diff)])

func on_system_out ():
	for grid in get_tree().get_nodes_in_group("Grids"):
		var tween = get_tree().create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	for grid in get_tree().get_nodes_in_group("MSGrids"):
		var tween = get_tree().create_tween()
		tween.tween_property(grid, "modulate", Color(1, 1, 1, 1), 0.1)
	game.hide_tooltip()

func on_system_click (id:int, l_id:int):
	var view = self.get_parent()
	if not view.dragged:
		game.switch_view("system", {"fn":"set_custom_coords", "fn_args":[["c_s", "c_s_g"], [l_id, id]]})
	view.dragged = false

func change_overlay(overlay_id:int, gradient:Gradient):
	var c_vl = game.overlay_data.galaxy.custom_values[overlay_id]
	match overlay_id:
		0:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.system_data[overlay.id].planet_num)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		1:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, len(game.system_data[overlay.id].stars))
				Helper.set_overlay_visibility(gradient, overlay, offset)
		2:
			for overlay in overlays:
				if game.system_data[overlay.id].has("discovered"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		3:
			for overlay in overlays:
				if game.system_data[overlay.id].has("explored"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		4:
			for overlay in overlays:
				if game.system_data[overlay.id].has("conquered"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)
		5:
			for overlay in overlays:
				var offset = inverse_lerp(c_vl.left, c_vl.right, game.system_data[overlay.id].diff)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		6:
			for overlay in overlays:
				var temp = game.get_hottest_star_temp(overlay.id)
				var offset = inverse_lerp(c_vl.left, c_vl.right, temp)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		7:
			for overlay in overlays:
				var temp = game.get_biggest_star_size(overlay.id)
				var offset = inverse_lerp(c_vl.left, c_vl.right, temp)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		8:
			for overlay in overlays:
				var temp = game.get_brightest_star_luminosity(overlay.id)
				var offset = inverse_lerp(c_vl.left, c_vl.right, temp)
				Helper.set_overlay_visibility(gradient, overlay, offset)
		9:
			for overlay in overlays:
				if game.system_data[overlay.id].has("has_MS"):
					overlay.circle.modulate = gradient.interpolate(0)
				else:
					overlay.circle.modulate = gradient.interpolate(1)

func _on_Galaxy_tree_exited():
	queue_free()

var items_collected = {}

func collect_all():
	items_collected.clear()
	var curr_time = OS.get_system_time_msecs()
	var systems = game.galaxy_data[game.c_g].systems
	var progress:TextureProgress = game.HUD.get_node("Bottom/Panel/CollectProgress")
	progress.max_value = len(systems)
	var cond = game.collect_speed_lag_ratio != 0
	for s_ids in systems:
		if game.c_v != "galaxy":
			break
		if not game.system_data[s_ids.local].has("discovered"):
			progress.value += 1
			continue
		game.planet_data = game.open_obj("Systems", s_ids.global)
		for p_ids in game.system_data[s_ids.local].planets:
			var planet:Dictionary = game.planet_data[p_ids.local]
			if planet.empty() or not planet.has("discovered"):
				continue
			if p_ids.local >= len(game.planet_data):
				continue
			if planet.has("tile_num"):
				if planet.bldg.name in ["ME", "PP", "MM", "AE"]:
					Helper.call("collect_%s" % planet.bldg.name, planet, planet, items_collected, curr_time, planet.tile_num)
			else:
				game.tile_data = game.open_obj("Planets", p_ids.global)
				var i:int
				for tile in game.tile_data:
					if tile:
						Helper.collect_rsrc(items_collected, planet, tile, i)
					i += 1
				Helper.save_obj("Planets", p_ids.global, game.tile_data)
		Helper.save_obj("Systems", s_ids.global, game.planet_data)
		if cond:
			progress.value += 1
			yield(get_tree().create_timer(0.02 * game.collect_speed_lag_ratio), "timeout")
	game.show_collect_info(items_collected)
	game.HUD.refresh()

const Y9 = Color(25, 0, 0, 255) / 255.0
const Y0 = Color(66, 0, 0, 255) / 255.0
const T0 = Color(117, 0, 0, 255) / 255.0
const L0 = Color(189, 32, 23, 255) / 255.0
const M0 = Color(255, 181, 108, 255) / 255.0
const K0 = Color(255, 218, 181, 255) / 255.0
const G0 = Color(255, 237, 227, 255) / 255.0
const F0 = Color(249, 245, 255, 255) / 255.0
const A0 = Color(213, 224, 255, 255) / 255.0
const B0 = Color(162, 192, 255, 255) / 255.0
const O0 = Color(140, 177, 255, 255) / 255.0
const Q0 = Color(134, 255, 117, 255) / 255.0
const R0 = Color(255, 100, 255, 255) / 255.0
const Z0 = Color(100, 30, 255, 255) / 255.0

func get_star_modulate (star_class:String):
	var w = int(star_class[1]) / 10.0#weight for lerps
	var m:Color
	match star_class[0]:
		"Y":
			m = lerp(Y0, Y9, w)
		"T":
			m = lerp(T0, Y0, w)
		"L":
			m = lerp(L0, T0, w)
		"M":
			m = lerp(M0, L0, w)
		"K":
			m = lerp(K0, M0, w)
		"G":
			m = lerp(G0, K0, w)
		"F":
			m = lerp(F0, G0, w)
		"A":
			m = lerp(A0, F0, w)
		"B":
			m = lerp(B0, A0, w)
		"O":
			m = lerp(O0, B0, w)
		"Q":
			m = lerp(Q0, O0, w)
		"R":
			m = lerp(R0, Q0, w)
		"Z":
			m = lerp(Z0, R0, w)
	return m


func _on_BuildingOverlayTimer_timeout():
	var s_i = discovered_sys[curr_bldg_overlay]
	var planet_data:Array = game.open_obj("Systems", s_i.id)
	var bldgs:Dictionary = {}
	var MSs:Dictionary = {}
	for p_i in planet_data:
		if p_i.empty():
			continue
		if p_i.has("tile_num") and p_i.bldg.has("name"):
			Helper.add_to_dict(bldgs, p_i.bldg.name, p_i.tile_num)
		if p_i.has("MS"):
			Helper.add_to_dict(MSs, p_i.MS, 1)
		var tile_data:Array = game.open_obj("Planets", p_i.id)
		for tile in tile_data:
			if tile and tile.has("bldg"):
				Helper.add_to_dict(bldgs, tile.bldg.name, 1)
	#yield(get_tree(), "idle_frame")
	for _star in s_i.stars:
		if _star.has("MS"):
			Helper.add_to_dict(MSs, _star.MS, 1)
	if not bldgs.empty():
		var grid_panel = preload("res://Scenes/BuildingInfo.tscn").instance()
		grid_panel.get_node("Top").visible = false
		var grid = grid_panel.get_node("PanelContainer/GridContainer")
		grid_panel.rect_scale *= 5.0
		for bldg in bldgs:
			var bldg_count = preload("res://Scenes/EntityCount.tscn").instance()
			grid.add_child(bldg_count)
			bldg_count.get_node("Texture").texture = game.bldg_textures[bldg]
			bldg_count.get_node("Texture").mouse_filter = Control.MOUSE_FILTER_IGNORE
			bldg_count.get_node("Label").text = "x %s" % Helper.format_num(bldgs[bldg])
		add_child(grid_panel)
		grid_panel.add_to_group("Grids")
		grid_panel.name = "Grid_%s" % s_i.l_id
		grid_panel.rect_position.x = s_i.pos.x - grid.rect_size.x / 2.0 * grid_panel.rect_scale.x
		grid_panel.rect_position.y = s_i.pos.y - (grid.rect_size.y + 30) * grid_panel.rect_scale.y
	if not MSs.empty():
		var MS_grid_panel = preload("res://Scenes/BuildingInfo.tscn").instance()
		MS_grid_panel.get_node("Bottom").visible = false
		var MS_grid = MS_grid_panel.get_node("PanelContainer/GridContainer")
		MS_grid_panel.rect_scale *= 5.0
		for MS in MSs:
			var MS_count = preload("res://Scenes/EntityCount.tscn").instance()
			MS_grid.add_child(MS_count)
			MS_count.get_node("Texture").texture = load("res://Graphics/Megastructures/%s_0.png" % MS)
			MS_count.get_node("Label").text = "x %s" % Helper.format_num(MSs[MS])
		add_child(MS_grid_panel)
		MS_grid_panel.add_to_group("MSGrids")
		MS_grid_panel.name = "MSGrid_%s" % s_i.l_id
		MS_grid_panel.rect_position.x = s_i.pos.x - MS_grid.rect_size.x / 2.0 * MS_grid_panel.rect_scale.x
		MS_grid_panel.rect_position.y = s_i.pos.y + MS_grid.rect_size.y * MS_grid_panel.rect_scale.y
		
	curr_bldg_overlay += 1
	if curr_bldg_overlay >= len(discovered_sys):
		bldg_overlay_timer.stop()
