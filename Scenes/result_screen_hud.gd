extends TextureRect

@onready var paper_flip_sfx = $"../../SFX/paper_flip"

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

func _on_times_up():
	await get_tree().create_timer(3).timeout
	
	visible = true
	
	# 1. Play the "Swish" sound
	paper_flip_sfx.play()
	
	# 2. Create the Animation
	var tween = create_tween()
	
	# TRANS_BACK gives it that slight "overshoot" or bounce 
	# making it feel like real heavy paper slapping down.
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	# Slide from current position (bottom) to target_pos (center) over 0.6 seconds
	tween.tween_property(self, "position", target_pos, 0.6)
