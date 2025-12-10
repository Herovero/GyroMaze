extends Area2D

@export var time_bonus: float = 30.0

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_nodes_in_group("Player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_body_entered(body):
	if body.is_in_group("Player"):
		SignalBus.emit_signal("add_time", time_bonus)
		queue_free()
