extends Area2D

@onready var fake_visual_coin: Sprite2D = $fake_visual_coin

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_tree().get_nodes_in_group("Player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_body_entered(body):
	if body.is_in_group("Player"):
		collect_coin()

func collect_coin():
	# 1. Disable immediately so it can't be collected twice
	call_deferred("set_monitoring", false)
	
	# 2. Hide the real coin (so it looks like we picked it up)
	hide()
	
	# 3. Create the visual effect
	spawn_flying_coin()
	
	# 4. Play Sound (Optional)
	# $AudioStreamPlayer2D.play()

func spawn_flying_coin():
	# --- A. SETUP THE FAKE COIN ---
	var fake_coin = Sprite2D.new()
	fake_coin.texture = fake_visual_coin.texture
	fake_coin.scale = scale # Match size
	fake_coin.z_index = 100 # Ensure it draws on top of everything
	
	# --- B. FIND THE DESTINATION ---
	# Find the UI element we tagged in Step 1
	var target_node = get_tree().get_first_node_in_group("CoinHUD")
	if not target_node:
		print("Error: No node in group 'CoinHUD' found!")
		queue_free()
		return

	# --- C. CALCULATE POSITIONS ---
	# CRITICAL: We must convert World Position (Game) to Screen Position (UI)
	# This math gets where the coin is on the player's screen right now.
	var start_pos = get_global_transform_with_canvas().origin
	
	# The target is already on the screen (UI), so we just use its global position.
	# We add size/2 to aim for the center of the icon, not the top-left corner.
	var target_pos = target_node.global_position
	if target_node is AnimatedSprite2D:
		var frames = target_node.sprite_frames
		# Get the size of the current animation's first frame
		if frames and frames.has_animation(target_node.animation):
			var tex = frames.get_frame_texture(target_node.animation, target_node.frame)
			var size = tex.get_size() * target_node.scale # Account for scale!
			
			# Add half size to center it
			# Note: If Centered is ON (default), global_position is ALREADY the center.
			if not target_node.centered:
				target_pos += size / 2
	# If it's a standard UI node (TextureRect/Label)
	elif "size" in target_node:
		target_pos += target_node.size / 2

	# --- D. ADD TO SCENE ---
	# We add it to the CanvasLayer so it sticks to the screen, not the map!
	# (Assuming your UI is in a CanvasLayer. If not, we add to current scene)
	var canvas_layer = get_tree().get_first_node_in_group("UI_Layer") # Optional safety
	if canvas_layer:
		canvas_layer.add_child(fake_coin)
	else:
		get_tree().root.add_child(fake_coin)
	
	fake_coin.global_position = start_pos
	
	# --- E. ANIMATE (TWEEN) ---
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK) # Adds a little "bounce" effect
	tween.set_ease(Tween.EASE_IN)
	
	# Move to target over 0.6 seconds
	tween.tween_property(fake_coin, "global_position", target_pos, 0.6)
	
	# Shrink it as it flies (optional)
	tween.parallel().tween_property(fake_coin, "scale", Vector2(0.2, 0.2), 0.6)
	
	# --- F. CLEANUP ---
	# When animation is done:
	await tween.finished
	
	# 1. Add the actual score NOW (so the number updates when the coin arrives)
	SignalBus.emit_signal("collect_coin") # Or however you handle score
	
	# 2. Delete the fake coin and the real coin object
	fake_coin.queue_free()
	queue_free()
