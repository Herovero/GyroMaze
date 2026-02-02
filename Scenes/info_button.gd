extends TouchScreenButton

@onready var settings_labels = $"../Settings/SettingsLabels"
@onready var tutorial_label = $"../Settings/TutorialLabel"
@onready var sfx_volume_slider = $"../Settings/SFXVolumeSlider"
@onready var bgm_volume_slider = $"../Settings/BGMVolumeSlider"
@onready var input_slider = $"../Settings/InputSlider"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_released():
	if settings_labels.visible:
		tutorial_label.show()
		settings_labels.hide()
		sfx_volume_slider.hide()
		bgm_volume_slider.hide()
		input_slider.hide()
	elif tutorial_label.visible:
		settings_labels.show()
		tutorial_label.hide()
		sfx_volume_slider.show()
		bgm_volume_slider.show()
		input_slider.show()
