extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _on_body_entered(body):
	if body.is_in_group("Player"):
		Global.current_level += 1
		print("Level Complete! Moving to Level: ", Global.current_level)
		get_tree().call_deferred("reload_current_scene")
