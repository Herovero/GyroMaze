extends TouchScreenButton

@onready var paused_label = $"../PAUSED_label"
@onready var pause_button: TouchScreenButton = $"../../PauseButton"
@onready var skip_button = $"../SkipButton"
@onready var quit_button = $"../QuitButton"
@onready var pause_background = $"../PauseBackground"
@onready var unpause_sfx = $"../../../SFX & BGM/unpause_sfx"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_released():
	get_tree().paused = false
	hide()
	pause_button.show()
	paused_label.hide()
	skip_button.hide()
	quit_button.hide()
	pause_background.hide()
	unpause_sfx.play()
