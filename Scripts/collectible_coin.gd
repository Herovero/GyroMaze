extends Area2D

@onready var fake_visual_coin: Sprite2D = $fake_visual_coin
@onready var collect_coin_sfx = $collect_coin_sfx

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
	Global.coins_collected += 1
	collect_coin_sfx.play()
	
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
	fake_coin.scale = fake_visual_coin.global_scale
	fake_coin.z_index = 100 
	
	# --- B. FIND THE DESTINATION (Target Icon) ---
	var target_node = get_tree().get_first_node_in_group("CoinHUD")
	if not target_node:
		print("Error: CoinHUD missing!")
		queue_free()
		return

	# --- C. CALCULATE START & END POSITIONS ---
	
	# 1. Start Position: Convert "Maze World Space" to "UI Screen Space"
	# This ensures the fake coin spawns exactly on top of the real coin visually.
	var start_pos = get_global_transform_with_canvas().origin
	
	# 2. End Position: The UI Icon
	var target_pos = target_node.global_position
	
	# Center the target calculation (Your existing logic was good!)
	if target_node is Control: # For TextureRect/Label
		target_pos += target_node.size / 2
	elif target_node is Node2D: # For Sprite2D
		# If it's not centered, offset it. If it IS centered, global_pos is already center.
		if "centered" in target_node and not target_node.centered:
			var tex_size = target_node.texture.get_size() * target_node.scale
			target_pos += tex_size / 2

	# --- D. PARENTING (The "Middle of Layer" Fix) ---
	
	# Find the specific "InGameUIs" CanvasLayer using our new Group
	var ui_layer = get_tree().get_first_node_in_group("GameUICanvasLayer")
	
	if ui_layer:
		ui_layer.add_child(fake_coin)
	else:
		# Fallback: Add to the current scene root if UI layer is missing
		get_tree().root.add_child(fake_coin)
	
	# Apply the calculated screen position
	fake_coin.global_position = start_pos
	
	# --- E. ANIMATE ---
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_property(fake_coin, "global_position", target_pos, 0.6)
	tween.parallel().tween_property(fake_coin, "scale", Vector2(0.2, 0.2), 0.6)
	
	await tween.finished
	
	SignalBus.emit_signal("collect_coin")
	fake_coin.queue_free()
	queue_free()
