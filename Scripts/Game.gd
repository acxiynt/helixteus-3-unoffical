extends Node2D

onready var planet_tiles_scene = preload("res://Scenes/Planet.tscn")
onready var construct_panel_scene = preload("res://Scenes/ConstructPanel.tscn")
onready var construct_panel:Control = construct_panel_scene.instance()

func _ready():
	construct_panel.name = "construct_panel"
	#construct_panel.rect_position = Vector2(640, 360)
	construct_panel.rect_scale = Vector2(0.8, 0.8)


func _load_game():
	#Loads planet scene
	self.remove_child($Title)
	var planet_tiles = planet_tiles_scene.instance()
	self.add_child(planet_tiles)
	self.add_child(construct_panel)
	construct_panel.visible = false

func _input(event):
	if Input.is_action_just_released("construct"):
		if not get_node("construct_panel").visible:
			add_construct_panel()
			print("A")
		else:
			remove_construct_panel()

func add_construct_panel():
	construct_panel.visible = true
	get_node("construct_panel/AnimationPlayer").play("FadeIn")

func remove_construct_panel():
	get_node("construct_panel/AnimationPlayer").play_backwards("FadeIn")
	$Timer.start()

func _on_Timer_timeout():
	construct_panel.visible = false
	print("removed")
