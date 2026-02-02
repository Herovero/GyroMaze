extends HSlider

@onready var bgm_slider = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	var bgm_index = AudioServer.get_bus_index("Music")
	
	# DEBUG 1: Check if the bus exists
	#print("DEBUG: Music Bus Index found: ", bgm_index)
	
	bgm_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_index))

# Connect this to the "value_changed" signal of your BGM Slider
func _on_value_changed(_new_value):
	var bus_index = AudioServer.get_bus_index("Music")
	
	# linear_to_db converts 0.0-1.0 to logarithmic Decibels (e.g., -80dB to 0dB)
	# This makes the slider feel natural to the human ear
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
