extends RigidBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var wing_sprite: AnimatedSprite2D = $wing_sprite

@export var tilt_strength: float = 2000.0 * Global.input_sensitivity
@export var spin_speed: float = 0.03 # Controls how fast the visual spin is

@onready var base_scale = sprite_2d.scale

var input_enabled: bool = false
var should_reset: bool = false
var force_rotation_lock: bool = false

# Keeps track of the total distance traveled
var rolled_accumulator = Vector2.ZERO

var shader_material: ShaderMaterial

# Remember where the player should reset position to 
var current_start_pos = Vector2.ZERO

var inventory = ["none", "none", "none"]
@onready var slots = [$"../InGameUIs/powerup_slot1",
	$"../InGameUIs/powerup_slot2",
	$"../InGameUIs/powerup_slot3",
]

@onready var maze: TileMapLayer = $"../maze"
@onready var hazard_tiles: TileMapLayer = $"../hazard_tiles"

# Power up variables
var ghost_charges = 0
var was_inside_wall: bool = false
var wing_timer = 0.0
var is_flying: bool = false
var is_magnet_active: bool = false
var magnet_timer: float = 0.0
var magnet_radius: float = 800.0  # How far the magnet reaches (in pixels)
var magnet_strength: float = 1000.0 # How fast coins fly to you

# hazard
var hazard_fiery = Vector2i(1, 0)

# Add this flag at the top of your script with other variables
var is_falling: bool = false

# Settings for wall impacts
var _previous_velocity: Vector2 = Vector2.ZERO
var min_impact_speed: float = 100.0  # Minimum speed to trigger a "thud"
var last_wall_hit_time: float = 0.0
var wall_hit_cooldown: float = 0.15  # 150ms delay between hits to prevent spam

# sfx
@onready var roll_sfx = $SFX/roll_sfx
@onready var collect_powerup_sfx = $SFX/collect_powerup_sfx
@onready var ghost_sfx = $SFX/ghost_sfx
@onready var wing_sfx = $SFX/wing_sfx
@onready var magnet_sfx = $SFX/magnet_sfx
@onready var hit_wall_sfx = $SFX/hit_wall_sfx

# Tweak these numbers to fit your game's speed
var max_speed = 300.0
var min_pitch = 0.8
var max_pitch = 1.5
var min_db = -80.0 # Silent
var max_db = 0.0   # Full volume

# Called when the node enters the scene tree for the first time.
func _ready():
	lock_rotation = false
	shader_material = sprite_2d.material as ShaderMaterial
	
	update_inventory_ui()
	
	SignalBus.connect("falling_into_hole", _on_falling_into_hole)

func set_start_position(pos: Vector2):
	current_start_pos = pos
	
	should_reset = true
	# Kill any existing movement immediately
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Capture the velocity BEFORE physics resolution happens
	_previous_velocity = linear_velocity
	
	var input_direction = Vector2.ZERO
	
	if OS.has_feature("mobile"):
		if input_enabled == true:
			var sensor_data = Input.get_gravity()
			input_direction = Vector2(sensor_data.x, -sensor_data.y)
			input_direction = input_direction / 5
	else:
		if input_enabled == true:
			input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") / 4

	if hazard_tiles.get_cell_atlas_coords(hazard_tiles.local_to_map(hazard_tiles.to_local(global_position))) == Vector2i(0, 1):
		linear_damp = -1.0
	elif hazard_tiles.get_cell_atlas_coords(hazard_tiles.local_to_map(hazard_tiles.to_local(global_position))) == Vector2i(1, 1):
		linear_damp = 4.0
	else:
		linear_damp = 1.0

	var force = input_direction * tilt_strength
	apply_central_force(force)
	
	# The easy way
	rotate_marble_visuals(delta)
	
	# The hard way
	#update_rolling_shader(delta)
	
	# movement_tile_logic()
	#if movement_tiles.get_cell_atlas_coords(movement_tiles.local_to_map(movement_tiles.to_local(global_position))) == Vector2i(0, 1):
	#	print("hi")
	
	if ghost_charges > 0:
		handle_ghost_logic()
	
	if is_flying:
		wing_timer -= delta
		if wing_timer <= 0:
			deactivate_wing()
	
	if is_magnet_active:
		handle_magnet_logic(delta)
		magnet_timer -= delta
		if magnet_timer <= 0:
			deactivate_magnet()
	
	# Get the current speed of the player
	var current_speed = linear_velocity.length()
	
	# Calculate the "Visual Spin Force" (The same math used in rotate_marble_visuals)
	# x_spin is linear_velocity.x
	# y_spin is -linear_velocity.y
	# So effective spin is: (velocity.x - velocity.y)
	var visual_spin_force = abs(linear_velocity.x - linear_velocity.y)
	
	# CONDITION: Must be moving AND actually rotating visually
	# We use > 10.0 as a buffer so it doesn't flicker when barely spinning
	if current_speed > 1.0 and visual_spin_force > 10.0:
		if not roll_sfx.playing:
			roll_sfx.play()
		
		# 1. VOLUME 
		var target_vol = lerp(-30.0, -10.0, current_speed / 50.0)
		roll_sfx.volume_db = clamp(target_vol, -80.0, -10.0)
		
		# 2. PITCH 
		# We calculate RPM based on the visual spin force now, for accuracy
		var visual_rpm = visual_spin_force * spin_speed
		var target_pitch = lerp(0.8, 1.2, visual_rpm / 1.5)
		
		roll_sfx.pitch_scale = lerp(roll_sfx.pitch_scale, target_pitch, delta * 5.0)
	else:
		# 1. Fade volume fast (was 50, now 400 for instant stop)
		if roll_sfx.volume_db > -80:
			roll_sfx.volume_db -= 400 * delta
		
		# 2. Also drop the pitch down to 0.1 so it sounds like it's grinding to a halt
		# We use 'move_toward' to smoothly slide the pitch down
		roll_sfx.pitch_scale = move_toward(roll_sfx.pitch_scale, 0.1, 2.0 * delta)
		
		# 3. Optional: Stop the sound completely if it's silent to save CPU
		if roll_sfx.volume_db <= -79:
			roll_sfx.stop()
		
	# 2. HANDLE PITCH (Faster = Higher Pitch)
	# Map speed to pitch: Slow = 0.8x, Fast = 1.5x
	var new_pitch = lerp(min_pitch, max_pitch, current_speed / max_speed)
	roll_sfx.pitch_scale = new_pitch

