extends TouchScreenButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_released():
	call_deferred("restart_game")

func restart_game():
	Global.reset_stats()
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
