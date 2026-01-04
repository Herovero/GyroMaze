extends TextureRect

@onready var paper_flip_sfx = $"../../SFX/paper_flip"
@onready var stamp_hud = $stamp_hud

@onready var coins_value = $ValueContainer/coins_value
@onready var levels_value = $ValueContainer/levels_value
@onready var powerups_value = $ValueContainer/powerups_value
@onready var deaths_value = $ValueContainer/deaths_value
@onready var time_value = $ValueContainer/time_value

# We need to remember where the paper is supposed to sit when finished
var target_pos: Vector2

func _ready():
	# 1. Listen for the Game Over signal
	SignalBus.connect("times_up", _on_times_up)
	
	# 2. Remember the center position you set in the editor
	target_pos = position
	
	# 3. Move the paper down below the screen immediately so it's hidden
	var screen_height = get_viewport_rect().size.y
	position.y = screen_height + 100 # +100 ensures it's fully off-screen
	
	# Keep it visible=true so the Tween can show it moving, 
	# but since it's off-screen, the player won't see it yet.
	visible = false 
	
	# Clear the text initially so the paper looks blank when it slides up
	clear_values()

func _on_times_up():
	await get_tree().create_timer(3).timeout
	
	visible = true
	
	# 1. Play the "Swish" sound
	paper_flip_sfx.play()
	
	# Change these numbers manually to test different stamps!
	var test_stats = {
		"deaths": 6,
		"level": 36,
		"coins": 48,
		"powerups": 9,     # Add this key
		"time_str": "15.00" # Add this key (formatted string)
	}
	
	# 2. Create the Animation
	var tween = create_tween()
	
	# TRANS_BACK gives it that slight "overshoot" or bounce 
	# making it feel like real heavy paper slapping down.
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	# Slide from current position (bottom) to target_pos (center) over 0.6 seconds
	tween.tween_property(self, "position", target_pos, 0.6)
	
	# Wait for slide to finish, then fill in the text
	tween.tween_interval(0.5)
	tween.tween_callback(func(): show_value(test_stats))
	
	# Wait for slide to finish, then slam the stamp
	tween.tween_interval(3.0)
	tween.tween_callback(func(): stamp_hud.apply_stamp(test_stats))

func show_value(stats: Dictionary):
	await get_tree().create_timer(0.4).timeout
	
	pop_in_label(coins_value, str(stats["coins"]))
	await get_tree().create_timer(0.4).timeout
	
	pop_in_label(levels_value, str(stats["level"]))
	await get_tree().create_timer(0.4).timeout
	
	pop_in_label(powerups_value, str(stats["powerups"]))
	await get_tree().create_timer(0.4).timeout
	
	pop_in_label(deaths_value, str(stats["deaths"]))
	await get_tree().create_timer(0.4).timeout 
	
	pop_in_label(time_value, str(stats["time_str"]))

func pop_in_label(label: Label, text_value: String):
	# 1. Set the text immediately
	label.scale = Vector2.ZERO
	
	# 2. Set the text
	label.text = text_value
	
	# 3. IMPORTANT: Reset pivot to center so it scales from the middle
	# We wait one frame to ensure Godot has calculated the new text size
	label.pivot_offset = label.size / 2
	
	# 4. Animate to Scale 1 (Normal)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK) # Makes it "pop" out slightly
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.4)
	
	# Optional: Add a small "pop" sound here if you have one!
	# pop_sfx.play()

func clear_values():
	coins_value.text = ""
	levels_value.text = ""
	powerups_value.text = ""
	deaths_value.text = ""
	time_value.text = ""
