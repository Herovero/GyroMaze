extends AnimatedSprite2D

@onready var times_up = $"../../SFX/times_up"

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.connect("times_up", _on_times_up)
	
	visible = false

func _on_times_up():
	visible = true
	play()
	times_up.play()
	get_tree().paused = true
