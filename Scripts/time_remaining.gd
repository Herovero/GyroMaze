extends Label

@onready var timer: Timer = $"../../Time_remaining"

@export var max_time_limit: float = 180.0

var player
var has_game_started: bool = false
var saved_time: float = 0.0
var amount: float

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	
	visible = false
	
	# Initialize our saved time to the full default time for first level
	saved_time = timer.wait_time
	
	SignalBus.connect("game_started", _on_game_started)
	SignalBus.connect("switch_level", _on_switch_level)
	SignalBus.connect("add_time", _on_add_time)
	
	#_on_switch_level()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not timer.is_stopped():
		update_display(timer.time_left)

func update_display(time_in_seconds):
	var total_seconds = int(ceil(time_in_seconds))
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	# Format string with padding
	# "%02d" means "make sure this number has at least 2 digits" (e.g., 5 becomes 05)
	text = "%d : %02d" % [minutes, seconds]

func _on_switch_level():
	has_game_started = false
	
	# Capture exactly how much time was left when the player hit the flag.
	if not timer.is_stopped():
		saved_time = timer.time_left
	
	timer.stop()
	update_display(saved_time)

func _on_game_started():
	if has_game_started:
		return
		
	visible = true
	has_game_started = true
	timer.start(saved_time)

func _on_add_time(amount):
	if not timer.is_stopped():
		var current_time = timer.time_left
		var new_time = min(current_time + amount, max_time_limit)
		timer.start(new_time)
		print_debug("Time Added! New time: ", new_time)
