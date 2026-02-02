extends TouchScreenButton

@onready var paused_label = $"../PAUSED_label"
@onready var resume_button = $"../ResumeButton"
@onready var skip_button = $"."
@onready var quit_button = $"../QuitButton"
@onready var pause_background = $"../PauseBackground"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_released():
	get_tree().paused = false
	paused_label.hide()
	resume_button.hide()
	skip_button.hide()
	quit_button.hide()
	pause_background.hide()
	SignalBus.emit_signal("times_up")
