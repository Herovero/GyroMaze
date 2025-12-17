extends TouchScreenButton

@onready var paused_label: Label = $"../PAUSED_label"

var game_paused: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	paused_label.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_released():
	get_tree().paused = true
	paused_label.show()