func update_rolling_shader(delta):
	# 1. Add the distance moved this frame to our total counter.
	# (Velocity = pixels per second. * delta = pixels moved this frame).
	rolled_accumulator += linear_velocity * delta
	
	# 2. Send this total distance to the shader
	if shader_material:
		shader_material.set_shader_parameter("roll_offset", rolled_accumulator)
		
func rotate_marble_visuals(delta):
	if is_flying:
		return
		
	# 1. Get horizontal movement (Right = Clockwise, Left = Counter-Clockwise)
	var x_spin = linear_velocity.x
	
	# 2. Get vertical movement
	# Up (-Y) -> Right Spin (+Rot)
	# Down (+Y) -> Left Spin (-Rot)
	var y_spin = -linear_velocity.y
	
	# 3. Combine them
	# If moving diagonally, these might cancel out slightly, but that actually
	# looks okay (it implies sliding).
	var total_spin = (x_spin + y_spin) * spin_speed * delta
	
	sprite_2d.rotation += total_spin

func _input(event):
	if event.is_action_pressed("ui_accept"):
		advance_level()

func advance_level():
	# 1. Increase Level Counter
	Global.current_level += 1
	
	SignalBus.emit_signal("switch_level")
		
		# 4. Optional: Reset Player Physics State if needed
		# (The move_player_to_start function inside mazegen handles position,
		# but you might want to reset velocity here to be safe)
		#state_reset_needed = true # Trigger your _integrate_forces reset

# 1. Trigger the flag
func reset_position():
	if is_flying:
		return
		
	should_reset = true

