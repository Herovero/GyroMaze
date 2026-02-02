extends TouchScreenButton

@onready var paused_label: Label = $"../PauseMenu/PAUSED_label"
@onready var pause_sfx = $"../../SFX & BGM/pause_sfx"
@onready var resume_button = $"../PauseMenu/ResumeButton"
@onready var skip_button = $"../PauseMenu/SkipButton"
@onready var quit_button = $"../PauseMenu/QuitButton"
@onready var pause_background = $"../PauseMenu/PauseBackground"

# Called when the node enters the scene tree for the first time.
func _ready():
	paused_label.hide()
	resume_button.hide()
	skip_button.hide()
	quit_button.hide()
	pause_background.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_released():
	if not Global.is_game_active:
		return
		
	hide()
	get_tree().paused = true
	paused_label.show()
	resume_button.show()
	skip_button.show()
	quit_button.show()
	pause_background.show()
	pause_sfx.play()
