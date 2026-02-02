extends TouchScreenButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_released():
	# Use call_deferred so the scene switch happens AFTER the input event finishes
	call_deferred("_do_scene_switch")

func _do_scene_switch():
	# 1. Unpause first (Important so the next scene isn't frozen)
	get_tree().paused = false
	
	# 2. Reset Stats
	Global.reset_stats()
	
	# 3. Change Scene
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