# 2. Handle the actual movement safely inside the physics loop
func _integrate_forces(state):
	if should_reset:
		# Teleport the body
		state.transform.origin = current_start_pos
		
		# Kill all momentum (stop it from flying)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		
		# Reset the visual rolling counter
		rolled_accumulator = Vector2.ZERO
		
		# Turn the flag off so we don't get stuck at (0,0)
		should_reset = false
	
	if force_rotation_lock:
		# 1. Kill any spinning momentum instantly
		state.angular_velocity = 0
		
		# 2. Force the rotation angle to 0 (Upright)
		# This overrides any collision that tried to tilt you this frame
		var new_transform = state.transform
		new_transform.x = Vector2(1, 0) # X axis points Right
		new_transform.y = Vector2(0, 1) # Y axis points Down
		state.transform = new_transform
	
	# iterate through all current contacts using the 'state' object
	for i in range(state.get_contact_count()):
		# Get the object we hit
		var body = state.get_contact_collider_object(i)
		
		# Check if we hit the wall
		if body == maze:
			# Get the "Normal" (The direction the wall is facing)
			# e.g., If we hit a right-side wall, normal points LEFT.
			var normal = state.get_contact_local_normal(i)
			
			# 3. Calculate Impact Intensity
			# We compare our Velocity with the Wall's Normal.
			# dot() returns how much of our velocity is opposing the normal.
			# If we slam head-on, this number is high. If we slide along, it's near 0.
			# We use negative (-) because velocity goes IN, normal comes OUT.
			var impact_intensity = -_previous_velocity.dot(normal)
			
			# 4. Check Threshold & Cooldown
			var current_time = Time.get_ticks_msec() / 1000.0
			
			if impact_intensity > min_impact_speed and (current_time - last_wall_hit_time) > wall_hit_cooldown:
				_play_wall_hit(impact_intensity)
				last_wall_hit_time = current_time
				
		# Check if we hit the Hazard TileMapLayer
		if body == hazard_tiles:
			print("hit hazard?")
			# Get the collision normal (direction of the wall face)
			var normal = state.get_contact_local_normal(i)
			# Get the collision point
			var contact_pos = state.get_contact_local_position(i)
			
			# Nudge the point slightly "into" the wall to grab the correct tile coordinate
			# We subtract the normal to go 'in'
			var check_pos = contact_pos - (normal * 5.0)
			
			# Convert global/local pixel pos to Grid Coordinates
			var local_check_pos = hazard_tiles.to_local(check_pos)
			var map_pos = hazard_tiles.local_to_map(local_check_pos)
			
			# Check if the tile is Fire
			if hazard_tiles.get_cell_atlas_coords(map_pos) == hazard_fiery:
				# We can't call 'die()' directly inside integrate_forces safely sometimes,
				# so we defer it or set a flag. Since reset_position() just sets a flag, it is safe!
				print("Burned!")
				reset_position()
				break # Stop checking other contacts if we are dead

func _play_wall_hit(intensity: float):
	# A. HANDLE AUDIO
	# Map intensity (e.g., 100 to 600) to Volume (-20dB to 0dB)
	# The harder you hit, the louder the thud.
	var volume = lerp(-20.0, 0.0, (intensity - min_impact_speed) / 500.0)
	hit_wall_sfx.volume_db = clamp(volume, -30.0, 0.0)
	
	# Random pitch slightly so it doesn't sound robotic
	hit_wall_sfx.pitch_scale = randf_range(0.9, 1.1)
	hit_wall_sfx.play()
	
	# B. HANDLE VIBRATION
	# Only vibrate if the user is on mobile
	if OS.has_feature("mobile"):
		if intensity > 400.0:
			 # HARD HIT: Longer vibration (simulated "Heavy")
			Input.vibrate_handheld(100)
		elif intensity > min_impact_speed:
			 # LIGHT HIT: Short crisp tap (simulated "Light")
			Input.vibrate_handheld(20)

func collect_powerup(powerup_type: String):
	# Logic: Find the first empty slot. If full, replace the last one.
	
	var slot_found = -1
	
	# Check Slot 0, then 1, then 2
	for i in range(3):
		if inventory[i] == "none":
			slot_found = i
			break
	
	if slot_found != -1:
		# Found an empty spot! Fill it.
		inventory[slot_found] = powerup_type
		print("Picked up: ", powerup_type)
		print("Inventory: ", inventory)
		update_inventory_ui()
		collect_powerup_sfx.play()
		
		return true
	else:
		# return false ensures power up stay on ground 
		print("Inventory full!")
		return false

func use_item_at_index(index: int):
	var type = inventory[index]
	
	if type == "none":
		return # Empty slot, do nothing
	
	# Activate the effect
	if type == "ghost":
		activate_ghost(3)
	elif type == "wing":
		activate_wing(8.0)
	elif type == "magnet":
		activate_magnet(15.0)
		
	# Clear JUST this slot
	inventory[index] = "none"
	
	# Optional: Shift items? (e.g. Item 2 moves to Item 1?)
	# For now, let's keep it simple: Just clear the slot.
	
	update_inventory_ui()

func update_inventory_ui():
	for i in range(3):
		var type = inventory[i]
		var button_node = slots[i]
		
		if button_node.has_method("update_visuals"):
			button_node.update_visuals(type)

func activate_ghost(charges: int):
	Global.powerups_used += 1
	ghost_sfx.play()
	ghost_charges = charges
	was_inside_wall = false
	
	# Disable collision with walls
	collision_mask = 2
	
	# Visual Cue: Make player semi-transparent
	modulate.a = 0.5
	print("Ghost Mode Activated! Charges: ", ghost_charges)

