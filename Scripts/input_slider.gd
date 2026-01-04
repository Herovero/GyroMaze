extends HSlider

func _ready():
	#pass
	value_changed.connect(_on_value_changed)
	value = Global.input_sensitivity
	
func _gui_input(event):
	if event is InputEventKey:
		accept_event()

func _on_value_changed(new_value):
	#pass
	Global.input_sensitivity = new_value
