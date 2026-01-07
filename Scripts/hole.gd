extends Area2D

# Variable to store the center position
var hole_global_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	hole_global_position = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_body_entered(body):
	if body.is_in_group("Player"):
		SignalBus.emit_signal("falling_into_hole", hole_global_position)
