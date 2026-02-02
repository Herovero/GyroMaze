extends Label

@onready var timer: Timer = $"../../Time_countdown"

var player
var has_game_ended: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	
	SignalBus.connect("times_up", _on_times_up)
	
	text = "0"
	if not SignalBus.is_connected("switch_level", _on_level_start):
		SignalBus.connect("switch_level", _on_level_start)
	
	# 2. Connect to the Timer's timeout (To hide label when done)
	if not timer.is_connected("timeout", _on_timer_timeout):
		timer.connect("timeout", _on_timer_timeout)

	# Start the first countdown immediately
	_on_level_start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not timer.is_stopped():
		# ceil() ensures we see "3", "2", "1" instead of "2", "1", "0"
		text = str(int(ceil(timer.time_left)))

func _on_level_start():
	Global.is_game_active = false
	player.input_enabled = false
	
	visible = true
	text = str(timer.wait_time)
	timer.stop()
	timer.start()

func _on_timer_timeout():
	# When time is up, hide the label
	visible = false
	if player:
		if !has_game_ended:
			player.input_enabled = true
	
	Global.is_game_active = true
	SignalBus.emit_signal("game_started")

func _on_times_up():
	has_game_ended = true
