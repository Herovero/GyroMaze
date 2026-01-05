extends Node

var current_level = 1
var input_sensitivity = 1

var coins_collected: int = 0
var levels_passed: int = 0
var powerups_used: int = 0
var deaths: int = 0
var time_spent: float = 0.0

# Add a switch to turn the timer on/off
var is_game_active: bool = false

func _process(delta):
	# If the game is running, add the frame time to our counter
	if is_game_active:
		time_spent += delta

# Call this when you start a fresh run (e.g. from Main Menu)
func reset_stats():
	coins_collected = 0
	levels_passed = 0
	powerups_used = 0
	deaths = 0
	time_spent = 0.0
	current_level = 1
	is_game_active = true

# Helper to get the nice "MM:SS" string for your result screen
func get_time_formatted() -> String:
	var total_seconds = int(time_spent)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	return "%d:%02d" % [minutes, seconds]
