extends TouchScreenButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_released():
	var player_cam = get_tree().get_first_node_in_group("PlayerCam")
	var overview_cam = get_tree().get_first_node_in_group("OverviewCam")
	
	if not player_cam or not overview_cam:
		print("Error: Cameras not found!")
		return

	# 2. Toggle Logic
	# If Player Camera is on, turn it off and turn Overview on.
	if player_cam.is_enabled():
		player_cam.enabled = false
		overview_cam.enabled = true
		texture_normal = preload("res://Assets/uis/zoomin_button.png")
	else:
		player_cam.enabled = true
		overview_cam.enabled = false
		texture_normal = preload("res://Assets/uis/zoomout_button.png")
