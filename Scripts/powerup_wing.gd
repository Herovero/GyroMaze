extends Area2D

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_nodes_in_group("Player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.has_method("collect_powerup"):
			var was_collected = body.collect_powerup("wing")
			# Only destroy the object if the player actually took it
			if was_collected == true:
				queue_free()
			else:
				# Inventory was full. Do nothing (item stays on ground).
				pass