func handle_ghost_logic():
	# Convert global position to local since maze scale is 9.0
	var local_pos = maze.to_local(global_position)
	
	# Get the tile coordinate under the player
	var tile_pos = maze.local_to_map(local_pos)
	#print(tile_pos)
	
	# 2. Check what kind of tile is there (Layer 0)
	var tile_atlas_coords = maze.get_cell_atlas_coords(tile_pos)
	#print(tile_atlas_coords)
	
	# Based on your mazegen script: Wall is (0,0), Floor is (0,1)
	var is_wall = (tile_atlas_coords == Vector2i(0, 0))
	
	if is_wall:
		# We are currently inside a wall
		was_inside_wall = true
	else:
		# We are currently on the floor
		if was_inside_wall:
			# We JUST exited a wall! Consumed 1 charge.
			ghost_charges -= 1
			was_inside_wall = false
			print("Passed through wall! Charges left: ", ghost_charges)
			
			# If we ran out of charges, turn solid again
			if ghost_charges <= 0:
				ghost_charges = 0
				collision_mask = 1 # Reset to default (Collide with Walls/Layer 1)
				modulate.a = 1.0 # Fully opaque
				print("Ghost Mode Deactivated")

func activate_wing(duration):
	Global.powerups_used += 1
	wing_sfx.play()
	is_flying = true
	wing_timer = duration
	wing_sprite.show()
	
	force_rotation_lock = true
	sprite_2d.rotation = 0
	
	print("Wing Activated! Flying for ", duration, "s")

func deactivate_wing():
	is_flying = false
	wing_sprite.hide()
	
	force_rotation_lock = false
	
	print("Wing Deactivated")

func activate_magnet(duration):
	Global.powerups_used += 1
	magnet_sfx.play()
	is_magnet_active = true
	magnet_timer = duration
	print("Magnet Activated! Range: ", magnet_radius)

func handle_magnet_logic(delta):
	# 1. Find all coins in the level
	var all_coins = get_tree().get_nodes_in_group("Coins")
	
	for coin in all_coins:
		# 2. Check distance
		var dist = global_position.distance_to(coin.global_position)
		if dist < magnet_radius:
			# 3. Move the coin towards the player
			# move_toward calculates the new position for us
			coin.global_position = coin.global_position.move_toward(global_position, magnet_strength * delta)

func deactivate_magnet():
	is_magnet_active = false
	print("Magnet Deactivated")

func movement_tile_logic():
	pass
	# Convert global position to local since maze scale is 9.0
	# var local_pos = movement_tiles.to_local(global_position)
	# Get the tile coordinate under the player
	# var tile_pos = movement_tiles.local_to_map(local_pos)
	#print(tile_pos)

	# 2. Check what kind of tile is there (Layer 0)
	#if movement_tiles.get_cell_atlas_coords(tile_pos) == Vector2i(0, 1):
	#	print("tile_atlas_coords")
	

func _on_powerup_slot_1_released():
	use_item_at_index(0)

func _on_powerup_slot_2_released():
	use_item_at_index(1)

func _on_powerup_slot_3_released():
	use_item_at_index(2)

func _on_falling_into_hole(hole_center_pos: Vector2):
	# 1. GUARD: Prevent this from triggering multiple times
	if is_falling:
		return
	is_falling = true
	
	# 2. INSTANTLY Disable Real Player
	input_enabled = false
	collision_mask = 0       # Ghost mode (touch nothing)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	sleeping = true          # Stop physics calculations
	hide()                   # Vanish the real body
	
	# 3. CREATE THE STUNT DOUBLE
	var stunt_double = Sprite2D.new()
	stunt_double.texture = sprite_2d.texture
	stunt_double.scale = sprite_2d.scale
	stunt_double.global_position = global_position
	stunt_double.rotation = sprite_2d.rotation
	stunt_double.z_index = 2
	
	# Important: Add it to the SCENE ROOT, not the player
	# This ensures it moves independently of the rigid body
	get_tree().root.add_child(stunt_double)
	
	# 4. ANIMATE THE DOUBLE
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	
	var fall_duration = 1.0
	
	# Move to center, Shrink to nothing, Spin wildy
	tween.tween_property(stunt_double, "global_position", hole_center_pos, fall_duration)
	tween.tween_property(stunt_double, "scale", Vector2.ZERO, fall_duration)
	tween.tween_property(stunt_double, "rotation", stunt_double.rotation + 10.0, fall_duration)
	
	# Optional: Play falling sound
	# roll_sfx.pitch_scale = 0.5
	# roll_sfx.play()

	# 5. WAIT & CLEANUP
	await tween.finished
	stunt_double.queue_free() # Delete the fake marble
	
	# 6. RESET REAL PLAYER
	Global.deaths += 1
	reset_position() # Teleports the hidden real body
	
	# Wait for physics to process the teleport
	await get_tree().physics_frame
	
	# 7. RESTORE REAL PLAYER
	show()
	collision_mask = 1       # Restore collisions (Layer 1)
	sleeping = false         # Wake up physics
	sprite_2d.scale = base_scale
	sprite_2d.rotation = 0
	
	input_enabled = true
	is_falling = false       # Reset flag so we can fall again later
