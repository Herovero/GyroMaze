extends Label

@onready var timer: Timer = $"../../Time_countdown"

var player
var has_game_ended: bool = false
var last_displayed_number: int = -1 # Keeps track of the last number we showed

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	
	SignalBus.connect("times_up", _on_times_up)
	
	text = ""
	visible = false
	
	if not SignalBus.is_connected("switch_level", _on_level_start):
		SignalBus.connect("switch_level", _on_level_start)
	
	# 2. Connect to the Timer's timeout (To hide label when done)
	if not timer.is_connected("timeout", _on_timer_timeout):
		timer.connect("timeout", _on_timer_timeout)

	# Start the first countdown immediately
	_on_level_start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not timer.is_stopped():
		# ceil() ensures we see "3", "2", "1" instead of "2", "1", "0"
		#text = str(int(ceil(timer.time_left)))
		# 1. Calculate the current number
		var current_number = int(ceil(timer.time_left))
		
		# 2. Only update if the number has CHANGED (e.g., 3 -> 2)
		if current_number != last_displayed_number and current_number > 0:
			update_display(current_number)

func update_display(number: int):
	last_displayed_number = number
	text = str(number)
	animate_pop_effect()

func animate_pop_effect():
	# A. Center the Pivot so it scales from the middle, not top-left
	pivot_offset = size / 2
	
	# B. Reset Start State (Big and Invisible)
	scale = Vector2(2.5, 2.5) 
	modulate.a = 0.0
	
	# C. Create Tween
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK) # This gives it a nice "bouncy" pop
	
	# D. Animate to Normal Size and Opaque
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _on_level_start():
	Global.is_game_active = false
	if player:
		player.input_enabled = false
	
	visible = false  # Hide initially so we don't see a static number during the wait
	last_displayed_number = -1 
	timer.stop()
	
	await get_tree().create_timer(1).timeout
	
	visible = true
	update_display(3)
	
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
