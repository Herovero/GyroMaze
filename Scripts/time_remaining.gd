extends Label

@onready var timer: Timer = $"../../Time_remaining"
@onready var hud = $"../time_remaining_hud"
@onready var hud_transition = $"../../HUD_transition"
@onready var five_second_remaining = $"../../SFX & BGM/five_second_remaining"

@export var max_time_limit: float = 180.0

var player
var has_game_started: bool = false
var saved_time: float = 0.0
var amount: float

# This acts as a memory to know if we already started the sound
var alarm_has_started: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	
	visible = false
	hud.visible = false
	
	# Initialize our saved time to the full default time for first level
	saved_time = timer.wait_time
	
	SignalBus.connect("game_started", _on_game_started)
	SignalBus.connect("switch_level", _on_switch_level)
	SignalBus.connect("add_time", _on_add_time)
	
	timer.timeout.connect(_on_timer_timeout)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not timer.is_stopped():
		var time_left = timer.time_left
		update_display(time_left)
	
		# Check if we are in the danger zone (between 0 and 5 seconds)
		if time_left <= 5.0 and time_left > 0:
			# Only play if we haven't triggered it yet
			if not alarm_has_started:
				five_second_remaining.play()
				alarm_has_started = true
		
		# If we get a time bonus and go back above 5 seconds, reset the flag
		elif time_left > 5.0:
			if alarm_has_started:
				five_second_remaining.stop()
				alarm_has_started = false

func update_display(time_in_seconds):
	var total_seconds = int(ceil(time_in_seconds))
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	# Format string with padding
	# "%02d" means "make sure this number has at least 2 digits" (e.g., 5 becomes 05)
	text = "%d : %02d" % [minutes, seconds]
	
	if time_in_seconds <= 30:
		modulate = Color.RED
	else:
		# Reset to White (Normal)
		modulate = Color.WHITE

func _on_switch_level():
	has_game_started = false
	visible = false
	hud.visible = false
	
	# Capture exactly how much time was left when the player hit the flag.
	if not timer.is_stopped():
		saved_time = timer.time_left
	
	timer.stop()
	update_display(saved_time)
	
	# If level ends while beeping, kill the sound
	if alarm_has_started:
		five_second_remaining.stop()
		alarm_has_started = false

func _on_game_started():
	if has_game_started:
		return
		
	visible = true
	hud.visible = true
	has_game_started = true
	hud_transition.play("display_time_remaining")
	timer.start(saved_time)

func _on_add_time(amount):
	if not timer.is_stopped():
		var current_time = timer.time_left
		var new_time = min(current_time + amount, max_time_limit)
		timer.start(new_time)
		print_debug("Time Added! New time: ", new_time)

func _on_timer_timeout():
	# Update the display one last time so it clearly shows "0 : 00"
	update_display(0)
	
	# Emit the signal
	print_debug("Time is up!")
	SignalBus.emit_signal("times_up")
	Global.is_game_active = false
	
	# Ensure sound doesn't keep looping if you have Loop enabled on the mp3
	if alarm_has_started:
		five_second_remaining.stop()
		alarm_has_started = false
