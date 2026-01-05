extends Node

# Get the audio stream player (adjust the path to match your Scene Tree)
@onready var bgm = $AudioStreamPlayer

func _ready():
	get_tree().scene_changed.connect(_on_scene_changed)
	bgm.play()

func _on_scene_changed():
	if bgm:
		bgm.stop()
