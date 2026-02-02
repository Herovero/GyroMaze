extends HSlider

@onready var sfx_slider = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	var sfx_index = AudioServer.get_bus_index("SFX")
	
	# DEBUG 1: Check if the bus exists
	#print("DEBUG: SFX Bus Index found: ", sfx_index)
	
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_index))

# Connect this to the "value_changed" signal of your SFX Slider
func _on_value_changed(_new_value):
	var bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
